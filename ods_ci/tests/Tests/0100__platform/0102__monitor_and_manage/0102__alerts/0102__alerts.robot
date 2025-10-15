*** Settings ***
Documentation       RHODS monitoring alerts test suite

Resource            ../../../../Resources/RHOSi.resource
Resource            ../../../../Resources/ODS.robot
Resource            ../../../../Resources/Common.robot
Resource            ../../../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource            ../../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../../../Resources/CLI/DataSciencePipelines/DataSciencePipelinesBackend.resource
Resource            ../../../../Resources/Page/ODH/Prometheus/Triage.resource
Library             OperatingSystem
Library             SeleniumLibrary
Library             JupyterLibrary

Suite Setup         Alerts Suite Setup
Suite Teardown      Alerts Suite Teardown


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
    [Documentation]    Verifies that all alerts have the expected severity
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-1227
    ...       Operator
    ...       Monitoring
    Verify "DeadManSnitch" Alerts Severity And Continue On Failure
    Verify "Kubeflow Notebook Controller Pod Is Not Running" Alerts Severity And Continue On Failure
    Verify "ODH Notebook Controller Pod Is Not Running" Alerts Severity And Continue On Failure
    Verify "User Notebook PVC Usage" Alerts Severity And Continue On Failure
    Verify "RHODS Dashboard Route Error Burn Rate" Alerts Severity And Continue On Failure
    Verify "RHODS Jupyter Probe Success Burn Rate" Alerts Severity And Continue On Failure
    Verify "RHODS Dashboard Probe Success Burn Rate" Alerts Severity And Continue On Failure

Verify Alert RHODS-PVC-Usage-Above-90 Is Fired When User PVC Is Above 90 Percent
    [Documentation]    Runs a jupyter notebook to fill the user PVC over 90% and
    ...    verifies that alert "User notebook pvc usage above 90%" is fired
    [Tags]    Tier2
    ...       ODS-516
    ...       Monitoring
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
    ...       Monitoring
    Fill Up User PVC    ${NOTEBOOK_REPO_URL}    ${TEST_ALERT_PVC100_NOTEBOOK_PATH}

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    RHODS-PVC-Usage
    ...    User notebook pvc usage at 100%
    ...    alert-duration=120

    [Teardown]    Teardown PVC Alert Test

Verify Alerts Are Fired When RHODS Dashboard Is Down    # robocop: disable:too-long-test-case
    [Documentation]    Verifies that alert "RHODS Dashboard Route Error Burn Rate" and "RHODS Probe Success Burn Rate"
    ...    are fired when rhods-dashboard is not working
    [Tags]    Tier3
    ...       ODS-739
    ...       Monitoring
    ...       AutomationBug

    ODS.Scale Deployment    ${OPERATOR_NAMESPACE}    rhods-operator    replicas=0
    ODS.Scale Deployment    ${APPLICATIONS_NAMESPACE}    rhods-dashboard    replicas=0

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-haproxy_backend_http_responses_dashboard
    ...    RHODS Dashboard Route Error Burn Rate
    ...    alert-duration=120
    ...    timeout=60 min

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-probe_success_dashboard
    ...    RHODS Dashboard Probe Success Burn Rate
    ...    alert-duration=120
    ...    timeout=60 min

    ODS.Restore Default Deployment Sizes

    Prometheus.Wait Until Alert Is Not Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-haproxy_backend_http_responses_dashboard
    ...    RHODS Dashboard Route Error Burn Rate
    ...    alert-duration=120
    ...    timeout=5 min

    Prometheus.Wait Until Alert Is Not Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-probe_success_dashboard
    ...    RHODS Dashboard Probe Success Burn Rate
    ...    alert-duration=120
    ...    timeout=5 min

    [Teardown]    ODS.Restore Default Deployment Sizes

Verify Alert "Kubeflow notebook controller pod is not running" Is Fired When Kubeflow Controller Is Down    # robocop: disable:too-long-test-case
    [Documentation]    Verifies that alert "Kubeflow notebook controller pod is not running"  is fired
    ...    when notebook-controller-deployment-xxx pod is not running
    [Tags]    Tier3
    ...       ODS-1700
    ...       Monitoring

    ODS.Scale Deployment    ${OPERATOR_NAMESPACE}        rhods-operator                    replicas=0
    ODS.Scale Deployment    ${APPLICATIONS_NAMESPACE}    notebook-controller-deployment    replicas=0

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    RHODS Notebook controllers
    ...    Kubeflow notebook controller pod is not running
    ...    alert-duration=300
    ...    timeout=10 min

    ODS.Restore Default Deployment Sizes

    Prometheus.Wait Until Alert Is Not Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    RHODS Notebook controllers
    ...    Kubeflow notebook controller pod is not running
    ...    alert-duration=300
    ...    timeout=5 min

    [Teardown]    ODS.Restore Default Deployment Sizes

Verify Alert "ODH notebook controller pod is not running" Is Fired When ODH Controller Manager Is Down    # robocop: disable:too-long-test-case
    [Documentation]    Verifies that alert "ODH notebook controller pod is not running"  is fired
    ...    when odh-notebook-controller-manager-xxx pod is not running
    [Tags]    Tier3
    ...       ODS-1701
    ...       Monitoring

    ODS.Scale Deployment    ${OPERATOR_NAMESPACE}        rhods-operator                     replicas=0
    ODS.Scale Deployment    ${APPLICATIONS_NAMESPACE}    odh-notebook-controller-manager    replicas=0

    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    RHODS Notebook controllers
    ...    ODH notebook controller pod is not running
    ...    alert-duration=300
    ...    timeout=10 min

    ODS.Restore Default Deployment Sizes

    Prometheus.Wait Until Alert Is Not Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    RHODS Notebook controllers
    ...    ODH notebook controller pod is not running
    ...    alert-duration=300
    ...    timeout=5 min

    [Teardown]    ODS.Restore Default Deployment Sizes

Verify That MT-SRE Are Not Paged For Alerts In Clusters Used For Development Or Testing
    [Documentation]     Verify that MT-SRE are not paged for alerts in clusters used for development or testing
    [Tags]              Sanity
    ...                 ODS-1058
    ...                 Tier1
    ...       Monitoring
    ${res} =    Check Cluster Name Contain "Aisrhods" Or Not
    IF    ${res}
        ${receiver} =         Set Variable    alerts-sink
    ELSE
        ${receiver} =         Set Variable    PagerDuty
    END
    Verify Alertmanager Receiver For Critical Alerts    receiver=${receiver}

Verify Ai Pipelines Application Alerts
    [Documentation]    Verifies that Data Science Pipelines Application alerts are fired when various parts are not running
    [Tags]    Tier3
    ...       ODS-2170
    ...       RHOAIENG-12886
    ...       Monitoring

    Set Test Variable  ${PROJECT}  test-dspa-alerts

    Log To Console    "Creating Data Science Pipelines Application"
    Projects.Create Data Science Project From CLI    ${PROJECT}    as_user=${TEST_USER.USERNAME}
    DataSciencePipelinesBackend.Create Pipeline Server    namespace=${PROJECT}
    ...    object_storage_access_key=${S3.AWS_ACCESS_KEY_ID}
    ...    object_storage_secret_key=${S3.AWS_SECRET_ACCESS_KEY}
    ...    object_storage_endpoint=${S3.BUCKET_2.ENDPOINT}
    ...    object_storage_region=${S3.BUCKET_2.REGION}
    ...    object_storage_bucket_name=${S3.BUCKET_2.NAME}
    ...    dsp_version=v2
    DataSciencePipelinesBackend.Wait Until Pipeline Server Is Deployed    namespace=${PROJECT}

    Log To Console    "Verifying metrics"
    @{metrics_to_check} =    Create List    data_science_pipelines_application_ready
    ...                                     data_science_pipelines_application_apiserver_ready
    ...                                     data_science_pipelines_application_persistenceagent_ready
    ...                                     data_science_pipelines_application_scheduledworkflow_ready

    FOR    ${metric}    IN    @{metrics_to_check}
            Wait Until Keyword Succeeds    1m    5s
            ...     Metric Should Be Equal To Value
                    ...    pm_url=${RHODS_PROMETHEUS_URL}
                    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
                    ...    pm_query=${metric}{dspa_namespace="${PROJECT}"}
                    ...    expected_value=1
    END

    Make Dummy GET Request To ds-pipeline-dspa Route    expected_status=404

    Wait Until Keyword Succeeds    2m    5s
    ...     Metric Should Be Equal To Value
            ...    pm_url=${RHODS_PROMETHEUS_URL}
            ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
            ...    pm_query=haproxy_backend_http_responses_total:burnrate5m{component="dsp", exported_namespace="${PROJECT}"}
            ...    expected_value=0

    Log To Console    "Scaling down"
    ODS.Scale Deployment    ${PROJECT}        ds-pipeline-dspa                                     replicas=0
    ODS.Scale Deployment    ${PROJECT}        ds-pipeline-persistenceagent-dspa                    replicas=0
    ODS.Scale Deployment    ${PROJECT}        ds-pipeline-scheduledworkflow-dspa                   replicas=0

    Log To Console    "Verifying metrics"
    FOR    ${metric}    IN    @{metrics_to_check}
            Wait Until Keyword Succeeds    1m    5s
            ...     Metric Should Be Equal To Value
                    ...    pm_url=${RHODS_PROMETHEUS_URL}
                    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
                    ...    pm_query=${metric}{dspa_namespace="${PROJECT}"}
                    ...    expected_value=0
    END

    Make Dummy GET Request To ds-pipeline-dspa Route    expected_status=503

    Wait Until Keyword Succeeds    1m    5s
    ...     Metric Should Be Greater Than Value
            ...    pm_url=${RHODS_PROMETHEUS_URL}
            ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
            ...    pm_query=haproxy_backend_http_responses_total:burnrate5m{component="dsp", exported_namespace="${PROJECT}"}
            ...    greater_than_value=0

    Log To Console    "Verifying alerts are pending or firing"
    @{alerts_to_check} =    Create List    Data Science Pipeline Application Unavailable
    ...                                    Data Science Pipeline APIServer Unavailable
    ...                                    Data Science Pipeline PersistenceAgent Unavailable
    ...                                    Data Science Pipeline ScheduledWorkflows Unavailable

    FOR    ${alert}    IN    @{alerts_to_check}
            Prometheus.Wait Until Alert Is Pending    ${RHODS_PROMETHEUS_URL}
            ...    ${RHODS_PROMETHEUS_TOKEN}
            ...    RHODS Data Science Pipelines
            ...    ${alert}
            ...    alert-duration=120
            ...    timeout=5 min
    END

    # This one starts firing shortly after, so let's check that it actually fires
    Prometheus.Wait Until Alert Is Firing    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-haproxy_backend_http_responses_dsp
    ...    Data Science Pipelines Application Route Error 5m and 1h Burn Rate high
    ...    alert-duration=120
    ...    timeout=3 min

    Log To Console    "Scaling up"
    ODS.Scale Deployment    ${PROJECT}        ds-pipeline-dspa                                     replicas=1
    ODS.Scale Deployment    ${PROJECT}        ds-pipeline-persistenceagent-dspa                    replicas=1
    ODS.Scale Deployment    ${PROJECT}        ds-pipeline-scheduledworkflow-dspa                   replicas=1

    Log To Console    "Verifying metrics"
    FOR    ${metric}    IN    @{metrics_to_check}
            Wait Until Keyword Succeeds    1m    5s
            ...     Metric Should Be Equal To Value
                    ...    pm_url=${RHODS_PROMETHEUS_URL}
                    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
                    ...    pm_query=${metric}{dspa_namespace="${PROJECT}"}
                    ...    expected_value=1
    END

    Make Dummy GET Request To ds-pipeline-dspa Route    expected_status=404

    Wait Until Keyword Succeeds    2m    5s
    ...     Metric Should Be Equal To Value
            ...    pm_url=${RHODS_PROMETHEUS_URL}
            ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
            ...    pm_query=haproxy_backend_http_responses_total:burnrate5m{component="dsp", exported_namespace="${PROJECT}"}
            ...    expected_value=0

    Log To Console    "Verifying alerts are inactive"
    FOR    ${alert}    IN    @{alerts_to_check}
            Prometheus.Wait Until Alert Is Inactive    ${RHODS_PROMETHEUS_URL}
            ...    ${RHODS_PROMETHEUS_TOKEN}
            ...    RHODS Data Science Pipelines
            ...    ${alert}
            ...    alert-duration=120
            ...    timeout=1 min
    END

    Prometheus.Wait Until Alert Is Inactive    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-haproxy_backend_http_responses_dsp
    ...    Data Science Pipelines Application Route Error 5m and 1h Burn Rate high
    ...    alert-duration=120
    ...    timeout=2 min

    [Teardown]    Delete Project Via CLI    ${PROJECT}


Verify Data Science Pipelines Operator Alert Fires When Operator Is Down
    [Documentation]     Verifies that alert "Data Science Pipelines Operator Probe Success Burn Rate (for 5m)" is fired
    [Tags]    Tier3
    ...       ODS-2166
    ...       RHOAIENG-13262
    ...       Monitoring

    ODS.Scale Deployment    ${OPERATOR_NAMESPACE}        rhods-operator                                      replicas=0
    ODS.Scale Deployment    ${APPLICATIONS_NAMESPACE}    data-science-pipelines-operator-controller-manager  replicas=0

    Prometheus.Wait Until Alert Is Pending    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-probe_success_dsp
    ...    Data Science Pipelines Operator Probe Success 5m and 1h Burn Rate high
    ...    timeout=20 min

    ODS.Restore Default Deployment Sizes

    Prometheus.Wait Until Alert Is Inactive    ${RHODS_PROMETHEUS_URL}
    ...    ${RHODS_PROMETHEUS_TOKEN}
    ...    SLOs-probe_success_dsp
    ...    Data Science Pipelines Operator Probe Success 5m and 1h Burn Rate high
    ...    timeout=10 min

    [Teardown]    ODS.Restore Default Deployment Sizes

Verify Alerts Have Links To The Triage Guide
    [Documentation]    Verifies that all alerts have expected and working links to the triage guide
    [Tags]    Tier3
    ...       ODS-558
    ...       RHOAIENG-13073
    ...       Monitoring
    ${all_rules}=    Get Rules    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    alert
    ${all_rules}=    Get From Dictionary    ${all_rules['data']}    groups

    FOR    ${rule}    IN    @{all_rules}
        ${rule_name}=    Get From Dictionary    ${rule}    name
        ${rules_list}=    Get From Dictionary    ${rule}    rules
        FOR    ${sub_rule}    IN    @{rules_list}
            ${name}=    Get From Dictionary    ${sub_rule}    name
            ${exists}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${sub_rule['annotations']}    triage
            IF    not ${exists}
                IF    '${name}' != 'DeadManSnitch'
                    Run Keyword And Continue On Failure    FAIL    msg=Alert '${name}' does not have triage entry
                END
                CONTINUE
            END
            ${expected_triage_url}=    Set Variable    ${EMPTY}
            FOR    ${item}    IN    &{TRIAGE_URLS}
                ${matches}=    Get Regexp Matches    ${name}    ${item}[0]
                IF  len(${matches}) > 0
                    ${expected_triage_url}=    Set Variable    ${item}[1]
                    BREAK
                END
            END
            IF    '${expected_triage_url}' == ''
                Run Keyword And Continue On Failure    FAIL    msg=TRIAGE_URLS does not have expected value for '${name}', please add it
                CONTINUE
            END
            ${triage_url}=    Get From Dictionary    ${sub_rule['annotations']}    triage
            Run Keyword And Continue On Failure    Should Be Equal    ${expected_triage_url}    ${triage_url}    msg=Triage URL does not match the expected one

            ${result}=    Run Process    curl -s -o /dev/null -w '\%{http_code}\n' ${triage_url}
            ...    shell=true
            ...    stderr=STDOUT
            Run Keyword And Continue On Failure    Should Be Equal As Integers	    ${result.rc}    0    msg=Downloading the triage document for ${sub_rule} failed
            Run Keyword And Continue On Failure    Should Be Equal As Integers	    ${result.stdout}    200    msg=HTTP Status code was not 200
        END
    END

*** Keywords ***
Alerts Suite Setup
    [Documentation]    Test suite configuration
    Set Library Search Order    SeleniumLibrary
    Skip If RHODS Is Self-Managed And New Observability Stack Is Disabled    # TODO Observability: We don't configure alerts yet with new observability stack, so may likely fail
    RHOSi Setup

Alerts Suite Teardown
    [Documentation]    Test suite teardown
    Skip If RHODS Is Self-Managed And New Observability Stack Is Disabled
    RHOSi Teardown

Teardown PVC Alert Test
    [Documentation]    Deletes user notebook files using the new "Clean Up User Notebook"
    ...    keyword because "End Web Test" doesn't work well when disk is 100% fill
    ...    ed
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
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Verify Service Account Authorization Not Required
    Fix Spawner Status
    Spawn Notebook With Arguments    image=science-notebook
    Clone Git Repository And Run    ${notebook_repo}    ${notebook_path}
    Sleep    5s

Verify "RHODS Dashboard Probe Success Burn Rate" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "RHODS Dashboard Probe Success Burn Rate" severity
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_dashboard    RHODS Dashboard Probe Success 5m and 1h Burn Rate high    critical    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_dashboard    RHODS Dashboard Probe Success 30m and 6h Burn Rate high    critical    alert-duration=900
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_dashboard    RHODS Dashboard Probe Success 2h and 1d Burn Rate high    warning    alert-duration=3600
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_dashboard    RHODS Dashboard Probe Success 6h and 3d Burn Rate high    warning    alert-duration=10800

Verify "RHODS Jupyter Probe Success Burn Rate" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "RHODS Jupyter Probe Success Burn Rate" severity
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    RHODS Jupyter Probe Success 5m and 1h Burn Rate high    critical    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    RHODS Jupyter Probe Success 30m and 6h Burn Rate high    critical    alert-duration=900
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    RHODS Jupyter Probe Success 2h and 1d Burn Rate high    warning    alert-duration=3600
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    RHODS Jupyter Probe Success 6h and 3d Burn Rate high    warning    alert-duration=10800

Verify "TrustyAI Controller Probe Success Burn Rate" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "TrustyAI Controller Probe Success Burn Rate" severity
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    TrustyAI Controller Probe Success 5m and 1h Burn Rate high    critical    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    TrustyAI Controller Probe Success 30m and 6h Burn Rate high    critical    alert-duration=900
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    TrustyAI Controller Probe Success 2h and 1d Burn Rate high    warning    alert-duration=3600

Verify "ODH Model Controller Probe Success Burn Rate" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "ODH Model Controller Probe Success Burn Rate" severity
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    ODH Model Controller Probe Success 5m and 1h Burn Rate high    critical    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    ODH Model Controller Probe Success 30m and 6h Burn Rate high    critical    alert-duration=900
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    ODH Model Controller Probe Success 2h and 1d Burn Rate high    warning    alert-duration=3600

Verify "KServe Controller Probe Success Burn Rate" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "KServe Controller Probe Success Burn Rate" severity
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    KServe Controller Probe Success 5m and 1h Burn Rate high    critical    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    KServe Controller Probe Success 30m and 6h Burn Rate high    critical    alert-duration=900
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    KServe Controller Probe Success 2h and 1d Burn Rate high    warning    alert-duration=3600

Verify "Data Science Pipelines Operator Probe Success Burn Rate" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "Data Science Pipelines Operator Probe Success Burn Rate" severity
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    Data Science Pipelines Operator Probe Success 5m and 1h Burn Rate high    info    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    Data Science Pipelines Operator Probe Success 30m and 6h Burn Rate high    info    alert-duration=900
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-probe_success_workbench    Data Science Pipelines Operator Probe Success 2h and 1d Burn Rate high    info    alert-duration=3600

Verify "RHODS Dashboard Route Error Burn Rate" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "RHODS Dashboard Route Error Burn Rate" severity
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    RHODS Dashboard Route Error 5m and 1h Burn Rate high    critical    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    RHODS Dashboard Route Error 30m and 6h Burn Rate high   critical    alert-duration=900
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    RHODS Dashboard Route Error 2h and 1d Burn Rate high   warning    alert-duration=3600
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    RHODS Dashboard Route Error 6h and 3d Burn Rate high    warning    alert-duration=10800

Verify "Data Science Pipelines Application Route Error Burn Rate" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "Data Science Pipelines Application Route Error Burn Rate" severity
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    Data Science Pipelines Application Route Error 5m and 1h Burn Rate high    info    alert-duration=120
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    Data Science Pipelines Application Route Error 30m and 6h Burn Rate high   info    alert-duration=900
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    Data Science Pipelines Application Route Error 2h and 1d Burn Rate high   info    alert-duration=3600
    Verify Alert Has A Given Severity And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    Data Science Pipelines Application Route Error 6h and 3d Burn Rate high    info    alert-duration=10800

Verify "Kubeflow Notebook Controller Pod Is Not Running" Alerts Severity And Continue On Failure
    [Documentation]    Verifies alert severity for different alert durations
    Verify Alert Has A Given Severity And Continue On Failure
    ...    RHODS Notebook controllers    Kubeflow notebook controller pod is not running
    ...    alert-severity=warning    alert-duration=300

Verify "ODH Notebook Controller Pod Is Not Running" Alerts Severity And Continue On Failure
    [Documentation]    Verifies alert severity for different alert durations
    Verify Alert Has A Given Severity And Continue On Failure
    ...    RHODS Notebook controllers    ODH notebook controller pod is not running
    ...    alert-severity=warning    alert-duration=300

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

Verify "Jupyter Image Builds Are Failing" Alerts Severity And Continue On Failure
    [Documentation]    Verifies that alert "JupyterHub image builds are failing" is warning
    Verify Alert Has A Given Severity And Continue On Failure
    ...    Builds    Jupyter image builds are failing    warning    alert-duration=120

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

Check Cluster Name Contain "Aisrhods" Or Not
    [Documentation]     Return true if cluster name contains aisrhods and if not return false
    ${cluster_name} =    Common.Get Cluster Name From Console URL
    ${return_value} =  Evaluate  "aisrhods" in "${cluster_name}"
    RETURN  ${return_value}

Check Particular Text Is Present In Rhods-operator's Log
    [Documentation]     Check if text is present in log
    [Arguments]         ${text_to_check}
    Open OCP Console
    Login To Openshift    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    ${OCP_ADMIN_USER.AUTH_TYPE}
    Maybe Skip Tour    ${OCP_ADMIN_USER.USERNAME}
    ${val_result}=  Get Pod Logs From UI  namespace=${OPERATOR_NAMESPACE}
    ...                                   pod_search_term=rhods-operator
    ...                                   container_button_id=rhods-deployer-link
    Log  ${val_result}
    List Should Contain Value    ${val_result}    ${text_to_check}
    Close Browser

Verify Alertmanager Receiver For Critical Alerts
    [Documentation]     Receiver value should be equal to ${receiver}
    [Arguments]         ${receiver}
    ${result} =    Run    oc get configmap alertmanager -n ${MONITORING_NAMESPACE} -o jsonpath='{.data.alertmanager\\.yml}' | yq '.route.routes[] | select(.match.severity == "critical") | .receiver'
    Should Be Equal    ${receiver}    ${result}    msg=Alertmanager has an unexpected receiver for critical alerts

Metric Should Be Equal To Value
    [Documentation]    Verifies that metric is equal to the expected value
    [Arguments]    ${pm_url}    ${pm_token}    ${pm_query}    ${expected_value}
    ${response} =    Prometheus.Run Query
    ...    pm_url=${pm_url}
    ...    pm_token=${pm_token}
    ...    pm_query=${pm_query}
    Log    The response was: ${response.json()}
    Should Be Equal    ${response.json()["data"]["result"][0]["value"][-1]}    ${expected_value}

Metric Should Be Greater Than Value
    [Documentation]    Verifies that metric is greater than the specified value
    [Arguments]    ${pm_url}    ${pm_token}    ${pm_query}    ${greater_than_value}
    ${response} =    Prometheus.Run Query
    ...    pm_url=${pm_url}
    ...    pm_token=${pm_token}
    ...    pm_query=${pm_query}
    Log    The response was: ${response.json()}
    Should Be True    ${response.json()["data"]["result"][0]["value"][-1]} > ${greater_than_value}

Make Dummy GET Request To ds-pipeline-dspa Route
    [Documentation]    Makes a dummy GET request to the DSPA route so the burnrate metric is not returning NaN
    [Arguments]    ${expected_status}
    ${token} =    Get Access Token
    ${return_code}    ${url} =   Run And Return Rc And Output   oc get route ds-pipeline-dspa -n ${PROJECT} --template={{.spec.host}}
    Should Be Equal As Integers    ${return_code}	 0
    ${headers} =    Create Dictionary    Authorization=Bearer ${token}
    RequestsLibrary.GET    url=https://${url}    headers=${headers}    verify=${False}  expected_status=${expected_status}
