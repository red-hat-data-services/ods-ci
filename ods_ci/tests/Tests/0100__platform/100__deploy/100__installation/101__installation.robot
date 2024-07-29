*** Settings ***
Documentation    Tests to verify that ODH in Openshift can be
...              installed from Dashboard
Metadata         Version    0.0.1
Resource         ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource         ../../../Resources/Page/HybridCloudConsole/HCCLogin.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/RHOSi.resource
Resource         ../../../Resources/ODS.robot
Library          ../../../../utils/scripts/ocm/ocm.py
Library          ../../../../libs/Helpers.py
Library          SeleniumLibrary
Suite Setup      Installation Suite Setup
Suite Teardown   Installation Suite Teardown


*** Variables ***
${STAGE_URL}    https://console.dev.redhat.com/openshift
${PROD_URL}     https://console.redhat.com/openshift


*** Test Cases ***
Can Install ODH Operator
  [Tags]  TBC
  Open OperatorHub
  Install ODH Operator
  ODH Operator Should Be Installed

Check DW Components Are Enabled By Default
    [Documentation]    Check that DW Components are enabled by default, can be run for OCP and OSD
    [Tags]    ODS-2685    Operator    OSD
    Component Should Be Enabled    codeflare
    Component Should Be Enabled    ray
    Component Should Be Enabled    kueue

Verify User Can Access RHODS Documentation From OCM Console
  [Documentation]   Checks user can access RHODS documentation from addon on OCM Console
  [Tags]  ODS-1303
  ...     Tier2
  [Setup]   OCM Test Setup
  Decide OCM URL And Open Link
  Login To HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
  Maybe Skip OCM Tour
  Open Cluster By Name
  Wait Until Page Contains Element    //div[@id="cl-details-top"]     20
  Click Button      //button[@data-ouia-component-id="Add-ons"]
  Wait Until Page Contains Element      //div[@data-ouia-component-id="card-addon-managed-odh"]     10
  Click Element     //div[@data-ouia-component-id="card-addon-managed-odh"]
  Page Should Contain Element       //div[@class="pf-l-flex pf-m-space-items-lg pf-m-column"]//a
  Verify Documentation Is Accessible


*** Keywords ***
Installation Suite Setup
  Set Library Search Order    SeleniumLibrary
  RHOSi Setup

Installation Suite Teardown
  Close All Browsers
  RHOSi Teardown

OCM Test Setup
  [Documentation]   Setup for ODH in Openshift Installation Test Cases
  Skip If RHODS Is Self-Managed
  Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
  ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}

Decide OCM URL And Open Link
  [Documentation]   Decides OCM URL based on the OpenShift Console URL and open the URL.
  ${cluster_type}=  Fetch ODS Cluster Environment
  IF    "${cluster_type}" == "stage"
        ${OCM_URL}=     Set Variable    ${STAGE_URL}
  ELSE
        ${OCM_URL}=     Set Variable    ${PROD_URL}
  END
  Go To     ${OCM_URL}

Verify Documentation Is Accessible
  [Documentation]   Checks documentation link is accessible.
  ${link}=  Get Element Attribute   //div[@class="pf-l-flex pf-m-space-items-lg pf-m-column"]//a    href
  ${status}=    Check HTTP Status Code    ${link}
  IF  ${status}!=200      FAIL
  ...     Documentation Is Not Accessible

