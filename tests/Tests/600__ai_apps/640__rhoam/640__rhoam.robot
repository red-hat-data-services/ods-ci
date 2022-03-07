*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/Page/ODH/AiApps/Rhoam.resource
Library         ../../../../libs/Helpers.py
Library         SeleniumLibrary
Library         OpenShiftCLI
Suite Setup     RHOAM Suite Setup
Suite Teardown  RHOAM Suite Teardown

*** Test Cases ***
Verify RHOAM Is Available In RHODS Dashboard Explore Page
  [Tags]  ODS-271  Smoke  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify Service Is Available In The Explore Page    OpenShift API Management
  Verify Service Provides "Get Started" Button In The Explore Page    OpenShift API Management

Verify install
    [Tags]  rhoam
    Install Rhoam Addon    cluster_name=<cluster_name>
    Wait Until RHOAM Installation Is Completed    retries=20   retries_interval=2min

Verify uninstall
    [Tags]  rhoam-uni
    Uninstall Rhoam Addon    cluster_name=<cluster_name>


*** Keywords ***
RHOAM Suite Setup
  Set Library Search Order  SeleniumLibrary

RHOAM Suite Teardown
  Close All Browsers


