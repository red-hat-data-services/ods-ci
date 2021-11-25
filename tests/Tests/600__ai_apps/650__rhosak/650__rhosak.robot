*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Library         SeleniumLibrary
Library         OpenShiftCLI
Suite Setup     Kafka Suite Setup
Suite Teardown  Kafka Suite Teardown
Test Setup      Kafka Test Setup

*** Variables ***
${rhosak_appname}=  rhosak

*** Test Cases ***
Verify RHOSAK Is Available In RHODS Dashboard Explore Page
  [Tags]  ODS-258  Smoke  Sanity
  Verify Service Is Available In The Explore Page    OpenShift Streams for Apache Kafka
  Verify Service Provides "Get Started" Button In The Explore Page    OpenShift Streams for Apache Kafka
  Verify Service Provides "Enable" Button In The Explore Page    OpenShift Streams for Apache Kafka

Verify User Can Enable RHOSAK from Dashboard Explore Page
  [Tags]  Sanity  Smoke
  ...     ODS-392
  Enable RHOSAK
  Wait Until Page Contains Element   xpath://div[@class='pf-c-alert pf-m-success']
  Capture Page Screenshot  kafka_enable_msg.png
  Menu.Navigate To Page    Applications    Enabled
  Wait Until RHODS Dashboard JupyterHub Is Visible
  Capture Page Screenshot  enabletab_rhosak_present.png
  Page Should Contain Element  xpath://div[@class="pf-c-card__title"]/span[.="OpenShift Streams for Apache Kafka"]
  Capture Page Screenshot  kafka_enable_tab.png
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
  Wait Until Page Contains    OpenShift Streams for Apache Kafka  timeout=30
  Click Element     xpath://*[@id='${rhosak_appname}']
  Wait Until Page Contains Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}   timeout=10   error=${rhosak_appname} does not have sidebar with information in the Explore page of ODS Dashboard
  Page Should Contain Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}   message=${rhosak_appname} does not have a "Enable" button in ODS Dashboard
  Click Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}
  Wait Until Page Contains Element    xpath://div[contains(@id, 'pf-modal-part')]
  Click Button    xpath://footer/button[text()='Enable']
