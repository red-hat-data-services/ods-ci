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
${openvino_operator_name}     OpenVINO Toolkit Operator
${openvino_build_label}       opendatahub.io/build_type\n=\nnotebook_image

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
   ...      ODS-675
   ...      ODS-495
   ...      ODS-651
   ...      ODS-652
   ...      ODS-1236
   [Documentation]  This Test Case Installed Openvino operator in Openshift cluster,
   ...              Cheks whether RHODS notification shows the Notebook images are running after installing openvino
   ...               and Check and Launch AIKIT notebook image from RHODS dashboard
   Check And Install Operator in Openshift    ${openvino_operator_name}   ${openvino_appname}
   Create Tabname Instance For Installed Operator        ${openvino_operator_name}       Notebook    redhat-ods-applications
   Wait Until Keyword Succeeds    1200    1     Check Image Build Status   Complete     openvino-notebook
   Build Should Contain Label    namespace=redhat-ods-applications    build_search_term=openvino-notebook
   ...                           required_label=${openvino_build_label}
   Go To RHODS Dashboard
   RHODS Notification Drawer Should Contain    message=Notebook images are building
   Verify Service Is Enabled          ${openvino_container_name}
   Verify JupyterHub Can Spawn Openvino Notebook
   Verify Git Plugin
   [Teardown]   Remove Openvino Operator

*** Keywords ***
Build Should Contain Label
    [Documentation]    Checks that openvino has the label ${required_label}
    [Arguments]    ${namespace}    ${build_search_term}    ${required_label}
    ${build_labels} =    Get Build Labels    ${namespace}    ${build_search_term}
    Should Contain    ${build_labels}    ${required_label}

OpenVino Suite Setup
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup

OpenVino Suite Teardown
    Close All Browsers
