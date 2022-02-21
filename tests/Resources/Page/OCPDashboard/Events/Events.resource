*** Settings ***
Documentation       Keyword Suites to work with Openshift Events

Library             Collections
Library             OpenShiftCLI


*** Keywords ***
Get Event Entry From Openshift
    [Documentation]    Capture openshift event based on namespace
    ...    and return filtered data
    [Arguments]    ${namespace}    ${object_kind}    ${expected_event}=2
    ${data}    Run Keyword    OpenShiftCLI.Get    kind=Event    namespace=${namespace}
    IF    len(${data}) >= ${expected_event}
        ${res_data}    Get Data Based On Object Kind    ${data}    ${object_kind}
    ELSE
        FAIL    All the Event not captured
    END
    [Return]    ${res_data}

Get Data Based On Object Kind
    [Documentation]    Compare and fiter data
    ...    from the provided payload based
    ...    on object kind and retrun the data
    ...    in new list
    [Arguments]    ${data}    ${resource_kind}
    @{tem_data}    Create List
    FOR    ${element}    IN    @{data}
        IF    '${element['involvedObject']['kind']}' == '${resource_kind}'
            Append To List    ${tem_data}    ${element}
        END
    END
    [Return]    ${tem_data}
