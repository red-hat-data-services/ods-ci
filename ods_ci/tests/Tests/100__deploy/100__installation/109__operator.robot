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
    ...       AutomationBug
    ${cluster_platform_type}=    Fetch Cluster Platform Type
    IF    "${cluster_platform_type}" == "AWS" or "${cluster_platform_type}" == "OpenStack"
        ${odhdeployer_logs_content}=     Set Variable
        ...    INFO: Fresh Installation, proceeding normally
    ELSE
        ${odhdeployer_logs_content}=     Set Variable
        ...    ERROR: Deploying on ${cluster_platform_type}, which is not supported. Failing Installation
    END
    ${odhdeployer_logs}=    Fetch Odh-deployer Pod Logs
    ${status}=   Run Keyword And Return Status     Should Contain    ${odhdeployer_logs}    ${odhdeployer_logs_content}
    IF     ${status}==False
            ${upgrade odhdeployer_logs_content}=     Set Variable
            ...   INFO: Migrating from JupyterHub to NBC, deleting old JupyterHub artifacts
            Should Contain    ${odhdeployer_logs}    ${upgrade odhdeployer_logs_content}
    ELSE IF   ${status}==True
          Pass Execution    message=INFO: Fresh Installation, proceeding normally
    ELSE
            Fail    Deploy or Upgrade INFO is not present in the operator logs
    END

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
Verify Clean Up ODS Deployer Post-Migration
    [Documentation]    Verifies that resources unused are cleaned up after migration
    [Tags]    Tier1
    ...       ODS-1767
    ...       Sanity
    ...       AutomationBug
    ${version_check} =    Is RHODS Version Greater Or Equal Than    1.17.0
    IF    ${version_check} == False
        Log    Skipping test case as RHODS version is less than 1.17.0
        Skip
    END
    ${cro_pod}=    Run Keyword And Return Status
    ...    Oc Get    kind=Pod    api_version=v1    label_selector=name=cloud-resource-operator
    IF    ${cro_pod} == True
        Fail    CRO pod found after migration
    END
    ${odhdeployer_logs}=    Fetch Odh-deployer Pod Logs
    ${odhdeployer_logs_content}=    Set Variable
    ...    INFO: No CRO resources found, proceeding normally
    ${status}=   Run Keyword And Return Status     Should Contain    ${odhdeployer_logs}    ${odhdeployer_logs_content}
    IF    ${status} == False
        ${odhdeployer_logs_content}=    Set Variable
        ...    INFO: Migrating from JupyterHub to NBC, deleting old JupyterHub artifacts
        Should Contain    ${odhdeployer_logs}    ${odhdeployer_logs_content}
    END
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=CustomResourceDefinition    name=blobstorages.integreatly.org     namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=CustomResourceDefinition    name=postgres.integreatly.org    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=CustomResourceDefinition    name=redis.integreatly.org    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=CustomResourceDefinition    name=postgressnapshots.integreatly.org    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=CustomResourceDefinition    name=redisnapshots.integreatly.org    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=ClusterRole    name=cloud-resource-operator-cluster-role    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=ClusterRoleBinding    name=cloud-resource-operator-cluster-rolebinding    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=Role    name=cloud-resource-operator-role    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=RoleBinding    name=cloud-resource-operator-rolebinding    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=Role    name=cloud-resource-operator-rds-role    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=RoleBinding    name=cloud-resource-operator-rds-rolebinding    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=Deployment    name=cloud-resource-operator    namespace=${APPLICATIONS_NAMESPACE}
    Run Keyword And Expect Error  ResourceOperationFailed: Get failed\nReason: Not Found
    ...    Oc Get    kind=ServiceAccount    name=cloud-resource-operator    namespace=${APPLICATIONS_NAMESPACE}

    ${dashboardConfig} =   Oc Get   kind=OdhDashboardConfig   namespace=${APPLICATIONS_NAMESPACE}  name=odh-dashboard-config
    Should Be Equal   ${dashboardConfig[0]["spec"]["groupsConfig"]["adminGroups"]}    dedicated-admins
    Should Be Equal   ${dashboardConfig[0]["spec"]["groupsConfig"]["allowedGroups"]}    system:authenticated
    Should Be True    ${dashboardConfig[0]["spec"]["notebookController"]["enabled"]}
    Should Be Equal   ${dashboardConfig[0]["spec"]["notebookController"]["pvcSize"]}    20Gi

*** Keywords ***
Fetch Odh-deployer Pod Info
    [Documentation]  Fetches information about odh-deployer pod
    ...    Args:
    ...        None
    ...    Returns:
    ...        odhdeployer_pod_info(dict): Dictionary containing the information of the odhdeployer pod
    @{resources_info_list}=    Oc Get    kind=Pod    api_version=v1    label_selector=name=rhods-operator
    &{odhdeployer_pod_info}=    Set Variable    ${resources_info_list}[0]
    RETURN    &{odhdeployer_pod_info}

Fetch Odh-deployer Pod Logs
    [Documentation]  Fetches the logs of pod odh-deployer
    ...    Args:
    ...        None
    ...    Returns:
    ...        odhdeployer_pod_logs(str): Logs of pod odh-deployer
    &{odhdeployer_pod_info}=    Fetch Odh-deployer Pod Info
    ${odhdeployer_pod_logs}=    Oc Get Pod Logs
    ...                         name=${odhdeployer_pod_info.metadata.name}
    ...                         namespace=${OPERATOR_NAMESPACE}
    ...                         container=rhods-deployer
    RETURN    ${odhdeployer_pod_Logs}

Fetch Operator Pod Info
    [Documentation]  Fetches information about operator pod
    ...    Args:
    ...        None
    ...    Returns:
    ...        operator_pod_info(dict): Dictionary containing the information of the operator pod
    @{operator_pod_info}=    Oc Get    kind=Pod    api_version=v1    label_selector=name=rhods-operator
    RETURN    @{operator_pod_info}

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
    RETURN    ${crashloopbackoff}

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



