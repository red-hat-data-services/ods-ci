*** Settings ***
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          DebugLibrary
Library          SeleniumLibrary
Library          JupyterLibrary


*** Variables ***
${rule_group}=  RHODS-PVC-Usage
${alert_90}=  User notebook pvc usage above 90%
${alert_100}=  User notebook pvc usage at 100%
${notebook_repo_url}=  https://github.com/redhat-rhods-qe/ods-ci-notebooks-main
${notebook_90}=  /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/203__alerts/notebook-pvc-usage/fill-notebook-pvc-over-90.ipynb
${notebook_100}=  /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/203__alerts/notebook-pvc-usage/fill-notebook-pvc-to-100.ipynb
${notebook_clean}=  /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/203__alerts/notebook-pvc-usage/fill-notebook-pvc-delete-testfiles.ipynb

*** Test Cases ***
Verify alert RHODS-PVC-Usage is fired when user notebook pvc usage is above 90 Percent
  [Tags]  Tier2  ODS-516
  Set Up Alert Test  ${notebook_90}
  Sleep  320
  Prometheus.Alert Should Be Firing  ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  ${rule_group}  ${alert_90}
  [Teardown]  Clean Up Files And End Web Test

Verify alert RHODS-PVC-Usage is fired when user notebook pvc usage is 100 Percent
  [Tags]  Tier2  ODS-517
  Set Up Alert Test  ${notebook_100}
  Sleep  320
  Prometheus.Alert Should Be Firing  ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  ${rule_group}  ${alert_100}
  [Teardown]  Clean Up Files And End Web Test

*** Keywords ***
Set Up Alert Test
    [Arguments]  ${NOTEBOOK_PATH}
    Set Library Search Order  SeleniumLibrary
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Iterative Image Test  s2i-generic-data-science-notebook  ${notebook_repo_url}  ${NOTEBOOK_PATH}
    Capture Page Screenshot

Clean Up Files And End Web Test
    [Documentation]  We delete the notebook files using the new -and expererimental- "Clean Up User Notebook" because "End Web Test" doesn't work well when disk is 100% filled
    Maybe Close Popup
    Run Keyword And Continue On Failure   Open With JupyterLab Menu   File  Close All Tabs
    Maybe Close Popup
    Navigate Home (Root folder) In JupyterLab Sidebar File Browser
    Delete Folder In User Notebook  ${OCP_ADMIN_USER.USERNAME}  ${TEST_USER.USERNAME}  ods-ci-notebooks-main
    Sleep  10  reason=Waiting for possible JupyterLab pop-up
    Maybe Close Popup
    Sleep  10  reason=Waiting for possible JupyterLab pop-up
    Maybe Close Popup
    Common.End Web Test

Iterative Image Test
    [Arguments]  ${image}  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
    ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
    IF  ${version-check}==True
      Launch JupyterHub From RHODS Dashboard Link
    ELSE
      Launch JupyterHub From RHODS Dashboard Dropdown
    END
    Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
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
    #This ensures all workloads are run even if one (or more) fails
    Run Keyword And Ignore Error  Clone Git Repository And Run  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
    Sleep  5
    Close JupyterLab Selected Tab
