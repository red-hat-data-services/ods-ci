*** Settings ***
Force Tags       Smoke  Sanity
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          SeleniumLibrary
Library          JupyterLibrary

*** Variables ***
${alert_90}=  User notebook pvc usage above 90%
${alert_100}=  User notebook pvc usage at 100%
${notebook_repo_url}=  https://github.com/redhat-rhods-qe/ods-ci-notebooks-main
${notebook_90}=  /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/203__alerts/notebook-pvc-usage/fill-notebook-pvc-over-90.ipynb
${notebook_100}=  /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/203__alerts/notebook-pvc-usage/fill-notebook-pvc-to-100.ipynb
${notebook_clean}=  /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/203__alerts/notebook-pvc-usage/fill-notebook-pvc-delete-testfiles.ipynb

*** Test Cases ***
Verify alert "RHODS Probe Success Burn Rate" fires when traefik-proxy service is down
  [Tags]  Tier2
   ...    PLACEHOLDER  #Category tags
   ...    ODS-712
  [Documentation]  Verify alert "RHODS Probe Success Burn Rate" is fired when traefik-proxy is not working.
   ...             Note: tests ODS-712 and ODS-713 are separated in execution order on purpose so their alerts not interfere each other
   ...             Execution Time:  45 mins
  Skip Test If Alert Is Already Firing  ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  SLOs-probe_success  RHODS Probe Success Burn Rate
  ODS.Scale Down rhods-operator Deployment
  ODS.Scale Down traefik-proxy Deployment
  Prometheus.Wait Until Alert Is Firing     ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  SLOs-probe_success  RHODS Probe Success Burn Rate  timeout=40 min
  [Teardown]  End "RHODS Probe Success Burn Rate" Alert Test


Verify alert RHODS-PVC-Usage is fired when user notebook pvc usage is above 90 Percent
  [Tags]  Sanity
  ...     PLACEHOLDER  #Category tags
  ...     ODS-516
  Set Up PVC Alert Test  ${notebook_90}
  Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  RHODS-PVC-Usage  ${alert_90}
  [Teardown]  Common.End Web Test

Verify alert RHODS-PVC-Usage is fired when user notebook pvc usage is 100 Percent
  [Tags]  Sanity
  ...    PLACEHOLDER  #Category tags
  ...    ODS-517
  Set Up PVC Alert Test  ${notebook_100}
  Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  RHODS-PVC-Usage  ${alert_100}
  [Teardown]  End PVC Alert Test


Verify alert "RHODS Probe Success Burn Rate" fires when rhods-dashboard service is down
  [Tags]  Tier2  RunThisTest
  ...    PLACEHOLDER  #Category tags
  ...    ODS-713
  [Documentation]  Verify alert "RHODS Probe Success Burn Rate" is fired when rhods-dashboard is not working.
  ...              Note: tests ODS-712 and ODS-713 are separated in execution order on purpose so their alerts not interfere each other
  ...              Execution Time:  45 mins
  Skip Test If Alert Is Already Firing  ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  SLOs-probe_success  RHODS Probe Success Burn Rate
  ODS.Scale Down rhods-operator Deployment
  ODS.Scale Down rhods-dashboard Deployment
  Prometheus.Wait Until Alert Is Firing     ${RHODS_PROMETHEUS_URL}  ${RHODS_PROMETHEUS_TOKEN}  SLOs-probe_success  RHODS Probe Success Burn Rate  timeout=4 min
  [Teardown]  End "RHODS Probe Success Burn Rate" Alert Test


*** Keywords ***
Set Up PVC Alert Test
    [Arguments]  ${NOTEBOOK_PATH}
    Set Library Search Order  SeleniumLibrary
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Iterative Image Test  s2i-generic-data-science-notebook  ${notebook_repo_url}  ${NOTEBOOK_PATH}
    Capture Page Screenshot

End PVC Alert Test
    [Documentation]  We delete the notebook files using the new -and expererimental- "Clean Up User Notebook" because "End Web Test" doesn't work well when disk is 100% filled
    Clean Up User Notebook  ${OCP_ADMIN_USER.USERNAME}  ${TEST_USER.USERNAME}
    Common.End Web Test

End "RHODS Probe Success Burn Rate" Alert Test
  ODS.Scale Up rhods-dashboard Deployment
  ODS.Scale Up traefik-proxy Deployment
  ODS.Scale Up rhods-operator Deployment
  Sleep  120  reason=Wait until the operator, traefik-proxy and rhods-dashboard are running again

Skip Test If Alert Is Already Firing
  [Arguments]    ${pm_url}  ${pm_token}  ${rule_group}  ${alert}
  ${alert_is_firing} =  Run Keyword And Return Status     Alert Should Be Firing  ${pm_url}  ${pm_token}  ${rule_group}  ${alert}
  Skip If   ${alert_is_firing}   msg=Test skiped because alert "${alert}" is already firing


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
