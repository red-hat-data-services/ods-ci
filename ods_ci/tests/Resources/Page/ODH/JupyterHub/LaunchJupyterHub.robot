*** Settings ***
Library  JupyterLibrary


*** Variables ***
# This variable is overriden for ODH runs via 'ods_ci/test-variables-odh-overwrite.yml'
${ODH_DASHBOARD_PROJECT_NAME}=   Red Hat OpenShift AI


*** Keywords ***
Launch Jupyterhub via Routes
   [Documentation]  This keyword only works with kubeadmin or accounts that are
   ...              cluster admins. Use Launch via App for other accounts.
   Wait Until Page Contains  Networking  timeout=60
   Click Button  Networking
   Wait Until Page Contains  Routes  timeout=15
   Click Link  Routes
   Maximize Browser Window
   Wait Until Page Contains Element  xpath://input[@data-test-id="item-filter"]
   Input Text  xpath://input[@data-test-id="item-filter"]  rhods-dashboard
   Wait Until Page Contains  rhods-dashboard
   Sleep  4s
   Input Text  xpath://input[@data-test-id="item-filter"]  jupyterhub
   Wait Until Page Contains  jupyterhub  timeout=15
   Click Element  partial link:https://jupyterhub
   Sleep  10s
   Switch Window  JupyterHub

Launch RHODS Via OCP Application Launcher
    [Documentation]    Uses the Application Launcher in the OCP Web UI to open the
    ...    RHODS Dashboard page.
    Click Element    xpath://button[@aria-label="Application launcher"]
    Wait Until Page Contains Element    xpath://span[.="${ODH_DASHBOARD_PROJECT_NAME}"]
    Click Element    xpath://span[.="${ODH_DASHBOARD_PROJECT_NAME}"]/..
    Switch Window    NEW
