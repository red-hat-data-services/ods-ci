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

Set Thanos Credentials Variables
    ${thanos_url}=    Get OpenShift Thanos URL
    ${token}=    Generate Thanos Token
    Set Suite Variable    ${THANOS_URL}    ${thanos_url}
    Set Suite Variable    ${THANOS_TOKEN}    ${token}

Metrics Should Exist In UserWorkloadMonitoring
    [Documentation]    Checks that the given ${metrics_searches} exists. It also accepts partial names.
    ...                Returns the complete list of metrics found with the given search texts
    [Arguments]    ${thanos_url}    ${thanos_token}    ${search_metrics}
    ${metrics}=    Create List
    FOR    ${index}    ${metric_search_text}    IN ENUMERATE    @{search_metrics}
        Log    ${index}: ${metric_search_text}
        ${metrics_names}=    Get Thanos Metrics List    thanos_url=${thanos_url}    thanos_token=${thanos_token}
        ...    search_text=${metric_search_text}
        ${found} =    Run Keyword And Return Status    Should Not Be Empty    ${metrics_names}
        IF  ${found}
            ${metrics_names}=    Split To Lines    ${metrics_names}
            Append To List    ${metrics}    @{metrics_names}
        ELSE
            Run Keyword And Continue On Failure    Fail    msg=${metric_search_text} not found
        END
    END
    RETURN    ${metrics}
