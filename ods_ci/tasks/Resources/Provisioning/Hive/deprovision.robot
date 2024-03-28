*** Keywords ***
Set Hive Default Variables
    ${cluster_name} =    Get Variable Value    ${cluster_name}    %{TEST_CLUSTER}
    Set Suite Variable    ${cluster_name}
    ${pool_name} =    Get Variable Value    ${pool_name}    ${cluster_name}-pool
    Set Suite Variable    ${pool_name}
    ${claim_name} =    Get Variable Value    ${claim_name}    ${cluster_name}-claim
    Set Suite Variable    ${claim_name}
    ${conf_name} =    Get Variable Value    ${conf_name}    ${cluster_name}-conf
    Set Suite Variable    ${conf_name}
    ${hive_namespace} =    Get Variable Value    ${hive_namespace}    %{HIVE_NAMESPACE}
    Set Suite Variable    ${hive_namespace}

Delete Cluster Configuration
    IF    ${use_cluster_pool}
        Log    Deleting cluster ${cluster_name} configuration    console=True
        @{Delete_Cluster} =    Oc Delete    kind=ClusterPool    name=${pool_name}
        ...    namespace=${hive_namespace}    api_version=hive.openshift.io/v1
        Log Many    @{Delete_Cluster}
        ${Delete_Cluster} =    Oc Delete    kind=ClusterDeploymentCustomization    name=${conf_name}
        ...    namespace=${hive_namespace}    api_version=hive.openshift.io/v1
        Log Many    @{Delete_Cluster}
    ELSE
        ${Delete_Cluster} =    Oc Delete    kind=ClusterDeployment    name=${cluster_name}
        ...    namespace=${hive_namespace}    api_version=hive.openshift.io/v1
    END

Deprovision Cluster
    ${cluster_claim} =    Run Keyword And Return Status
    ...    Unclaim Cluster    ${claim_name}
    ${cluster_deprovision} =    Run Keyword And Return Status
    ...    Delete Cluster Configuration
    IF    ${cluster_claim} == False
    ...    Log    Cluster Claim ${claim_name} does not exists. Deleting Configuration   console=True
    IF    ${cluster_deprovision} == False
    ...    Log    Cluster ${cluster_name} has not been deleted. Please do it manually   console=True
    Log    Cluster ${cluster_name} has been deprovisioned    console=True

Unclaim Cluster
    [Arguments]    ${unclaimname}
    Oc Delete    kind=ClusterClaim    name=${unclaimname}    namespace=${hive_namespace}
    ${status} =    Oc Get    kind=ClusterClaim    name=${unclaimname}    namespace=${hive_namespace}
    Log    ${status}    console=True