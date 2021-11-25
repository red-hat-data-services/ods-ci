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
  Wait Until Page Contains Element   xpath://div[@class='pf-c-alert pf-m-success']
  Capture Page Screenshot  kafka_enable_msg.png
  Menu.Navigate To Page    Applications    Enabled
  Wait Until RHODS Dashboard JupyterHub Is Visible
  Page Should Contain Element  xpath://div[@class="pf-c-card__title"]/span[.="${rhosak_displayed_appname}"]
  Capture Page Screenshot  kafka_enable_tab.png
  Launch OpenShift Streams for Apache Kafka From RHODS Dashboard Link
  Login to HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
  Wait For HCC Splash Page
  Maybe Skip RHOSAK Tour
  Wait Until Page Contains    Kafka Instances
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

