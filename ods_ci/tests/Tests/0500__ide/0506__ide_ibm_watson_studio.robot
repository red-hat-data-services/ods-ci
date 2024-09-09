*** Settings ***
Resource        ../../Resources/Page/LoginPage.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../Resources/RHOSi.resource
Library         SeleniumLibrary
Suite Setup     IBM Watsonx AI Suite Setup
Suite Teardown  IBM Watsonx AI Suite Teardown
Test Tags       ExcludeOnODH

*** Test Cases ***
Verify IBM Watsonx AI Is Available In RHODS Dashboard Explore Page
  [Documentation]  Very simple test to check that the Watsonx.ai tile/card is present
  ...    in the list of applications on the Applications -> Explore page.
  [Tags]  Smoke
  ...     ODS-267
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load
  Verify Service Is Available In The Explore Page    IBM watsonx.ai
  Verify Service Provides "Get Started" Button In The Explore Page    IBM watsonx.ai

* Keywords ***
IBM Watsonx AI Suite Setup
  [Documentation]  Suite setup
  Set Library Search Order  SeleniumLibrary
  RHOSi Setup

IBM Watsonx AI Suite Teardown
  [Documentation]  Suite teardown
  Close All Browsers
