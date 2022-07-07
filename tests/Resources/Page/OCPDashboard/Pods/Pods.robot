*** Settings ***
Documentation       Collection of keywords to work with Pods

Resource            ../../OCPDashboard/Page.robot
Resource            ../../ODH/ODHDashboard/ODHDashboard.robot
Library             ../../../../libs/Helpers.py


*** Keywords ***
Get Pod Logs From UI
    [Documentation]    Get pod logs text from OCP UI ${container_button_id} is button id on log page
    [Arguments]    ${namespace}    ${pod_search_term}   ${container_button_id}=${EMPTY} 
    Navigate To Page    Workloads    Pods
    Search Last Item Instance By Title In OpenShift Table    search_term=${pod_search_term}
    ...    namespace=${namespace}
    Click Link    xpath://tr[@data-key='0-0']/td/span/a
    IF    "${container_button_id}" == "${EMPTY}"
        Click Link    Logs
        Sleep    4
        Capture Page Screenshot    logs_page.png
    ELSE
        Go To Log Tab And Select A Container  container_button_id=${container_button_id}
    END
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
    [Documentation]   Returns list pod  ${pod_start_with} = here ypu have to provide starting of pod name
    [Arguments]   ${namespace}  ${pod_start_with}
    ${pod} =  Run  oc get pods -n ${namespace} -o json | jq '.items[] | select(.metadata.name | startswith("${pod_start_with}")) | .metadata.name'
    @{list_pods} =  Split String  ${pod}  \n
    [Return]  ${list_pods}

Run Command In Container
    [Documentation]    Executes a command in a container.
    ...    If ${container_name} is omitted, the first container in the pod will be chosen
    [Arguments]    ${namespace}    ${pod_name}    ${command}    ${container_name}=${EMPTY}
    IF    "${container_name}" == "${EMPTY}"
        ${output}    Run    oc exec ${pod_name} -n ${namespace} -- ${command}
    ELSE
        ${output}    Run    oc exec ${pod_name} -n ${namespace} -c ${container_name} -- ${command}
    END
    [Return]    ${output}

Wait Until Container Exist
    [Documentation]     Waits until container is exists
    [Arguments]     ${namespace}    ${pod_name}    ${container_to_check}    ${timeout}=5 min
    Wait Until Keyword Succeeds    ${timeout}    1 min
    ...    Check Is Container Exist    namespace=${namespace}  pod_name=${pod_name}  container_to_check=${container_to_check}

Check Is Container Exist
    [Documentation]     Checks container is exist or if not then fails
    [Arguments]     ${namespace}    ${pod_name}    ${container_to_check}
    ${container_name} =  Run  oc get pod ${pod_name} -n ${namespace} -o json | jq '.spec.containers[] | select(.name == "${container_to_check}") | .name'
    Should Be Equal    "${container_to_check}"    ${container_name}

Find First Pod By Name
    [Documentation]   Returns first occurred pod  ${pod_start_with} = here ypu have to provide starting of pod name
    [Arguments]   ${namespace}  ${pod_start_with}
    ${list_pods} =  Search Pod  namespace=${namespace}  pod_start_with=${pod_start_with}
    [Return]  ${list_pods}[0]

Get Containers
    [Documentation]    Returns list of containers
    [Arguments]    ${pod_name}    ${namespace}
    ${containers}    Run    oc get pod ${pod_name} -n ${namespace} -o json | jq '.spec.containers[] | .name'
    ${containers}    Replace String    ${containers}    "    ${EMPTY}
    @{containers}    Split String    ${containers}    \n
    [Return]    ${containers}

Get User Server Node
    [Documentation]    Returns the name of the node on which the user's server pod is running
    [Arguments]    ${username}=${TEST_USER.USERNAME}
    ${pod_name} =    Get User Notebook Pod Name    ${username}
    ${node_name} =    Run    oc describe Pod ${pod_name} -n rhods-notebooks | grep Node: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"/"); print b[1]}'
    [Return]    ${node_name}

Go To Log Tab And Select A Container
    [Documentation]     Click on log tab and change container with help of ${container_button_id}
    [Arguments]         ${container_button_id}
    Click Link    Logs
    Sleep    4
    Click Button    xpath://div[@class="resource-log"]//button[@data-test-id="dropdown-button"]
    Click Button    id=${container_button_id}
    Sleep    4
    Capture Page Screenshot    logs_page.png