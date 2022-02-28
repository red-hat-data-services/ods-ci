*** Settings ***
Documentation       Collection of keywords to work with Pods

Library             OpenShiftCLI
Resource            ../../OCPDashboard/Page.robot
Resource            ../../ODH/ODHDashboard/ODHDashboard.robot
Library             ../../../../libs/Helpers.py


*** Keywords ***
Get Pod Logs From UI
    [Documentation]    Get pod logs text from OCP UI
    [Arguments]    ${namespace}    ${pod_search_term}
    Navigate To Page    Workloads    Pods
    Search Last Item Instance By Title In OpenShift Table    search_term=${pod_search_term}
    ...    namespace=${namespace}
    Click Link    xpath://tr[@data-key='0-0']/td/span/a
    Click Link    Logs
    Sleep    4
    Capture Page Screenshot    logs_page.png
    ${log_lines_flag}=    Run Keyword And Return Status    Wait Until Page Contains Element
    ...    xpath://div[@class='log-window__lines']
    ${log_list_flag}=    Run Keyword And Return Status    Wait Until Page Contains Element
    ...    xpath://div[@class='pf-c-log-viewer__list']
    IF    ${log_lines_flag} == ${TRUE}
        ${logs_text}=    Get Text    xpath://div[@class='log-window__lines']
    ELSE IF    ${log_list_flag} == ${TRUE}
        Click Link    Raw
        Switch Window    NEW
        ${logs_text}=    Get Text    xpath://pre
        Close Window
        Switch Window    MAIN
    ELSE
        Fail    No logs window found..
    END
    ${log_rows}=    Text To List    ${logs_text}
    [Return]    ${log_rows}

Delete Pods Using Label Selector
    [Documentation]    Deletes an openshift pod by label selector
    [Arguments]    ${namespace}    ${label_selector}
    ${status}=    Check If POD Exists    ${namespace}    ${label_selector}
    Run Keyword IF    '${status}'=='PASS'    OpenShiftCLI.Delete    kind=Pod    namespace=${namespace}
    ...    label_selector=${label_selector}    ELSE    FAIL
    ...    No PODS present with Label '${label_selector}' in '${namespace}' namespace, Check the label selector and namespace provide is correct and try again
    Sleep    2
    ${status}=    Check If POD Exists    ${namespace}    ${label_selector}
    Run Keyword IF    '${status}'!='FAIL'    FAIL
    ...    PODS with Label '${label_selector}' is not deleted in '${namespace}' namespace

Check If POD Exists
    [Documentation]    Check existence of an openshift pod by label selector
    [Arguments]    ${namespace}    ${label_selector}
    ${status}    ${val}=    Run Keyword And Ignore Error    OpenShiftCLI.Get    kind=Pod    namespace=${namespace}
    ...    label_selector=${label_selector}
    [Return]    ${status}

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
