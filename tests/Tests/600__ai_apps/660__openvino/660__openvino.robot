*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Library         SeleniumLibrary
Suite Setup     OpenVino Suite Setup
Suite Teardown  OpenVino Suite Teardown

*** Test Cases ***
Verify OpenVino Is Available In RHODS Dashboard Explore Page
  [Tags]  ODS-258  Smoke  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify Service Is Available In The Explore Page    OpenVINO
  Verify Service Provides "Get Started" Button In The Explore Page    OpenVINO

* Keywords ***
OpenVino Suite Setup
  Set Library Search Order  SeleniumLibrary

OpenVino Suite Teardown
  Close All Browsers
