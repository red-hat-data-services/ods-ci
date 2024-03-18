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
${DATA_SCIENCE_PIPELINES_APPLICATION_PATH}=    ods_ci/tests/Resources/Files
${PIPELINES_IMPORT_BTN_FORM_XP}=    xpath://footer/button[text()="Import pipeline"]
${PIPELINE_NAME_INPUT_XP}=          id:pipeline-name
${PIPELINE_DESC_INPUT_XP}=          id:pipeline-description
${PIPELINE_RUN_NAME_INPUT_XP}=      id:run-name
${PIPELINE_RUN_DESC_INPUT_XP}=      id:run-description

*** Keywords ***
# robocop: disable:line-too-long
Install DataSciencePipelinesApplication CR
    [Documentation]    Install and verifies that DataSciencePipelinesApplication CRD is installed and working
    [Arguments]     ${project}    ${dsp_file}=data-science-pipelines-sample.yaml    ${assert_install}=True
    Log    ${project}
    Oc Apply    kind=DataSciencePipelinesApplication    src=${DATA_SCIENCE_PIPELINES_APPLICATION_PATH}/${dsp_file}    namespace=${project}
    IF    ${assert_install}==True
        ${generation_value}    Run    oc get datasciencepipelinesapplications -n ${project} -o json | jq '.items[0].metadata.generation'
        Should Be True    ${generation_value} == 1    DataSciencePipelinesApplication created
    END

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
    Choose File    //div[contains(@class, "-file-upload")]//input[@type="file"]    ${pwd}/${filepath}
    Element Should Be Enabled    ${PIPELINES_IMPORT_BTN_FORM_XP}

Fill In Run Creation Form    # robocop: disable
    [Documentation]    Compiles the form to create a pipeline run.
    ...                It works when you start server creation from either
    ...                DS Project details page or DS Pipelines page.
    [Arguments]    ${name}    ${pipeline_name}=${NONE}    ${from_actions}=${TRUE}    ${run_type}=Immediate
    ...            ${trigger_type}=Periodic    ${start_date}=${NONE}    ${start_time}=${NONE}
    ...            ${end_date}=${NONE}    ${end_time}=${NONE}    ${cron_expr}=${NONE}&{model_param}
    Input Text    ${PIPELINE_RUN_NAME_INPUT_XP}    ${name}
    Input Text    ${PIPELINE_RUN_DESC_INPUT_XP}    ${name}
    Run Keyword And Warn On Failure    Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}

#    TODO: by fix it to select latest version of ${pipeline_name}
#    IF    "${pipeline_name}" != "${NONE}"
#        Select Pipeline For The Run    pipeline_name=${pipeline_name}
#    END

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

    Wait Until Page Contains Element    //button[@data-testid="pipeline-toggle-button"]
    Click Element                       //button[@data-testid="pipeline-toggle-button"]
    Wait Until Page Contains Element    xpath://ul/li/a[text()="${pipeline_name}"]
    Click Element                       xpath://ul/li/a[text()="${pipeline_name}"]

Get Workflow Name From Topology Page
    [Documentation]    Returns the workflow name corresponding to the displayed pipeline.
    ...                The workflow name can be used to retrieve pods, for example
    ${workflow_name}=    Get Text    xpath://div[b/text()='Workflow name']/following-sibling::div
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
    Click Action From Pipeline Run Actions Menu    ${run_name}    Delete
    Handle Deletion Confirmation Modal    ${run_name}    triggered run
    Wait Until Page Contains Element    xpath://h2[contains(text(), 'No triggered runs yet')]

Delete Pipeline
    [Documentation]    Delete a pipeline. From the left menu select "Data Science Pipelines" -> Pipelines.
    ...                The "Delete Pipeline" will search for a line in the grid that match the pipeline name.
    ...                Based on that, hit the ... Menu in the row and hit Delete drop down menu.
    [Arguments]    ${pipeline_name}
    Navigate To Page    Data Science Pipelines    Pipelines
    Wait Until Page Contains Element    xpath://h2[text()='${pipeline_name}']
    Pipelines.Click Action From Actions Menu    ${pipeline_name}    Delete
    Handle Deletion Confirmation Modal    ${pipeline_name}    pipeline
    Wait Until Page Contains Element    xpath://h4[contains(text(), 'No pipelines yet')]

Delete Pipeline Server
    [Documentation]    Delete a pipeline server. From the top right menu inside "Data Science Pipelines" -> Pipelines
    [Arguments]    ${data_science_project_name}
    Wait Until Page Contains Element    xpath://button[contains(span/text(), 'Pipeline server actions')]
    Sleep    20s
    Click Button            xpath://button[contains(span/text(), 'Pipeline server actions')]
    Wait Until Page Contains Element    xpath://li[contains(a/text(), 'Delete pipeline server')]
    Click Element    //li[contains(a/text(), 'Delete pipeline server')]
    Handle Deletion Confirmation Modal    ${data_science_project_name} pipeline server    pipeline server
    Wait Until Page Contains Element    xpath://h3[text()="Enable pipelines"]    timeout=180s
    FOR  ${index}  IN RANGE  0  30
        ${pod_count}    Run    oc get pods -n ${data_science_project_name} -l component=data-science-pipelines | wc -l
        IF  ${pod_count}==0  BREAK
        Sleep  1s
    END
    Should Be True    ${pod_count} == 0    Pods weren't removed

Verify There Is No "Error Displaying Pipelines" After Creating Pipeline Server
    [Documentation]    Verify me message "Error displaying Pipelines" after creating pipeline server
    ...    Bug: RHOAIENG-2931
    Run Keyword And Ignore Error       Wait Until Page Contains    Error displaying pipelines    timeout=60s
    Run Keyword And Warn On Failure    Page Should Not Contain     Error displaying pipelines

Open Pipeline Detail
    [Documentation]    Open the Pipeline detail
    [Arguments]    ${pipeline_name}
    Wait Until Page Contains Element    xpath=//button[text()='Data Science Pipelines']
    Click Element    xpath=//button[text()='Data Science Pipelines']
    Wait Until Page Contains Element    xpath=//a[text()='Pipelines']
    Click Element    xpath=//a[text()='Pipelines']
    Wait Until Page Contains Element    xpath=//h2[text()='${pipeline_name}']
    Click Element    xpath=//button[@id='pipeline-row-item0']
    Wait Until Page Contains Element    xpath=//a[text()='${pipeline_name}']
    Click Element    xpath=//a[text()='${pipeline_name}']
    Wait Until Page Contains Element    xpath=//div[@data-test-id='topology']
    Capture Page Screenshot

Open Pipeline Run
    [Documentation]    Open the Pipeline Run detail.
    [Arguments]    ${pipeline_run_name}
    ${present}=  Run Keyword And Return Status    Element Should Be Visible   xpath=//a[text()='Runs']
    # We can run Open Pipeline Run step multiple times. If the menu is expanded, then it will colapse
    IF    ${present} == ${FALSE}
        Wait Until Page Contains Element    xpath=//button[text()='Data Science Pipelines']
        Click Element    xpath=//button[text()='Data Science Pipelines']
        Wait Until Page Contains Element    xpath=//a[text()='Runs']
    END
    Click Element    xpath=//a[text()='Runs']
    Wait Until Page Contains Element    xpath=//span[text()='Triggered']    timeout=30s
    Click Element    xpath=//span[text()='Triggered']
    Wait Until Page Contains Element    xpath=//span[text()='${pipeline_run_name}']
    Click Element    xpath=//span[text()='${pipeline_run_name}']
    Wait Until Page Contains Element    xpath=//div[@data-test-id='topology']

# robocop: disable:line-too-long
Get Pipeline Run Step Log
    [Documentation]    Get Pipeline Run Step Log
    [Arguments]    ${pipeline_run_step}
    Click Element    xpath=//*[name()='svg']//*[local-name()='g']//*[@class='pf-topology-pipelines__pill-text' and text()='${pipeline_run_step}']
    Wait Until Page Contains Element    xpath=//button[@data-ouia-component-type='PF5/TabButton' and text()='Logs']
    Click Element    xpath=//button[@data-ouia-component-type='PF5/TabButton' and text()='Logs']
    # the logs are full loaded when "The log window displays partial content" the message appeared
    Wait Until Page Contains Element    xpath=//h2[text()='The log window displays partial content']
    Capture Page Screenshot
    ${log_with_tags}=    Get Element Attribute    xpath://div[@class="pf-v5-c-log-viewer__list"]    innerHTML
    Log    ${log_with_tags}
    # we close the modal otherwise any othe step in the test case will need to close it
    Click Element    xpath=//button[@aria-label="Close drawer panel"]
    RETURN    ${log_with_tags}

Verify Pipeline Run Is Completed
    [Documentation]    Open the Pipeline detail and wait for the Completed Status
    [Arguments]    ${pipeline_run_name}
    Open Pipeline Run    ${pipeline_run_name}
    Wait Until Page Contains Element    //span[@class='pf-v5-c-label__text' and text()='Completed']    timeout=10m
    Capture Page Screenshot

# robocop: disable:line-too-long
Get Pipeline Run Duplicate Parameters
    [Documentation]    Get Pipeline Run Duplicate Parameters
    [Arguments]    ${pipeline_run_name}
    Open Pipeline Run    ${PIPELINE_TEST_RUN_BASENAME}
    Wait Until Page Contains Element    xpath://button[contains(span/text(), 'Actions')]
    Click Element    xpath://button[contains(span/text(), 'Actions')]
    Wait Until Page Contains Element    xpath://a[@role='menuitem' and text()='Duplicate']
    Click Element    xpath://a[@role='menuitem' and text()='Duplicate']
    Wait Until Page Contains Element    xpath://div[text()='Pipeline input parameters']
    Capture Page Screenshot
    ${input_parameters}=    Get Element Attribute    xpath://div[text()='Pipeline input parameters']/following-sibling::div[1]    innerHTML
    Log    ${input_parameters}
    RETURN    ${input_parameters}




