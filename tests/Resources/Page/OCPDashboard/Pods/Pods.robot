*** Settings ***
Library    OpenShiftCLI
Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot
Library    ../../../../libs/Helpers.py

*** Keywords ***
Get Pod Logs From UI
  [Arguments]  ${namespace}  ${pod_search_term}
  Navigate To Page    Workloads    Pods
  Search Last Item Instance By Title in OpenShift Table  search_term=${pod_search_term}  namespace=${namespace}
  Click Link    xpath://tr[@data-key='0-0']/td/span/a
  Click Link    Logs
  Sleep  4
  Capture Page Screenshot  logs_page.png
  ${logs_text}=  Get Text    xpath://div[@class='log-window__lines']
  ${log_rows}=  Text To List  ${logs_text}
  [Return]  ${log_rows}

Delete Pods Using Label Selector
    [Arguments]   ${namespace}                ${label_selector}
    ${status}      Check If POD Exists       ${namespace}        ${label_selector}
    Run Keyword IF          '${status}'=='PASS'   OpenShiftCLI.Delete   kind=Pod     namespace=${namespace}   label_selector=${label_selector}
    ...        ELSE      FAIL        No PODS present with Label '${label_selector}' in '${namespace}' namespace, Check the label selector and namespace provide is correct and try again
    Sleep    2
    ${status}      Check If POD Exists       ${namespace}        ${label_selector}
    Run Keyword IF          '${status}'!='FAIL'     FAIL        PODS with Label '${label_selector}' is not deleted in '${namespace}' namespace

Check If POD Exists
    [Arguments]   ${namespace}   ${label_selector}
    ${status}     ${val}       Run keyword and Ignore Error   OpenShiftCLI.Get   kind=Pod     namespace=${namespace}   label_selector=${label_selector}
    [Return]   ${status}

Verify Operator Pod Status
    [Documentation]    Verify Pod status
    [Arguments]  ${namespace}   ${label_selector}  ${expected_status}=Running
    ${status}    Get Pod Status    ${namespace}    ${label_selector}
    Run Keyword IF   $status != $expected_status     Fail     RHODS operator status is
    ...    not matching with the expected state

Get Pod Name
    [Documentation]    Get the POD name based on namespace and label selector
    [Arguments]   ${namespace}   ${label_selector}
    ${data}       Run Keyword   OpenShiftCLI.Get   kind=Pod
    ...    namespace=${namespace}   label_selector=${label_selector}
    [Return]      ${data[0]['metadata']['name']}

Get Pod Status
    [Documentation]    Get the Pod status based on namespace and label selector
    [Arguments]   ${namespace}   ${label_selector}
    ${data}       Run Keyword   OpenShiftCLI.Get   kind=Pod
    ...    namespace=${namespace}   label_selector=${label_selector}
    [Return]      ${data[0]['status']['phase']}

Get POD Names
    [Documentation]    Get the name of list based on
    ...    namespace and label selector and return the
    ...    name of all the pod with matching label selector
    [Arguments]   ${namespace}   ${label_selector}
    ${pod_name}    Create List
    ${status}      Check If POD Exists       ${namespace}        ${label_selector}
    IF    '${status}'=='PASS'
         ${data}        OpenShiftCLI.Get   kind=Pod     namespace=${namespace}   label_selector=${label_selector}
         FOR    ${index}    ${element}    IN ENUMERATE    @{data}
                Append To List    ${pod_name}     ${data[${index}]['metadata']['name']}
         END
    ELSE
         FAIL    No POD found with the provided label selector in a given namespace '${namespace}'
    END
    [Return]    ${pod_name}

Get Container Restart Counts
    [Documentation]    Get the container name with restart
    ...    count for each pod provided
    [Arguments]        ${name}   ${namespace}
    ${restart_c}      Create Dictionary
    FOR    ${element}    IN    @{name}
        ${c_detail}    Create Dictionary
        ${data}    OpenShiftCLI.Get   kind=Pod     namespace=${namespace}   field_selector=metadata.name==${element}
        FOR    ${index}    ${container}    IN ENUMERATE    @{data[0]['status']['containerStatuses']}
               ${value}    Convert To Integer    ${container['restartCount']}
               IF    ${value} > ${0}
                    Set To Dictionary    ${c_detail}     ${container['name']}    ${value}
               END
        END
        Set To Dictionary    ${restart_c}    ${element}    ${c_detail}
    END
    [Return]    ${restart_c}
