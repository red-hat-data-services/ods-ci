*** Settings ***
Documentation       Contains Keywords for checking alerts

Resource            ../Prometheus/Prometheus.resource


*** Keywords ***
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

Verify Number Of Alerting Rules
    [Documentation]    Verifies number of alerting rules with a specified alert state present in Prometheus
    [Arguments]    ${expected_count}    ${alert_state}
    ${all_rules} =    Prometheus.Get Rules    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    alert
    ${all_rules_json_string} =    Evaluate    json.dumps(${all_rules})    json   # Need to to this as Get Rules returns a dictionary, not a JSON text
    ${return_code}    ${actual_count} =    Run And Return Rc And Output
    ...    jq '[.data.groups[].rules[] | select(.state == "${alert_state}")] | length' <<< '${all_rules_json_string}'
    Should Be Equal As Integers	 ${return_code}	 0  msg=Error getting number of alerting rules
    Should Be Equal As Integers	 ${actual_count}  ${expected_count}
    ...    msg=Number of alerting rules doesn't match, actual '${actual_count}', expected '${expected_count}'

# Grouped checks per rule group
Verify "KubeFlow Training Operator" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "KubeFlow Training Operator" is not firing
    Verify Alert Is Not Firing And Continue On Failure
    ...    KubeFlow Training Operator    KubeFlow Training Operator is not running

Verify "RHODS Dashboard Route Error Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "RHODS Dashboard Route Error Burn Rate" is not firing
    ...    for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    RHODS Dashboard Route Error 5m and 1h Burn Rate high    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    RHODS Dashboard Route Error 30m and 6h Burn Rate high    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    RHODS Dashboard Route Error 2h and 1d Burn Rate high    alert-duration=3600
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dashboard    RHODS Dashboard Route Error 6h and 3d Burn Rate high    alert-duration=10800

Verify "RHODS Dashboard Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "RHODS Dashboard Probe Success Burn Rate" is not firing
    ...    for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_dashboard    RHODS Dashboard Probe Success 5m and 1h Burn Rate high    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_dashboard    RHODS Dashboard Probe Success 30m and 6h Burn Rate high    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_dashboard    RHODS Dashboard Probe Success 2h and 1d Burn Rate high    alert-duration=3600
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_dashboard    RHODS Dashboard Probe Success 6h and 3d Burn Rate high    alert-duration=10800

Verify "Data Science Pipelines Application Route Error Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "Data Science Pipelines Application Route Error Burn Rate" is not firing
    ...     for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dsp    Data Science Pipelines Application Route Error 5m and 1h Burn Rate high    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dsp    Data Science Pipelines Application Route Error 30m and 6h Burn Rate high    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dsp    Data Science Pipelines Application Route Error 2h and 1d Burn Rate high    alert-duration=3600
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-haproxy_backend_http_responses_dsp    Data Science Pipelines Application Route Error 6h and 3d Burn Rate high    alert-duration=10800

Verify "Data Science Pipelines Operator Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "Data Science Pipelines Operator Probe Success Burn Rate" is not firing
    ...     for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_dsp    Data Science Pipelines Operator Probe Success 5m and 1h Burn Rate high    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_dsp    Data Science Pipelines Operator Probe Success 30m and 6h Burn Rate high    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_dsp    Data Science Pipelines Operator Probe Success 2h and 1d Burn Rate high    alert-duration=3600

Verify "RHODS Data Science Pipelines" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alerts from group "RHODS Data Science Pipelines" are not firing
    Verify Alert Is Not Firing And Continue On Failure
    ...    RHODS Data Science Pipelines    Data Science Pipeline Application Unavailable    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    RHODS Data Science Pipelines    Data Science Pipeline APIServer Unavailable    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    RHODS Data Science Pipelines    Data Science Pipeline PersistenceAgent Unavailable    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    RHODS Data Science Pipelines    Data Science Pipeline ScheduledWorkflows Unavailable    alert-duration=120

Verify "ODH Model Controller Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "ODH Model Controller Probe Success Burn Rate" is not firing
    ...     for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_model_controller    ODH Model Controller Probe Success 5m and 1h Burn Rate high    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_model_controller    ODH Model Controller Probe Success 30m and 6h Burn Rate high    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_model_controller    ODH Model Controller Probe Success 2h and 1d Burn Rate high    alert-duration=3600

Verify "Kserve Controller Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "Kserve Controller Probe Success Burn Rate" is not firing
    ...     for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_kserve    Kserve Controller Probe Success 5m and 1h Burn Rate high    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_kserve    Kserve Controller Probe Success 30m and 6h Burn Rate high    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_kserve    Kserve Controller Probe Success 2h and 1d Burn Rate high    alert-duration=3600

Verify "Distributed Workloads Kuberay" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "Distributed Workloads Kuberay" is not firing
    Verify Alert Is Not Firing And Continue On Failure
    ...    Distributed Workloads Kuberay    KubeRay Operator is not running

Verify "Distributed Workloads Kueue" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "Distributed Workloads Kueue" is not firing
    Verify Alert Is Not Firing And Continue On Failure
    ...    Distributed Workloads Kueue    Kueue Operator is not running

Verify "Kubeflow notebook controller pod is not running" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "Kubeflow notebook controller pod is not running" is not firing
    ...    for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    RHODS Notebook controllers    Kubeflow notebook controller pod is not running    alert-duration=300

Verify "ODH notebook controller pod is not running" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "ODH notebook controller pod is not running" is not firing
    ...    for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    RHODS Notebook controllers    ODH notebook controller pod is not running    alert-duration=300

Verify "RHODS Jupyter Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "RHODS JupyterHub Probe Success Burn Rate" is not firing
    ...     for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_workbench    RHODS Jupyter Probe Success 5m and 1h Burn Rate high    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_workbench    RHODS Jupyter Probe Success 30m and 6h Burn Rate high    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_workbench    RHODS Jupyter Probe Success 2h and 1d Burn Rate high    alert-duration=3600
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_workbench    RHODS Jupyter Probe Success 6h and 3d Burn Rate high    alert-duration=10800

Verify "TrustyAI Controller Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "Kserve Controller Probe Success Burn Rate" is not firing
    ...     for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_trustyai    TrustyAI Controller Probe Success 5m and 1h Burn Rate high    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_trustyai    TrustyAI Controller Probe Success 30m and 6h Burn Rate high    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_trustyai    TrustyAI Controller Probe Success 2h and 1d Burn Rate high    alert-duration=3600

Verify "Model Registry Operator Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    [Documentation]    Verifies that alert "Kserve Controller Probe Success Burn Rate" is not firing
    ...     for all alert durations
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_model_controller    Model Registry Operator Probe Success 5m and 1h Burn Rate high    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_model_controller    Model Registry Operator Probe Success 30m and 6h Burn Rate high    alert-duration=900
    Verify Alert Is Not Firing And Continue On Failure
    ...    SLOs-probe_success_model_controller    Model Registry Operator Probe Success 2h and 1d Burn Rate high    alert-duration=3600
