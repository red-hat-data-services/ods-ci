*** Settings ***
Documentation       Queries Prometheus using API calls
Resource            ../../../Common.robot

Library             Collections
Library             Process
Library             RequestsLibrary
Library             DateTime
Library             OperatingSystem


*** Keywords ***
Get Observatorium Token
    [Documentation]  Returns the token to access observatorium
    ${data}=    Create Dictionary     grant_type=client_credentials  client_id=${STARBURST.OBS_CLIENT_ID}  client_secret=${STARBURST.OBS_CLIENT_SECRET}
    ${resp}=     RequestsLibrary.POST  ${STARBURST.OBS_TOKEN_URL}   data=${data}
    RETURN    ${resp.json()['access_token']}

Run Query
    [Documentation]    Runs a prometheus query, obtaining the current value. More info at:
    ...                - https://promlabs.com/blog/2020/06/18/the-anatomy-of-a-promql-query
    ...                - https://prometheus.io/docs/prometheus/latest/querying/api/#range-queries
    [Arguments]    ${pm_url}    ${pm_token}    ${pm_query}  ${project}=RHODS
    ${pm_headers}=    Create Dictionary    Authorization=Bearer ${pm_token}

    IF  "${project}" == "SERH"
        ${resp}=    RequestsLibrary.GET    url=${pm_url}?query=${pm_query}
        ...    headers=${pm_headers}    verify=${False}
        Status Should Be    200    ${resp}

    ELSE
        ${resp}=    RequestsLibrary.GET    url=${pm_url}/api/v1/query?query=${pm_query}
        ...    headers=${pm_headers}    verify=${False}
        Status Should Be    200    ${resp}
    END
    RETURN    ${resp}

Run Range Query
    [Documentation]    Runs a prometheus range query, in order to obtain the result of a PromQL expression over a given
    ...                time range. More info at:
    ...                - https://promlabs.com/blog/2020/06/18/the-anatomy-of-a-promql-query
    ...                - https://prometheus.io/docs/prometheus/latest/querying/api/#range-queries
    [Arguments]    ${pm_query}    ${pm_url}    ${pm_token}    ${interval}=12h     ${steps}=172
    ${time}=    Get Start Time And End Time  interval=${interval}
    ${pm_headers}=    Create Dictionary    Authorization=Bearer ${pm_token}
    ${resp}=    RequestsLibrary.GET    url=${pm_url}/api/v1/query_range?query=${pm_query}&start=${time[0]}&end=${time[1]}&step=${steps}    #robocop:disable
    ...    headers=${pm_headers}    verify=${False}
    Status Should Be    200    ${resp}
    RETURN    ${resp}

Get Start Time And End Time
    [Documentation]     Returns start and end time for Query range from current time
    [Arguments]         ${interval}   # like 12h  7 days etc
    ${end_time}=  Get Current Date
    ${end_time}=  BuiltIn.Evaluate  datetime.datetime.fromisoformat("${end_time}").timestamp()
    ${start_time}=    Subtract Time From Date    ${end_time}    ${interval}
    ${start_time}=  BuiltIn.Evaluate  datetime.datetime.fromisoformat("${start_time}").timestamp()
    @{time}=  Create List  ${start_time}  ${end_time}
    RETURN    ${time}

Get Rules
    [Documentation]    Gets Prometheus rules
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_type}
    ${pm_headers}=    Create Dictionary    Authorization=Bearer ${pm_token}
    ${resp}=    RequestsLibrary.GET    url=${pm_url}/api/v1/rules?type=${rule_type}
    ...    headers=${pm_headers}    verify=${False}
    Status Should Be    200    ${resp}
    RETURN    ${resp.json()}

Verify Rule
    [Documentation]    Verifies that a Prometheus rule exist, failing if it doesn't
    [Arguments]    ${rule_group}    @{all_rules}

    FOR    ${rule}    IN    @{all_rules}
        ${rule_name}=    Get From Dictionary    ${rule}    name
        ${rules_list}=    Get From Dictionary    ${rule}    rules

        IF    '${rule_name}' == '${rule_group}'
            ${rules_list_len}=    Get Length    ${rules_list}
            Should Be True    ${rules_list_len} != 0
            RETURN    ${TRUE}
        END
    END
    Fail    msg=${rule_group} was not found in Prometheus rules

Verify Rules
    [Documentation]    Verifies that a list of Prometheus rules exist, failing if one or more doesn't
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_type}    @{rule_groups}
    ${all_rules}=    Get Rules    ${pm_url}    ${pm_token}    ${rule_type}
    ${all_rules}=    Get From Dictionary    ${all_rules['data']}    groups

    FOR    ${rule_group}    IN    @{rule_groups}
        Prometheus.Verify Rule    ${rule_group}    @{all_rules}
    END

Alert Should Be Firing    # robocop: disable:too-many-calls-in-keyword
    [Documentation]    Fails if a Prometheus alert is not firing
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}=${EMPTY}
    ${all_rules}=    Get Rules    ${pm_url}    ${pm_token}    alert
    ${all_rules}=    Get From Dictionary    ${all_rules['data']}    groups
    ${alert_found}=    Set Variable    False

    FOR    ${rule}    IN    @{all_rules}
        ${rule_name}=    Get From Dictionary    ${rule}    name
        ${rules_list}=    Get From Dictionary    ${rule}    rules

        IF    '${rule_name}' == '${rule_group}'
            FOR    ${sub_rule}    IN    @{rules_list}
                ${state}=    Get From Dictionary    ${sub_rule}    state
                ${name}=    Get From Dictionary    ${sub_rule}    name
                ${duration}=    Get From Dictionary    ${sub_rule}    duration

                ${alert_found}=    Run Keyword And Return Status
                ...    Alerts Should Be Equal    ${alert}    ${alert-duration}    ${name}    ${duration}

                IF    ${alert_found}
                    IF    '${state}' == 'firing'
                        RETURN    ${TRUE}
                    ELSE
                        Exit For Loop
                    END
                END
            END
        END
    END

    IF    ${alert_found} == True
        # Log To Console    msg=Alert "${alert} ${alert-duration}" was found in Prometheus but state != firing
        Fail    msg=Alert "${alert} ${alert-duration}" was found in Prometheus but state != firing
    ELSE
        Log    message=ERROR: Alert "${alert} ${alert-duration}" was not found in Prometheus    level=WARN
        Fail    msg=Alert "${alert} ${alert-duration}" was not found in Prometheus
    END

Alerts Should Not Be Firing    #robocop: disable:too-many-calls-in-keyword
    [Documentation]    Fails if any Prometheus alert is in pending or firing state,
    ...  excluding alert with name = ${expected-firing-alert}
    [Arguments]    ${pm_url}    ${pm_token}    ${expected-firing-alert}=${EMPTY}     ${message_prefix}=${EMPTY}

    ${all_rules}=    Get Rules    ${pm_url}    ${pm_token}    alert
    ${all_rules}=    Get From Dictionary    ${all_rules['data']}    groups
    @{alerts_firing}=    Create List

    FOR    ${rule}    IN    @{all_rules}
        ${rule_name}=    Get From Dictionary    ${rule}    name
        ${rules_list}=    Get From Dictionary    ${rule}    rules
        FOR    ${sub_rule}    IN    @{rules_list}
            ${state}=    Get From Dictionary    ${sub_rule}    state
            ${name}=    Get From Dictionary    ${sub_rule}    name
            ${duration}=    Get From Dictionary    ${sub_rule}    duration
            IF    '${state}' in ['firing','pending']
                IF    '${name}' != '${expected-firing-alert}'
                    ${alert_info}=    Set Variable    ${name} (for:${duration}, state:${state})
                    Append To List    ${alerts_firing}    ${alert_info}
                END
            END
        END
    END
    ${alerts_firing_count}=    Get Length     ${alerts_firing}
    IF    ${alerts_firing_count} > 0
        Fail    msg=${message_prefix} Alerts should not be firing: ${alerts_firing}
    END

Alert Severity Should Be    # robocop: disable:too-many-calls-in-keyword
    [Documentation]    Fails if a given Prometheus alert does not have the expected severity
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-severity}    ${alert-duration}=${EMPTY}    #robocop:disable
    ${all_rules}=    Get Rules    ${pm_url}    ${pm_token}    alert
    ${all_rules}=    Get From Dictionary    ${all_rules['data']}    groups
    ${alert_found}=    Set Variable    False

    FOR    ${rule}    IN    @{all_rules}
        ${rule_name}=    Get From Dictionary    ${rule}    name
        ${rules_list}=    Get From Dictionary    ${rule}    rules

        IF    '${rule_name}' == '${rule_group}'
            FOR    ${sub_rule}    IN    @{rules_list}
                ${state}=    Get From Dictionary    ${sub_rule}    state
                ${name}=    Get From Dictionary    ${sub_rule}    name
                ${duration}=    Get From Dictionary    ${sub_rule}    duration
                ${labels}=    Get From Dictionary    ${sub_rule}    labels
                ${severity}=    Get From Dictionary    ${labels}    severity

                ${alert_found}=    Run Keyword And Return Status
                ...    Alerts Should Be Equal    ${alert}    ${alert-duration}    ${name}    ${duration}

                IF    ${alert_found}
                    IF    '${severity}' == '${alert-severity}'
                        RETURN    ${TRUE}
                    ELSE
                        Exit For Loop
                    END
                END
            END
        END
    END

    IF    ${alert_found} == True
        # Log To Console    msg=Alert "${alert} ${alert-duration}" was found in Prometheus but state != firing
        Fail    msg=Alert "${alert} ${alert-duration}" was found in Prometheus but severity != ${alert-severity}
    ELSE
        Log    message=ERROR: Alert "${alert} ${alert-duration}" was not found in Prometheus    level=WARN
        Fail    msg=Alert "${alert} ${alert-duration}" was not found in Prometheus
    END

Alerts Should Be Equal
    [Documentation]    Compares two alerts names and fails if they are different.
    ...    If ${alert1-duration} is not empty, compare it also with ${alert2-duration}
    [Tags]    Private
    [Arguments]    ${alert1-name}    ${alert1-duration}    ${alert2-name}    ${alert2-duration}
    Should Be Equal    ${alert1-name}    ${alert2-name}
    IF    "${alert1-duration}" != "${EMPTY}"
        Should Be Equal As Strings    ${alert1-duration}    ${alert2-duration}
    END

Alert Should Not Be Firing
    [Documentation]    Fails if a Prometheus alert is firing
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}=${EMPTY}
    ${is_alert_firing}=    Run Keyword And Return Status
    ...    Alert Should Be Firing
    ...    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}
    Should Be True    not ${is_alert_firing}    msg=Alert ${alert} should not be firing

Alert Should Not Be Firing In The Next Period    # robocop: disable:too-many-arguments
    [Documentation]    Fails if a Prometheus alert is firing in the next ${period}
    ...    ${period} should be 1m or bigger
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}
    ...    ${alert-duration}=${EMPTY}    ${period}=10 min

    ${passed}=    Run Keyword And Return Status    Wait Until Alert Is Firing
    ...    pm_url=${pm_url}    pm_token=${pm_token}    rule_group=${rule_group}
    ...    alert=${alert}    alert-duration=${alert-duration}    timeout=${period}
    IF    ${passed}    Fail    msg=Alert ${alert} should not be firing

Wait Until Alert Is Firing    # robocop: disable:too-many-arguments
    [Documentation]    Waits until alert is firing or timeout is reached (failing in that case),
    ...    checking the alert state every 30 seconds
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}
    ...    ${alert}    ${alert-duration}=${EMPTY}    ${timeout}=10 min
    Wait Until Keyword Succeeds    ${timeout}    30s
    ...    Alert Should Be Firing    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}

Wait Until Alert Is Not Firing    # robocop: disable:too-many-arguments
    [Documentation]    Waits until alert is not firing or timeout is reached (failing in that case),
    ...    checking the alert state every 30 seconds
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}
    ...    ${alert}    ${alert-duration}=${EMPTY}    ${timeout}=5 min
    Wait Until Keyword Succeeds    ${timeout}    30s
    ...    Alert Should Not Be Firing    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}

Get Target Endpoints
    [Documentation]     Returns list of Endpoint URLs
    [Arguments]         ${target_name}    ${pm_url}    ${pm_token}    ${username}    ${password}
    ${links}=    Run  curl --silent -X GET -H "Authorization:Bearer ${pm_token}" -u ${username}:${password} -k ${pm_url}/api/v1/targets | jq '.data.activeTargets[] | select(.scrapePool == "${target_name}") | .globalUrl'       #robocop:disable
    ${links}=    Replace String    ${links}    "    ${EMPTY}
    @{links}=    Split String  ${links}  \n
    RETURN    ${links}

Get Target Endpoints Which Have State Up
    [Documentation]    Returns list of endpoints who have state is "UP"
    [Arguments]        ${target_name}    ${pm_url}    ${pm_token}    ${username}    ${password}
    ${links}=    Run  curl --silent -X GET -H "Authorization:Bearer ${pm_token}" -u ${pm_token}:${password} -k ${pm_token}/api/v1/targets | jq '.data.activeTargets[] | select(.scrapePool == "${target_name}") | select(.health == "up") | .globalUrl'    #robocop:disable
    ${links}=    Replace String    ${links}    "    ${EMPTY}
    @{links}=    Split String  ${links}  \n
    RETURN    ${links}

Get Date When Availability Value Matches Expected Value
    [Documentation]    Returns date when availability value matches expected value
    ...    Args:
    ...        expected_value: expected availability value
    [Arguments]    ${expected_value}
    ${resp}=    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}   rhods_aggregate_availability
    ${date}=    Convert Date    ${resp.json()["data"]["result"][0]["value"][0]}    epoch
    ${value}=    Set Variable    ${resp.json()["data"]["result"][0]["value"][1]}
    Should Match    ${value}    ${expected_value}
    RETURN    ${date}

Verify ODS Availability
    [Documentation]    Verifies that there is no downtime in ODS
    ...    Returns:
    ...        None
    ${expression}=    Set Variable    rhods_aggregate_availability[10m : 1m]
    ${resp}=    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    @{values}=    Set Variable    ${resp.json()["data"]["result"][0]["values"]}
    FOR    ${value}    IN    @{values}
        Should Not Be Equal As Strings    ${value}[1]    0
    END

Verify ODS Availability Range
    [Documentation]   Verifies that there is no downtime in ODS between start and end dates
    ...    Returns:
    ...        None
    [Arguments]   ${start}   ${end}    ${step}=1s    ${component}=${EMPTY}
    IF    "${component}" == "${EMPTY}"
        Log   Component Empty
    ELSE IF    "${component}" == "jupyterhub"
        Set Local Variable    ${component}   instance=~"jupyterhub.*"
    ELSE IF    "${component}" == "rhods-dashboard"
        Set Local Variable    ${component}   instance=~"rhods-dashboard.*"
    ELSE IF    "${component}" == "combined"
        Set Local Variable    ${component}   instance="combined"
    ELSE
        Fail   msg="Unknown component: ${component} (expected: jupyterhub, rhods-dashboard, combined)"
    END

    &{expression}=    Create Dictionary    query=rhods_aggregate_availability{${component}}    start=${start}    end=${end}    step=${step}
    ${resp}=    Run Query Range        &{expression}
    @{values}=    Set Variable    ${resp.json()["data"]["result"][0]["values"]}
    @{downtime}=    Create List
    FOR    ${value}    IN    @{values}
        IF    ${value[1]} == 0
            Append To List    ${downtime}    ${value[0]}
        END
    END
    Log Many   @{downtime}
    IF    "@{downtime}" != "${EMPTY}"
        ${downtime_length}=    Get Length    ${downtime}
        IF   ${downtime_length} == 0
            Log    message=ODS is not down ${values}
        ELSE IF   ${downtime_length} == 1
            Fail  msg=There is a Downtime at ${downtime-duration}[0] in ODS
        ELSE
            ${downtime_lower_value}=    Convert Date    ${downtime}[0]
            ${downtime_upper_value}=    Convert Date    ${downtime}[-1]
            ${downtime-duration}=  Subtract Date From Date    ${downtime_upper_value}    ${downtime_lower_value}    compact
            Fail    msg=There is a Downtime of ${downtime-duration} in ODS
        END
    END
    RETURN   ${values}

Run Query Range
    [Documentation]    Runs a Prometheus query using the API
    [Arguments]   &{pm_query}
    ${pm_headers}=    Create Dictionary    Authorization=Bearer ${RHODS_PROMETHEUS_TOKEN}
    ${resp}=    RequestsLibrary.GET    url=${RHODS_PROMETHEUS_URL}/api/v1/query_range   params=&{pm_query}
    ...    headers=${pm_headers}    verify=${False}
    Request Should Be Successful
    RETURN    ${resp}
