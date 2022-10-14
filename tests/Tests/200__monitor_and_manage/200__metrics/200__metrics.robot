*** Settings ***
Documentation       Test suite testing ODS Metrics
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Library             DateTime
Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown
Test Setup          Begin Metrics Web Test
Test Teardown       End Metrics Web Test


*** Variables ***
@{RECORD_GROUPS}    Availability Metrics    SLOs - ODH Dashboard
...    SLOs - RHODS Operator    Usage Metrics

@{ALERT_GROUPS}     Builds    DeadManSnitch    RHODS Notebook controllers
...    RHODS-PVC-Usage    SLOs-haproxy_backend_http_responses_total    SLOs-probe_success


*** Test Cases ***
Test Existence of Prometheus Alerting Rules
    [Documentation]    Verifies the prometheus alerting rules
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-509
    Check Prometheus Alerting Rules

Test Existence of Prometheus Recording Rules
    [Documentation]    Verifies the prometheus recording rules
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-510
    Check Prometheus Recording Rules

Test Metric "Notebook CPU Usage" On ODS Prometheus
    [Documentation]    Verifing the notebook cpu usage showing on RHODS promethues
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-178
    ...       FlakyTest
    ${cpu_usage_before} =    Read Current CPU Usage
    Run Jupyter Notebook For 5 Minutes
    ${cpu_usage_after} =    Read Current CPU Usage
    Should Not Be Equal    ${cpu_usage_before}    ${cpu_usage_after}

Test Metric "Rhods_Total_Users" On ODS Prometheus
    [Documentation]    Verifies that metric value for rhods_total_users
    ...    matches the value of its corresponding expression
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-628

    # Note: the expression ends with "step=1" to obtain the value for current second
    ${expression} =    Set Variable    rhods_total_users&step=1
    ${rhods_total_users} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}
    ...   ${expression}
    ${rhods_total_users} =    Set Variable    ${rhods_total_users.json()["data"]["result"][0]["value"][-1]}
    Log    rhods_total_users:${rhods_total_users}

    # Note: the expression ends with "step=1" to obtain the value cor current second
    ${expression} =    Set Variable
    ...    count(kube_statefulset_replicas{namespace=~"rhods-notebooks", statefulset=~"jupyter-nb-.*"})&step=1
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
    ${expression} =    Set Variable    rhods_aggregate_availability&step=1
    ${resp} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values} =    Create List    1    0
    Should Contain    ${list_values}    ${resp.json()["data"]["result"][0]["value"][-1]}

Verify JupyterHub Leader Monitoring Using ODS Prometheus
    [Documentation]    Verifies the only one endpoint is up at a time in JupyterHub Metrics
    [Tags]    Sanity
    ...       ODS-689
    ...       Tier1

    Skip If RHODS Version Greater Or Equal Than    version=1.16.0

    @{endpoints} =    Prometheus.Get Target Endpoints Which Have State Up
    ...    target_name=JupyterHub Metrics
    ...    pm_url=${RHODS_PROMETHEUS_URL}
    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
    ...    username=${OCP_ADMIN_USER.USERNAME}
    ...    password=${OCP_ADMIN_USER.PASSWORD}
    ${Length} =    Get Length    ${endpoints}
    Should Be Equal As Integers    ${Length}    1
    ${query_result} =    Prometheus.Run Range Query    pm_query=up{job="JupyterHub Metrics"}    pm_url=${RHODS_PROMETHEUS_URL}    pm_token=${RHODS_PROMETHEUS_TOKEN}
    Verify That There Was Only 1 Jupyterhub Server Available At A Time  query_result=${query_result}


*** Keywords ***
Begin Metrics Web Test
    Set Library Search Order    SeleniumLibrary

End Metrics Web Test
    Close All Browsers

Check Prometheus Recording Rules
    Prometheus.Verify Rules    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    record    @{RECORD_GROUPS}

Check Prometheus Alerting Rules
    Prometheus.Verify Rules    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    alert    @{ALERT_GROUPS}

Read Current CPU Usage
    [Documentation]    Returns list of current cpu usage
    ${Expression} =    Set Variable
    ...    sum(rate(container_cpu_usage_seconds_total{prometheus_replica="prometheus-k8s-0", container="",pod=~"jupyter-nb.*",namespace="rhods-notebooks"}[1h]))
    ${resp} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${Expression}
    IF    ${resp.json()["data"]["result"]} == []
        ${cpu_usage}    Set Variable    0
    ELSE
        ${cpu_usage}    Set Variable    ${resp.json()["data"]["result"][0]["value"][-1]}
    END
    [Return]    ${cpu_usage}
## TODO: Add this keyword with the other JupyterHub stuff

Run Jupyter Notebook For 5 Minutes
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Iterative Image Test    s2i-generic-data-science-notebook    https://github.com/lugi0/minimal-nb-image-test
    ...    minimal-nb-image-test/minimal-nb.ipynb

##TODO: This is a copy of "Iterative Image Test" keyword from image-iteration.robob. We have to refactor the code not to duplicate this method

Iterative Image Test
    [Arguments]    ${image}    ${REPO_URL}    ${NOTEBOOK_TO_RUN}
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Page Should Not Contain    403 : Forbidden
    ${authorization_required} =    Is Service Account Authorization Required
    Run Keyword If    ${authorization_required}    Authorize jupyterhub service account
    Fix Spawner Status
    Spawn Notebook With Arguments    image=${image}
    Run Cell And Check Output    print("Hello World!")    Hello World!
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
    #This ensures all workloads are run even if one (or more) fails
    Run Keyword And Continue On Failure    Clone Git Repository And Run    ${REPO_URL}    ${NOTEBOOK_TO_RUN}
    Clean Up Server
    Stop JupyterLab Notebook Server
    Go To    ${ODH_DASHBOARD_URL}
    Sleep    10    reason=Waiting for ODH Dashboard home page to load

Verify That There Was Only 1 Jupyterhub Server Available At A Time
    [Documentation]    Verify that there was only 1 jupyterhub server available at a time
    [Arguments]        ${query_result}
    @{data} =  BuiltIn.Evaluate   list(${query_result.json()["data"]["result"]})
    Log  ${data}
    @{list_to_check}  Create List
    FOR  ${time_value}  IN  @{data}
        @{values} =  BuiltIn.Evaluate   list(${time_value["values"]})
        FOR  ${v}  IN  @{values}
            IF  ${v[1]} == 1
                List Should Not Contain Value  ${list_to_check}  ${v[0]}  msg=More than one endpoints are up at same time
                Append To List  ${list_to_check}  ${v[0]}
            END
        END
    END
