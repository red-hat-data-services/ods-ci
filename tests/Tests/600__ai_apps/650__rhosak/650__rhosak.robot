*** Settings ***
Documentation       Test integration with RHOSAK isv

Library             SeleniumLibrary
Library             OpenShiftCLI
Resource            ../../../Resources/Page/ODH/AiApps/Rhosak.resource

Suite Setup         Kafka Suite Setup
Suite Teardown      Kafka Suite Teardown
Test Setup          Kafka Test Setup


*** Variables ***
${RHOSAK_REAL_APPNAME}=         rhosak
${RHOSAK_DISPLAYED_APPNAME}=    OpenShift Streams for Apache Kafka
${STREAM_NAME_TEST}=            ${RHOSAK_CONFIG_TEST.STREAM_NAME}
${STREAM_REGION_TEST}=          ${RHOSAK_CONFIG_TEST.STREAM_REGION}
${CLOUD_PROVIDER_TEST}=         ${RHOSAK_CONFIG_TEST.CLOUD_PROVIDER}
${SERVICE_ACCOUNT_TEST}=        ${RHOSAK_CONFIG_TEST.SERVICE_ACCOUNT}
${TOPIC_NAME_TEST}=             ${RHOSAK_CONFIG_TEST.TOPIC_NAME}
${CONSUMER_GROUP_TEST}=         ${RHOSAK_CONFIG_TEST.CONSUMER_GROUP}
${GIT_REPO_NOTEBOOKS}=          https://github.com/bdattoma/notebook-examples.git
${NOTEBOOK_DIR_PATH}=           notebook-examples/kafka-sasl-plain
${NOTEBOOK_CONS_FILENAME}=      2_kafka_consumer_print.ipynb
${NOTEBOOK_PROD_FILENAME}=      1_kafka_producer.ipynb
${KAFKA_CLIENT_ID}=             "placeholder"
${KAFKA_CLIENT_SECRET}=         "placeholder"


*** Test Cases ***
Verify RHOSAK Is Available In RHODS Dashboard Explore Page
    [Documentation]    Checks RHOSAK card is present in RHODS Dashboard > Explore Page
    [Tags]    Smoke    Sanity
    ...       ODS-258
    Verify Service Is Available In The Explore Page    ${RHOSAK_DISPLAYED_APPNAME}
    Verify Service Provides "Get Started" Button In The Explore Page    ${RHOSAK_DISPLAYED_APPNAME}
    Verify Service Provides "Enable" Button In The Explore Page    ${RHOSAK_DISPLAYED_APPNAME}

Verify User Can Enable RHOSAK from Dashboard Explore Page
    [Documentation]    Checks it is possible to enable RHOSAK from RHODS Dashboard > Explore Page
    [Tags]    Sanity    Smoke
    ...       ODS-392
    [Teardown]  Remove RHOSAK From Dashboard
    Enable RHOSAK
    Capture Page Screenshot  kafka_enable_msg.png
    Verify Service Is Enabled  ${RHOSAK_DISPLAYED_APPNAME}
    Capture Page Screenshot    kafka_enable_tab.png
    Launch OpenShift Streams for Apache Kafka From RHODS Dashboard Link    # robocop: disable
    Login To HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
    Maybe Skip RHOSAK Tour
    Wait Until Page Contains    Kafka Instances

Verify User Is Able to Produce and Consume Events
  [Tags]  Tier2
  ...     ODS-248  ODS-247  ODS-246  ODS-245  ODS-243  ODS-241  ODS-239  ODS-242
  [Teardown]  Clean Up RHOSAK    stream_to_delete=${STREAM_NAME_TEST}
  ...                            topic_to_delete=${TOPIC_NAME_TEST}
  ...                            sa_clientid_to_delete=${KAFKA_CLIENT_ID}
  ...                            rhosak_app_id=${RHOSAK_REAL_APPNAME}
  Enable RHOSAK
  Verify Service Is Enabled  ${RHOSAK_DISPLAYED_APPNAME}
  Launch OpenShift Streams for Apache Kafka From RHODS Dashboard Link
  Login to HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
  Maybe Skip RHOSAK Tour
  Sleep  5
  Wait Until Page Contains    Create Kafka instance
  ## Create kafka stream
  Create Kafka Stream Instance  stream_name=${STREAM_NAME_TEST}  stream_region=${STREAM_REGION_TEST}  cloud_provider=${CLOUD_PROVIDER_TEST}
  Wait Until Keyword Succeeds    450  1  Check Stream Status  target_status=Ready  target_stream=${STREAM_NAME_TEST}
  ## Create service account
  Click From Actions Menu  search_col=Name  search_value=${STREAM_NAME_TEST}  action=Connection
  Wait Until Page Contains Element  xpath=//input[@aria-label="Bootstrap server"]
  ${bootstrap_server}=  Get Element Attribute    xpath=//input[@aria-label="Bootstrap server"]  value
  ${kafka_sa_creds}=  Create Service Account From Connection Menu  sa_description=${SERVICE_ACCOUNT_TEST}
  ${KAFKA_CLIENT_ID}=  Set Variable  ${kafka_sa_creds}[KAFKA_CLIENT_ID]
  ${KAFKA_CLIENT_SECRET}=  Set Variable  ${kafka_sa_creds}[KAFKA_CLIENT_SECRET]
  ## Create topic
  Enter Stream  stream_name=${STREAM_NAME_TEST}
  Enter Stream Topics Section
  # Wait For HCC Splash Page
  Create Topic  topic_name_to_create=${TOPIC_NAME_TEST}
  Page Should Contain Element    xpath=//a[text()='${TOPIC_NAME_TEST}']
  ## Assign permissions to SA
  Enter Stream Access Section
  Assign Permissions To ServiceAccount in RHOSAK  sa_client_id=${KAFKA_CLIENT_ID}  sa_to_assign=${SERVICE_ACCOUNT_TEST}
  ...                                             topic_to_assign=${TOPIC_NAME_TEST}  cg_to_assign=${CONSUMER_GROUP_TEST}

  ## Spawn a notebook with env variables
  Switch Window  title:Red Hat OpenShift Data Science Dashboard
  Wait for RHODS Dashboard to Load
  Launch JupyterHub Spawner From Dashboard
  Wait Until Page Contains Element  xpath://input[@name="Standard Data Science"]
  &{notebook_envs}=  Create Dictionary  KAFKA_BOOTSTRAP_SERVER=${bootstrap_server}  KAFKA_USERNAME=${KAFKA_CLIENT_ID}
  ...                                   KAFKA_PASSWORD=${KAFKA_CLIENT_SECRET}  KAFKA_TOPIC=${TOPIC_NAME_TEST}
  ...                                   KAFKA_CONSUMER_GROUP=${CONSUMER_GROUP_TEST}
  Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook  envs=&{notebook_envs}
  ## clone JL notebooks from git and run
  Clone Git Repository  REPO_URL=${GIT_REPO_NOTEBOOKS}
  Open Consumer Notebook  dir_path=${NOTEBOOK_DIR_PATH}  filename=${NOTEBOOK_CONS_FILENAME}
  ${cons_tab_id} =    Get Selected Tab ID
  Open With JupyterLab Menu  Run  Run All Cells
  Sleep  1
  Open Producer Notebook  dir_path=${NOTEBOOK_DIR_PATH}  filename=${NOTEBOOK_PROD_FILENAME}
  ${prod_tab_id} =    Get Selected Tab ID
  Open With JupyterLab Menu  Run  Run All Cells
  Wait Until JupyterLab Code Cell Is Not Active In a Given Tab  tab_id_to_wait=${prod_tab_id}
  Capture Page Screenshot  cell_not_active.png
  ${producer_output} =  Get JupyterLab Code Output In a Given Tab  tab_id_to_read=${prod_tab_id}
  Capture Page Screenshot  producer_run.png
  Select ${NOTEBOOK_CONS_FILENAME} Tab
  Sleep  3
  ${consumer_output} =  Get JupyterLab Code Output In a Given Tab  tab_id_to_read=${cons_tab_id}
  Check Consumer and Producer Output Equality  producer_text=${producer_output}  consumer_text=${consumer_output}
  Capture Page Screenshot  consumer_run.png
  Fix Spawner Status


*** Keywords ***
Kafka Suite Setup
    [Documentation]    Setup for RHOSAK Test Suite
    Set Library Search Order    SeleniumLibrary

Kafka Suite Teardown
    [Documentation]    Teardown for Test Suite
    Close All Browsers

Kafka Test Setup
    [Documentation]    Setup for RHOSAK Test Cases
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
