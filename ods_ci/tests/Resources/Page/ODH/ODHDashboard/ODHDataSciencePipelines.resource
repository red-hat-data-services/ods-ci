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
${PIPELINES_IMPORT_BTN_FORM_XP}=               xpath://*[@data-testid="import-button"]
${PIPELINE_NAME_INPUT_XP}=                     xpath://*[@data-testid="pipeline-name"]
${PIPELINE_DESC_INPUT_XP}=                     xpath://*[@data-testid="pipeline-description"]
${PIPELINE_RUN_NAME_INPUT_XP}=                 id:run-name
${PIPELINE_RUN_DESC_INPUT_XP}=                 id:run-description
${PIPELINE_RUN_CREATE_BTN_XP}=                 xpath://*[@data-testid="run-page-submit-button"]


*** Keywords ***
# robocop: disable:line-too-long
Install DataSciencePipelinesApplication CR
    [Documentation]    Install and verifies that DataSciencePipelinesApplication CRD is installed and working
    [Arguments]     ${project}    ${dsp_file}=data-science-pipelines-sample.yaml    ${assert_install}=True
    Log    ${project}
    Oc Apply    kind=DataSciencePipelinesApplication    src=${DATA_SCIENCE_PIPELINES_APPLICATION_PATH}/${dsp_file}    namespace=${project}
    IF    ${assert_install}==True
        ${generation_value}    Run    oc get datasciencepipelinesapplications -n ${project} -o json | jq '.items[0].metadata.generation'
        Should Be True    ${generation_value} == 2    DataSciencePipelinesApplication created
    END

Create Pipelines ConfigMap With Custom Pip Index Url And Trusted Host
    [Documentation]     Creates a Configmap (ds-pipeline-custom-env-vars) in the project,
    ...    storing the values for pip_index_url and pip_trusted_host
    [Arguments]    ${project_title}
    Run     oc create configmap ds-pipeline-custom-env-vars --from-literal=pip_index_url=${PIP_INDEX_URL} --from-literal=pip_trusted_host=${PIP_TRUSTED_HOST} -n ${project_title}

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
    Element Should Be Disabled    ${PIPELINE_RUN_CREATE_BTN_XP}
    Input Text    ${PIPELINE_RUN_NAME_INPUT_XP}    ${name}
    Input Text    ${PIPELINE_RUN_DESC_INPUT_XP}    ${name}

#    TODO: by fix it to select latest version of ${pipeline_name}
#    IF    "${pipeline_name}" != "${NONE}"
#        Select Pipeline For The Run    pipeline_name=${pipeline_name}
#    END

    Wait Until Element Is Enabled    ${PIPELINE_RUN_CREATE_BTN_XP}  timeout=10
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
    ${workflow_name}=    Get Text    xpath://*[@data-testid="detail-item-Workflow name"]/dd[@data-testid="detail-item-value"]/div
    RETURN    ${workflow_name}

Archive Pipeline Run
    [Documentation]    Delete a pipeline that ran based on name and pipeline. From the left menu select
    ...                "Data Science Pipelines" -> Runs. In the new page, select the tab "Triggered".
    ...                The "Delete Pipeline Run" will search for a line in the grid that match the pipeline name and
    ...                the run name. Based on that, hit the ... Menu in the row and hit Delete drop down menu.
    [Arguments]    ${run_name}    ${pipeline_name}
    Navigate To Page    Data Science Pipelines    Runs

    Wait Until Page Contains Element    xpath=//*[@data-testid="active-runs-tab"]      timeout=30s
    Click Element    xpath=//*[@data-testid="active-runs-tab"]
    Click Action From Pipeline Run Actions Menu    ${run_name}    Archive
    Handle Deletion Confirmation Modal    ${run_name}    triggered run
    Wait Until Page Contains Element    xpath://h2[contains(text(), 'No triggered runs yet')]

Delete Pipeline
    [Documentation]    Navigates to "Data Science Pipelines" -> Pipelines, deletes the latest pipeline version
    ...    available and deletes the pipeline using the pipelines actions menu.
    ...    TODO: improve keyword to delete multiple pipeline versions
    [Arguments]    ${pipeline_name}
    Navigate To Page    Data Science Pipelines    Pipelines
    ODHDashboard.Maybe Wait For Dashboard Loading Spinner Page

    Pipelines.Expand Pipeline Details    ${pipeline_name}
    Pipelines.Click Action From Pipeline Version Actions Menu    ${pipeline_name}    Delete pipeline version
    Handle Deletion Confirmation Modal    ${pipeline_name}    pipeline

    Pipelines.Click Action From Pipeline Actions Menu    ${pipeline_name}    Delete
    Handle Deletion Confirmation Modal    ${pipeline_name}    pipeline
    Wait Until Pipeline Is Not Listed    ${pipeline_name}

Delete Pipeline Server
    [Documentation]    Navigates to "Data Science Pipelines" -> Pipelines and deletes the pipeline server
    [Arguments]    ${data_science_project_name}
    Navigate To Page    Data Science Pipelines    Pipelines
    ODHDashboard.Maybe Wait For Dashboard Loading Spinner Page
    Wait Until Page Contains Element    xpath://button[contains(span/text(), 'Pipeline server actions')]
    Wait Until Element Is Enabled       xpath://button[contains(span/text(), 'Pipeline server actions')]
    Click Element                       xpath://button[contains(span/text(), 'Pipeline server actions')]
    Wait Until Page Contains Element    xpath://li[contains(a/text(), 'Delete pipeline server')]
    Click Element    //li[contains(a/text(), 'Delete pipeline server')]
    Handle Deletion Confirmation Modal    ${data_science_project_name} pipeline server    pipeline server
    Wait Until Page Contains     text=Configure pipeline server    timeout=120s
    Pipelines.Wait Until Pipeline Server Is Deleted    ${data_science_project_name}

Verify There Is No "Error Displaying Pipelines" After Creating Pipeline Server
    [Documentation]    Verify me message "Error displaying Pipelines" after creating pipeline server
    ...    Bug: RHOAIENG-2931
    ${expected_text_list} =    Create List    Start by importing a pipeline    Error displaying pipelines
    Wait Until Page Contains A String In List    ${expected_text_list}    retry=18x
    Run Keyword And Warn On Failure    Page Should Not Contain     Error displaying pipelines

Verify That There Are No Sample Pipelines After Creating Pipeline Server
    [Documentation]     Verify creation of sample pipelines by default when deploying dsp in RHOAI/ODH
    Log    ${PRODUCT}
    ${samples_not_created}=      Run Keyword And Return Status      Wait Until Page Contains    Start by importing a pipeline    timeout=40s
    Run Keyword If    ${samples_not_created}    Log    Sample Pipelines Not Created
    IF       ${samples_not_created}==False
        Fail    Default Sample Pipelines should not be created after creating a pipeline server in ${PRODUCT}
    END



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
    Navigate To Page    Data Science Pipelines    Runs
    ODHDashboard.Maybe Wait For Dashboard Loading Spinner Page
    Wait Until Page Contains Element    xpath=//*[@data-testid="active-runs-tab"]      timeout=30s
    Click Element    xpath=//*[@data-testid="active-runs-tab"]
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
    [Arguments]    ${pipeline_run_name}    ${timeout}=10m
    Open Pipeline Run    ${pipeline_run_name}
    Wait Until Page Contains Element    //span[@class='pf-v5-c-label__text' and text()='Succeeded']    timeout=${timeout}
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




