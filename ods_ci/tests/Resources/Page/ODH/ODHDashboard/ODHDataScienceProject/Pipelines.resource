# robocop: off=line-too-long,unnecessary-string-conversion,file-too-long,too-many-arguments,too-many-calls-in-keyword
*** Settings ***
Documentation    Collection of keywords to interact with DS Pipelines
Resource       Projects.resource
Resource       ../ODHDataSciencePipelines.resource


*** Variables ***
${PIPELINES_SECTION_XP}=              xpath://div[@id="pipelines-projects"]
${PIPELINES_TABLE_XP}=                xpath://table[@data-testid="pipelines-table"]
${PIPELINES_SERVER_BTN_XP}=           xpath=//*[@data-testid="create-pipeline-button"]
${PIPELINES_SERVER_CONFIG_BTN_XP}=    xpath=//*[@data-testid="modal-submit-button"]
${PIPELINES_IMPORT_BTN_XP}=           xpath://*[@data-testid="import-pipeline-button"]
${CREATE_RUN_BTN_XP}=                 xpath://*[@data-testid="run-page-submit-button"]
${RUN_TOPOLOGY_DETAILS_BTN_XP}=       xpath://*[@data-testid="pipeline-run-tab-details"]
${RUN_TOPOLOGY_OUTPUT_BTN_XP}=        xpath://*[@data-testid="bottom-drawer-tab-run-output"]
${RUN_TOPOLOGY_XP}=                   xpath://*[@data-test-id="topology"]
${PIPELINES_DISABLED_EXC_MARK}=       xpath=//*[@id="page-sidebar"]/div/nav/ul/li[3]/a/div/div[2]


*** Keywords ***
Create Pipeline Server    # robocop: off=too-many-calls-in-keyword
    [Documentation]    Creates the DS Pipeline server from DS Project details page
    ...                It assumes the Data Connection is aleady created
    ...                and you wants to use defaul DB configurations [TEMPORARY]
    [Arguments]    ${dc_name}    ${project_title}
    # Every 2 mins the frontend updates its cache and the client polls every 30seconds.
    # So the longest you’d have to wait is 2.5 mins. Set 3 min just to make sure
    Projects.Move To Tab    Pipelines
    Wait Until Page Contains Element    ${PIPELINES_SERVER_BTN_XP}    timeout=180s
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
    # robocop: off=line-too-long
    Wait Until Page Contains Element    xpath://button[@data-testid="select-data-connection"]
    Click Button                        xpath://button[@data-testid="select-data-connection"]
    Wait Until Page Contains Element    xpath://button//*[text()="${dc_name}"]
    Click Element    xpath://button//*[text()="${dc_name}"]

Wait Until Pipeline Is Not Listed
    [Documentation]    Waits until pipeline is no longer listed in the pipelines table
    [Arguments]    ${pipeline_name}    ${timeout}=60s
    Maybe Wait For Dashboard Loading Spinner Page
    ${pipeline_row_xp}=    Set Variable    //*[@data-testid="table-row-title"]/a/span[text()="${pipeline_name}"]/ancestor::tr
    Wait Until Page Does Not Contain Element    ${pipeline_row_xp}    timeout=${timeout}

Import Pipeline
    [Documentation]    Import a pipeline definition from DS Project details page.
    ...                It expects to receive the relative path starting from ods_ci/
    [Arguments]    ${name}    ${filepath}    ${project_title}    ${description}=${NONE}    ${press_cancel}=${FALSE}
    Projects.Move To Tab    Pipelines
    Click Button    ${PIPELINES_IMPORT_BTN_XP}
    Wait Until Generic Modal Appears
    Run Keyword And Continue On Failure    Element Should Be Disabled    ${PIPELINES_IMPORT_BTN_FORM_XP}
    Fill In Pipeline Import Form    ${name}    ${filepath}    ${project_title}    ${description}
    IF    ${press_cancel}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Click Button    ${PIPELINES_IMPORT_BTN_FORM_XP}
    END
    Wait Until Generic Modal Disappears
    Maybe Wait For Dashboard Loading Spinner Page     timeout=45s
    Wait For Dashboard Page Title    ${name}    timeout=30s

Create Pipeline Run
    [Documentation]    Create a pipeline run from DS Project details page.
    ...                Note that the ${type} arguments can accept:
    ...                - immediate
    ...                - schedule -> this requires to insert additional arguments
    ...                TEMPORARILY SUPPORTING ONLY IMMEDIATE RUNS AND DEFAULT MODEL PARAMS
    [Arguments]    ${name}    ${pipeline_name}=${NONE}    ${run_type}=Immediate
    ...            ${start_date}=${NONE}    ${start_time}=${NONE}    ${end_date}=${NONE}
    ...            ${end_time}=${NONE}    ${cron_expr}=${NONE}    ${press_cancel}=${FALSE}    &{model_param}
    Projects.Move To Tab    Pipelines
    Pipelines.Click Action From Pipeline Actions Menu    pipeline_name=${pipeline_name}    action=Create run
    Fill In Run Creation Form    name=${name}    pipeline_name=${pipeline_name}
    ...    run_type=${run_type}    trigger_type=Periodic    start_date=${start_date}
    ...    start_time=${start_time}    end_date=${end_date}    end_time=${end_time}
    ...    cron_expr=${cron_expr}    &{model_param}
    IF    ${press_cancel}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
        Wait For RHODS Dashboard To Load    expected_page=Pipelines
        ...    wait_for_cards=${FALSE}
        ${workflow_name}=    Set Variable    ${NONE}
    ELSE
        Click Element    ${CREATE_RUN_BTN_XP}
        Wait Until Page Contains Run Topology Page    run_name=${name}
        ${workflow_name}=    Get Workflow Name From Topology Page
    END
    RETURN    ${workflow_name}

Expand Pipeline Details
    [Documentation]    Expands a pipeline row in the dashboard UI
    [Arguments]    ${pipeline_name}

    ${pipeline_row_xp}=                 Set Variable    //*[@data-testid="table-row-title"]/a/span[text()="${pipeline_name}"]/ancestor::tr
    ${pipeline_details_xp}=             Set Variable    ${pipeline_row_xp}/td/button[@aria-label="Details"]
    ${expanded_pipeline_details_xp}=    Set Variable    ${pipeline_row_xp}/td/button[@aria-expanded="true"]

    Sleep    2    reason=Sometimes it takes ~1sec to render the row
    ${is_expanded}=  Run Keyword And Return Status
    ...  Page Should Contain Element  xpath:${expanded_pipeline_details_xp}
    IF  not ${is_expanded}    Click Button  xpath:${pipeline_details_xp}

Collapse Pipeline Details
    [Documentation]    Collapses a pipeline row in the dashboard UI
    [Arguments]    ${pipeline_name}
    ${pipeline_row_xp}=                 Set Variable    //*[@data-testid="table-row-title"]/a/span[text()="${pipeline_name}"]/ancestor::tr
    ${pipeline_details_xp}=             Set Variable    ${pipeline_row_xp}/td/button[@aria-label="Details"]
    ${expanded_pipeline_details_xp}=    Set Variable    ${pipeline_row_xp}/td/button[@aria-expanded="true"]

    ${is_expanded}=  Run Keyword And Return Status
    ...  Page Should Contain Element  xpath:${expanded_pipeline_details_xp}
    IF  ${is_expanded}    Click Button  xpath:${pipeline_details_xp}

Click Action From Pipeline Actions Menu
    [Documentation]    Click an action from Pipeline Actions menu (3-dots menu on the right)
    [Arguments]    ${pipeline_name}    ${action}
    # robocop: off=line-too-long
    ${pipeline_row_xp}=    Set Variable    //*[@data-testid="table-row-title"]//span[text()="${pipeline_name}"]/ancestor::tr
    ${kebab_xp}=           Set Variable    ${pipeline_row_xp}/td/button[@aria-label="Kebab toggle"]
    ${kebap_action_xp}=    Set Variable    ${pipeline_row_xp}/td/div/div/ul/li/button[.//*[contains(text(), '${action}')]]
    Wait Until Page Contains Element    ${kebab_xp}
    Click Element                       ${kebab_xp}
    Wait Until Page Contains Element    ${kebap_action_xp}
    Click Element                       ${kebap_action_xp}

Click Action From Pipeline Version Actions Menu
    [Documentation]    Click an action from Pipeline Version Actions menu (3-dots menu on the right)
    [Arguments]    ${pipeline_version_name_contains}    ${action}
    # robocop: off=line-too-long
    ${version_row_xp}=    Set Variable     //*[@data-testid="table-row-title"]/span/a[contains(text(),"${pipeline_version_name_contains}")]/ancestor::tr
    ${kebab_xp}=           Set Variable    ${version_row_xp}/td/button[@aria-label="Kebab toggle"]
    ${kebap_action_xp}=    Set Variable    ${version_row_xp}/td/div/div/ul/li/button[.//*[contains(text(), '${action}')]]
    Wait Until Page Contains Element    ${kebab_xp}
    Click Element                       ${kebab_xp}
    Wait Until Page Contains Element    ${kebap_action_xp}
    Click Element                       ${kebap_action_xp}

Click Action From Pipeline Run Actions Menu
    [Documentation]    In Data Science Pipelines > Runs, click an action from Actions menu (3-dots menu on the right)
    [Arguments]    ${pipeline_run_name}    ${action}

    ${pipeline_run_row_xp}=    Set Variable    //span[contains(text(),"${pipeline_run_name}")]/../../../..
    ${kebab_xp}=               Set Variable    ${pipeline_run_row_xp}/td/button[@aria-label="Kebab toggle"]
    ${kebap_action_xp}=        Set Variable    ${pipeline_run_row_xp}/td/div/div/ul/li/button[.//*[contains(text(), '${action}')]]
    Wait Until Page Contains Element    ${kebab_xp}
    Click Element                       ${kebab_xp}
    Wait Until Page Contains Element    ${kebap_action_xp}
    Click Element                       ${kebap_action_xp}

Pipeline Context Menu Should Be Working
    [Documentation]   Test Pipeline YAML context menu works with mouse right-click and with keyboard
    [Arguments]    ${pipeline_name}
    ${orig wait}=    SeleniumLibrary.Set Selenium Implicit Wait    10s
    Menu.Navigate To Page    Data Science Pipelines
    Wait Until Element Is Visible     //a[text()="${pipeline_name}"]          timeout=30s
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
    Menu.Navigate To Page    Data Science Pipelines
    Wait Until Element Is Visible     //a[text()="${pipeline_name}"]          timeout=30s
    Click Link      ${pipeline_name}
    Click Element     //button[@aria-label="Pipeline YAML Tab"]
    Press Keys    //div[contains(@class, 'lines-content')]    cannot_enter_read_only
    Wait Until Element Is Visible    //div[@class="pf-v5-c-code-editor pf-m-read-only odh-dashboard__code-editor"]    timeout=10
    Capture Page Screenshot
    SeleniumLibrary.Set Selenium Implicit Wait    ${orig wait}

Pipeline Should Be Listed
    [Documentation]    Verifies a pipeline is listed in Data Science Project > Pipelines
    [Arguments]     ${pipeline_name}    ${pipeline_description}=${EMPTY}

    Projects.Move To Tab    Pipelines
    ${pipeline_title_xp}=    Set Variable      //*[@data-testid="table-row-title"]//span[text()="${pipeline_name}"]
    Run Keyword And Continue On Failure    Wait Until Page Contains Element    ${pipeline_title_xp}

    IF    "${pipeline_description}" != "${EMPTY}"
        Run Keyword And Continue On Failure
        ...    Wait Until Page Contains Element
        ...        ${pipeline_title_xp}/ancestor::td//div[@class="odh-markdown-view"]/p[text()="${pipeline_description}"]
    END

Pipeline Should Not Be Listed
    [Documentation]    Verifies a pipeline not listed in Data Science Project > Pipelines
    [Arguments]     ${pipeline_name}
    Projects.Move To Tab    Pipelines
    ${pipeline_title_xp}=    Set Variable      (//*[@data-testid="table-row-title" and text()="${pipeline_name}"])[1]
    Run Keyword And Continue On Failure    Wait Until Page Does Not Contain Element    ${pipeline_title_xp}

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

Pipeline Run Status Should Be
    [Documentation]    Checks if the pipeline run has the expected status
    ...                View: Data Science Pipelines -> Runs, Triggered tab
    [Arguments]    ${pipeline_name}    ${status}=success
    Run Keyword And Continue On Failure
    ...    Page Should Contain Element
    ...    //td[@data-label="Name"]//span[contains(text(), "${pipeline_name}")]/ancestor::tr//td[@data-label="Status"]//span[contains(@class, "${status}")]

Wait Until Pipeline Last Run Is Finished
    [Documentation]    Waits until the run reported in the "last run" column of the test pipeline
    ...                in the DS Project details page completes the execution (i.e., status is not Running)
    [Arguments]    ${pipeline_name}    ${timeout}=260s
    ${pipeline_row_xp}=    Set Variable     ${PIPELINES_SECTION_XP}//tr[td[@data-label="Name"]/*[a[text()="${pipeline_name}"]]]    # robocop: disable
    Wait Until Page Does Not Contain Element    ${pipeline_row_xp}//td/div[text()="Running"]
    ...    timeout=${timeout}

Wait Until Pipeline Run Is Finished
    [Documentation]    Waits until a pipeline run has a different text than "-" in the Duration column.
    ...                View: Data Science Pipelines -> Runs, Triggered tab
    [Arguments]    ${pipeline_name}    ${timeout}=260s
    Wait Until Page Does Not Contain Element    //td[@data-label="Name"]//span[contains(text(), "${pipeline_name}")]/ancestor::tr//td[@data-label="Duration" and text()="-"]
    ...    timeout=${timeout}

Wait Until Pipeline Last Run Is Started
    [Documentation]    Waits until the run reported in the "last run" column of the test pipeline
    ...                in the DS Project details page starts the execution (i.e., status is Running)
    [Arguments]    ${pipeline_name}    ${timeout}=60s

    ${pipeline_row_xp}=    Set Variable    ${PIPELINES_TABLE_XP}/tbody/tr/td/h2[text()="${pipeline_name}"]/../..
    Wait Until Page Contains Element    ${pipeline_row_xp}//td/div[text()="Running"]
    ...    timeout=${timeout}

Wait Until Pipeline Run Is Started
    [Documentation]    Waits until a pipeline run has the text "Just now" in the Started column.
    ...                View: Data Science Pipelines -> Runs, Triggered tab
    [Arguments]    ${pipeline_name}    ${timeout}=60s
    Wait Until Page Contains Element    //td[@data-label="Name"]//span[contains(text(), "${pipeline_name}")]/ancestor::tr//td[@data-label="Created"]//time[text()="Just now"]
    ...    timeout=${timeout}

Wait Until Page Contains Run Topology Page
    [Documentation]    Waits until the page containing the run details and its topology
    ...                is rendered on the screen
    [Arguments]    ${run_name}

    Run Keyword And Continue On Failure    Wait Until Page Contains Element
    ...    xpath://*[@data-testid="app-page-title"]/*/*[.//text()="${run_name}"]    timeout=10s
    Run Keyword And Continue On Failure    Wait Until Page Contains Element
    ...    ${RUN_TOPOLOGY_DETAILS_BTN_XP}
    Run Keyword And Continue On Failure    Wait Until Page Contains Element
    ...    ${RUN_TOPOLOGY_XP}

# TODO: we need to replace this keyword for a similar one checking in Data Science Pipelines > Runs
# Verify Successful Pipeline Run Via Project UI
#    [Documentation]    Validates that a given pipeline run in a given pipeline is in successful end state
#    ...    In the DS Project view of a given project
#    [Arguments]    ${pipeline_run_name}    ${pipeline_name}    ${project_name}
#    Open Data Science Project Details Page    ${project_name}    tab_id=pipelines-projects
#    Wait Until Pipeline Last Run Is Started    pipeline_name=${pipeline_name}
#    ...    timeout=10s
#    Wait Until Pipeline Last Run Is Finished    pipeline_name=${pipeline_name}
#    Pipeline Last Run Should Be    pipeline_name=${pipeline_name}
#    ...    run_name=${pipeline_run_name}
#    Pipeline Last Run Status Should Be    pipeline_name=${pipeline_name}
#    ...    status=Completed
#    Pipeline Run Should Be Listed    name=${pipeline_run_name}
#    ...    pipeline_name=${pipeline_name}

Verify Successful Pipeline Run Via Pipelines Runs UI
    [Documentation]    Validates that a given pipeline run in a given pipeline is in successful end state
    ...                View: Data Science Pipelines -> Runs, Triggered tab
    [Arguments]    ${pipeline_name}
    Menu.Navigate To Page    Data Science Pipelines
    Wait Until Page Contains Element    xpath://span[text()='Triggered']   timeout=10s
    Click Element    //span[text()='Active']
    Wait Until Pipeline Run Is Started    pipeline_name=${pipeline_name}
    ...    timeout=10s
    Wait Until Pipeline Run Is Finished    pipeline_name=${pipeline_name}
    Pipeline Run Status Should Be    pipeline_name=${pipeline_name}
    ...    status=success

Verify Pipelines Are Enabled
   [Documentation]    Verifies the Dashboard enabled pipelines
   Wait Until Page Contains       Data Science Pipelines
   Page Should Not Contain Element    ${PIPELINES_DISABLED_EXC_MARK}  timeout=10s

Verify Pipelines Are Disabled
   [Documentation]    Verifies the Dashboard disabled pipelines
   Wait Until Page Contains       Data Science Pipelines
   Page Should Contain Element    ${PIPELINES_DISABLED_EXC_MARK}  timeout=10s
