*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Library         SeleniumLibrary
Suite Setup     Intel_Aikit Suite Setup
Suite Teardown  Intel_Aikit Suite Teardown

*** Variables ***
${intel_aikit_appname}   aikit
${intel_aikit_container_name}    Intel® oneAPI AI Analytics Toolkit Container
${intel_aikit_operator_name}    Intel® oneAPI AI Analytics Toolkit Operator

*** Test Cases ***
Verify intel aikit Is Available In RHODS Dashboard Explore Page
  [Tags]  ODS-1017 Smoke  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify Service Is Available In The Explore Page     ${intel_aikit_container_name} 
  Verify Service Provides "Get Started" Button In The Explore Page     ${intel_aikit_container_name} 

Install intelaikit From the Operatorhub
   [Tags]  ODS-760   Sanity
    Open Installed Operators Page
    Search Installed Operator  ${intel_aikit_operator_name} 
    ${status}    Is Operator Installed     ${intel_aikit_operator_name}
    IF  not ${status}
         Open OperatorHub
         ${no_of_operator}    Get List Of Operator Available     ${intel_aikit_appname}
         IF  ${no_of_operator} == ${2}
             Install Operator        ${intel_aikit_appname}
             Create Installed Operator instance        ${intel_aikit_operator_name}      AIKitContainer
         ELSE
                  FAIL      Only one openvino operator is found in upearatorhub
         END
    ELSE
        Log To Console       Oprator is already installed
    END
    Go To  ${ODH_DASHBOARD_URL}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    ${status}       Run keyword and Return Status           Verify Service Is Enabled          ${intel_aikit_container_name}
    Run keyword If  ${status}    Launch JupyterHub Spawner From Dashboard
    ...        ELSE   FAIL      ${intel_aikit_container_name}  tile  is not present in the Enable tab
    Wait Until Page Contains Element  xpath://input[@name="oneAPI AI Analytics Toolkit"]
    Wait Until Element Is Enabled    xpath://input[@name="oneAPI AI Analytics Toolkit"]   timeout=10
    Spawn Notebook With Arguments  image=oneapi-aikit
    Wait for JupyterLab Splash Screen  timeout=60
    Maybe Select Kernel
    Fix Spawner Status
    Go To  ${OCP_CONSOLE_URL}
    Maybe Skip Tour
    Delete Installed Operator instance     ${intel_aikit_operator_name}      AIKitContainer
    Uninstall Operator      ${intel_aikit_operator_name} 

***Keywords ***
Intel_Aikit Suite Setup
  Set Library Search Order  SeleniumLibrary

Intel_Aikit Suite Teardown
  Close All Browsers

Verify JupyterNotebook
  Go To  ${ODH_DASHBOARD_URL}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  ${status}       Run keyword and Return Status           Verify Service Is Enabled          ${intel_aikit_container_name} 
  Run keyword If  ${status}    Launch JupyterHub Spawner From Dashboard
  ...        ELSE   FAIL      ${intel_aikit_container_name}  tile  is not present in the Enable tab
  Wait Until Page Contains Element  xpath://input[@name="oneAPI AI Analytics Toolkit"]
  Wait Until Element Is Enabled    xpath://input[@name="oneAPI AI Analytics Toolkit"]   timeout=10
  Spawn Notebook With Arguments  image=oneapi-aikit
  Wait for JupyterLab Splash Screen  timeout=60
  Maybe Select Kernel

Create Installed Operator instances
   Switch To Administrator Perspective
   Navigate to Installed Operators
   Installed Operators Should Be Open
   Select All Projects
   Click On Searched Operator   ${intel_aikit_operator_name} 
   Switch To New Tab       AIKitContainer
   sleep    5
   Click Button     Create AIKitContainer
   Wait Until Element is Visible     //button[contains(text(), "Create")]          timeout=10
   Click Button      Create

