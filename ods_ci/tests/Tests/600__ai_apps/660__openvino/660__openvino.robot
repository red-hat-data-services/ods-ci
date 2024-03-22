*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource        ../../../Resources/Page/ODH/AiApps/AiApps.resource
Resource        ../../../Resources/RHOSi.resource
Library         SeleniumLibrary
Suite Setup     OpenVino Suite Setup
Suite Teardown  OpenVino Suite Teardown

*** Variables ***
${openvino_appname}           ovms
${openvino_container_name}    OpenVINO
${openvino_operator_name}    OpenVINO Toolkit Operator

*** Test Cases ***
Verify OpenVino Is Available In RHODS Dashboard Explore Page
  [Tags]  Smoke
  ...     Tier1
  ...     ODS-493
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load
  Verify Service Is Available In The Explore Page    OpenVINO
  Verify Service Provides "Get Started" Button In The Explore Page    OpenVINO

Verify Openvino Operator Can Be Installed Using OpenShift Console
   [Tags]   Tier2
   ...      ODS-675
   ...      ODS-495
   ...      ODS-1236
   ...      ODS-651
   ...      ODS-1085
   [Documentation]  This Test Case Installed Openvino operator in Openshift cluster
   ...               and Check and Launch Openvino notebook image from RHODS dashboard
   Check And Install Operator in Openshift    ${openvino_operator_name}   ${openvino_appname}
   Create Tabname Instance For Installed Operator        ${openvino_operator_name}       Notebook    ${APPLICATIONS_NAMESPACE}
   Wait Until Keyword Succeeds    1200      1   Check Image Build Status    Complete        openvino-notebook
   Go To RHODS Dashboard
   Verify Service Is Enabled          ${openvino_container_name}
   Verify JupyterHub Can Spawn Openvino Notebook
   Verify Git Plugin
   Image Should Be Pinned To A Numeric Version
   [Teardown]   Remove Openvino Operator


*** Keywords ***
OpenVino Suite Setup
  Set Library Search Order  SeleniumLibrary
  RHOSi Setup

OpenVino Suite Teardown
  Close All Browsers
