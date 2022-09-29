*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/RHOSi.resource
Resource        ../../../Resources/Page/ODH/AiApps/Rhoam.resource
Library         SeleniumLibrary
Suite Setup     RHOAM Suite Setup
Suite Teardown  RHOAM Suite Teardown


*** Test Cases ***
Verify RHOAM Is Available In RHODS Dashboard Explore Page
  [Tags]    Smoke   Tier1
  ...       ODS-271
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify RHOAM Availability Based On RHODS Installation Type

Verify RHOAM Is Enabled In RHODS After Installation
    [Documentation]    Verifies RHOAM tile is displayed in RHODS Dashboard > Enabled page.
    ...                It assumes RHOAM addon has been previously installed on the same cluster
    [Tags]    MPS-Pipeline
    ...       RHOAM-RHODS
    Verify RHOAM Is Enabled In RHODS Dashboard


*** Keywords ***
RHOAM Suite Setup
  Set Library Search Order  SeleniumLibrary
  RHOSi Setup

RHOAM Suite Teardown
  Close All Browsers

Verify RHOAM Availability Based On RHODS Installation Type
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    ${is_self_managed} == ${TRUE}
        Verify Service Is Not Available In The Explore Page    OpenShift API Management
    ELSE
        Verify Service Is Available In The Explore Page    OpenShift API Management
        Verify Service Provides "Get Started" Button In The Explore Page    OpenShift API Management
    END



