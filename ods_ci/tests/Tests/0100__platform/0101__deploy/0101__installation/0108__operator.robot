*** Settings ***
Documentation       Post install test cases that verify OCP operator resources and objects

Library           OpenShiftLibrary
Resource          ../../../../Resources/ODS.robot
Resource          ../../../../Resources/RHOSi.resource
Resource          ../../../../Resources/OCP.resource
Resource          ../../../../Resources/Common.robot
Resource          ../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Suite Setup       Operator Setup
Suite Teardown    RHOSi Teardown


*** Test Cases ***
Verify That DSC And DSCI Release.Name Attribute matches ${expected_release_name}
    [Documentation]    Tests the release.name attribute from the DSC and DSCI matches the desired value.
    ...                ODH: Open Data Hub
    ...                RHOAI managed: OpenShift AI Cloud Service
    ...                RHOAI selfmanaged: OpenShift AI Self-Managed
    [Tags]    Smoke
    ...       Operator
    ...       RHOAIENG-9760
    Should Be Equal As Strings    ${DSC_RELEASE_NAME}     ${expected_release_name}
    Should Be Equal As Strings    ${DSCI_RELEASE_NAME}    ${expected_release_name}

Verify That DSC And DSCI Release.Version Attribute matches the value in the subscription
    [Documentation]    Tests the release.version attribute from the DSC and DSCI matches the value in the subscription.
    [Tags]    Smoke
    ...       Operator
    ...       RHOAIENG-8082
    ${rc}    ${csv_name}=    Run And Return Rc And Output
    ...    oc get subscription -n ${OPERATOR_NAMESPACE} -l ${OPERATOR_SUBSCRIPTION_LABEL} -o json | jq '.items[0].status.installedCSV' | tr -d '"'

    Should Be Equal As Integers    ${rc}    ${0}    ${rc}

    ${csv_version}=     Get Resource Attribute      ${OPERATOR_NAMESPACE}
    ...                 ClusterServiceVersion      ${csv_name}        .spec.version

    Should Be Equal As Strings    ${DSC_RELEASE_VERSION}    ${csv_version}
    Should Be Equal As Strings    ${DSCI_RELEASE_VERSION}    ${csv_version}

Verify That The Operator Pod Does Not Get Stuck After Upgrade
    [Documentation]    Verifies that the operator pod doesn't get stuck after an upgrade
    [Tags]    Sanity
    ...       ODS-818
    ...       Operator
    ${operator_pod_info}=    Fetch operator Pod Info
    ${length}=    Get length    ${operator_pod_info}
    IF    ${length} == 2
        ${crashloopbackoff}=    Verify Operator Pods Have CrashLoopBackOff Status After upgrade    ${operator_pod_info}
        IF   ${crashloopbackoff}
            Log Error And Fail Pods When Pods Were Terminated    ${operator_pod_info}    Opertator Pod Stuck
        END
    END

*** Keywords ***
Operator Setup
    [Documentation]  Setup for the Operator tests
    RHOSi Setup
    ${IS_SELF_MANAGED}=    Is RHODS Self-Managed
    Set Suite Variable    ${IS_SELF_MANAGED}
    Gather Release Attributes From DSC And DSCI
    Set Expected Value For Release Name

Fetch Odh-deployer Pod Info
    [Documentation]  Fetches information about odh-deployer pod
    ...    Args:
    ...        None
    ...    Returns:
    ...        odhdeployer_pod_info(dict): Dictionary containing the information of the odhdeployer pod
    @{resources_info_list}=    Oc Get    kind=Pod    api_version=v1    label_selector=${OPERATOR_LABEL_SELECTOR}
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
    @{operator_pod_info}=    Oc Get    kind=Pod    api_version=v1    label_selector=${OPERATOR_LABEL_SELECTOR}
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



