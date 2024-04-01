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
${RUN_TOPOLOGY_DETAILS_BTN_XP}=       xpath://*[@data-testid="bottom-drawer-tab-details"]
${RUN_TOPOLOGY_OUTPUT_BTN_XP}=        xpath://*[@data-testid="bottom-drawer-tab-run-output"]
${RUN_TOPOLOGY_XP}=                   xpath://*[@data-test-id="topology"]
${PIPELINES_DISABLED_EXC_MARK}=       xpath=//*[@id="page-sidebar"]/div/nav/ul/li[3]/a/div/div[2]

*** Keywords ***
Create Pipeline Server
    [Documentation]    Creates the DS Pipeline server from DS Project details page
    ...                It assumes the Data Connection is aleady created
    ...                and you wants to use defaul DB configurations [TEMPORARY]
    [Arguments]    ${dc_name}    ${project_title}
    ...            ${aws_s3_ca_bundle}=${NONE}
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
    ${is_ca_empty}=    Is String Empty    ${aws_s3_ca_bundle}
    IF    ${is_ca_empty}
        ${aws_s3_ca_bundle}=    Get Variable Value    ${S3.AWS_CA_BUNDLE}    ${NONE}
    END
    ${is_ca_empty}=    Is String Empty    ${aws_s3_ca_bundle}
    IF    not ${is_ca_empty}
        Patch Pipeline Server With CA Bundle
        ...    project_title=${project_title}    aws_s3_ca_bundle=${aws_s3_ca_bundle}
    END

Patch Pipeline Server With CA Bundle
    [Documentation]    Patch the underlying dspa resource with CA Bundle
    ...                The CA Bundle can be obtained from S3.AWS_CA_BUNDLE in test-variables.yml
    [Arguments]    ${project_title}    ${aws_s3_ca_bundle}
    ${dc_namespace}=    Get Openshift Namespace From Data Science Project    ${project_title}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc create configmap custom-ca-bundle -n ${dc_namespace} --from-literal=ca-bundle.crt='${aws_s3_ca_bundle}'    # robocop: disable
    Should Be Equal As Integers    ${rc}    0
    Log    "${out}"
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc patch dspa pipelines-definition -n ${dc_namespace} -p '[{"op":"add","path":"/spec/apiServer/cABundle","value":{"configMapKey":"ca-bundle.crt","configMapName":"custom-ca-bundle"}}]' --type json     # robocop: disable
    Should Be Equal As Integers    ${rc}    0
    Log    "${out}"

Select Data Connection
    [Documentation]    Selects an existing data connection from the dropdown
    ...                in the modal for Pipeline Server creation
    [Arguments]    ${dc_name}
    Wait Until Page Contains Element    xpath://div[@class="pf-v5-c-form__group"][.//label//*[text()="Access key"]]//div[@data-ouia-component-type="PF5/Dropdown"]
    Click Element                       xpath://div[@class="pf-v5-c-form__group"][.//label//*[text()="Access key"]]//div[@data-ouia-component-type="PF5/Dropdown"]
    Wait Until Page Contains Element    xpath://button//*[text()="${dc_name}"]
    Click Element    xpath://button//*[text()="${dc_name}"]

Import Pipeline
    [Documentation]    Import a pipeline definition from DS Project details page.
    ...                It expects to receive the relative path starting from ods_ci/
    [Arguments]    ${name}    ${filepath}    ${project_title}    ${description}=${NONE}    ${press_cancel}=${FALSE}
    Projects.Move To Tab    Pipelines
    Wait Until Element Is Enabled       ${PIPELINES_IMPORT_BTN_XP}  timeout=120
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
    [Arguments]    ${name}    ${pipeline_name}=${NONE}    ${run_type}=Immediate
    ...            ${trigger_type}=Periodic    ${start_date}=${NONE}    ${start_time}=${NONE}    ${end_date}=${NONE}
    ...            ${end_time}=${NONE}    ${cron_expr}=${NONE}    ${press_cancel}=${FALSE}    &{model_param}
    Projects.Move To Tab    Pipelines
    Pipelines.Click Action From Actions Menu    pipeline_name=${pipeline_name}    action=Create run
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
        Click Element    ${CREATE_RUN_BTN_XP}
        Wait Until Page Contains Run Topology Page    run_name=${name}
        ${workflow_name}=    Get Workflow Name From Topology Page
    END
    RETURN    ${workflow_name}

# robocop: disable=too-many-calls-in-keyword,line-too-long
Click Action From Actions Menu
    [Documentation]    Click an action from Actions menu (3-dots menu on the right)
    [Arguments]    ${pipeline_name}    ${action}

    ${pipeline_row_xp}=    Set Variable    //*[@data-testid="table-row-title-${pipeline_name}"]/../..
    ${kebab_xp}=           Set Variable    ${pipeline_row_xp}/td/button[@aria-label="Kebab toggle"]
    ${kebap_action_xp}=    Set Variable    ${pipeline_row_xp}/td/div/div/ul/li/button[.//*[contains(text(), '${action}')]]
    Wait Until Page Contains Element    ${kebab_xp}
    Click Element                       ${kebab_xp}
    Wait Until Page Contains Element    ${kebap_action_xp}
    Click Element                       ${kebap_action_xp}


Click Action From Pipeline Run Actions Menu
    [Documentation]    In Data Science Pipelines > Runs, click an action from Actions menu (3-dots menu on the right)
    [Arguments]    ${pipeline_run_name}    ${action}

    ${pipeline_run_row_xp}=    Set Variable    //table[@data-testid="pipeline-run-table"]/tbody/tr/td/div/div/p[text()="${pipeline_run_name}"]/../../../..
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
    Wait Until Element Is Visible    //div[@class="pf-v5-c-code-editor pf-m-read-only odh-dashboard__code-editor"]    timeout=10
    Capture Page Screenshot
    SeleniumLibrary.Set Selenium Implicit Wait    ${orig wait}

Pipeline Should Be Listed
    [Documentation]    Verifies a pipeline is listed in Data Science Project > Pipelines
    [Arguments]     ${pipeline_name}    ${pipeline_description}
    Projects.Move To Tab    Pipelines
    ${pipeline_name_xpath}=    Set Variable    //*[@data-testid="table-row-title-${pipeline_name}"]
    Run Keyword And Continue On Failure    Wait Until Page Contains Element    ${pipeline_name_xpath}

    IF    "${pipeline_description}" != ${NONE}
        Run Keyword And Continue On Failure
        ...    Wait Until Page Contains Element
        ...        ${pipeline_name_xpath}/following-sibling::*[p[text()="${pipeline_description}"]]
    END

Pipeline Should Not Be Listed
    [Documentation]    Verifies a pipeline not listed in Data Science Project > Pipelines
    [Arguments]     ${pipeline_name}    ${pipeline_description}
    Projects.Move To Tab    Pipelines
    ${pipeline_name_xpath}=    Set Variable    //*[@data-testid="table-row-title-${pipeline_name}"]
    Run Keyword And Continue On Failure    Wait Until Page Does Not Contain Element    ${pipeline_name_xpath}

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
    ...    ${RUN_TOPOLOGY_OUTPUT_BTN_XP}
    Run Keyword And Continue On Failure    Wait Until Page Contains Element
    ...    ${RUN_TOPOLOGY_XP}

Verify Pipeline Server Deployments    # robocop: disable
    [Documentation]    Verifies the correct deployment of DS Pipelines in the rhods namespace
    [Arguments]    ${project_title}

    ${namespace}=    Get Openshift Namespace From Data Science Project
    ...    project_title=${project_title}

    @{all_pods}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=component=data-science-pipelines
    Run Keyword And Continue On Failure    Length Should Be    ${all_pods}    7

    @{pipeline_api_server}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-dspa
    ${containerNames}=  Create List  oauth-proxy    ds-pipeline-api-server
    Verify Deployment    ${pipeline_api_server}  1  2  ${containerNames}

    @{pipeline_metadata_envoy}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-metadata-envoy-dspa
    ${containerNames}=  Create List  container
    Verify Deployment    ${pipeline_metadata_envoy}  1  1  ${containerNames}

    @{pipeline_metadata_grpc}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-metadata-grpc-dspa
    ${containerNames}=  Create List  container
    Verify Deployment    ${pipeline_metadata_grpc}  1  1  ${containerNames}

    @{pipeline_persistenceagent}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-persistenceagent-dspa
    ${containerNames}=  Create List  ds-pipeline-persistenceagent
    Verify Deployment    ${pipeline_persistenceagent}  1  1  ${containerNames}

    @{pipeline_scheduledworkflow}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-scheduledworkflow-dspa
    ${containerNames}=  Create List  ds-pipeline-scheduledworkflow
    Verify Deployment    ${pipeline_scheduledworkflow}  1  1  ${containerNames}

    @{pipeline_workflow_controller}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-workflow-controller-dspa
    ${containerNames}=  Create List  ds-pipeline-workflow-controller
    Verify Deployment    ${pipeline_workflow_controller}  1  1  ${containerNames}

    @{mariadb}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=mariadb-dspa
    ${containerNames}=  Create List  mariadb
    Verify Deployment    ${mariadb}  1  1  ${containerNames}


Wait Until Pipeline Server Is Deployed
    [Documentation]    Waits until all the expected pods of the pipeline server
    ...                are running
    [Arguments]    ${project_title}
    Wait Until Keyword Succeeds    10 times    10s
    ...    Verify Pipeline Server Deployments    project_title=${project_title}

# TODO: we need to replace this keyword for a similar one checking in Data Science Pipelines > Runs
#Verify Successful Pipeline Run Via Project UI
#    [Documentation]    Validates that a given pipeline run in a given pipeline is in successful end state
#    ...    In the DS Project view of a given project
#    [Arguments]    ${pipeline_run_name}    ${pipeline_name}    ${project_name}
#    Open Data Science Project Details Page    ${project_name}
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
    Menu.Navigate To Page    Data Science Pipelines    Runs
    Wait Until Page Contains Element    xpath://span[text()='Triggered']
    Click Element    //span[text()='Triggered']
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
