*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Library         SeleniumLibrary
Suite Setup     Anaconda Commercial Edition Suite Setup
Suite Teardown  Anaconda Commercial Edition Suite Teardown

*** Test Cases ***
Verify Anaconda Commercial Edition Is Available In RHODS Dashboard Explore/Enabled Page
  [Tags]  ODS-262  Smoke  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify Service Is Available In The Explore Page    Anaconda Commercial Edition
  Verify Service Provides "Get Started" Button In The Explore Page    Anaconda Commercial Edition
  ${status}       Run keyword and Return Status         Verify Service Provides "Enable" Button In The Explore Page    Anaconda Commercial Edition 
  Run Keyword If   ${status} == ${False}   Run Keywords
  ...              Verify Service Is Enabled      Anaconda Commercial Edition 
  ...              AND
  ...              FAIL   Anaconda Commercial Edition does not have a "Enable" button in ODH Dashboard since it has been alreday Enabled and Present in Enabled Page


* Keywords ***
Anaconda Commercial Edition Suite Setup
  Set Library Search Order  SeleniumLibrary

Anaconda Commercial Edition Suite Teardown
  Close All Browsers
