*** Settings ***
Resource    ../../../Resources/ODS.robot
Resource    ../../../Resources/Common.robot
Resource    ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource    ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library        JupyterLibrary
Library        SeleniumLibrary
Test Setup     Begin Billing Metrics Web Test
Test Teardown  End Web Billing Metrics Test

*** Variables ***
${METRIC_RHODS_CPU}                 cluster:usage:consumption:rhods:cpu:seconds:rate5m
${METRIC_RHODS_UNDEFINED}           cluster:usage:consumption:rhods:undefined:seconds:rate5m
@{generic-1}  s2i-generic-data-science-notebook  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb

*** Test Cases ***
Verify OpenShift Monitoring results are correct when running undefined queries
  [Tags]  Smoke  Sanity  ODS-173
  Run OpenShift Metrics Query  ${METRIC_RHODS_UNDEFINED}  retry-attempts=1
  Metrics.Verify Query Results Dont Contain Data

Test Billing Metric (notebook cpu usage) on OpenShift Monitoring
  [Tags]  Smoke  Sanity  ODS-175
  #Skip Test If Previous CPU Usage Is Not Zero
  Run Jupyter Notebook For 5 Minutes
  Verify Previus CPU Usage Is Greater Than Zero

*** Keywords ***
Begin Billing Metrics Web Test
  Set Library Search Order  SeleniumLibrary

End Web Billing Metrics Test
  CleanUp JupyterHub
  SeleniumLibrary.Close All Browsers

Skip Test If Previous CPU Usage Is Not Zero
  ${metrics_value} =   Run OpenShift Metrics Query    ${METRIC_RHODS_CPU}
  ${metrics_query_results_contain_data} =  Run Keyword And Return Status     Metrics.Verify Query Results Contain Data
  IF  ${metrics_query_results_contain_data}
    Log To Console    Current CPU usage: ${metrics_value}
    Skip if  ${metrics_value} > 0  The previos CPU usage is not zero. Current CPU usage: ${metrics_value}. Skiping test
  END

Run OpenShift Metrics Query
  [Documentation]  Runs a query in the Monitoring section of Open Shift
  ...              Note: in order to run this keyword OCP_ADMIN_USER.USERNAME needs to
  ...                 belong to a group with "view" role in OpenShift
  ...              Example command to assign the role: oc adm policy add-cluster-role-to-group view rhods-admins
  [Arguments]  ${query}  ${retry-attempts}=10
  Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  LoginPage.Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
  OCPMenu.Switch To Administrator Perspective
  Wait Until Page Contains   Monitoring  timeout=20  error=${OCP_ADMIN_USER.USERNAME} can't see the Monitoring section in OpenShift Console, please make sure it belongs to a group with "view" role
  Menu.Navigate To Page   Monitoring  Metrics
  Metrics.Verify Page Loaded
  Metrics.Run Query  ${query}  ${retry-attempts}
  ${result} =   Metrics.Get Query Results
  [Return]  ${result}

Verify Previus CPU Usage Is Greater Than Zero
  ${metrics_value} =   Run OpenShift Metrics Query    ${METRIC_RHODS_CPU}
  Metrics.Verify Query Results Contain Data
  Capture Page Screenshot
  Should Be True  ${metrics_value} > 0

## TODO: Add this keyword with the other JupyterHub stuff
Run Jupyter Notebook For 5 Minutes
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Iterative Image Test  s2i-generic-data-science-notebook  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb


##TODO: This is a copy of "Iterative Image Test" keyword from image-iteration.robob. We have to refactor the code not to duplicate this method
Iterative Image Test
  [Arguments]  ${image}  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
  Launch JupyterHub From RHODS Dashboard Dropdown
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Page Should Not Contain    403 : Forbidden
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Fix Spawner Status
  Spawn Notebook With Arguments  image=${image}
  Wait for JupyterLab Splash Screen  timeout=30
  Maybe Select Kernel
  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document
  Close Other JupyterLab Tabs
  Sleep  5
  Run Cell And Check Output  print("Hello World!")  Hello World!
  Capture Page Screenshot
  JupyterLab Code Cell Error Output Should Not Be Visible
  #This ensures all workloads are run even if one (or more) fails
  Run Keyword And Continue On Failure  Clone Git Repository And Run  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
  Clean Up Server
  Stop JupyterLab Notebook Server
  Go To  ${ODH_DASHBOARD_URL}
  Sleep  10


CleanUp JupyterHub
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Launch JupyterHub From RHODS Dashboard Dropdown
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Page Should Not Contain    403 : Forbidden
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Common.End Web Test
