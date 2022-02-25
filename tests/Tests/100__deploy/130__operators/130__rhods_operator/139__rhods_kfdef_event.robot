*** Settings ***
Documentation   139 - KFDEF_EVENT_VERIFICATION
...             Verify kfdef event is streaming for redhat-ods-application namespace
...
...             = Variables =
...             | Namespace                | Required |        RHODS Namespace/Project |
...             | Resource_kind            | Required |        Object resource kind |

Library        Collections
Resource       ../../../../Resources/Page/OCPDashboard/Events/Events.resource


*** Variables ***
${NAMESPACE}           redhat-ods-applications
${RESOURCE_KIND}       KfDef


*** Test Cases ***
Verify KFDEF Is Streaming Event
    [Documentation]    Perform kfdef event streaming
    ...   in openshift after RHODS deployment
    [Tags]    Sanity
    ...       ODS-1005
    ${ev_data}    Get Openshift Event    ${NAMESPACE}
    ...    ${RESOURCE_KIND}    2
    Verify KFDEF Event Status    ${ev_data}


*** Keywords ***
Verify KFDEF Event Status
    [Documentation]    Verify if kfdef event is good and status is Normal
    [Arguments]     ${kfdef_data}
    FOR    ${element}    IN    @{kfdef_data}
        ${name}     Set Variable   ${element['involvedObject']['name']}
        Should Be Equal As Strings    ${element['message']}
        ...    KfDef instance ${name} created and deployed successfully
        Should Be Equal As Strings    ${element['type']}    Normal
    END
