*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Library         SeleniumLibrary
Suite Setup     Intel_Aikit Suite Setup
Suite Teardown  Intel_Aikit Suite Teardown

*** Variables ***
${intel_aikit_appname}           aikit
${intel_aikit_container_name}    Intel® oneAPI AI Analytics Toolkit Container
${intel_aikit_operator_name}    Intel® oneAPI AI Analytics Toolkit Operator
${image_path}                   image-registry.openshift-image-registry.svc:5000/redhat-ods-applications

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
         ${no_of_operator}    Get The Number of Operator Available    ${intel_aikit_appname}
         IF  ${no_of_operator} == ${2}
             Install Operator        ${intel_aikit_appname}
             Create tabname Instance For Installed Operator        ${intel_aikit_operator_name}      AIKitContainer
             Wait Until Element Is Visible    //table[contains(@class,"ReactVirtualized")]//tr     timeout=10
         ELSE
                  FAIL      Only ${no_of_operator} ${intel_aikit_operator_name} is found in Opearatorhub
         END
    ELSE
        Log To Console       Operator is already installed
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
    Sleep  3
    Close Other JupyterLab Tabs
    ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
    Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
    Launch a new JupyterLab Document
    Sleep  3
    Maybe Select Kernel
    Close Other JupyterLab Tabs
    Add and Run JupyterLab Code Cell in Active Notebook  import os
    Wait Until JupyterLab Code Cell Is Not Active
    Run Cell And Check Output   print(os.environ['JUPYTER_IMAGE'])     ${image_path}/oneapi-aikit:oneapi-aikit
    Fix Spawner Status
    Go To  ${OCP_CONSOLE_URL}
    Maybe Skip Tour
    Delete tabname Instance For Installed Operator     ${intel_aikit_operator_name}      AIKitContainer
    Uninstall Operator      ${intel_aikit_operator_name} 

***Keywords ***
Intel_Aikit Suite Setup
  Set Library Search Order  SeleniumLibrary

Intel_Aikit Suite Teardown
  Close All Browsers





