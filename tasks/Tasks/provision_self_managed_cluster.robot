*** Settings ***
Documentation    Provision Self-Managed clusters for testing Beta
Metadata         provision
Resource         ../Resources/Provisioning/Hive/provision.robot
Resource         ../Resources/Provisioning/Hive/deprovision.robot
Resource         ../Resources/Provisioning/Hive/gpu-provision.robot
Resource         ../Resources/Provisioning/Hive/disconnect.robot
Library          OperatingSystem
Library          OpenShiftLibrary
Library          String
Library          Process

*** Tasks ***
Provision Self-Managed Cluster
    [Documentation]    Provision a self-managed cluster
    [Tags]  self_managed_provision
    Provision Cluster
    Wait For Cluster To Be Ready
    Claim Cluster
    # Login To Cluster
    [Teardown]  Clean Failed Cluster

Deprovision Self-Managed Cluster
    [Documentation]    Deprovision a self-managed cluster
    [Tags]    self_managed_deprovision
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
    Login To Cluster
    Disconnect Cluster