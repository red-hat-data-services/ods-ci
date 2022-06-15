*** Settings ***
Documentation       Post install test cases that verify OCP operator resources and objects

Library             OpenShiftLibrary
Resource            ../../../Resources/ODS.robot


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
