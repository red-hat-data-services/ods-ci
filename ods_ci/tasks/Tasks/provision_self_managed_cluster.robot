*** Settings ***
Documentation    Provision Self-Managed clusters for testing. The cluster provisioning
...              currently leverages on Hive ClusterPool for AWS, GCP and OpenStack (PSI).
...              For IBM Cloud it leverages on Hive ClusterDeployment since Pools are not currently
...              supported for this provider in Hive.
Metadata         provision
Resource         ../../tests/Resources/Common.robot
Resource         ../Resources/Provisioning/Hive/provision.robot
Resource         ../Resources/Provisioning/Hive/deprovision.robot
Resource         ../Resources/Provisioning/Hive/gpu-provision.robot
Resource         ../Resources/Provisioning/Hive/disconnect.robot
Library          OperatingSystem
Library          OpenShiftLibrary
Library          String
Library          Process

***Variables***
${hive_kubeconf}         %{KUBECONFIG}
${cluster_name}          ${infrastructure_configurations}[hive_cluster_name]
${hive_namespace}        ${infrastructure_configurations}[hive_claim_ns]
${provider_type}         ${infrastructure_configurations}[provider]
${release_image}         ${infrastructure_configurations}[release_image]
${claim_name}            ${cluster_name}-claim
${pool_name}             ${cluster_name}-pool
${conf_name}             ${cluster_name}-conf
${artifacts_dir}         ${OUTPUT DIR}


*** Tasks ***
Provision Self-Managed Cluster
    [Documentation]    Provision a self-managed cluster
    [Tags]  self_managed_provision
    [Setup]    Set ClusterPool Variables
    Provision Cluster
    IF    ${use_cluster_pool}    Claim Cluster
    Wait For Cluster To Be Ready
    Save Cluster Credentials
    Login To Cluster
    Pass Execution    Self-Managed Cluster ${cluster_name} provisionend successfully

Deprovision Self-Managed Cluster
    [Documentation]    Deprovision a self-managed cluster
    [Tags]    self_managed_deprovision
    [Setup]   Run Keywords    Set Hive Default Variables
    ...    AND
    ...    Set ClusterPool Variables
    Deprovision Cluster

Add GPU Node To Self-Managed AWS Cluster
    [Documentation]    Add GPU node to self-managed cluster
    [Tags]    gpu_node_aws_self_managed_provision
    Login To Cluster
    Create GPU Node In Self Managed AWS Cluster
    Install GPU Operator on Self Managed Cluster

Delete GPU Node From Self-Managed AWS Cluster
    [Documentation]    Delete GPU node from self-managed cluster
    [Tags]    gpu_node_aws_self_managed_deprovision
    Login To Cluster
    Delete GPU Node In Self Managed AWS Cluster

Disconnect Self-Managed Cluster
    [Documentation]    Disconnect a self-managed cluster
    [Tags]    self_managed_disconnect
    Disconnect Cluster


*** Keywords ***
Set ClusterPool Variables
    [Documentation]    Set the variable to instruct the task about using ClusterPool
    ...                or ClusterDeployment provisioning type.
    ...                You can set the value of 'use_cluster_pool' key in the infrastructure_configurations yaml file.
    ...                By default (if the key is not set in the yaml) it uses ClusterPool
    ${key_present}=    Run Keyword And Return Status    Dictionary Should Contain Key
    ...    ${infrastructure_configurations}    use_cluster_pool
    IF    ${key_present}
        Set Task Variable    ${use_cluster_pool}    ${infrastructure_configurations}[use_cluster_pool]
    ELSE
        # use ClusterPool as default option
        Set Task Variable    ${use_cluster_pool}    ${TRUE}
    END
