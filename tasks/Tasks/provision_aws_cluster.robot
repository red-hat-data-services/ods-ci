*** Settings ***
Documentation    Provision AWS Self-Managed clusters for testing Beta
Metadata         provision
Resource         ../Resources/Provisioning/Hive/AWS/oc-provision.robot
Library          OperatingSystem
Library          OpenShiftLibrary
Library          String
Library          Process

***Variables***
&{infrastructure_configurations}

*** Tasks ***
Provision Self-Managed Cluster In AWS &{infrastructure_configurations}
    [Tags]  aws_self_managed_provision
    Run AWS Configuration In Hive    &{infrastructure_configurations}
    Claim Cluster
    Login To AWS Cluster With Hive

Add GPU Node To Self-Managed AWS Cluster
    [Tags]    gpu_node_aws_self_managed_provision
    Login To AWS Cluster With Hive
    Create GPU Node In Self Managed AWS Cluster
    Install GPU Operator on Self Managed Cluster

Delete GPU Node From Self-Managed AWS Cluster
    [Tags]    gpu_node_aws_self_managed_deprovision
    Login To AWS Cluster With Hive
    Delete GPU Node In Self Managed AWS Cluster

Deprovision Self-Managed Cluster In AWS &{infrastructure_configurations}
    [Tags]  aws_self_managed_deprovision
    Unclaim Hive Cluster    ${infrastructure_configurations}[hive_claim_name]
