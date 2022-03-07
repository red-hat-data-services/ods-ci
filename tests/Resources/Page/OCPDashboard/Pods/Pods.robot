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

Get Containers With Non Zero Restart Counts
    [Documentation]    Get the container name with restart
    ...    count for each pod provided
    [Arguments]        ${pod_names}   ${namespace}
    ${pod_restarts}      Create Dictionary
    FOR    ${pod_name}    IN    @{pod_names}
        ${container_restarts}    Create Dictionary
        ${data}    OpenShiftCLI.Get   kind=Pod     namespace=${namespace}   field_selector=metadata.name==${pod_name}
        FOR    ${index}    ${container}    IN ENUMERATE    @{data[0]['status']['containerStatuses']}
               ${value}    Convert To Integer    ${container['restartCount']}
               IF    ${value} > ${0}
                    Set To Dictionary    ${container_restarts}     ${container['name']}    ${value}
               END
        END
        Set To Dictionary    ${pod_restarts}    ${pod_name}    ${container_restarts}
    END
    [Return]    ${pod_restarts}

Verify Containers Have Zero Restarts
    [Documentation]    Get and verify container restart
    ...    Counts for pods
    [Arguments]    ${pod_names}    ${namespace}
    ${pod_restart_data}    Get Containers With Non Zero Restart Counts    ${pod_names}    ${namespace}
    FOR    ${pod_name}    ${container_details}    IN    &{pod_restart_data}
        IF    len(${container_details}) > ${0}
            Run Keyword And Continue On Failure    FAIL
            ...    Container restart "${container_details}" found for '${pod_name}' pod.
        ELSE
            Log    No container with restart count found!
        END
    END

Verify Container Image
    [Documentation]  Checks if the container image matches  $expected-image-url 
    [Arguments]   ${namespace}  ${pod}  ${container}  ${expected-image-url}
    ${image} =  Run  oc get pod ${pod} -n ${namespace} -o json | jq '.spec.containers[] | select(.name == "${container}") | .image'
    Should Be Equal  ${image}  ${expected-image-url}

Search Pod
    [Documentation]   Return list of pods   pod_start_with = here ypu have to provide starting of pod name
    [Arguments]   ${namespace}  ${pod_start_with}
    ${pod} =  Run  oc get pods -n ${namespace} -o json | jq '.items[] | select(.metadata.name | startswith("${pod_start_with}")) | .metadata.name'
    @{list_pods} =  Split String  ${pod}  \n
    [Return]  ${list_pods}[0]
