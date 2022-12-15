*** Keywords ***
Clean Failed Cluster
    Run Keyword If Test Failed      Deprovision Cluster

Delete Cluster Configuration 
    Log    Deleting cluster configuration    console=True
    ${template} =    Select Provisioner Template
    ${Delete_Cluster} =    Oc Delete    kind=List    src=${template}    template_data=${infrastructure_configurations}

Deprovision Cluster
    ${cluster_claim} =    Run Keyword And Return Status
    ...    Unclaim Cluster    ${infrastructure_configurations['hive_claim_name']}
    ${cluster_deprovision} =    Run Keyword And Return Status
    ...    Delete Cluster Configuration
    Run Keyword If    ${cluster_claim} == False
    ...    Log    Cluster Claim does not exists. Deleting Configuration   console=True
    Run Keyword If    ${cluster_deprovision} == False
    ...    Log    Cluster has not been delete. Please do it manually   console=True
    Log    Cluster has been deprovisioned    console=True

Unclaim Cluster
    [Arguments]    ${unclaimname}
    Oc Delete    kind=ClusterClaim    name=${unclaimname}    namespace=rhods
    ${status} =    Oc Get    kind=ClusterClaim    name=${unclaimname}    namespace=rhods