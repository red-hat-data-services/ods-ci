*** Settings ***
Documentation    Provision Self-Managed clusters for testing Beta
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
${claim_name}            ${cluster_name}-claim
${pool_name}             ${cluster_name}-pool
${conf_name}             ${cluster_name}-conf
${artifacts_dir}         ${OUTPUT DIR}

*** Tasks ***
Provision Self-Managed Cluster
    [Documentation]    Provision a self-managed cluster
    [Tags]  self_managed_provision
    Provision Cluster
    Claim Cluster
    Wait For Cluster To Be Ready
    Save Cluster Credentials
    Login To Cluster
    Set Cluster Storage
    Pass Execution    Self-Managed Cluster ${cluster_name} provisionend successfully

Deprovision Self-Managed Cluster
    [Documentation]    Deprovision a self-managed cluster
    [Tags]    self_managed_deprovision
    [Setup]   Set Hive Default Variables
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