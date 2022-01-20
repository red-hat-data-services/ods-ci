*** Settings ***
Library         SeleniumLibrary
Library         OpenShiftCLI
Resource        ../../../Resources/Page/ODH/AiApps/Rhosak.resource
Suite Setup     Kafka Suite Setup
Suite Teardown  Kafka Suite Teardown
Test Setup      Kafka Test Setup


*** Variables ***
${rhosak_real_appname}=  rhosak
${rhosak_displayed_appname}=  OpenShift Streams for Apache Kafka
${stream_name_test}=  ${RHOSAK_CONFIG_TEST.STREAM_NAME}
${stream_region_test}=  ${RHOSAK_CONFIG_TEST.STREAM_REGION}
${cloud_provider_test}=  ${RHOSAK_CONFIG_TEST.CLOUD_PROVIDER}
${service_account_test}=  ${RHOSAK_CONFIG_TEST.SERVICE_ACCOUNT}
${topic_name_test}=   ${RHOSAK_CONFIG_TEST.TOPIC_NAME}
${consumer_group_test}=  ${RHOSAK_CONFIG_TEST.CONSUMER_GROUP}
${GIT_REPO_NOTEBOOKS}=  https://github.com/bdattoma/notebook-examples.git
${NOTEBOOK_DIR_PATH}=   notebook-examples/kafka-sasl-plain
${NOTEBOOK_CONS_FILENAME}=   2_kafka_consumer_print.ipynb
${NOTEBOOK_PROD_FILENAME}=   1_kafka_producer.ipynb
${kafka_client_id}=  "placeholder"
${kafka_client_secret}=  "placeholder"

*** Test Cases ***
Verify RHOSAK Is Available In RHODS Dashboard Explore Page
  [Tags]  ODS-258  Smoke  Sanity
  Verify Service Is Available In The Explore Page    ${rhosak_displayed_appname}
  Verify Service Provides "Get Started" Button In The Explore Page    ${rhosak_displayed_appname}
  Verify Service Provides "Enable" Button In The Explore Page    ${rhosak_displayed_appname}


Verify User Can Enable RHOSAK from Dashboard Explore Page
  [Tags]  Sanity  Smoke
  ...     ODS-392
  Enable RHOSAK
  Capture Page Screenshot  kafka_enable_msg.png
  Verify Service Is Enabled  ${rhosak_displayed_appname}
  Capture Page Screenshot  kafka_enable_tab.png
  Launch OpenShift Streams for Apache Kafka From RHODS Dashboard Link
  Login to HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
  Maybe Skip RHOSAK Tour
  Wait Until Page Contains    Kafka Instances
  Delete Configmap    name=rhosak-validation-result  namespace=redhat-ods-applications


Verify User Is Able to Produce and Consume Events
  [Tags]  Sanity  Tier2
  ...     ODS-248  ODS-247  ODS-246  ODS-245  ODS-243  ODS-241  ODS-239  ODS-242
  [Teardown]  Clean Up RHOSAK    stream_to_delete=${stream_name_test}
  ...                            topic_to_delete=${topic_name_test}
  ...                            sa_clientid_to_delete=${kafka_client_id}
  Enable RHOSAK
  Verify Service Is Enabled  ${rhosak_displayed_appname}
  Launch OpenShift Streams for Apache Kafka From RHODS Dashboard Link
  Login to HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
  Maybe Skip RHOSAK Tour
  Sleep  5
  Wait Until Page Contains    Create Kafka instance
  ## Create kafka stream
  Create Kafka Stream Instance  stream_name=${stream_name_test}  stream_region=${stream_region_test}  cloud_provider=${cloud_provider_test}
  Search Item By Name and Owner in RHOSAK Table  name_search_term=${stream_name_test}  owner_search_term=${SSO.USERNAME}
  Wait Until Keyword Succeeds    450  1  Check Stream Status  target_status=Ready  target_stream=${stream_name_test}
  ## Create service account
  Click From Actions Menu  search_col=Name  search_value=${stream_name_test}  action=Connection
  Wait Until Page Contains Element  xpath=//input[@aria-label="Bootstrap server"]
  ${bootstrap_server}=  Get Element Attribute    xpath=//input[@aria-label="Bootstrap server"]  value
  ${kafka_sa_creds}=  Create Service Account From Connection Menu  sa_description=${service_account_test}
  ${kafka_client_id}=  Set Variable  ${kafka_sa_creds}[kafka_client_id]
  ${kafka_client_secret}=  Set Variable  ${kafka_sa_creds}[kafka_client_secret]
  ## Create topic
  Enter Stream  stream_name=${stream_name_test}
  Enter Stream Topics Section
  # Wait For HCC Splash Page
  Create Topic  topic_name_to_create=${topic_name_test}
  Page Should Contain Element    xpath=//a[text()='${topic_name_test}']
  ## Assign permissions to SA
  Enter Stream Access Section
  Assign Permissions To ServiceAccount in RHOSAK  sa_client_id=${kafka_client_id}  sa_to_assign=${service_account_test}
  ...                                             topic_to_assign=${topic_name_test}  cg_to_assign=${consumer_group_test}

  ## Spawn a notebook with env variables
  Switch Window  title:Red Hat OpenShift Data Science Dashboard
  Wait for RHODS Dashboard to Load
  Launch JupyterHub Spawner From Dashboard
  Wait Until Page Contains Element  xpath://input[@name="Standard Data Science"]
  &{notebook_envs}=  Create Dictionary  KAFKA_BOOTSTRAP_SERVER=${bootstrap_server}  KAFKA_USERNAME=${kafka_client_id}
  ...                                   KAFKA_PASSWORD=${kafka_client_secret}  KAFKA_TOPIC=${topic_name_test}
  ...                                   KAFKA_CONSUMER_GROUP=${consumer_group_test}
  Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook  envs=&{notebook_envs}
  Wait for JupyterLab Splash Screen  timeout=60
  Maybe Select Kernel
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
  Set Library Search Order  SeleniumLibrary

Kafka Suite Teardown
  Close All Browsers

Kafka Test Setup
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

