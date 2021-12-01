*** Settings ***
Force Tags       Smoke  Sanity
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          SeleniumLibrary
Library          JupyterLibrary

*** Variables ***
${rule_group}=  RHODS-PVC-Usage
${alert_90}=  User notebook pvc usage above 90%
${alert_100}=  User notebook pvc usage at 100%
${notebook_repo_url}=  https://github.com/redhat-rhods-qe/ods-ci-notebooks-main

*** Test Cases ***
Verify alert RHODS-PVC-Usage is fired when user notebook pvc usage is above 90 Percent
  [Tags]  Sanity  ODS-516
  Set Up Alert Test  90
  Sleep  320
  Prometheus.Alert Should Be Firing  ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  ${rule_group}  ${alert_90}
  [Teardown]  Clean Up Files And End Web Test

Verify alert RHODS-PVC-Usage is fired when user notebook pvc usage is 100 Percent
  [Tags]  Sanity  ODS-517
  Set Up Alert Test  100
  Sleep  320
  Prometheus.Alert Should Be Firing  ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  ${rule_group}  ${alert_100}
  [Teardown]  Clean Up Files And End Web Test

*** Keywords ***
Set Up Alert Test
  [Arguments]  ${pvc_alarm}

  ${version-check} =  Is RHODS Version Greater Or Equal Than  1.3.0
  IF  ${version-check}==True
    IF    ${pvc_alarm} == 90
        ${notebook_path} =  Set Variable
        ...  /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/203__alerts/notebook-pvc-usage/fill-pvc-19GB.ipynb
    ELSE
        ${notebook_path} =  Set Variable
        ...  /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/203__alerts/notebook-pvc-usage/fill-pvc-20GB.ipynb
    END
  ELSE
    IF    ${pvc_alarm} == 90
        ${notebook_path} =  Set Variable
        ...  /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/203__alerts/notebook-pvc-usage/fill-pvc-1.9GB.ipynb
    ELSE
        ${notebook_path} =  Set Variable
        ...  /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/203__alerts/notebook-pvc-usage/fill-pvc-2GB.ipynb
    END
  END

  Set Library Search Order  SeleniumLibrary
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Iterative Image Test  s2i-generic-data-science-notebook  ${notebook_repo_url}  ${notebook_path}
  Capture Page Screenshot

Clean Up Files And End Web Test
    [Documentation]  We delete the notebook files using the new -and expererimental- "Clean Up User Notebook" because "End Web Test" doesn't work well when disk is 100% filled
    Clean Up User Notebook  ${OCP_ADMIN_USER.USERNAME}  ${TEST_USER.USERNAME}
    Maybe Accept a JupyterLab Prompt
    Sleep  5
    Maybe Accept a JupyterLab Prompt
    Common.End Web Test

Iterative Image Test
    [Arguments]  ${image}  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
    Launch JupyterHub From RHODS Dashboard Dropdown
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
