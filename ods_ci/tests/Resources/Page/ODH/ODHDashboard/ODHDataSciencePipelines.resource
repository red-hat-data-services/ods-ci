*** Settings ***
Documentation       Collection of keywords to interact with Data Science Pipelines
Resource            ../../../RHOSi.resource
Resource            ../../../ODS.robot
Resource            ../../../Common.robot
Resource            ../../../Page/ODH/ODHDashboard/ODHDashboard.robot
Library             DateTime
Library             ../../../../../libs/DataSciencePipelinesAPI.py
Resource            ODHDataScienceProject/Pipelines.resource


*** Variables ***
${DATA_SCIENCE_PIPELINES_APPLICATION_YAML}=    ods_ci/tests/Resources/Files/data-science-pipelines-sample.yaml
${PIPELINES_IMPORT_BTN_FORM_XP}=    xpath://footer/button[text()="Import pipeline"]
${PIPELINE_NAME_INPUT_XP}=    id:pipeline-name
${PIPELINE_DESC_INPUT_XP}=    id:pipeline-description

*** Keywords ***
Install DataSciencePipelinesApplication CR
    [Documentation]    Install and verifies that DataSciencePipelinesApplication CRD is installed and working
    [Arguments]     ${project}
    Log    ${project}
    Oc Apply    kind=DataSciencePipelinesApplication    src=${DATA_SCIENCE_PIPELINES_APPLICATION_YAML}     namespace=${project}    # robocop: disable:line-too-long
    ${generation_value}    Run    oc get datasciencepipelinesapplications -n ${project} -o json | jq '.items[0].metadata.generation'    # robocop: disable:line-too-long
    Should Be True    ${generation_value} == 1    DataSciencePipelinesApplication created

Fill In Pipeline Import Form
    [Documentation]    Compiles the form to create a pipeline.
    ...                It works when you start server creation from either
    ...                DS Project details page or DS Pipelines page.
    [Arguments]    ${name}    ${filepath}    ${project_title}
    ...            ${description}=${NONE}
    Run Keyword And Continue On Failure    Element Should Be Disabled    ${PIPELINES_IMPORT_BTN_FORM_XP}
    Input Text    ${PIPELINE_NAME_INPUT_XP}    ${name}
    Input Text    ${PIPELINE_DESC_INPUT_XP}    ${description}
    ${rc}    ${pwd}=    Run And Return Rc And Output    echo $PWD
    Choose File    //div[@class="pf-c-file-upload"]//input[@type="file"]    ${pwd}/${filepath}
    Element Should Be Enabled    ${PIPELINES_IMPORT_BTN_FORM_XP}

Fill In Run Creation Form    # robocop: disable
    [Documentation]    Compiles the form to create a pipeline run.
    ...                It works when you start server creation from either
    ...                DS Project details page or DS Pipelines page.
    [Arguments]    ${name}    ${pipeline_name}=${NONE}    ${from_actions}=${TRUE}    ${run_type}=Immediate
    ...            ${trigger_type}=Periodic    ${start_date}=${NONE}    ${start_time}=${NONE}
    ...            ${end_date}=${NONE}    ${end_time}=${NONE}    ${cron_expr}=${NONE}&{model_param}
    Input Text    ${PIPELINE_NAME_INPUT_XP}    ${name}
    Input Text    ${PIPELINE_DESC_INPUT_XP}    ${name}
    Run Keyword And Warn On Failure    Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    IF    "${pipeline_name}" != "${NONE}"
        Select Pipeline For The Run    pipeline_name=${pipeline_name}
    END
    Element Should Be Enabled    ${GENERIC_CREATE_BTN_XP}
    # select run_type
    # set options based on run_type
    # change model param if required
    # check selected project
    # insert name
    # insert description
    # select pipeline
    # select run type
    # insert additional params based on run type
    # insert additinal params based on the model

Select Pipeline For The Run
    [Documentation]    Selects the given ${pipeline_name} from the pipeline
    ...                dropdown in the Run creation form.
    [Arguments]    ${pipeline_name}
    Wait Until Page Contains Element    xpath://section[@id="run-section-pipeline"]//span[@class="pf-c-dropdown__toggle-text"]/..
    Click Element    xpath://section[@id="run-section-pipeline"]//span[@class="pf-c-dropdown__toggle-text"]/..
    Wait Until Page Contains Element    xpath://ul/li/a[text()="${pipeline_name}"]
    Click Element     xpath://ul/li/a[text()="${pipeline_name}"]

Get Workflow Name From Topology Page
    [Documentation]    Returns the workflow name corresponding to the displayed pipeline.
    ...                The workflow name can be used to retrieve pods, for example
    ${workflow_name}=    Get Text    xpath://div/div[text()="Workflow name"]/following-sibling::div
    RETURN    ${workflow_name}

Delete Pipeline Run
    [Documentation]    Delete a pipeline that ran based on name and pipeline. From the left menu select
    ...                "Data Science Pipelines" -> Runs. In the new page, select the tab "Triggered".
    ...                The "Delete Pipeline Run" will search for a line in the grid that match the pipeline name and
    ...                the run name. Based on that, hit the ... Menu in the row and hit Delete drop down menu.
    [Arguments]    ${run_name}    ${pipeline_name}
    Navigate To Page    Data Science Pipelines    Runs
    Wait Until Page Contains Element    xpath://span[text()='Triggered']
    Click Element    //span[text()='Triggered']
    Pipelines.Click Action From Actions Menu    ${run_name}    Delete
    Handle Deletion Confirmation Modal    ${run_name}    triggered run
    Wait Until Page Contains Element    xpath://h2[contains(text(), 'No triggered runs yet')]

Delete Pipeline
    [Documentation]    Delete a pipeline. From the left menu select "Data Science Pipelines" -> Pipelines.
    ...                The "Delete Pipeline" will search for a line in the grid that match the pipeline name.
    ...                Based on that, hit the ... Menu in the row and hit Delete drop down menu.
    [Arguments]    ${pipeline_name}
    Navigate To Page    Data Science Pipelines    Pipelines
    Wait Until Page Contains Element    xpath://a[text()='${pipeline_name}']
    Pipelines.Click Action From Actions Menu    ${pipeline_name}    Delete
    Handle Deletion Confirmation Modal    ${pipeline_name}    pipeline
    Wait Until Page Contains Element    xpath://h4[contains(text(), 'No pipelines yet')]

Delete Pipeline Server
    [Documentation]    Delete a pipeline server. From the top right menu inside "Data Science Pipelines" -> Pipelines
    [Arguments]    ${data_science_project_name}
    Wait Until Page Contains Element    xpath://button[contains(span/text(), 'Pipeline server actions')]
    Click Element    //button[contains(span/text(), 'Pipeline server actions')]
    Wait Until Page Contains Element    xpath://li[contains(a/text(), 'Delete pipeline server')]
    Click Element    //li[contains(a/text(), 'Delete pipeline server')]
    Handle Deletion Confirmation Modal    ${data_science_project_name} pipeline server    pipeline server
    Wait Until Page Contains Element    xpath://h2[contains(text(), 'No pipeline server')]
    FOR  ${index}  IN RANGE  0  30
        ${pod_count}    Run    oc get pods -n ${data_science_project_name} -l component=data-science-pipelines | wc -l
        IF  ${pod_count}==0  BREAK
        Sleep  1s
    END
    Should Be True    ${pod_count} == 0    Pods weren't removed
