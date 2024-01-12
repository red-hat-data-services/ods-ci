*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/RHOSi.resource
Library         SeleniumLibrary
Suite Setup     IBM Watson Studio Suite Setup
Suite Teardown  IBM Watson Studio Suite Teardown

*** Test Cases ***
Verify IBM Watson Studio Is Available In RHODS Dashboard Explore Page
  [Tags]  Smoke
  ...     Tier1
  ...     ODS-267
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify Service Is Available In The Explore Page    IBM Watson Studio
  Verify Service Provides "Get Started" Button In The Explore Page    IBM Watson Studio

* Keywords ***
IBM Watson Studio Suite Setup
  Set Library Search Order  SeleniumLibrary
  RHOSi Setup

IBM Watson Studio Suite Teardown
  Close All Browsers
