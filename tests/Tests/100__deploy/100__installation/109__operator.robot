*** Settings ***
Documentation       Post install test cases that verify OCP operator resources and objects

Library             OpenShiftLibrary
Resource            ../../../Resources/ODS.robot
Resource          ../../../Resources/RHOSi.resource
Suite Setup       RHOSi Setup
Suite Teardown    RHOSi Teardown


*** Test Cases ***
Verify Odh-deployer Checks Cluster Platform Type
    [Documentation]    Verifies if odh-deployer checks the platform type of the cluster before installing
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1316
    ${cluster_platform_type}=    Fetch Cluster Platform Type
    IF    "${cluster_platform_type}" == "OpenStack"
        ${odhdeployer_logs_content}=    Set Variable    INFO: Deploying on PSI. Creating local database
    ELSE IF    "${cluster_platform_type}" == "AWS"
        ${odhdeployer_logs_content}=     Set Variable
        ...    INFO: Deploying on AWS. Creating CRO for deployment of RDS Instance
    ELSE
        ${odhdeployer_logs_content}=     Set Variable
        ...    ERROR: Deploying on ${cluster_platform_type}, which is not supported. Failing Installation
    END
    ${odhdeployer_logs}=    Fetch Odh-deployer Pod Logs
    Should Contain    ${odhdeployer_logs}    ${odhdeployer_logs_content}

Verify That The Operator Pod Does Not Get Stuck After Upgrade
    [Documentation]    Verifies that the operator pod doesn't get stuck after an upgrade
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-818
    ${operator_pod_info}=    Fetch operator Pod Info
    ${length}=    Get length    ${operator_pod_info}
    IF    ${length} == 2
        ${crashloopbackoff}=    Verify Operator Pods Have CrashLoopBackOff Status After upgrade    ${operator_pod_info}
        IF   ${crashloopbackoff}
            Log Error And Fail Pods When Pods Were Terminated    ${operator_pod_info}    Opertator Pod Stuck
        END
    END

*** Keywords ***
Fetch Odh-deployer Pod Info
    [Documentation]  Fetches information about odh-deployer pod
    ...    Args:
    ...        None
    ...    Returns:
    ...        odhdeployer_pod_info(dict): Dictionary containing the information of the odhdeployer pod
    @{resources_info_list}=    Oc Get    kind=Pod    api_version=v1    label_selector=name=rhods-operator
    &{odhdeployer_pod_info}=    Set Variable    ${resources_info_list}[0]
    [Return]    &{odhdeployer_pod_info}

Fetch Odh-deployer Pod Logs
    [Documentation]  Fetches the logs of pod odh-deployer
    ...    Args:
    ...        None
    ...    Returns:
    ...        odhdeployer_pod_logs(str): Logs of pod odh-deployer
    &{odhdeployer_pod_info}=    Fetch Odh-deployer Pod Info
    ${odhdeployer_pod_logs}=    Oc Get Pod Logs
    ...                         name=${odhdeployer_pod_info.metadata.name}
    ...                         namespace=redhat-ods-operator
    ...                         container=rhods-deployer
    [Return]    ${odhdeployer_pod_Logs}

Fetch Operator Pod Info
    [Documentation]  Fetches information about operator pod
    ...    Args:
    ...        None
    ...    Returns:
    ...        operator_pod_info(dict): Dictionary containing the information of the operator pod
    @{operator_pod_info}=    Oc Get    kind=Pod    api_version=v1    label_selector=name=rhods-operator
    [Return]    @{operator_pod_info}

Verify Operator Pods Have CrashLoopBackOff Status After Upgrade
    [Documentation]  Verifies operator pods have CrashLoopBackOff status after upgrade
    ...    Args:
    ...        operator_pod_info(dict): Dictionary containing the information of the operator pod
    ...    Returns:
    ...        crashloopbackoff(bool): True when the status CrashLoopBackOff is present
    [Arguments]    ${operator_pod_info}
    ${crashloopbackoff}=    Run Keyword And Return Status
    ...    Wait Until Keyword Succeeds  60 seconds  1 seconds
    ...    OpenShift Resource Field Value Should Be Equal As Strings
    ...    status.containerStatuses[0].state.waiting.reason
    ...    CrashLoopBackOff
    ...    @{operator_pod_info}
    [Return]    ${crashloopbackoff}

Log Error And Fail Pods When Pods Were Terminated
    [Documentation]  Logs the error why the specified pods were terminated and fails the pod for the specified reason
    ...    Args:
    ...        pods_info(list(dict)): List of Dictionaries containing the information of the pods
    ...        fail_reason(str): Reason for failing the pods
    [Arguments]    ${pods_info}    ${fail_reason}
    FOR    ${pod_info}    IN    @{pods_info}
        &{operator_pod_info_dict}=    Set Variable    ${pod_info}
        ${reason}=    Set Variable    ${operator_pod_info_dict.status.containerStatuses[0].lastState.terminated.reason}
        ${exit_code}=    Set Variable    ${operator_pod_info_dict.status.containerStatuses[0].lastState.terminated.exitCode}
        Log    ${fail_reason}. Reason: ${reason} Exit Code: ${exit_code}
        Fail   ${fail_reason}
    END



