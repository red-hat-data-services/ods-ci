*** Settings ***
Documentation       Collections of keyword to handle Deployment config objects in OCP
Library     OpenShiftLibrary
Library     OperatingSystem


*** Keywords ***
Restart Rollout
    [Documentation]     Rollout a deployment in Openshift using restart mode
    [Arguments]  ${dc_name}  ${namespace}
    Run    oc rollout restart dc/${dc_name} -n ${namespace}

Start Rollout
    [Documentation]     Rollout a deployment in Openshift fetching the latest version
    [Arguments]  ${dc_name}  ${namespace}
    Run    oc rollout latest dc/${dc_name} -n ${namespace}

Wait Until Rollout Is Started
    [Documentation]     Wait until the old pods are replace with the new ones after a rollout is triggered
    [Arguments]     ${previous_pods}    ${namespace}    ${label_selector}
    ...             ${comparison_fields}=['metadata.name']    ${retries}=5    ${retries_interval}=5s
    Log     ${previous_pods}
    FOR  ${retry_idx}  IN RANGE  0  1+${retries}
        ${current_pods}=    Oc Get    kind=Pod  namespace=${namespace}   label_selector=${label_selector}   fields=${comparison_fields}
        Log      ${current_pods}
        ${equal_flag}=     Run Keyword And Return Status    Should Not Be Equal As Strings    ${previous_pods}    ${current_pods}
        Exit For Loop If    $equal_flag == True
        Sleep    ${retries_interval}
    END
    IF    $equal_flag == False
        Fail    Rollout has not started...Please check your cluster
    END
