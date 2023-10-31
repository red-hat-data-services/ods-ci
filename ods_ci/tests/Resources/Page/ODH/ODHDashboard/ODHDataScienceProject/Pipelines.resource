*** Settings ***
Documentation    Collection of keywords to interact with DS Pipelines
Resource       Projects.resource
Resource       ../ODHDataSciencePipelines.resource


*** Variables ***
${PIPELINES_SECTION_XP}=    xpath://div[@id="pipelines-projects"]
${PIPELINES_SERVER_BTN_XP}=    xpath://button[text()="Create a pipeline server"]
${PIPELINES_SERVER_CONFIG_BTN_XP}=    xpath://button[text()="Configure"]
${PIPELINES_IMPORT_BTN_XP}=    xpath://button[text()="Import pipeline"]
${CREATE_RUN_BTN_XP}=    xpath://*[text()="Create run"]
${RUN_TOPOLOGY_DETAILS_BTN_XP}=    xpath://li//button[text()="Details"]
${RUN_TOPOLOGY_OUTPUT_BTN_XP}=    xpath://li//button[text()="Run output"]
${RUN_TOPOLOGY_XP}=    css:div[data-test-id="topology"]


*** Keywords ***
Create Pipeline Server
    [Documentation]    Creates the DS Pipeline server from DS Project details page
    ...                It assumes the Data Connection is aleady created
    ...                and you wants to use defaul DB configurations [TEMPORARY]
    [Arguments]    ${dc_name}    ${project_title}
    Wait Until Page Contains Element    ${PIPELINES_SERVER_BTN_XP}
    Run Keyword And Continue On Failure    Element Should Be Disabled    ${PIPELINES_IMPORT_BTN_XP}
    Element Should Be Enabled    ${PIPELINES_SERVER_BTN_XP}
    Click Button    ${PIPELINES_SERVER_BTN_XP}
    Wait Until Generic Modal Appears
    Run Keyword And Continue On Failure    Element Should Be Disabled    ${PIPELINES_SERVER_CONFIG_BTN_XP}
    Select Data Connection    dc_name=${dc_name}
    Element Should Be Enabled    ${PIPELINES_SERVER_CONFIG_BTN_XP}
    Click Element    ${PIPELINES_SERVER_CONFIG_BTN_XP}
    Wait Until Generic Modal Disappears
    Wait Until Project Is Open    project_title=${project_title}
    ...    timeout-pre-spinner=5s    timeout-spinner=60s

Select Data Connection
    [Documentation]    Selects an existing data connection from the dropdown
    ...                in the modal for Pipeline Server creation
    [Arguments]    ${dc_name}
    Click Element    css:form div span button[aria-label="Options menu"]
    Wait Until Page Contains Element    xpath://button[text()="${dc_name}"]
    Click Element    xpath://button[text()="${dc_name}"]

Import Pipeline
    [Documentation]    Import a pipeline definition from DS Project details page.
    ...                It expects to receive the relative path starting from ods_ci/
    [Arguments]    ${name}    ${filepath}    ${project_title}    ${description}=${NONE}    ${press_cancel}=${FALSE}
    # Begin - Workaround for https://github.com/opendatahub-io/data-science-pipelines-operator/issues/349
    Capture Page Screenshot
    Reload Page
    Log     Workaround for data-science-pipelines-operator/issues/349     level=WARN
    Wait Until Page Contains Element    ${PIPELINES_IMPORT_BTN_XP}     timeout=120
    Wait Until Page Contains Element    //*[contains(text(), 'To get started, import a pipeline.')]    timeout=120
    Wait Until Element Is Enabled  ${PIPELINES_IMPORT_BTN_XP}  timeout=120
    Capture Page Screenshot
    # End - Workaround
    Element Should Be Enabled    ${PIPELINES_IMPORT_BTN_XP}
    Click Button    ${PIPELINES_IMPORT_BTN_XP}
    Wait Until Generic Modal Appears
    Run Keyword And Continue On Failure    Element Should Be Disabled    ${PIPELINES_IMPORT_BTN_FORM_XP}
    Fill In Pipeline Import Form    ${name}    ${filepath}    ${project_title}    ${description}
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Click Button    ${PIPELINES_IMPORT_BTN_FORM_XP}
    END
    Wait Until Generic Modal Disappears
    Wait Until Project Is Open    project_title=${project_title}

Create Pipeline Run    # robocop: disable
    [Documentation]    Create a pipeline run from DS Project details page.
    ...                Note that the ${type} arguments can accept:
    ...                - immediate
    ...                - schedule -> this requires to insert additional arguments
    ...                TEMPORARILY SUPPORTING ONLY IMMEDIATE RUNS AND DEFAULT MODEL PARAMS
    [Arguments]    ${name}    ${pipeline_name}=${NONE}    ${from_actions_menu}=${TRUE}    ${run_type}=Immediate
    ...            ${trigger_type}=Periodic    ${start_date}=${NONE}    ${start_time}=${NONE}    ${end_date}=${NONE}
    ...            ${end_time}=${NONE}    ${cron_expr}=${NONE}    ${press_cancel}=${FALSE}    &{model_param}
    IF    ${from_actions_menu} == ${FALSE}
        Show Pipeline Runs Section    pipeline_name=${pipeline_name}
        Wait Until Page Contains Element    ${CREATE_RUN_BTN_XP}
        Click Element    ${CREATE_RUN_BTN_XP}
    ELSE
        Pipelines.Click Action From Actions Menu    pipeline_name=${pipeline_name}
        ...    action=Create run
    END
    Wait For RHODS Dashboard To Load    expected_page=Create run
    ...    wait_for_cards=${FALSE}
    Fill In Run Creation Form    name=${name}    pipeline_name=${pipeline_name}
    ...    run_type=${run_type}    trigger_type=Periodic    start_date=${start_date}
    ...    start_time=${start_time}    end_date=${end_date}    end_time=${end_time}
    ...    cron_expr=${cron_expr}    &{model_param}
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
        Wait For RHODS Dashboard To Load    expected_page=Pipelines
        ...    wait_for_cards=${FALSE}
        ${workflow_name}=    Set Variable    ${NONE}
    ELSE
        Click Element    ${GENERIC_CREATE_BTN_XP}
        Wait Until Page Contains Run Topology Page    run_name=${name}
        ${workflow_name}=    Get Workflow Name From Topology Page
    END
    RETURN    ${workflow_name}

# robocop: disable=too-many-calls-in-keyword,line-too-long
Click Action From Actions Menu
    [Documentation]    Click an action from Actions menu (3-dots menu on the right)
    [Arguments]    ${pipeline_name}    ${action}
    Wait Until Page Contains Element    xpath://table//tr[td[*[a[text()='${pipeline_name}']]]]//td[contains(@class, 'pf-c-table__action')]/div
    Click Element    xpath://table//tr[td[*[a[text()='${pipeline_name}']]]]//td[contains(@class, 'pf-c-table__action')]/div
    Wait Until Page Contains Element    //table//tr[td[*[a[text()='${pipeline_name}']]]]//td[contains(@class, 'pf-c-table__action')]/div/ul/li/button[contains(text(), '${action}')]
    Click Element    //table//tr[td[*[a[text()='${pipeline_name}']]]]//td[contains(@class, 'pf-c-table__action')]/div/ul/li/button[contains(text(), '${action}')]

Pipeline Context Menu Should Be Working
    [Documentation]   Test Pipeline YAML context menu works with mouse right-click and with keyboard
    [Arguments]    ${pipeline_name}
    ${orig wait}=    SeleniumLibrary.Set Selenium Implicit Wait    10s
    Menu.Navigate To Page    Data Science Pipelines    Pipelines
    Wait Until Element is Visible     //a[text()="${pipeline_name}"]          timeout=30s
    Click Link      ${pipeline_name}
    Click Element     //button[@aria-label="Pipeline YAML Tab"]
    Open Context Menu    //div[contains(@class, 'lines-content')]
    Click Element     //button[@aria-label="Pipeline YAML Tab"]
    Press Keys    //div[contains(@class, 'lines-content')]    F1+fold+SPACE+all+ENTER
    Capture Page Screenshot
    SeleniumLibrary.Set Selenium Implicit Wait    ${orig wait}

Pipeline Yaml Should Be Readonly
    [Documentation]   Verify Pipeline Yaml is read only (https://github.com/opendatahub-io/odh-dashboard/issues/1689)
    [Arguments]    ${pipeline_name}
    ${orig wait}=    SeleniumLibrary.Set Selenium Implicit Wait    10s
    Menu.Navigate To Page    Data Science Pipelines    Pipelines
    Wait Until Element is Visible     //a[text()="${pipeline_name}"]          timeout=30s
    Click Link      ${pipeline_name}
    Click Element     //button[@aria-label="Pipeline YAML Tab"]
    Press Keys    //div[contains(@class, 'lines-content')]    cannot_enter_read_only
    Wait Until Element Is Visible    //div[@class="pf-c-code-editor pf-m-read-only odh-dashboard__code-editor"]    timeout=10
    Capture Page Screenshot
    SeleniumLibrary.Set Selenium Implicit Wait    ${orig wait}

Pipeline Should Be Listed
    [Documentation]    Checks a pipeline is listed in the DS Project details page
    [Arguments]     ${pipeline_name}    ${pipeline_description}
    Run Keyword And Continue On Failure
    ...    Wait Until Page Contains Element
    ...    ${PIPELINES_SECTION_XP}//td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]
    IF    "${pipeline_description}" == ${NONE}
        Run Keyword And Continue On Failure
        ...    Wait Until Page Does Not Contain Element
        ...        ${PIPELINES_SECTION_XP}//tr[td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]]//td[@data-label="Name"]/*[p[text()="${pipeline_description}"]]    # robocop: disable
    ELSE
        Run Keyword And Continue On Failure
        ...    Wait Until Page Contains Element
        ...        ${PIPELINES_SECTION_XP}//tr[td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]]//td[@data-label="Name"]/*[p[text()="${pipeline_description}"]]    # robocop: disable
    END

Pipeline Should Not Be Listed
    [Documentation]    Checks a pipeline is not listed in the DS Project details page
    [Arguments]     ${pipeline_name}    ${pipeline_description}
    Run Keyword And Continue On Failure
    ...    Wait Until Page Does Not Contain Element
    ...    ${PIPELINES_SECTION_XP}//td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]
    Run Keyword And Continue On Failure
    ...    Wait Until Page Does Not Contain Element
    ...    ${PIPELINES_SECTION_XP}//tr[td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]]//td[@data-label="Name"]/*[p[text()="${pipeline_description}"]]    # robocop: disable

Pipeline Run Should Be Listed
    [Documentation]    Checks a pipeline run is listed in the DS Project details page
    ...                under the hidden run sub-section.
    ...                THIS KEYWORD NEED A REFINEMENT TO CHECK THE RUN AND ITS CORRESPONDING STATUS
    ...                WHEN MULTIPLE RUNS ARE EXECUTED
    [Arguments]     ${name}    ${pipeline_name}
    Show Pipeline Runs Section    pipeline_name=${pipeline_name}
    Run Keyword And Continue On Failure
    ...    Wait Until Page Contains Element
    ...    ${PIPELINES_SECTION_XP}//a//span[text()="${name}"]

Pipeline Last Run Should Be
    [Documentation]    Checks the pipeline last run which is reported is the expected one
    [Arguments]    ${pipeline_name}    ${run_name}
    ${pipeline_row_xp}=    Set Variable     ${PIPELINES_SECTION_XP}//tr[td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]]    # robocop: disable
    Run Keyword And Continue On Failure
    ...    Page Should Contain Element
    ...    ${pipeline_row_xp}//td/a//span[text()="${run_name}"]

Pipeline Last Run Status Should Be
    [Documentation]    Checks if the pipeline last run has the expected status
    [Arguments]    ${pipeline_name}    ${status}
    ${pipeline_row_xp}=    Set Variable     ${PIPELINES_SECTION_XP}//tr[td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]]    # robocop: disable
    Run Keyword And Continue On Failure
    ...    Page Should Contain Element
    ...    ${pipeline_row_xp}//td/div[text()="${status}"]

Wait Until Pipeline Last Run Is Finished
    [Documentation]    Waits until the run reported in the "last run" column of the test pipeline
    ...                in the DS Project details page completes the execution (i.e., status is not Running)
    [Arguments]    ${pipeline_name}    ${timeout}=60s
    ${pipeline_row_xp}=    Set Variable     ${PIPELINES_SECTION_XP}//tr[td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]]    # robocop: disable
    Wait Until Page Does Not Contain Element    ${pipeline_row_xp}//td/div[text()="Running"]
    ...    timeout=${timeout}

Wait Until Pipeline Last Run Is Started
    [Documentation]    Waits until the run reported in the "last run" column of the test pipeline
    ...                in the DS Project details page starts the execution (i.e., status is Running)
    [Arguments]    ${pipeline_name}    ${timeout}=60s
    ${pipeline_row_xp}=    Set Variable     ${PIPELINES_SECTION_XP}//tr[td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]]    # robocop: disable
    Wait Until Page Contains Element    ${pipeline_row_xp}//td/div[text()="Running"]
    ...    timeout=${timeout}

Show Pipeline Runs Section
    [Documentation]    Open the sub-section of the pipeline runs in the DS Project details page.
    ...                The sub-section is hidden and the robot clicks on a toggle button
    ...                near the pipeline name to show the sub-section
    [Arguments]    ${pipeline_name}
    ${pipeline_row_xp}=    Set Variable     ${PIPELINES_SECTION_XP}//tr[td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]]    # robocop: disable
    Click Element    ${pipeline_row_xp}//td[@class="pf-c-table__toggle"]/button

Wait Until Page Contains Run Topology Page
    [Documentation]    Waits until the page containing the run details and its topology
    ...                is rendered on the screen
    [Arguments]    ${run_name}
    Run Keyword And Continue On Failure    Wait Until Page Contains Element
    ...    xpath://h1//div[text()="${run_name}"]    timeout=10s
    Run Keyword And Continue On Failure    Wait Until Page Contains Element
    ...    ${RUN_TOPOLOGY_DETAILS_BTN_XP}
    Run Keyword And Continue On Failure    Wait Until Page Contains Element
    ...    ${RUN_TOPOLOGY_OUTPUT_BTN_XP}
    Run Keyword And Continue On Failure    Wait Until Page Contains Element
    ...    ${RUN_TOPOLOGY_XP}

Verify Pipeline Server Deployments    # robocop: disable
    [Documentation]    Verifies the correct deployment of DS Pipelines in the rhods namespace
    [Arguments]    ${project_title}
    ${namespace}=    Get Openshift Namespace From Data Science Project
    ...    project_title=${project_title}
    @{persistenceagent}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-persistenceagent-pipelines-definition
    ${containerNames}=  Create List  ds-pipeline-persistenceagent
    Verify Deployment    ${persistenceagent}  1  1  ${containerNames}
    @{pipeline_definition}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-pipelines-definition
    ${containerNames}=  Create List  oauth-proxy    ds-pipeline-api-server
    Verify Deployment    ${pipeline_definition}  1  2  ${containerNames}
    @{schedule_workflow}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-scheduledworkflow-pipelines-definition
    ${containerNames}=  Create List  ds-pipeline-scheduledworkflow
    Verify Deployment    ${schedule_workflow}  1  1  ${containerNames}
    @{db}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=mariadb-pipelines-definition
    ${containerNames}=  Create List  mariadb
    Verify Deployment    ${db}  1  1  ${containerNames}
    @{all_pods}=  Oc Get    kind=Pod    namespace=${namespace}
    Run Keyword And Continue On Failure    Length Should Be    ${all_pods}    4

Wait Until Pipeline Server Is Deployed
    [Documentation]    Waits until all the expected pods of the pipeline server
    ...                are running
    [Arguments]    ${project_title}
    Wait Until Keyword Succeeds    10 times    10s
    ...    Verify Pipeline Server Deployments    project_title=${project_title}

Verify Successful Pipeline Run Via Project UI
    [Documentation]    Validates that a given pipeline run in a given pipeline is in successful end state
    ...    In the DS Project view of a given project
    [Arguments]    ${pipeline_run_name}    ${pipeline_name}    ${project_name}
    Open Data Science Project Details Page    ${project_name}
    Wait Until Pipeline Last Run Is Started    pipeline_name=${pipeline_name}
    ...    timeout=10s
    Wait Until Pipeline Last Run Is Finished    pipeline_name=${pipeline_name}
    ...    timeout=180s
    Pipeline Last Run Should Be    pipeline_name=${pipeline_name}
    ...    run_name=${pipeline_run_name}
    Pipeline Last Run Status Should Be    pipeline_name=${pipeline_name}
    ...    status=Completed
    Pipeline Run Should Be Listed    name=${pipeline_run_name}
    ...    pipeline_name=${pipeline_name}
