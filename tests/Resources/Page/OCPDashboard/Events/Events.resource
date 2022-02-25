*** Settings ***
Documentation       Keyword Suites to work with Openshift Events

Library             Collections
Library             OpenShiftCLI


*** Keywords ***
Get Openshift Event
    [Documentation]    Capture openshift event based on namespace
    ...    and return filtered data, fail if no events are captured
    [Arguments]    ${namespace}    ${object_kind}    ${expected-events-count}=1
    ${data}    Run Keyword    OpenShiftCLI.Get    kind=Event    namespace=${namespace}
    IF    len(${data}) >= ${expected-events-count}
        ${res_data}    Get Data Based On Object Kind    ${data}    ${object_kind}
    ELSE
        FAIL    All the Events are not captured
    END
    [Return]    ${res_data}

Get Data Based On Object Kind
    [Documentation]    Compare and filter data
    ...    from the provided payload based
    ...    on object kind and return the data
    ...    in new list
    [Arguments]    ${data}    ${resource_kind}
    [Tags]    Private
    @{tem_data}    Create List
    FOR    ${element}    IN    @{data}
        IF    '${element['involvedObject']['kind']}' == '${resource_kind}'
            Append To List    ${tem_data}    ${element}
        END
    END
    [Return]    ${tem_data}
