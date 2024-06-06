*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource        ../../../Resources/Page/ODH/AiApps/AiApps.resource
Resource        ../../../Resources/RHOSi.resource
Library         SeleniumLibrary
Suite Setup     Intel_Aikit Suite Setup
Suite Teardown  Intel_Aikit Suite Teardown
Test Tags       ExcludeOnODH

*** Variables ***
${intel_aikit_appname}           aikit
${intel_aikit_container_name}    Intel® oneAPI AI Analytics Toolkit Containers
${intel_aikit_operator_name}    Intel® oneAPI AI Analytics Toolkit Operator
${image_path}                   image-registry.openshift-image-registry.svc:5000/${APPLICATIONS_NAMESPACE}

*** Test Cases ***
Verify Intel AIKIT Is Available In RHODS Dashboard Explore Page
  [Tags]  Smoke
  ...     Tier1
  ...     ODS-1017
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load
  Verify Service Is Available In The Explore Page     ${intel_aikit_container_name}
  Verify Service Provides "Get Started" Button In The Explore Page     ${intel_aikit_container_name}

Verify Intel AIKIT Operator Can Be Installed Using OpenShift Console
   [Tags]   Tier2
   ...      ODS-760
   ...      ODS-1237
   ...      ODS-715
   ...      ODS-1247
   [Documentation]  This Test Case Installed Intel AIKIT operator in Openshift cluster
   ...              Check and Launch AIKIT notebook image from RHODS dashboard
   ...              ProductBug: RHODS-2748
   Check And Install Operator in Openshift    ${intel_aikit_container_name}    ${intel_aikit_appname}
   Create Tabname Instance For Installed Operator        ${intel_aikit_operator_name}      AIKitContainer    ${APPLICATIONS_NAMESPACE}
   Go To RHODS Dashboard
   Verify Service Is Enabled          ${intel_aikit_container_name}
   Verify JupyterHub Can Spawn AIKIT Notebook
   Verify Git Plugin
   Run Keyword And Warn On Failure    Image Should Be Pinned To A Numeric Version
   [Teardown]   Remove AIKIT Operator


***Keywords ***
Intel_Aikit Suite Setup
  Set Library Search Order  SeleniumLibrary
  RHOSi Setup

Intel_Aikit Suite Teardown
  Close All Browsers
