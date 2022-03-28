*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/RHOSi.resource
Library         SeleniumLibrary
Suite Setup     RHOAM Suite Setup
Suite Teardown  RHOAM Suite Teardown


*** Test Cases ***
Verify RHOAM Is Available In RHODS Dashboard Explore Page
  [Tags]    Smoke   Tier1    Sanity
  ...       ODS-271
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify Service Is Available In The Explore Page    OpenShift API Management
  Verify Service Provides "Get Started" Button In The Explore Page    OpenShift API Management


*** Keywords ***
RHOAM Suite Setup
  Set Library Search Order  SeleniumLibrary
  RHOSi Setup

RHOAM Suite Teardown
  Close All Browsers



