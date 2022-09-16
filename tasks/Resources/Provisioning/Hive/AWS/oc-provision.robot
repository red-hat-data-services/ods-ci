*** Settings ***
Library           OperatingSystem

*** Keywords ***
Run AWS Configuration In Hive
    [Arguments]    &{infrastructure_configurations}
    Oc Apply    kind=List    src=tasks/Resources/Provisioning/Hive/AWS/aws-cluster.yaml
    ...    template_data=${infrastructure_configurations}
    Sleep    60
    ${namespace} =    Oc Get    kind=Namespace    label_selector=hive.openshift.io/cluster-pool-name=${infrastructure_configurations}[hive_cluster_name]
    Log    ${namespace[0]['metadata']['name']}    console=True
    ${pod} =    Oc Get    kind=Pod    namespace=${namespace[0]['metadata']['name']}
    Log    ${pod[0]['metadata']['name']}    console=True
    Wait Until Keyword Succeeds    40 min    10 s
    ...    Wait Until Cluster Is Provisioned    ${pod[0]['metadata']['name']}    ${namespace[0]['metadata']['name']}

Wait Until Cluster Is Provisioned
    [Arguments]    ${pod_name}    ${namespace}
    ${installation_log} =    Oc Get Pod Logs    name=${pod_name}    container=hive    namespace=${namespace}
    Should Contain    ${installation_log}    install completed successfully

Claim Cluster
    Oc Apply    kind=ClusterClaim    src=tasks/Resources/Provisioning/Hive/AWS/claim.yaml
    ...    template_data=${infrastructure_configurations}
    Wait Until Keyword Succeeds    15 min    10 s
    ...    Wait Until Cluster to be Claimed

Wait Until Cluster to be claimed
    ${status} =    Oc Get    kind=ClusterClaim    name=${infrastructure_configurations}[hive_claim_name]    namespace=rhods
    Should Be Equal As Strings    ${status[0]['status']['conditions'][0]['reason']}    ClusterClaimed

Login To AWS Cluster With Hive
    Set Log Level    None
    ${ns} =    Oc Get    kind=Namespace    label_selector=hive.openshift.io/cluster-pool-name=${infrastructure_configurations}[hive_cluster_name]
    ${apiURL} =    Run and Return Rc And Output    oc -n ${ns[0]['metadata']['name']} get cd ${ns[0]['metadata']['name']} -o jsonpath='{ .status.apiURL }'
    ${credentials} =    Run and Return Rc And Output    oc extract -n ${ns[0]['metadata']['name']} secret/$(oc -n ${ns[0]['metadata']['name']} get cd ${ns[0]['metadata']['name']} -o jsonpath='{.spec.clusterMetadata.adminPasswordSecretRef.name}') --to=-
    ${credentials_splited} =    Split To Lines    ${credentials[1]}
    Run And Return Rc    oc login --username=${credentials_splited[3]} --password=${credentials_splited[1]} ${apiURL[1]} --insecure-skip-tls-verify

Create GPU Node In Self Managed AWS Cluster
    Set Log Level    Info
    ${gpu_node} =    Run Process    sh    tasks/Resources/Provisioning/Hive/AWS/provision-gpu.sh

Delete GPU Node In Self Managed AWS Cluster
    ${gpu_nodes} =    Oc Get    kind=Machine    label_selector=machine.openshift.io/instance-type=g4dn.xlarge
    Log    ${gpu_nodes[0]['metadata']['name']}    console=True
    Run And Return Rc    oc annotate machine/${gpu_nodes[0]['metadata']['name']} -n openshift-machine-api machine.openshift.io/cluster-api-delete-machine="true"
    Run And Return Rc    oc adm cordon ${gpu_nodes[0]['metadata']['name']}
    Run And Return Rc    oc adm drain ${gpu_nodes[0]['metadata']['name']} --ignore-daemonsets --delete-local-data
    ${gpu_machineset} =    Oc Get    kind=MachineSet    label_selector=gpu-machineset=true
    Run And Return Rc    oc scale --replicas=0 machineset/${gpu_machineset[0]['metadata']['name']} -n openshift-machine-api

Unclaim Hive Cluster
    [Arguments]    ${unclaimname}
    Oc Delete    kind=ClusterClaim    name=${unclaimname}    namespace=rhods
    ${status} =    Oc Get    kind=ClusterClaim    name=${unclaimname}    namespace=rhods<

Install GPU Operator on Self Managed Cluster
   [Documentation]  Install GPU operator on Self Managed cluster
   ${gpu_install} =    Run Process    sh    tasks/Resources/Provisioning/GPU/gpu_deploy.sh   shell=yes
   Should Not Contain    ${gpu_install.stdout}    FAIL
   Wait For Pods Status   namespace=nvidia-gpu-operator   timeout=600
