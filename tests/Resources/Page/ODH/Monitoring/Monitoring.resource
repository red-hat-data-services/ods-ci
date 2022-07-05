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
    [Return]    ${value}

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
    [Return]    ${availability}

Fail If Average Availability For Time Range Breached SLA
    [Documentation]    Gets Average Availability for ${time_range} and Fails test if the value is under 99.95
    [Arguments]    ${pm_url}    ${pm_token}    ${time_range}=15m
    ${availability}=    Get Average Availability For Time Range    ${pm_url}    ${pm_token}    ${time_range}
    IF    ${availability} < ${SLA_AVAILABILITY}
        Fail    ODS Availability is currently breaching SLA: ${availability} < ${SLA_AVAILABILITY} (time-range:${time_range})
    END

Log Availability Comparison    #robocop:disable:too-many-arguments
    [Documentation]    Gets Average Availability for ${time_range}, compares with ${previous_value} and
    ...    Logs a WARN message if current availability < ${previous_value}
    [Arguments]    ${message_prefix}    ${previous_value}    ${pm_url}    ${pm_token}    ${time_range}=15m    ${precision}=2    #robocop:disable:line-too-long

    ${current_availability}=    Get Average Availability For Time Range
    ...    ${pm_url}    ${pm_token}    ${time_range}    ${precision}
    IF    ${current_availability} < ${previous_value}
        #robocop:disable
        ${message}=    Set Variable
        ...    ${message_prefix}ODS Availability is worse than previous value: ${current_availability} < ${previous_value} (time_range:${time_range})
        Log    message=${message}    level=WARN    console=False
    ELSE
        #robocop:disable
        ${message}=    Set Variable
        ...    ${message_prefix}ODS Availability is equal or better than previous value: ${current_availability} >= ${previous_value} (time_range:${time_range})
        Log    message=${message}    level=INFO    console=False
    END

Suite Availability Setup
    [Documentation]    Obtains and stores Average Availability for the last 2m, 15m, 1h and 3h
    ...    Log a WARN message if availability is under 99.95
    [Arguments]    ${pm_url}    ${pm_token}

    ${availability}=    Log If Average Availability For Time Range Breached SLA    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=2m    message_prefix=Suite Setup: ${SUITE NAME}:
    Set Global Variable    ${SUITE_AVAILABILITY_2M}    ${availability}

    ${availability}=    Log If Average Availability For Time Range Breached SLA    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=15m    message_prefix=Suite Setup: ${SUITE NAME}:
    Set Global Variable    ${SUITE_AVAILABILITY_15M}    ${availability}

    ${availability}=    Log If Average Availability For Time Range Breached SLA    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=1h    message_prefix=Suite Setup: ${SUITE NAME}:
    Set Global Variable    ${SUITE_AVAILABILITY_1H}    ${availability}

    ${availability}=    Log If Average Availability For Time Range Breached SLA    pm_url=${pm_url}
    ...    pm_token=${pm_token}    time_range=3h    message_prefix=Suite Setup: ${SUITE NAME}:
    Set Global Variable    ${SUITE_AVAILABILITY_3H}    ${availability}

Suite Availability Teardown
    [Documentation]    Compare current Average Availability with the values stored in Suite Availability.
    ...    Logs a WARN message if the current values are lower
    [Arguments]    ${pm_url}    ${pm_token}

    Log Availability Comparison    message_prefix=Suite Teardown: ${SUITE NAME}:
    ...    previous_value=${SUITE_AVAILABILITY_2M}    pm_url=${pm_url}    pm_token=${pm_token}    time_range=2m

    Log Availability Comparison    message_prefix=Suite Teardown: ${SUITE NAME}:
    ...    previous_value=${SUITE_AVAILABILITY_15M}    pm_url=${pm_url}    pm_token=${pm_token}    time_range=15m

    Log Availability Comparison    message_prefix=Suite Teardown: ${SUITE NAME}:
    ...    previous_value=${SUITE_AVAILABILITY_1H}    pm_url=${pm_url}    pm_token=${pm_token}    time_range=1h

    Log Availability Comparison    message_prefix=Suite Teardown: ${SUITE NAME}:
    ...    previous_value=${SUITE_AVAILABILITY_3H}    pm_url=${pm_url}    pm_token=${pm_token}    time_range=3h
