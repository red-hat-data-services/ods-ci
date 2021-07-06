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
  [Tags]  Sanity  ODS-173  RunThisTest
  Run OpenShift Metrics Query  ${METRIC_RHODS_UNDEFINED}
  Metrics.Verify Query Results Dont Contain Data

Test Billing Metric (notebook cpu usage) on OpenShift Monitoring
  [Tags]  Sanity  ODS-175  RunThisTest
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
  [Arguments]  ${query}
  Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  LoginPage.Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
  Menu.Switch To Administrator Perspective
  Wait Until Page Contains    Status  timeout=20
  Menu.Navigate To Page   Monitoring  Metrics
  Metrics.Verify Page Loaded
  Metrics.Run Query  ${query}
  ${result} =   Metrics.Get Query Results
  [Return]  ${result}

Verify Previus CPU Usage Is Greater Than Zero
  Log    Verify Previus CPU Usage Is Greater Than Zero
  ${metrics_value} =   Run OpenShift Metrics Query    ${METRIC_RHODS_CPU}
  Metrics.Verify Query Results Contain Data
  Log To Console    Current CPU usage: ${metrics_value}
  Should Be True  ${metrics_value} > 0

## TODO: Add this keyword with the other JupyterHub stuff
Run Jupyter Notebook For 5 Minutes
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for ODH Dashboard to Load
  Iterative Image Test  s2i-generic-data-science-notebook  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb
  CleanUp JupyterHub

##TODO: This is a copy of "Iterative Image Test" keyword from image-iteration.robob. We have to refactor the code not to duplicate this method
Iterative Image Test
  [Arguments]  ${image}  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
  Launch JupyterHub From ODH Dashboard Dropdown
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Page Should Not Contain    403 : Forbidden
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Select Notebook Image  ${image}
  Spawn Notebook
  Wait for JupyterLab Splash Screen  timeout=30
  Maybe Select Kernel
  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document
  Close Other JupyterLab Tabs
  Sleep  5
  Run Cell And Check Output  print("Hello World!")  Hello World!
  #Needs to change for RHODS release
  Run Cell And Check Output  !python --version  Python 3.8.3
  #Run Cell And Check Output  !python --version  Python 3.8.7
  Capture Page Screenshot
  JupyterLab Code Cell Error Output Should Not Be Visible
  #This ensures all workloads are run even if one (or more) fails
  Run Keyword And Continue On Failure  Clone Git Repository And Run  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
  Clean Up Server
  Click JupyterLab Menu  File
  Capture Page Screenshot
  Click JupyterLab Menu Item  Hub Control Panel
  Switch Window  JupyterHub
  Sleep  5
  Click Element  //*[@id="stop"]
  Wait Until Page Contains  Start My Server  timeout=15
  Capture Page Screenshot
  Go To  ${ODH_DASHBOARD_URL}
  Sleep  10


CleanUp JupyterHub
  Common.End Web Test
