*** Keywords ***
Clean Failed Cluster
    Run Keyword If Test Failed      Deprovision Cluster

Delete Cluster Configuration 
    Log    Deleting cluster configuration    console=True
    @{Delete_Cluster} =    Oc Delete    kind=ClusterPool    name=${pool_name}    
    ...    namespace=${hive_namespace}    api_version=hive.openshift.io/v1
    Log Many    @{Delete_Cluster}
    ${Delete_Cluster} =    Oc Delete    kind=ClusterDeploymentCustomization    name=${conf_name}    
    ...    namespace=${hive_namespace}    api_version=hive.openshift.io/v1
    Log Many    @{Delete_Cluster}

Deprovision Cluster
    ${cluster_claim} =    Run Keyword And Return Status
    ...    Unclaim Cluster    ${claim_name}
    ${cluster_deprovision} =    Run Keyword And Return Status
    ...    Delete Cluster Configuration
    IF    ${cluster_claim} == False
    ...    Log    Cluster Claim does not exists. Deleting Configuration   console=True
    IF    ${cluster_deprovision} == False
    ...    Log    Cluster has not been delete. Please do it manually   console=True
    Log    Cluster has been deprovisioned    console=True

Unclaim Cluster
    [Arguments]    ${unclaimname}
    Oc Delete    kind=ClusterClaim    name=${unclaimname}    
    ...    namespace=${hive_namespace}    api_version=hive.openshift.io/v1
    ${status} =    Oc Get    kind=ClusterClaim    name=${unclaimname}    namespace=${hive_namespace}
    Log    ${status}    console=True