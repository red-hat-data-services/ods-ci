*** Settings ***
Documentation       RHODS monitoring alerts test suite

Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/OCPDashboard/Builds/Builds.robot
Library             OperatingSystem
Library             SeleniumLibrary
Library             JupyterLibrary
Library             OpenShiftCLI

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
Verify All Alerts Severity
    [Documentation]    Verifies that all alerts have severity
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1227

    ${version_check} =    Is RHODS Version Greater Or Equal Than    1.9.0
    IF    ${version_check}==True
        Verify "RHODS Probe Success Burn Rate" Alerts Severity And Continue On Failure

        Verify "RHODS Route Error Burn Rate" Alerts Severity And Continue On Failure

        Verify "User Notebook PVC Usage" Alerts Severity And Continue On Failure

        Verify "DeadManSnitch" Alerts Severity And Continue On Failure

        Verify "JupyterHub Image Builds Are Failing" Alerts Severity And Continue On Failure
    ELSE
        Skip    msg=Critical alert severity is set since RHODS 1.9.0
    END

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

Verify Alert "JupyterHub image builds are failing" Fires When There Is An Image Build Error    # robocop: disable:too-long-test-case
    [Documentation]     Verify the "JupyterHub image builds are failing" alert when there is a image build failed
    [Tags]    Tier2
    ...       ODS-717
    ...       Execution-Time-Over-30m

    ${failed_build_name} =    Provoke Image Build Failure    namespace=redhat-ods-applications
    ...    build_name_includes=tensorflow    build_config_name=s2i-tensorflow-gpu-cuda-11.4.2-notebook
    ...    container_to_kill=sti-build

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    Builds
    ...    JupyterHub image builds are failing

    ${build_name} =    Start New Build    namespace=redhat-ods-applications
    ...    buildconfig=s2i-tensorflow-gpu-cuda-11.4.2-notebook

    Prometheus.Wait Until Alert Is Not Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    Builds
    ...    JupyterHub image builds are failing

    Wait Until Build Status Is    namespace=redhat-ods-applications
    ...    build_name=${build_name}    expected_status=Complete

    Prometheus.Alert Should Not Be Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    Builds
    ...    JupyterHub image builds are failing

    Sleep    10m    reason=Waiting for the alert to keep not firing
    Prometheus.Alert Should Not Be Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    Builds
    ...    JupyterHub image builds are failing

    Sleep    10m    reason=Waiting for the alert to keep not firing
    Prometheus.Alert Should Not Be Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    Builds
    ...    JupyterHub image builds are failing

    Sleep    10m    reason=Waiting for the alert to keep not firing
    Prometheus.Alert Should Not Be Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    Builds
    ...    JupyterHub image builds are failing

    [Teardown]    Delete Build    namespace=redhat-ods-applications    build_name=${failed_build_name}

Verify Alert "JupyterHub Image Builds Are Failing" Fires At Least 20 Minutes When There Is An Image Build Error     # robocop: disable:too-long-test-case
    [Documentation]    Verify that build alert fires at least 20 minutes when there is an image
    ...                build error and then it resolves automatically
    [Tags]    Tier2
    ...       ODS-790
    ...       Execution-Time-Over-30m

    ${failed_build_name} =    Provoke Image Build Failure    namespace=redhat-ods-applications
    ...    build_name_includes=pytorch    build_config_name=s2i-pytorch-gpu-cuda-11.4.2-notebook
    ...    container_to_kill=sti-build

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    Builds
    ...    JupyterHub image builds are failing

    Sleep    20m    reason=Waiting for the alert to keep firing
    Prometheus.Alert Should Be Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    Builds
    ...    JupyterHub image builds are failing

    Prometheus.Wait Until Alert Is Not Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    Builds
    ...    JupyterHub image builds are failing
    ...    timeout=15min

    [Teardown]    Delete Failed Build And Start New One    namespace=redhat-ods-applications
    ...    failed_build_name=${failed_build_name}    build_config_name=s2i-pytorch-gpu-cuda-11.4.2-notebook

Verify That MT-SRE Are Not Paged For Alerts In Clusters Used For Development Or Testing
    [Documentation]     Verify that MT-SRE are not paged for alerts in clusters used for development or testing
    [Tags]              Sanity
    ...                 ODS-1058
    ...                 Tier1
    ${res} =    Check Cluster Name Contain "Aisrhods" Or Not
    IF    ${res}
        ${text_to_check} =    Set Variable    Cluster is for RHODS engineering or test purposes. Disabling SRE alerting.
        ${receiver} =         Set Variable    alerts-sink
    ELSE
        ${text_to_check} =    Set Variable    Cluster is not for RHODS engineering or test purposes.
        ${receiver} =         Set Variable    PagerDuty
    END
    Check Particular Text Is Present In Rhods-operator's Log  text_to_check=${text_to_check}
    Verify Receiver Value In Configmap Alertmanager Is  receiver=${receiver}
    [Teardown]    Close All Browsers

*** Keywords ***
Alerts Suite Setup
    [Documentation]    Test suite configuration
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

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
    ${authorization_required} =    Is Service Account Authorization Required
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

Verify "RHODS Probe Success Burn Rate" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "RHODS Probe Success Burn Rate" severity
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success    RHODS Probe Success Burn Rate    critical    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success    RHODS Probe Success Burn Rate    critical    alert-duration=900
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success    RHODS Probe Success Burn Rate    warning    alert-duration=3600
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success    RHODS Probe Success Burn Rate    warning    alert-duration=10800

Verify "RHODS Route Error Burn Rate" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "RHODS Route Error Burn Rate" severity
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_total    RHODS Route Error Burn Rate    critical    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_total    RHODS Route Error Burn Rate   critical    alert-duration=900
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_total    RHODS Route Error Burn Rate   warning    alert-duration=3600
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_total    RHODS Route Error Burn Rate    warning    alert-duration=10800

Verify "User Notebook PVC Usage" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "User notebook pvc usage" is warning
    Verify Alert Has A Given Severity And Continue On Failure
    ...    RHODS-PVC-Usage    User notebook pvc usage above 90%    warning    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    RHODS-PVC-Usage    User notebook pvc usage at 100%    warning    alert-duration=120

Verify "DeadManSnitch" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "DeadManSnitch" is critical
    Verify Alert Has A Given Severity And Continue On Failure
    ...    DeadManSnitch    DeadManSnitch    critical

Verify "JupyterHub Image Builds Are Failing" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "JupyterHub image builds are failing" is warning
    Verify Alert Has A Given Severity And Continue On Failure
    ...    Builds    JupyterHub image builds are failing    warning    alert-duration=120

Verify Alert Has A Given Severity And Continue On Failure
    [Documentation]    Verifies that alert has a certain severity, failing otherwhise but continuing the execution
    [Arguments]    ${rule_group}    ${alert}    ${alert-severity}    ${alert-duration}=${EMPTY}
    Run Keyword And Continue On Failure    Prometheus.Alert Severity Should Be
    ...    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    ${rule_group}
    ...    ${alert}
    ...    ${alert-severity}
    ...    ${alert-duration}

Skip Test If Alert Is Already Firing
    [Documentation]    Skips tests if ${alert} is already firing
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}=${EMPTY}
    ${alert_is_firing} =    Run Keyword And Return Status    Alert Should Be Firing
    ...    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}
    Skip If    ${alert_is_firing}    msg=Test skiped because alert "${alert} ${alert-duration}" is already firing

Check Cluster Name Contain "Aisrhods" Or Not
    [Documentation]     Return true if cluster name contains aisrhods and if not return false
    ${cluster_id} =     Get Cluster ID
    ${cluster_name} =    Get Cluster Name By Cluster ID  cluster_id=${cluster_id}
    ${return_value} =  Evaluate  "aisrhods" in "${cluster_name}"
    [Return]  ${return_value}

Check Particular Text Is Present In Rhods-operator's Log
    [Documentation]     Check if text is present in log
    [Arguments]         ${text_to_check}
    Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To Openshift    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    ${OCP_ADMIN_USER.AUTH_TYPE}
    Maybe Skip Tour
    ${val_result}=  Get Pod Logs From UI  namespace=redhat-ods-operator
    ...                                   pod_search_term=rhods-operator
    ...                                   container_button_id=rhods-deployer-link
    Log  ${val_result}
    List Should Contain Value    ${val_result}    ${text_to_check}
    Close Browser

Verify Receiver Value In Configmap Alertmanager Is
    [Documentation]     Receiver value should be equal to ${receiver}
    [Arguments]         ${receiver}
    ${result} =    Run    oc get configmap alertmanager -n redhat-ods-monitoring -o jsonpath='{.data.alertmanager\\.yml}' | yq '.route.receiver'
    Log  ${result}
    Should Be Equal    "${receiver}"    ${result}
