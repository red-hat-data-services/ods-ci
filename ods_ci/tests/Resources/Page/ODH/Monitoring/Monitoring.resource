*** Settings ***
Documentation       Contains ODS Monitoring Keywords

Resource            ../Prometheus/Prometheus.resource


*** Variables ***
${SLA_AVAILABILITY}             99.95
${SUITE_AVAILABILITY_2M}        0
${SUITE_AVAILABILITY_15M}       0
${SUITE_AVAILABILITY_1H}        0
${SUITE_AVAILABILITY_3H}        0


*** Keywords ***
Get Average Availability For Time Range
    [Documentation]    Returns the average availability of ODS for a time range
    ...    querying the Prometheus instance at ${pm_url} using token ${pm_token}.
    ...
    ...    returns =    avg_over_time(rhods_aggregate_availability[${time_range}]) * 100
    [Arguments]    ${pm_url}    ${pm_token}    ${time_range}=15m    ${precision}=2
    ${response}=    Prometheus.Run Query
    ...    pm_url=${pm_url}
    ...    pm_token=${pm_token}
    ...    pm_query=avg_over_time(rhods_aggregate_availability[${time_range}])*100
    ${value}=    Set Variable    ${response.json()["data"]["result"][0]["value"][-1]}
    ${value}=    Convert To Number    ${value}    ${precision}
    RETURN    ${value}

Create Suite Availability Checkpoint
    [Documentation]    Obtains and stores Average Availability for the last 2m, 15m, 1h and 3h
    [Arguments]    ${pm_url}    ${pm_token}      ${message_prefix}=${EMPTY}

    ${availability}=    Get Average Availability For Time Range    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=2m
    Set Global Variable    ${SUITE_AVAILABILITY_2M}    ${availability}

    ${availability}=    Get Average Availability For Time Range    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=15m
    Set Global Variable    ${SUITE_AVAILABILITY_15M}    ${availability}

    ${availability}=    Get Average Availability For Time Range    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=1h
    Set Global Variable    ${SUITE_AVAILABILITY_1H}    ${availability}

    ${availability}=    Get Average Availability For Time Range    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=3h
    Set Global Variable    ${SUITE_AVAILABILITY_3H}    ${availability}

#robocop:disable
Log If Availability Decreased Since Suite Availability Checkpoint
    [Documentation]    Obtains current Average Availability for the last 2m, 15m, 1h and 3h and
    ...    Logs a WARN message in case it decreased, and an INFO message if it's the same or better
    [Arguments]    ${pm_url}    ${pm_token}    ${message_prefix}=${EMPTY}

    ${availability_decreased}=    Set Variable    False

    ${current_availability}=    Get Average Availability For Time Range    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=2m
    IF    ${current_availability} < ${SUITE_AVAILABILITY_2M}
        ${availability_decreased}=    Set Variable    True
    END
    ${availability_info}=    Set Variable    2m: ${current_availability} vs ${SUITE_AVAILABILITY_2M};

    ${current_availability}=    Get Average Availability For Time Range    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=15m
    IF    ${current_availability} < ${SUITE_AVAILABILITY_15M}
        ${availability_decreased}=    Set Variable    True
    END
    ${availability_info}=    Set Variable    ${availability_info} 15m: ${current_availability} vs ${SUITE_AVAILABILITY_15M};

    ${current_availability}=    Get Average Availability For Time Range    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=1h
    IF    ${current_availability} < ${SUITE_AVAILABILITY_1H}
        ${availability_decreased}=    Set Variable    True
    END
    ${availability_info}=    Set Variable    ${availability_info} 1h: ${current_availability} vs ${SUITE_AVAILABILITY_1H};

    ${current_availability}=    Get Average Availability For Time Range    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=3h
    IF    ${current_availability} < ${SUITE_AVAILABILITY_3H}
        ${availability_decreased}=    Set Variable    True
    END
    ${availability_info}=    Set Variable    ${availability_info} 3h: ${current_availability} vs ${SUITE_AVAILABILITY_3H}

    IF    ${availability_decreased} == True
        ${message}=    Set Variable
        ...    ${message_prefix} Average Availability decreased since previous checkpoint: (${availability_info})
        Log    message=${message}    level=WARN    console=False
    ELSE
        ${message}=    Set Variable
        ...    ${message_prefix} Average Availability not decreased since previous checkpoint: (${availability_info})
        Log    message=${message}    level=INFO    console=False
    END

Log If Average Availability For Time Range Breached SLA
    [Documentation]    Gets Average Availability for ${time_range} and Logs a WARN message
    ...    if the value is under 99.95
    ...    returns =    avg_over_time(rhods_aggregate_availability[${time_range}]) * 100
    [Arguments]    ${pm_url}    ${pm_token}    ${time_range}=15m    ${message_prefix}=${EMPTY}
    ${availability}=    Get Average Availability For Time Range    ${pm_url}    ${pm_token}    ${time_range}
    IF    ${availability} < ${SLA_AVAILABILITY}
        #robocop:disable
        ${message}=    Set Variable
        ...    ${message_prefix}ODS Availability is currently breaching SLA: ${availability} < ${SLA_AVAILABILITY} (time-range:${time_range})
        Log    message=${message}    level=WARN    console=False
    END
    RETURN    ${availability}

Fail If Average Availability For Time Range Breached SLA
    [Documentation]    Gets Average Availability for ${time_range} and Fails test if the value is under 99.95
    [Arguments]    ${pm_url}    ${pm_token}    ${time_range}=15m
    ${availability}=    Get Average Availability For Time Range    ${pm_url}    ${pm_token}    ${time_range}
    IF    ${availability} < ${SLA_AVAILABILITY}
        Fail    ODS Availability is currently breaching SLA: ${availability} < ${SLA_AVAILABILITY} (time-range:${time_range})
    END

Suite Availability Setup
    [Documentation]    Obtains and stores Average Availability for the last 2m, 15m, 1h and 3h
    ...    Log a WARN message if availability is under 99.95 or an alert is firing
    [Arguments]    ${pm_url}    ${pm_token}
    Run Keyword And Warn On Failure
    ...    Create Suite Availability Checkpoint    pm_url=${pm_url}    pm_token=${pm_token}
    Run Keyword And Warn On Failure    Alerts Should Not Be Firing
    ...    pm_url=${pm_url}    pm_token=${pm_token}    expected-firing-alert=DeadManSnitch
    ...    message_prefix=Suite Setup: ${SUITE NAME}:

Suite Availability Teardown
    [Documentation]    Compare current Average Availability with the values stored in Suite Availability.
    ...    Logs a WARN message if the current values are lower or an alert is firing
    [Arguments]    ${pm_url}    ${pm_token}
    Run Keyword And Warn On Failure
    ...    Log If Availability Decreased Since Suite Availability Checkpoint     pm_url=${pm_url}    pm_token=${pm_token}
    ...    message_prefix=Suite Trdwn: ${SUITE NAME}:
    Run Keyword And Warn On Failure    Alerts Should Not Be Firing
    ...    pm_url=${pm_url}    pm_token=${pm_token}    expected-firing-alert=DeadManSnitch
    ...    message_prefix=Suite Trdwn: ${SUITE NAME}:

Get OpenShift Thanos URL
    [Documentation]    Fetches the thanos URL from the OpenShift cluster
    ${url}=    Oc Get    kind=Route    name=thanos-querier    namespace=openshift-monitoring
    ...    fields=['status.ingress[0].host']
    RETURN   ${url}[0][status.ingress[0].host]

Generate Thanos Token
    [Documentation]    Fetch user token to access thanos-querier.
    ${rc}    ${out}=    Run And Return Rc And Output    oc whoami -t
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${out}

Get Thanos Metrics List
    [Documentation]    Gets the list of metrics available in thanos-querier and their type
    ...                (e.g., counter, histogram, etc)
    [Arguments]    ${thanos_url}    ${thanos_token}    ${search_text}=${EMPTY}
    ${cmd}=    Set Variable    curl -k -H "Authorization: Bearer ${thanos_token}" https://${thanos_url}/api/v1/label/__name__/values
    IF    "${search_text}" == "${EMPTY}"
        ${cmd}=    Catenate    ${cmd}    | jq '.data'
    ELSE
        ${cmd}=    Catenate    ${cmd} | jq '.data[]' | grep ${search_text}
    END
    ${rc}    ${out}=    Run And Return Rc And Output    ${cmd} | tr -d '"'
    RETURN    ${out}
