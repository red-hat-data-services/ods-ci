*** Settings ***
Documentation       RHODS monitoring alerts test suite

Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Library             SeleniumLibrary
Library             JupyterLibrary

Suite Setup         Alerts Suite Setup


*** Variables ***
${NOTEBOOK_REPO_URL}                    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main

${TEST_ALERT_PVC90_NOTEBOOK_PATH}       SEPARATOR=
...                                     /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/
...                                     203__alerts/notebook-pvc-usage/fill-notebook-pvc-over-90.ipynb

${TEST_ALERT_PVC100_NOTEBOOK_PATH}      SEPARATOR=
...                                     /ods-ci-notebooks-main/notebooks/200__monitor_and_manage/
...                                     203__alerts/notebook-pvc-usage/fill-notebook-pvc-to-100.ipynb


*** Test Cases ***
Verify No Alerts Are Firing Except For DeadManSnitch    # robocop: disable:too-long-test-case
    [Documentation]    Verifies that, in a regular situation, only the DeadManSnitch alert is firing
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-540

    Verify Alert Is Firing And Continue On Failure
    ...    DeadManSnitch    DeadManSnitch

    Verify Alert Is Not Firing And Continue On Failure
    ...    Builds    JupyterHub image builds are failing    alert-duration=120

    Verify Alert Is Not Firing And Continue On Failure
    ...    RHODS-PVC-Usage    User notebook pvc usage above 90%    alert-duration=120

    Verify Alert Is Not Firing And Continue On Failure
    ...    RHODS-PVC-Usage    User notebook pvc usage at 100%    alert-duration=120

    Verify "RHODS Route Error Burn Rate" Alerts Are Not Firing And Continue On Failure

    Verify "RHODS Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure

Verify Alert RHODS-PVC-Usage-Above-90 Is Fired When User PVC Is Above 90 Percent
    [Documentation]    Runs a jupyter notebook to fill the user PVC over 90% and
    ...    verifies that alert "User notebook pvc usage above 90%" is fired
    [Tags]    Tier2
    ...       ODS-516

    Fill Up User PVC    ${NOTEBOOK_REPO_URL}    ${TEST_ALERT_PVC90_NOTEBOOK_PATH}

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    RHODS-PVC-Usage
    ...    User notebook pvc usage above 90%
    ...    alert-duration=120

    [Teardown]    Teardown PVC Alert Test

Verify Alert RHODS-PVC-Usage-At-100 Is Fired When User PVC Is At 100 Percent
    [Documentation]    Runs a jupyter notebook to fill the user PVC over 100% and
    ...    verifies that alert "User notebook pvc usage at 100%" is fired
    [Tags]    Tier2
    ...       ODS-517

    Fill Up User PVC    ${NOTEBOOK_REPO_URL}    ${TEST_ALERT_PVC100_NOTEBOOK_PATH}

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    RHODS-PVC-Usage
    ...    User notebook pvc usage at 100%
    ...    alert-duration=120

    [Teardown]    Teardown PVC Alert Test

Verify Alert "RHODS Route Error Burn Rate" Is Fired When Traefik Is Down    # robocop: disable:too-long-test-case
    [Documentation]    Verifies that alert "RHODS Route Error Burn Rate" is fired when traefik-proxy is not working
    [Tags]    Tier3
    ...       ODS-738

    Skip    msg=This alert was disabled in RHODS 1.3.0. More info at RHODS-2101

    Skip Test If Alert Is Already Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-haproxy_backend_http_responses_total
    ...    RHODS Route Error Burn Rate
    ...    alert-duration=120

    ODS.Scale Deployment    redhat-ods-operator    rhods-operator    replicas=0
    ODS.Scale Deployment    redhat-ods-applications    traefik-proxy    replicas=0

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-haproxy_backend_http_responses_total
    ...    RHODS Route Error Burn Rate
    ...    alert-duration=120
    ...    timeout=40 min

    ODS.Restore Default Deployment Sizes

    Prometheus.Wait Until Alert Is Not Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-haproxy_backend_http_responses_total
    ...    RHODS Route Error Burn Rate
    ...    alert-duration=120
    ...    timeout=5 min

    [Teardown]    ODS.Restore Default Deployment Sizes

Verify Alert "RHODS Route Error Burn Rate" Is Fired When RHODS Dashboard Is Down    # robocop: disable:too-long-test-case
    [Documentation]    Verifies that alert "RHODS Route Error Burn Rate" is fired when rhods-dashboard is not working
    [Tags]    Tier3
    ...       ODS-739

    Skip Test If Alert Is Already Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-haproxy_backend_http_responses_total
    ...    RHODS Route Error Burn Rate

    ODS.Scale Deployment    redhat-ods-operator    rhods-operator    replicas=0
    ODS.Scale Deployment    redhat-ods-applications    rhods-dashboard    replicas=0

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-haproxy_backend_http_responses_total
    ...    RHODS Route Error Burn Rate
    ...    alert-duration=120
    ...    timeout=40 min

    ODS.Restore Default Deployment Sizes

    Prometheus.Wait Until Alert Is Not Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-haproxy_backend_http_responses_total
    ...    RHODS Route Error Burn Rate
    ...    alert-duration=120
    ...    timeout=5 min

    [Teardown]    ODS.Restore Default Deployment Sizes

Verify Alert "RHODS Probe Success Burn Rate" Is Fired When Traefik Is Down    # robocop: disable:too-long-test-case
    [Documentation]    Verifies that alert "RHODS Probe Success Burn Rate" is fired when traefik-proxy is not working
    [Tags]    Tier3
    ...       ODS-712

    Skip Test If Alert Is Already Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-probe_success
    ...    RHODS Probe Success Burn Rate

    ODS.Scale Deployment    redhat-ods-operator    rhods-operator    replicas=0
    ODS.Scale Deployment    redhat-ods-applications    traefik-proxy    replicas=0

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-probe_success
    ...    RHODS Probe Success Burn Rate
    ...    alert-duration=120
    ...    timeout=40 min

    ODS.Restore Default Deployment Sizes

    Prometheus.Wait Until Alert Is Not Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-probe_success
    ...    RHODS Probe Success Burn Rate
    ...    alert-duration=120
    ...    timeout=5 min

    [Teardown]    ODS.Restore Default Deployment Sizes

Verify Alert "RHODS Probe Success Burn Rate" Is Fired When RHODS Dashboard Is Down    # robocop: disable:too-long-test-case
    [Documentation]    Verifies that alert "RHODS Probe Success Burn Rate" is fired when rhods-dashboard is not working
    [Tags]    Tier3
    ...       ODS-713

    Skip Test If Alert Is Already Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-probe_success
    ...    RHODS Probe Success Burn Rate
    ...    alert-duration=120

    ODS.Scale Deployment    redhat-ods-operator    rhods-operator    replicas=0
    ODS.Scale Deployment    redhat-ods-applications    rhods-dashboard    replicas=0

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-probe_success
    ...    RHODS Probe Success Burn Rate
    ...    alert-duration=120
    ...    timeout=40 min

    ODS.Restore Default Deployment Sizes

    Prometheus.Wait Until Alert Is Not Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-probe_success
    ...    RHODS Probe Success Burn Rate
    ...    alert-duration=120
    ...    timeout=5 min

    [Teardown]    ODS.Restore Default Deployment Sizes


*** Keywords ***
Alerts Suite Setup
    [Documentation]    Test suite configuration
    Set Library Search Order    SeleniumLibrary

Teardown PVC Alert Test
    [Documentation]    Deletes user notebook files using the new "Clean Up User Notebook"
    ...    keyword because "End Web Test" doesn't work well when disk is 100% filled
    Maybe Close Popup
    Run Keyword And Continue On Failure    Open With JupyterLab Menu    File    Close All Tabs
    Maybe Close Popup
    Navigate Home (Root Folder) In JupyterLab Sidebar File Browser
    Delete Folder In User Notebook    ${OCP_ADMIN_USER.USERNAME}    ${TEST_USER.USERNAME}    ods-ci-notebooks-main
    Sleep    10s    reason=Waiting for possible JupyterLab pop-up
    Maybe Close Popup
    Sleep    10s    reason=Waiting for possible JupyterLab pop-up
    Maybe Close Popup
    Common.End Web Test

Fill Up User PVC    # robocop: disable:too-many-calls-in-keyword
    [Documentation]    Runs the jupyter notebook passed as parameter to fill up user PVC
    [Arguments]    ${notebook_repo}    ${notebook_path}
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub From RHODS Dashboard Link
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required}=    Is Service Account Authorization Required
    Run Keyword If    ${authorization_required}    Authorize jupyterhub service account
    Fix Spawner Status
    Spawn Notebook With Arguments    image=s2i-generic-data-science-notebook
    Clone Git Repository And Run    ${notebook_repo}    ${notebook_path}
    Sleep    5s

Verify Alert Is Firing And Continue On Failure
    [Documentation]    Verifies that alert is firing, failing otherwhise but continuing the execution
    [Arguments]    ${rule_group}    ${alert}    ${alert-duration}=${EMPTY}
    Run Keyword And Continue On Failure    Prometheus.Alert Should Be Firing
    ...    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    ${rule_group}
    ...    ${alert}
    ...    ${alert-duration}

Verify Alert Is Not Firing And Continue On Failure
    [Documentation]    Verifies that alert is not firing, failing otherwhise but continuing the execution
    [Arguments]    ${rule_group}    ${alert}    ${alert-duration}=${EMPTY}
    Run Keyword And Continue On Failure    Prometheus.Alert Should Not Be Firing
    ...    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    ${rule_group}
    ...    ${alert}
    ...    ${alert-duration}

Verify "RHODS Route Error Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "RHODS Route Error Burn Rate" is not firing for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_total    RHODS Route Error Burn Rate    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_total    RHODS Route Error Burn Rate    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_total    RHODS Route Error Burn Rate    alert-duration=3600
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_total    RHODS Route Error Burn Rate    alert-duration=10800

Verify "RHODS Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "RHODS Probe Success Burn Rate" is not firing for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success    RHODS Probe Success Burn Rate    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success    RHODS Probe Success Burn Rate    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success    RHODS Probe Success Burn Rate    alert-duration=3600
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success    RHODS Probe Success Burn Rate    alert-duration=10800

Skip Test If Alert Is Already Firing
    [Documentation]    Skips tests if ${alert} is already firing
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}=${EMPTY}
    ${alert_is_firing}=    Run Keyword And Return Status    Alert Should Be Firing
    ...    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}
    Skip If    ${alert_is_firing}    msg=Test skiped because alert "${alert} ${alert-duration}" is already firing
