*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource        ../../../Resources/Page/ODH/AiApps/AiApps.resource
Library         SeleniumLibrary
Suite Setup     OpenVino Suite Setup
Suite Teardown  OpenVino Suite Teardown

*** Variables ***
${openvino_appname}           ovms
${openvino_container_name}    OpenVINO
${openvino_operator_name}    OpenVINO Toolkit Operator

*** Test Cases ***
Verify OpenVino Is Available In RHODS Dashboard Explore Page
  [Tags]  ODS-258  Smoke  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify Service Is Available In The Explore Page    OpenVINO
  Verify Service Provides "Get Started" Button In The Explore Page    OpenVINO

Verify Openvino Operator Can Be Installed Using OpenShift Console
   [Tags]   Tier2
   ...      ODS-675   ODS-702   ODS-495
   [Documentation]  This Test Case Installed Openvino operator in Openshift cluster
   ...               and Check and Launch AIKIT notebook image from RHODS dashboard
   Check And Install Operator in Openshift    ${openvino_operator_name}   ${openvino_appname}
   Create Tabname Instance For Installed Operator        ${openvino_operator_name}       Notebook    redhat-ods-applications
   Wait Until Keyword Succeeds    900  1     Check Image Build Status   Complete     openvino-notebook
   Go To RHODS Dashboard
   Verify Service Is Enabled          ${openvino_container_name}
   Verify JupyterHub Can Spawn Openvino Notebook
   [Teardown]   Uninstall Openvino Operator


*** Keywords ***
OpenVino Suite Setup
  Set Library Search Order  SeleniumLibrary

OpenVino Suite Teardown
  Close All Browsers
