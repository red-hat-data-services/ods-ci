*** Settings ***
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource            ../../../Resources/Page/OCPLogin/OCPLogin.resource
Resource            ../../../Resources/OCP.resource
Resource            ../../../Resources/Page/ODH/Grafana/Grafana.resource
Library             DateTime
Library             JupyterLibrary
Library             SeleniumLibrary

Test Setup          Begin Billing Metrics Web Test
Test Teardown       End Web Billing Metrics Test


*** Variables ***
${METRIC_RHODS_CPU}                 cluster:usage:consumption:rhods:cpu:seconds:rate1h
${METRIC_RHODS_CPU_BEFORE_1.5.0}    cluster:usage:consumption:rhods:cpu:seconds:rate5m
${METRIC_RHODS_UNDEFINED}           cluster:usage:consumption:rhods:undefined:seconds:rate5m
${METRIC_RHODS_ACTIVE_USERS}        cluster:usage:consumption:rhods:active_users
${METRIC_RHODS_CPU}                 cluster:usage:consumption:rhods:cpu:seconds:rate1h
${METRIC_RHODS_PODUP}
${telemeter_url}                     https://telemeter-lts-dashboards.datahub.redhat.com/

*** Test Cases ***
Verify OpenShift Monitoring Results Are Correct When Running Undefined Queries
    [Documentation]     Verifies openshift monitoring results are correct when firing undefined queries
    [Tags]    Smoke
    ...       Sanity
    ...       ODS-173
    Run OpenShift Metrics Query    ${METRIC_RHODS_UNDEFINED}    retry-attempts=1
    Metrics.Verify Query Results Dont Contain Data
    [Teardown]    SeleniumLibrary.Close All Browsers

Test Billing Metric (Notebook Cpu Usage) On OpenShift Monitoring
    [Documentation]     Run notebook for 5 min and checks CPU usage is greater than zero
    [Tags]    Smoke
    ...       Sanity
    ...       ODS-175
    Run Jupyter Notebook For 5 Minutes
    Verify Previus CPU Usage Is Greater Than Zero

Test Metric "Rhods_Total_Users" On Cluster Monitoring Prometheus
    [Documentation]     Verifies the openshift metrics and rhods prometheus showing same rhods_total_users values
    [Tags]    Sanity
    ...       ODS-634
    ...       Tier1
    ${value} =    Run OpenShift Metrics Query    query=rhods_total_users
    ${value_from_promothues} =    Fire Query On RHODS Prometheus And Return Value    query=rhods_total_users
    Should Be Equal    ${value_from_promothues}    ${value}
    [Teardown]    Test Teardown For Matrics Web Test

Test Metric "Rhods_Aggregate_Availability" On Cluster Monitoring Prometheus
    [Documentation]     Verifies the openshift metrics and rhods prometheus showing same rhods_aggregate_availability values
    [Tags]    Sanity
    ...       ODS-637
    ...       Tier1
    ${value} =    Run OpenShift Metrics Query    query=rhods_aggregate_availability
    ${value_from_promothues} =    Fire Query On RHODS Prometheus And Return Value    query=rhods_aggregate_availability
    Should Be Equal    ${value_from_promothues}    ${value}
    [Teardown]    Test Teardown For Matrics Web Test

Test Metric "Active_Users" On OpenShift Monitoring On Cluster Monitoring Prometheus
    [Documentation]    Test launchs notebook for N user and and checks Openshift Matrics showing N active users
    [Tags]    Sanity
    ...       ODS-1053
    ...       Tier1
    Skip Test If Current Active Users Count Is Not Zero
    @{list_of_usernames} =    Create List    ${TEST_USER_3.USERNAME}    ${TEST_USER_4.USERNAME}
    Log In N Users To JupyterLab And Launch A Notebook For Each Of Them
    ...    list_of_usernames=${list_of_usernames}
    ${value} =    Run OpenShift Metrics Query    query=cluster:usage:consumption:rhods:active_users
    Should Be Equal    ${value}    2    msg=Active Users are not equal to length of list or N users
    [Teardown]    CleanUp JupyterHub For N users    list_of_usernames=${list_of_usernames}

Test Metric "Active Users" On Telemeter
    [Documentation]    Verifies the openshift metrics and telemeter shows
    ...                the same rhods active users
    [Tags]    ODS-1054
    ...       Tier2
    @{list_of_usernames} =    Create List    ${TEST_USER_3.USERNAME}    ${TEST_USER_4.USERNAME}
    Log In N Users To JupyterLab And Launch A Notebook For Each Of Them
    ...    list_of_usernames=${list_of_usernames}
    ${value} =    Run OpenShift Metrics Query    query=cluster:usage:consumption:rhods:active_users
    ${cluster_id} =    Get Cluster ID
    ${query} =    Set Variable    cluster:usage:consumption:rhods:active_users{_id=${cluster_id}}
    Sleep  15m
    Launch Grafana    ocp_user_name=${MY_USER.USERNAME}    ocp_user_pw=${MY_USER.PASSWORD}
    ...               ocp_user_auth_type=my_ldap_provider    grafana_url=${telemeter_url}
    ...               browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    ${data_source} =   Get Telemeter DataSource For ODS Environment
    ${data} =    Run Range Query In Browser    ${telemeter_url}   ${data_source}   ${query}
    Should Be Equal    ${value}    ${data}
    [Teardown]    CleanUp JupyterHub For N users    list_of_usernames=${list_of_usernames}


Test metric "Notebook Cpu Usage" on Telemeter
    [Documentation]    Verifies prometheus and grafana shows the same CPU usage.
    [Tags]    ODS-181
    ...       Tier1
    ${cluster_id} =    Get Cluster ID
    Run Jupyter Notebook For 10 Minutes
    ${pm_query} =    Set Variable
    ...  sum(rate(container_cpu_usage_seconds_total{prometheus_replica="prometheus-k8s-0", container="",pod=~"jupyterhub-nb.*",namespace="rhods-notebooks"}[1h]))
    ${usage} =    Run Range Query    ${pm_query}    pm_url=${RHODS_PROMETHEUS_URL}
    ...           pm_token=${RHODS_PROMETHEUS_TOKEN}    interval=12h     steps=172
    ${usage} =   Set Variable  ${usage.json()["data"]["result"][0]["values"][-1][1]}
    ${query} =   Set Variable    cluster:usage:consumption:rhods:cpu:seconds:rate1h{_id=${cluster_id}}
    Launch Grafana    ocp_user_name=${MY_USER.USERNAME}    ocp_user_pw=${MY_USER.PASSWORD}
    ...               ocp_user_auth_type=my_ldap_provider    grafana_url=${telemeter_url}
    ...               browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    ${data_source} =   Get Telemeter DataSource For ODS Environment
    ${data} =    Run Range Query In Browser    ${telemeter_url}     ${data_source}     ${query}
    Should Be Equal    ${usage}    ${data}

Test metric "Rhods_Total_Users" On Telemeter
    [Documentation]    Verifies the prometheus and telemeter shows
    ...                the same numbers of total rhods users
    [Tags]    ODS-635
    ...       Tier1
    @{list_of_usernames} =    Create List    ${TEST_USER_3.USERNAME}    ${TEST_USER_4.USERNAME}
    Log In N Users To JupyterLab And Launch A Notebook For Each Of Them
    ...    list_of_usernames=${list_of_usernames}
    CleanUp JupyterHub For N users    list_of_usernames=${list_of_usernames}
    ${rhods_total_users} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    rhods_total_users
    ${rhods_total_users} =    Set Variable   ${rhods_total_users.json()["data"]["result"][0]["value"][-1]}
    Launch Grafana    ocp_user_name=${MY_USER.USERNAME}    ocp_user_pw=${MY_USER.PASSWORD}
    ...               ocp_user_auth_type=my_ldap_provider    grafana_url=${telemeter_url}
    ...               browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    ${cluster_id} =    Get Cluster ID
    ${query} =    Set Variable    rhods_total_users{_id=${cluster_id}}
    ${data_source} =   Get Telemeter DataSource For ODS Environment
    ${data} =    Run Range Query In Browser    ${telemeter_url}    ${data_source}    ${query}
    Should Be Equal    ${rhods_total_users}    ${data}


Test Metric "Active Notebook Pod Time" On OpenShift Monitoring - Cluster Monitoring Prometheus
    [Documentation]    Test launchs notebook for N user and and checks Openshift Matrics showing number of running pods
    [Tags]    Sanity
    ...       ODS-1055
    ...       Tier1
    @{list_of_usernames} =    Create List    ${TEST_USER_3.USERNAME}    ${TEST_USER_4.USERNAME}
    Log In N Users To JupyterLab And Launch A Notebook For Each Of Them
    ...    list_of_usernames=${list_of_usernames}
    ${value} =    Run OpenShift Metrics Query    query=cluster:usage:consumption:rhods:pod:up
    Should Not Be Empty    ${value}    msg=Matrics does not contains value for pod:up query
    [Teardown]    CleanUp JupyterHub For N users    list_of_usernames=${list_of_usernames}

Test metric "Rhods_Aggregate_Availability" on Telemeter
    [Documentation]    Verifies the prometheus and telemeter shows
    ...                the same rhods aggregate availability
    [Tags]    ODS-638
    ...       Tier1
    @{list_of_usernames} =    Create List    ${TEST_USER_3.USERNAME}    ${TEST_USER_4.USERNAME}
    Log In N Users To JupyterLab And Launch A Notebook For Each Of Them
    ...    list_of_usernames=${list_of_usernames}
    ${rhods_aggregate_availability} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}
    ...                                 rhods_aggregate_availability
    ${rhods_aggregate_availability} =    Set Variable   ${rhods_aggregate_availability.json()["data"]["result"][0]["value"][-1]}
    Launch Grafana    ocp_user_name=${MY_USER.USERNAME}    ocp_user_pw=${MY_USER.PASSWORD}
    ...               ocp_user_auth_type=my_ldap_provider    grafana_url=${telemeter_url}
    ...               browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    ${cluster_id} =    Get Cluster ID
    ${query} =    Set Variable    rhods_aggregate_availability{_id=${cluster_id}}
    ${data_source} =   Get Telemeter DataSource For ODS Environment
    ${data} =    Run Range Query In Browser    ${telemeter_url}    ${data_source}    ${query}
    Should Be Equal    ${rhods_aggregate_availability}    ${data}
    [Teardown]    CleanUp JupyterHub For N users    list_of_usernames=${list_of_usernames}

Test Metric "Active Notebook Pod Time" On Telemeter
    [Documentation]    Verifies the openshift metrics and telemeter shows
    ...                the same active notebook pod time
    [Tags]    ODS-1056
    ...       Tier1
    @{list_of_usernames} =    Create List    ${TEST_USER_3.USERNAME}    ${TEST_USER_4.USERNAME}
    Log In N Users To JupyterLab And Launch A Notebook For Each Of Them
    ...    list_of_usernames=${list_of_usernames}
    ${value} =    Run OpenShift Metrics Query    query=cluster:usage:consumption:rhods:pod:up
    ${cluster_id} =    Get Cluster ID
    ${query} =    Set Variable    cluster:usage:consumption:rhods:pod:up{_id=${cluster_id}}
    Launch Grafana    ocp_user_name=${MY_USER.USERNAME}    ocp_user_pw=${MY_USER.PASSWORD}
    ...               ocp_user_auth_type=my_ldap_provider    grafana_url=${telemeter_url}
    ...               browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    ${data_source} =   Get Telemeter DataSource For ODS Environment
    ${data} =    Run Range Query In Browser    ${telemeter_url}    ${data_source}    ${query}
    Should Be Equal    ${value}    ${data}
    [Teardown]    CleanUp JupyterHub For N users    list_of_usernames=${list_of_usernames}


*** Keywords ***
Get Telemeter DataSource For ODS Environment
    [Documentation]    Returns the (int)datasource for telemeter
    ${env} =  Fetch ODS Cluster Environment
    ${data_source} =  Set Variable
    IF    "${env}" == "stage"
        ${data_source} =    Set Variable    ${2}
    ELSE
        ${data_source} =    Set Variable    ${1}
    END
    [Return]    ${data_source}

Begin Billing Metrics Web Test
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup

End Web Billing Metrics Test
    CleanUp JupyterHub
    SeleniumLibrary.Close All Browsers

Test Setup For Matrics Web Test
    [Documentation]     Opens openshift console metrics for metrics test
    Set Library Search Order    SeleniumLibrary
    Open Browser    ${OCP_CONSOLE_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To OCP
    Wait Until OpenShift Console Is Loaded
    Click Button    Observe
    Click Link    Metrics
    Wait Until Element is Visible    xpath://textarea[@class="pf-c-form-control query-browser__query-input"]

Test Teardown For Matrics Web Test
    [Documentation]     Closes all browsers
    SeleniumLibrary.Close All Browsers

Run Jupyter Notebook For 10 Minutes
    [Documentation]     Opens jupyter notebook and run for 10 min
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Iterative Image Test
    ...    s2i-generic-data-science-notebook
    ...    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main.git
    ...    ods-ci-notebooks-main/notebooks/200__monitor_and_manage/200__metrics/stress-cpu-all-cores-600-60.ipynb

Run Query On Metrics And Return Value
    [Documentation]    Fires query in metrics through web browser and returns value
    [Arguments]    ${query}    ${count_of_columns}    # count of columns + 1 like name,values example: ${count_of_columns}=3
    Input Text    xpath://textarea[@class="pf-c-form-control query-browser__query-input"]    ${query}
    Click Button    Run queries
    Wait Until Element is Visible    xpath://table[@class="pf-c-table pf-m-compact"]    timeout=15seconds
    @{data} =    Get WebElements    //table[@class="pf-c-table pf-m-compact"] //tbody/tr/td[${count_of_columns}]
    [Return]    ${data[0].text}

Fire Query On RHODS Prometheus And Return Value
    [Documentation]    Fires query in Prometheus through cli and returns value
    [Arguments]    ${query}
    ${expression} =    Set Variable    ${query}&step=1    #step = 1 beacuase it will return value of current second
    ${query_result} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    [Return]    ${query_result.json()["data"]["result"][0]["value"][-1]}

Skip Test If Previous CPU Usage Is Not Zero
    [Documentation]     Skips test if CPU usage is not zero
    ${metrics_value} =    Run OpenShift Metrics Query    ${METRIC_RHODS_CPU}
    ${metrics_query_results_contain_data} =    Run Keyword And Return Status    Metrics.Verify Query Results Contain Data
    IF    ${metrics_query_results_contain_data}
        Log To Console    Current CPU usage: ${metrics_value}
        Skip if
        ...    ${metrics_value} > 0
        ...    The previos CPU usage is not zero. Current CPU usage: ${metrics_value}. Skiping test
    END

Run OpenShift Metrics Query
    [Documentation]    Runs a query in the Monitoring section of Open Shift
    ...    Note: in order to run this keyword OCP_ADMIN_USER.USERNAME needs to
    ...    belong to a group with "view" role in OpenShift
    ...    Example command to assign the role: oc adm policy add-cluster-role-to-group view rhods-admins
    [Arguments]    ${query}    ${retry-attempts}=10
    Open Browser    ${OCP_CONSOLE_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    LoginPage.Login To Openshift    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    ${OCP_ADMIN_USER.AUTH_TYPE}
    OCPMenu.Switch To Administrator Perspective

    # In OCP 4.9 metrics are under the Observe menu (it was called Monitoring in 4.8)
    ${menu_observe_exists} =    Run Keyword and Return Status    Menu.Page Should Contain Menu    Observe
    IF    ${menu_observe_exists}
        Menu.Navigate To Page    Observe    Metrics
    ELSE
        ${menu_monitoring_exists} =    Run Keyword and Return Status    Menu.Page Should Contain Menu    Monitoring
        IF    ${menu_monitoring_exists}
            Menu.Navigate To Page    Monitoring    Metrics
        ELSE
            Fail
            ...    msg=${OCP_ADMIN_USER.USERNAME} can't see the Observe/Monitoring section in OpenShift Console, please make sure it belongs to a group with "view" role
        END
    END

    Metrics.Verify Page Loaded
    Metrics.Run Query    ${query}    ${retry-attempts}
    ${result} =    Metrics.Get Query Results
    [Return]    ${result}

Verify Previus CPU Usage Is Greater Than Zero
    [Documentation]     Verifies the cpu usage is greater than zero
    ${metrics_value} =    Run OpenShift Metrics Query    ${METRIC_RHODS_CPU}
    Metrics.Verify Query Results Contain Data
    Capture Page Screenshot
    Should Be True    ${metrics_value} > 0

## TODO: Add this keyword with the other JupyterHub stuff

Run Jupyter Notebook For 5 Minutes
    [Documentation]     Opens jupyter notebook and run for 5 min
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Iterative Image Test
    ...    s2i-generic-data-science-notebook
    ...    https://github.com/lugi0/minimal-nb-image-test
    ...    minimal-nb-image-test/minimal-nb.ipynb

##TODO: This is a copy of "Iterative Image Test" keyword from image-iteration.robob. We have to refactor the code not to duplicate this method

Iterative Image Test
    [Documentation]     Launch the jupyterhub and clone from ${REPO_URL},clean jupyterlab after completing
    [Arguments]    ${image}    ${REPO_URL}    ${NOTEBOOK_TO_RUN}
    Launch JupyterHub From RHODS Dashboard Link
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
    Sleep    10

CleanUp JupyterHub
    [Documentation]     Cleans JupyterHub
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Launch JupyterHub From RHODS Dashboard Link
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Page Should Not Contain    403 : Forbidden
    ${authorization_required} =    Is Service Account Authorization Required
    Run Keyword If    ${authorization_required}    Authorize jupyterhub service account
    Common.End Web Test

Skip Test If Current Active Users Count Is Not Zero
    [Documentation]     Skips test if active users count is not zero
    ${current_value} =    Run OpenShift Metrics Query    query=cluster:usage:consumption:rhods:active_users    retry-attempts=1
    IF    "${current_value}" == "${EMPTY}"
        ${current_value}    Set Variable    0
    END
    Skip if
    ...    ${current_value} > 0
    ...    The current active users count is not zero.Current Count:${current_value}.Skiping test
