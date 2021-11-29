*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/Page/HybridCloudConsole/HCCLogin.robot
Library         SeleniumLibrary
Library         OpenShiftCLI
Suite Setup     Kafka Suite Setup
Suite Teardown  Kafka Suite Teardown
Test Setup      Kafka Test Setup

*** Variables ***
${rhosak_real_appname}=  rhosak
${rhosak_displayed_appname}=  OpenShift Streams for Apache Kafka
${stream_name_test}=  qe-test-stream
${stream_region_test}=  us-east-1
${cloud_provider_test}=  Amazon Web Services

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
  [Tags]  Sanity  Smoke
  ...     ODS-242
  Enable RHOSAK
  Verify Service Is Enabled  ${rhosak_displayed_appname}
  Launch OpenShift Streams for Apache Kafka From RHODS Dashboard Link
  Login to HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
  Maybe Skip RHOSAK Tour
  Sleep  5
  Wait Until Page Contains    Create Kafka instance
  Create Kafka Stream Instance  stream_name=${stream_name_test}  stream_region=${stream_region_test}  cloud_provider=${cloud_provider_test}
  Search Item By Name and Owner in RHOSAK Table  name_search_term=${stream_name_test}  owner_search_term=${SSO.USERNAME}
  Wait Until Keyword Succeeds    300  1  Check Stream Status  Ready
  Delete Kafka Stream Instance  stream_name=${stream_name_test}  stream_owner=${SSO.USERNAME}
  Wait Until Keyword Succeeds    300  1  Page Should Contain    No results found
  Delete Configmap    name=rhosak-validation-result  namespace=redhat-ods-applications


** Keywords ***
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
  Select From List By Value    id:cloud-region-select   ${stream_region}
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


