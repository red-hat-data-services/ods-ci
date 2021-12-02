*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/Page/HybridCloudConsole/HCCLogin.robot
Resource        ../../../Resources/Page/ODH/JupyterHub/LoginJupyterHub.robot
Resource        ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource        ../../../Resources/Page/ODH/JupyterHub/JupyterLabSidebar.robot
Library         SeleniumLibrary
Library         OpenShiftCLI
Library    ../../../../libs/Helpers.py
Suite Setup     Kafka Suite Setup
Suite Teardown  Kafka Suite Teardown


*** Variables ***
${rhosak_real_appname}=  rhosak
${rhosak_displayed_appname}=  OpenShift Streams for Apache Kafka
${stream_name_test}=  qe-stream-test
${stream_region_test}=  us-east-1
${cloud_provider_test}=  Amazon Web Services
${service_account_test}=  qe-sa-test2
${topic_name_test}=   qe-topic-test2
${consumer_group_test}=  qe-cg-test2

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

Verify User Is Able to Create And Delete a Kafka Stream
  [Tags]  Sanity
  ...     ODS-242
  Enable RHOSAK
  Verify Service Is Enabled  ${rhosak_displayed_appname}
  Launch OpenShift Streams for Apache Kafka From RHODS Dashboard Link
  Login to HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
  Maybe Skip RHOSAK Tour
  Sleep  5
  Wait Until Page Contains    Create Kafka instance
  Create Kafka Stream Instance  stream_name=${stream_name_test}  stream_region=${stream_region_test}  cloud_provider=${cloud_provider_test}
  Capture Page Screenshot  newly_created_stream.png
  Search Item By Name and Owner in RHOSAK Table  name_search_term=${stream_name_test}  owner_search_term=${SSO.USERNAME}
  Wait Until Keyword Succeeds    300  1  Check Stream Status  Ready
  Delete Kafka Stream Instance  stream_name=${stream_name_test}  stream_owner=${SSO.USERNAME}
  Wait Until Keyword Succeeds    300  1  Page Should Contain    No results found
  Capture Page Screenshot  after deleting_stream.png
  OpenShiftCLI.Delete      kind=ConfigMap  name=rhosak-validation-result  namespace=redhat-ods-applications
  Delete    kind=ConfigMap  name=rhosak-validation-result  namespace=redhat-ods-applications

Verify User Is Able to Produce and Consume Events
  [Tags]  Sanity  Smoke
  ...     ODS-242-ext

  # test setup -
  Open Browser  https://jupyterhub-redhat-ods-applications.apps.ods-qe-tc.agbe.s1.devshift.org/user/ldap-admin9/lab  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  # Wait for JupyterLab Splash Screen  timeout=60
  Maybe Select Kernel

  ## Create kafka stream
  Create Kafka Stream Instance  stream_name=${stream_name_test}  stream_region=${stream_region_test}  cloud_provider=${cloud_provider_test}
  Search Item By Name and Owner in RHOSAK Table  name_search_term=${stream_name_test}  owner_search_term=${SSO.USERNAME}
  Wait Until Keyword Succeeds    300  1  Check Stream Status  Ready
  ## Create service account
  Click Connection Submenu From Actions Menu
  Wait Until Page Contains Element  xpath=//input[@aria-label="Bootstrap server"]
  ${bootstrap_server}=  Get Element Attribute    xpath=//input[@aria-label="Bootstrap server"]  value
  ${kafka_sa_creds}=  Create Service Account From Connection Menu  sa_description=${service_account_test}
  ## Create topic
  Wait Until Page Contains Element  xpath=//a[text()='${stream_name_test}']
  Click Link    xpath=//a[text()='${stream_name_test}']
  Wait For HCC Splash Page
  Click Button    xpath=//button[@aria-label='Topics']
  Wait For HCC Splash Page
  Create Topic  topic_name_to_create=${topic_name_test}
  Page Should Contain Element    xpath=//a[text()='${topic_name_test}']


  ## Assign permissions
  ## Spawn a notebook with env variables

  Sleep  3
  # Load Kafka Notebooks From Git
  Open Consumer notebook
  ${cons_tab_id} =    Get Selected Tab ID
  Open With JupyterLab Menu  Run  Run All Cells
  Open Producer notebook
  ${prod_tab_id} =    Get Selected Tab ID
  Open With JupyterLab Menu  Run  Run All Cells
  Wait Until JupyterLab Code Cell Is Not Active In a Given Tab  tab_id_to_wait=${prod_tab_id}
  Capture Page Screenshot  cell_not_active.png
  ${producer_output} =  Get JupyterLab Code Output In a Given Tab  tab_id_to_read=${prod_tab_id}
  Capture Page Screenshot  producer_run.png
  Select 2_kafka_consumer_print.ipynb Tab
  Sleep  3
  ${consumer_output} =  Get JupyterLab Code Output In a Given Tab  tab_id_to_read=${cons_tab_id}
  Check Consumer and Producer Output Equality  producer_text=${producer_output}  consumer_text=${consumer_output}
  Sleep  3
  Capture Page Screenshot  consumer_run.png
  #############END DRAFT CODE##############
  # Launch JupyterHub Spawner From Dashboard
  #Wait Until Page Contains Element  xpath://input[@name="Standard Data Science"]
  #Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook
  #Wait for JupyterLab Splash Screen  timeout=60
  #Maybe Select Kernel
  #Load Kafka Notebooks From Git
  #Open Producer notebook
  #Open With JupyterLab Menu  Run  Run All Cells



Verify Permission Assignment
  [Tags]  access
  Open Browser  https://console.redhat.com/application-services/streams/kafkas/c6j2losoj920eaqq5gf0/acls  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  # Open Browser  https://console.redhat.com/application-services/streams/kafkas  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login to HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
  # Maybe Skip RHOSAK Tour
  # Sleep  5
  # Wait Until Page Contains    Create Kafka instance
  # Search Item By Name and Owner in RHOSAK Table  name_search_term=${stream_name_test}  owner_search_term=${SSO.USERNAME}
  # Wait Until Page Contains Element  xpath=//a[text()='${stream_name_test}']
  # Click Link    xpath=//a[text()='${stream_name_test}']
  # Wait For HCC Splash Page
  # Click Button    xpath=//button[@aria-label='Access']
  # Wait For HCC Splash Page
  Sleep  3
  Assign Permissions To ServiceAccount in RHOSAK  sa_client_id=srvc-acct-898640c2-50a6-48bc-984c-6e72e8a93cbe  sa_to_assign=${service_account_test}



** Keywords ***
Assign Permissions To ServiceAccount in RHOSAK
  [Arguments]  ${sa_client_id}  ${sa_to_assign}
  Click Button  Manage access
  Wait Until Page Contains Element  xpath=//div[@id='manage-permissions-modal']/form//input[@aria-label='Select an account']
  # Click Element   xpath=//div[@id='manage-permissions-modal']/form//div[contains(@class, 'pf-m-typeahead')]
  # Input Text  xpath=//div[@id='manage-permissions-modal']/form//input[@aria-label='Select an account']   ${sa_to_assign}
  Input Text  xpath=//div[(@id='manage-permissions-modal') and (@class='pf-c-modal-box__body')]/form//input[@aria-label='Select an account']   ${sa_to_assign}
  Sleep  1
  Click Element   xpath=//div[(@id='manage-permissions-modal') and (@class='pf-c-modal-box__body')]/form//li/button/span[text()='${sa_client_id}']
  Wait Until Element Is Enabled  xpath=//button[text()='Next']
  Click Button  Next
  Wait Until Page Contains  Assign permissions
  Click Element  xpath=//button[@aria-label='Options menu']
  Wait Until Page Contains Element  xpath=//div/ul[@class='pf-c-select__menu']/li/button[text()='Topic']
  Click Element  xpath=//div/ul[@class='pf-c-select__menu']/li/button[text()='Topic']
  Click Button  Add




Wait Until JupyterLab Code Cell Is Not Active In a Given Tab
  [Documentation]  Waits until the current cell no longer has an active prompt "[*]:".
  ...              This assumes that there is only one cell currently active and it is the currently selected cell
  ...              It works when there are multiple notebook tabs opened
  [Arguments]  ${tab_id_to_wait}  ${timeout}=120seconds
  Wait Until Element Is Not Visible  //div[@aria-labelledby="${tab_id_to_wait}"]/div[2]/div[1]/div[2]/div[contains(@class,"jp-Cell-inputArea")]/div[contains(@class,"jp-InputArea-prompt") and (.="[*]:")][1]   ${timeout}

Get Selected Tab ID
  ${active-nb-tab} =    Get WebElement    xpath:${JL_TABBAR_SELECTED_XPATH}
  ${tab-id} =    Get Element Attribute    ${active-nb-tab}    id
  [Return]  ${tab-id}

Get JupyterLab Code Output In a Given Tab
   [Arguments]  ${tab_id_to_read}
   ${outputtext}=  Get Text  (//div[@aria-labelledby="${tab_id_to_read}"]//div[2]/div[1]/div[3]/div[contains(@class,"jp-Cell-outputArea")]/div/div[contains(@class,"jp-RenderedText")])[last()]
   [Return]  ${outputtext}

Select ${filename} Tab
  Click Element    xpath:${JL_TABBAR_CONTENT_XPATH}/li/div[.="${filename}"]

Check Consumer and Producer Output Equality
  [Arguments]  ${producer_text}  ${consumer_text}
  ${producer_output_list}=  Text To List  text=${producer_text}
  ${consumer_output_list}=  Text To List  text=${consumer_text}
  Should Be Equal    ${producer_output_list}    ${consumer_output_list}[1:]

Kafka Test Setup MOD
  Open Browser  https://jupyterhub-redhat-ods-applications.apps.ods-qe-tc.agbe.s1.devshift.org/user/ldap-admin9/lab  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  # Wait for JupyterLab Splash Screen  timeout=60
  Maybe Select Kernel

Launch JupyterHub Spawner From Dashboard MOD
  Menu.Navigate To Page    Applications    Enabled
  Launch JupyterHub From RHODS Dashboard Dropdown
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  # ${authorization_required} =  Is Service Account Authorization Required
  # Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  # Fix Spawner Status
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']

Load Kafka Notebooks From Git
  Open With JupyterLab Menu  File  New  Notebook
  Sleep  1
  Maybe Select Kernel
  Sleep  3
  Close Other JupyterLab Tabs
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  Git  Clone a Repository
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  https://github.com/bdattoma/notebook-examples.git
  Click Element  xpath://div[.="CLONE"]
  Sleep  5

Open Producer notebook
  # open producer
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  notebook-examples/kafka-sasl-plain/1_kafka_producer.ipynb
  Click Element  xpath://div[.="Open"]
  Wait Until 1_kafka_producer.ipynb JupyterLab Tab Is Selected

Open Consumer notebook
  # open consumer
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  notebook-examples/kafka-sasl-plain/2_kafka_consumer_print.ipynb
  Click Element  xpath://div[.="Open"]
  Wait Until 2_kafka_consumer_print.ipynb JupyterLab Tab Is Selected


Kafka Suite Setup
  Set Library Search Order  SeleniumLibrary

Kafka Suite Teardown
  Close All Browsers

Kafka Test Setup
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

Enable RHOSAK
  Menu.Navigate To Page    Applications    Explore
  Wait Until Page Contains    ${rhosak_displayed_appname}  timeout=30
  Click Element     xpath://*[@id='${rhosak_real_appname}']
  Wait Until Page Contains Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}   timeout=10   error=${rhosak_real_appname} does not have sidebar with information in the Explore page of ODS Dashboard
  Page Should Contain Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}   message=${rhosak_real_appname} does not have a "Enable" button in ODS Dashboard
  Click Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}
  Wait Until Page Contains Element    xpath://div[contains(@id, 'pf-modal-part')]
  Click Button    xpath://footer/button[text()='Enable']
  Wait Until Page Contains Element   xpath://div[@class='pf-c-alert pf-m-success']

Check Stream Status
  [Arguments]  ${target_status}
  ${status}=  Get Text    xpath://tr[@tabindex='0']/td[@data-label='Status']
  Should Be Equal    ${status}    ${target_status}

Check Stream Creation
  Wait Until Keyword Succeeds    300  1  Check Stream Status  Ready


Create Kafka Stream Instance
  [Arguments]  ${stream_name}  ${stream_region}  ${cloud_provider}
  Click Button  Create Kafka instance
  Sleep  5
  Maybe Accept Cookie Policy
  Sleep  5
  Maybe Agree RH Terms and Conditions
  Wait Until Page Contains Element    xpath=//div[@id='modalCreateKafka']  timeout=10
  ${warn_msg}=  Run Keyword And Return Status    Page Should Not Contain    To deploy a new instance, delete your existing one first
  IF    ${warn_msg} == ${False}
     Log  level=WARN  message=The next keywords are going to fail because you cannot create more than one stream at a time.
  END
  Input Text    xpath=//input[@id='form-instance-name']    ${stream_name}
  Click Element    xpath=//div[text()='${cloud_provider}']
  Select From List By Value    id:form-cloud-region-option   ${stream_region}
  Click Button    Create instance
  Capture Page Screenshot  form.png
  Sleep    2

Delete Kafka Stream Instance
  [Arguments]  ${stream_name}  ${stream_owner}
  Click Button    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/button[@aria-label='Actions']
  Wait Until Page Contains Element    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/ul/li/button[text()='Delete']
  Click Button    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/ul/li/button[text()='Delete']
  Wait Until Page Contains Element    xpath=//div[contains(@id, 'pf-modal-part')]
  Input Text    id:name__input   ${stream_name}
  Click Button    Delete

Click ${action} Submenu From Actions Menu
  Wait Until Page Contains Element    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/button[@aria-label='Actions']
  Click Button    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/button[@aria-label='Actions']
  Wait Until Page Contains Element    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/ul/li/button[text()='${action}']
  Click Button    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/ul/li/button[text()='${action}']

Create Service Account From Connection Menu
  [Arguments]  ${sa_description}
  # Set Log Level    NONE
  Wait Until Page Contains Element    xpath=//section[contains(@id, 'pf-tab-section-connection')]/div/button[text()='Create service account']
  Click Button  xpath=//section[contains(@id, 'pf-tab-section-connection')]/div/button[text()='Create service account']
  Wait Until Page Contains Element    xpath=//div[@id='modalCreateSAccount']
  Input Text  xpath=//input[@id='text-input-short-description']  ${sa_description}
  Click Button  Create
  Wait Until Page Contains  Credentials successfully generated
  ${kafka_client_id}=  Get Element Attribute  xpath=//input[@aria-label='Client ID']  value
  ${kafka_client_secret}=  Get Element Attribute  xpath=//input[@aria-label='Client secret']  value
  &{service_account_creds}=  Create Dictionary  kafka_client_id=${kafka_client_id}  kafka_client_secret=${kafka_client_secret}
  Select Checkbox    xpath=//input[@class='pf-c-check__input']
  Wait Until Element Is Enabled    xpath=//button[@data-testid='modalCredentials-buttonClose']
  [Return]  &{service_account_creds}

Create Topic
  [Arguments]  ${topic_name_to_create}
  Click Button  Create topic
  Wait For HCC Splash Page
  Input Text  name:step-topic-name  ${topic_name_to_create}
  Click Button   Next
  Wait Until Page Contains Element  xpath=//h2[text()='Partitions']
  Click Button   Next
  Wait Until Page Contains Element  xpath=//h2[text()='Message retention']
  Click Button   Next
  Wait Until Page Contains Element    xpath=//button[text()='Finish']
  Click Button   Finish
  Wait For HCC Splash Page








