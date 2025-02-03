*** Settings ***
Documentation       Test suite testing ODS Metrics
Resource            ../../../../Resources/RHOSi.resource
Resource            ../../../../Resources/ODS.robot
Resource            ../../../../Resources/Common.robot
Library             DateTime
Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown
Test Setup          Begin Metrics Web Test
Test Teardown       End Metrics Web Test
Test Tags           ExcludeOnODH


*** Variables ***
@{RECORD_GROUPS}    SLOs - Data Science Pipelines Operator    SLOs - Data Science Pipelines Application
...    SLOs - Modelmesh Controller
...    SLOs - ODH Model Controller
...    SLOs - RHODS Operator v2

@{ALERT_GROUPS}    SLOs-haproxy_backend_http_responses_dsp    RHODS Data Science Pipelines    SLOs-probe_success_dsp
...    SLOs-probe_success_modelmesh     SLOs-probe_success_dashboard    SLOs-probe_success_workbench
...    DeadManSnitch


*** Test Cases ***
Test Existence of Prometheus Alerting Rules
    [Documentation]    Verifies the prometheus alerting rules
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-509
    ...       Monitoring
    Skip If RHODS Is Self-Managed
    Check Prometheus Alerting Rules

Test Existence of Prometheus Recording Rules
    [Documentation]    Verifies the prometheus recording rules
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-510
    ...       Monitoring
    Skip If RHODS Is Self-Managed
    Check Prometheus Recording Rules

Test Metric "Notebook CPU Usage" On ODS Prometheus
    [Documentation]    Verifing the notebook cpu usage showing on RHODS promethues
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-178
    ...       Monitoring
    Skip If RHODS Is Self-Managed
    ${cpu_usage_before} =    Read Current CPU Usage
    Run Jupyter Notebook For 5 Minutes
    Wait Until Keyword Succeeds    10 times   30s
    ...    CPU Usage Should Have Increased    ${cpu_usage_before}

Test Metric "Rhods_Total_Users" On ODS Prometheus
    [Documentation]    Verifies that metric value for rhods_total_users
    ...    matches the value of its corresponding expression
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-628
    ...       Monitoring
    Skip If RHODS Is Self-Managed
    # Note: the expression ends with "step=1" to obtain the value for current second
    ${expression} =    Set Variable    rhods_total_users&step=1
    ${rhods_total_users} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}
    ...   ${expression}
    ${rhods_total_users} =    Set Variable    ${rhods_total_users.json()["data"]["result"][0]["value"][-1]}
    Log    rhods_total_users:${rhods_total_users}

    # Note: the expression ends with "step=1" to obtain the value cor current second
    ${expression} =    Set Variable
    ...    count(kube_statefulset_replicas{namespace=~"${NOTEBOOKS_NAMESPACE}", statefulset=~"jupyter-nb-.*"})&step=1
    ${total_users_using_expression} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}
    ...    ${expression}
    ${total_users_using_expression} =    Set Variable
    ...    ${total_users_using_expression.json()["data"]["result"][0]["value"][-1]}
    Log    total_users_using_expression: ${total_users_using_expression}

    Should Be Equal    ${rhods_total_users}    ${total_users_using_expression}
    ...    msg=metric value for rhods_total_users does not match the value of is corresponding expression

Test Metric Existence For "Rhods_Aggregate_Availability" On ODS Prometheus
    [Documentation]    Verifies the rhods aggregate availability on rhods prometheus
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-636
    ...       Monitoring
    Skip If RHODS Is Self-Managed
    ${expression} =    Set Variable    rhods_aggregate_availability&step=1
    ${resp} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values} =    Create List    1    0
    Should Contain    ${list_values}    ${resp.json()["data"]["result"][0]["value"][-1]}

Test Targets Are Available And Up In RHOAI Prometheus
    [Documentation]   Verifies the expected targets in Prometheus are available and up running
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-179
    ...       RHOAIENG-13066
    ...       Monitoring
    Skip If RHODS Is Self-Managed
    @{targets} =    Prometheus.Get Target Pools Which Have State Up
    ...    pm_url=${RHODS_PROMETHEUS_URL}
    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
    ...    username=${OCP_ADMIN_USER.USERNAME}
    ...    password=${OCP_ADMIN_USER.PASSWORD}
    List Should Contain Value    ${targets}    CodeFlare Operator
    List Should Contain Value    ${targets}    Data Science Pipelines Operator
    List Should Contain Value    ${targets}    Federate Prometheus
    List Should Contain Value    ${targets}    Kserve Controller Manager
    List Should Contain Value    ${targets}    KubeRay Operator
    List Should Contain Value    ${targets}    Kubeflow Notebook Controller Service Metrics
    List Should Contain Value    ${targets}    Kueue Operator
    List Should Contain Value    ${targets}    Modelmesh Controller
    List Should Contain Value    ${targets}    ODH Model Controller
    List Should Contain Value    ${targets}    ODH Notebook Controller Service Metrics
    List Should Contain Value    ${targets}    TrustyAI Controller Manager
    List Should Contain Value    ${targets}    user_facing_endpoints_status_codeflare
    List Should Contain Value    ${targets}    user_facing_endpoints_status_dsp
    List Should Contain Value    ${targets}    user_facing_endpoints_status_rhods_dashboard
    List Should Contain Value    ${targets}    user_facing_endpoints_status_workbenches

Test RHOAI Dashboard Metrics By Code Are Defined
    [Documentation]   Verifies the RHOAI Dashboard Metrics By Code Are Defined and show accurate values
    ...               (2xx and 5xx codes)
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-195
    ...       RHOAIENG-13261
    ...       Monitoring
    Skip If RHODS Is Self-Managed
    ${response_by_code} =    Prometheus.Run Query
    ...    pm_url=${RHODS_PROMETHEUS_URL}
    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
    ...    pm_query=sum(haproxy_backend_http_responses_total {route='rhods-dashboard'}) by(code)
    ${response_5xx} =    Prometheus.Run Query
    ...    pm_url=${RHODS_PROMETHEUS_URL}
    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
    ...    pm_query=sum(haproxy_backend_http_responses_total{route='rhods-dashboard', code='5xx'})
    ${response_2xx} =    Prometheus.Run Query
    ...    pm_url=${RHODS_PROMETHEUS_URL}
    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
    ...    pm_query=sum(haproxy_backend_http_responses_total{route='rhods-dashboard', code='2xx'})
    ${response_total} =    Prometheus.Run Query
    ...    pm_url=${RHODS_PROMETHEUS_URL}
    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
    ...    pm_query=sum(haproxy_backend_http_responses_total{route='rhods-dashboard'})

    @{metrics_by_code} =    Set Variable    ${response_by_code.json()["data"]["result"]}
    ${metrics_by_code_5xx} =    Set Variable    ${metrics_by_code[4]["value"][-1]}
    ${metrics_by_code_5xx} =    Convert To Number    ${metrics_by_code_5xx}    2
    ${metrics_by_code_2xx} =    Set Variable    ${metrics_by_code[1]["value"][-1]}
    ${metrics_by_code_2xx} =    Convert To Number    ${metrics_by_code_2xx}    2
    ${metrics_5xx} =    Set Variable    ${response_5xx.json()["data"]["result"][0]["value"][-1]}
    ${metrics_5xx} =    Convert To Number    ${metrics_5xx}    2
    ${metrics_2xx} =    Set Variable    ${response_2xx.json()["data"]["result"][0]["value"][-1]}
    ${metrics_2xx} =    Convert To Number    ${metrics_2xx}    2
    ${metrics_total} =    Set Variable    ${response_total.json()["data"]["result"][0]["value"][-1]}
    ${metrics_total} =    Convert To Number    ${metrics_total}    2

    Should Be True      ${metrics_by_code_5xx} == ${metrics_5xx}
    Should Be True      ${metrics_by_code_2xx} == ${metrics_2xx}
    Should Be True      ${metrics_total} == ${metrics_by_code_5xx}+${metrics_by_code_2xx}

Test RHOAI Dashboard Metrics Are Defined
    [Documentation]   Verifies the RHOAI Dashboard Metrics Are Defined and show meaningful values
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-194
    ...       RHOAIENG-13260
    ...       Monitoring
    Skip If RHODS Is Self-Managed
    ${response} =    Prometheus.Run Query
    ...    pm_url=${RHODS_PROMETHEUS_URL}
    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
    ...    pm_query={job="user_facing_endpoints_status_rhods_dashboard"}

    ${metrics_names} =   Run  echo '${response.text}' | jq .data.result[].metric.__name__
    @{expected_metric_names} =    Create List  probe_dns_lookup_time_seconds  probe_duration_seconds  probe_failed_due_to_regex
    ...                                     probe_http_content_length  probe_http_duration_seconds  probe_http_last_modified_timestamp_seconds
    ...                                     probe_http_redirects  probe_http_ssl  probe_http_status_code  probe_http_uncompressed_body_length
    ...                                     probe_http_version  probe_ip_addr_hash  probe_ip_protocol  probe_ssl_earliest_cert_expiry
    ...                                     probe_ssl_last_chain_expiry_timestamp_seconds  probe_ssl_last_chain_info  probe_success
    ...                                     probe_tls_version_info  scrape_duration_seconds  scrape_samples_post_metric_relabeling
    ...                                     scrape_samples_scraped  scrape_series_added

    FOR    ${metric}    IN    @{expected_metric_names}
        Should Contain    ${metrics_names}    ${metric}
    END

*** Keywords ***
Begin Metrics Web Test
    [Documentation]    Test Setup
    Set Library Search Order    SeleniumLibrary

End Metrics Web Test
    [Documentation]    Test Teardown
    Close All Browsers

Check Prometheus Recording Rules
    [Documentation]    Verifies recording rules in prometheus
    Prometheus.Verify Rules    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    record    @{RECORD_GROUPS}

Check Prometheus Alerting Rules
    [Documentation]    Verifies alerting rules in prometheus
    Prometheus.Verify Rules    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    alert    @{ALERT_GROUPS}

Read Current CPU Usage
    [Documentation]    Returns list of current cpu usage
    ${expression} =    Set Variable
    ...    sum(rate(container_cpu_usage_seconds_total{container="",pod=~"jupyter-nb.*",namespace="${NOTEBOOKS_NAMESPACE}"}[1h]))    # robocop:disable
    ${resp} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    IF    ${resp.json()["data"]["result"]} == []
        ${cpu_usage} =    Set Variable    0
    ELSE
        ${cpu_usage} =    Set Variable    ${resp.json()["data"]["result"][0]["value"][-1]}
    END
    RETURN    ${cpu_usage}

CPU Usage Should Have Increased
     [Documentation]   Verifies that CPU usage for notebook pods has increased since previous value
     [Arguments]    ${cpu_usage_before}
     ${cpu_usage_current} =    Read Current CPU Usage
     Should Be True    ${cpu_usage_current}>${cpu_usage_before}

Run Jupyter Notebook For 5 Minutes
    [Documentation]    Runs a notebook for a few minutes
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Iterative Image Test    science-notebook    https://github.com/lugi0/minimal-nb-image-test
    ...    minimal-nb-image-test/minimal-nb.ipynb

#robocop: disable:too-many-calls-in-keyword
Iterative Image Test
    [Documentation]    Launches a jupyter notebook by repo and path.
    ...    TODO: This is a copy of "Iterative Image Test" keyword from image-iteration.robob.
    ...    We have to refactor the code not to duplicate this method
    [Arguments]    ${image}    ${REPO_URL}    ${NOTEBOOK_TO_RUN}
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Page Should Not Contain    403 : Forbidden
    ${authorization_required} =    Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize JupyterLab Service Account
    Fix Spawner Status
    Spawn Notebook With Arguments    image=${image}
    Run Cell And Check Output    print("Hello World!")    Hello World!
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
    # This ensures all workloads are run even if one (or more) fails
    Run Keyword And Warn On Failure    Clone Git Repository And Run    ${REPO_URL}    ${NOTEBOOK_TO_RUN}
    Clean Up Server
    Stop JupyterLab Notebook Server
    Go To    ${ODH_DASHBOARD_URL}
    Sleep    10    reason=Waiting for ODH Dashboard home page to load

Verify That There Was Only 1 Jupyterhub Server Available At A Time
    [Documentation]    Verify that there was only 1 jupyterhub server available at a time
    [Arguments]        ${query_result}
    @{data} =  BuiltIn.Evaluate   list(${query_result.json()["data"]["result"]})
    Log  ${data}
    @{list_to_check} =    Create List
    FOR  ${time_value}  IN  @{data}
        @{values} =  BuiltIn.Evaluate   list(${time_value["values"]})
        FOR  ${v}  IN  @{values}
            IF  ${v[1]} == 1
                List Should Not Contain Value  ${list_to_check}  ${v[0]}  msg=More than one endpoints are up at same time
                Append To List  ${list_to_check}  ${v[0]}
            END
        END
    END
