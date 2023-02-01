*** Keywords ***
Claim Cluster    
    Log    Claiming cluster    console=True
    Oc Apply    kind=ClusterClaim    src=tasks/Resources/Provisioning/Hive/claim.yaml
    ...    template_data=${infrastructure_configurations}
    Wait Until Keyword Succeeds    30 min    10 s
    ...    Confirm Cluster Is Claimed

Does ClusterName Exists
    @{clusterpoolname} =    Oc Get   kind=ClusterPool    namespace=rhods    api_version=hive.openshift.io/v1
    Log Many    @{clusterpoolname}
    Log Many    ${infrastructure_configurations['hive_cluster_name']}
    FOR    ${name}    IN    @{clusterpoolname}
        IF    "${name}[metadata][name]" == "${infrastructure_configurations['hive_cluster_name']}"
            Log    ${name}[metadata][name]    console=True
            ${clustername_exists} =    Set Variable    "${name}[metadata][name]"
            RETURN    ${clustername_exists}
        END  
    END
    RETURN    False

Get Clusters
    @{clusters} =    Oc Get    kind=ClusterClaim    namespace=rhods
    FOR   ${cluster}    IN    @{clusters}
        Log    Name: "${cluster}[spec][clusterPoolName]"    console=True
    END

Get Cluster Credentials
    ${ns} =    Oc Get    kind=Namespace    label_selector=hive.openshift.io/cluster-pool-name=${infrastructure_configurations}[hive_cluster_name]
    ${consoleURL} =    Run and Return Rc And Output    oc -n ${ns[0]['metadata']['name']} get cd ${ns[0]['metadata']['name']} -o jsonpath='{ .status.webConsoleURL }'
    Create File  cluster_details.txt  consoleUrl=${consoleURL}\n
    ${credentials} =    Run and Return Rc And Output    oc extract -n ${ns[0]['metadata']['name']} secret/$(oc -n ${ns[0]['metadata']['name']} get cd ${ns[0]['metadata']['name']} -o jsonpath='{.spec.clusterMetadata.adminPasswordSecretRef.name}') --to=-
    ${credentials_splited} =    Split To Lines    ${credentials[1]}
    Append to File  cluster_details.txt  username=${credentials_splited[3]}\n
    Append to File  cluster_details.txt  password=${credentials_splited[1]}\n

Login To Cluster
    ${ns} =    Oc Get    kind=Namespace    label_selector=hive.openshift.io/cluster-pool-name=${infrastructure_configurations['hive_cluster_name']}
    ${ClusterDeployment} =    Oc Get    kind=ClusterDeployment    name=${ns[0]['metadata']['name']}    
    ...    namespace=${ns[0]['metadata']['name']}    api_version=hive.openshift.io/v1
    ${apiURL} =    Set Variable    "${ClusterDeployment[0]['status']['apiURL']}"
    ${credentials} =    Run and Return Rc And Output    oc extract -n ${ns[0]['metadata']['name']} secret/$(oc -n ${ns[0]['metadata']['name']} get cd ${ns[0]['metadata']['name']} -o jsonpath='{.spec.clusterMetadata.adminPasswordSecretRef.name}') --to=-
    ${credentials_splited} =    Split To Lines    ${credentials[1]}
    Run And Return Rc    oc login --username=${credentials_splited[3]} --password=${credentials_splited[1]} ${apiURL} --insecure-skip-tls-verify
    Log    Logged in to Hive cluster    console=True

Provision Cluster
    Log    Setting cluster configuration    console=True
    ${template} =    Select Provisioner Template
    ${clustername_exists} =    Does ClusterName Exists
    IF    ${clustername_exists}    
    ...    FAIL    Cluster name ${infrastructure_configurations['hive_cluster_name']} already exists. Please choose a different name.
    Log     Configuring cluster    console=True
    Log Many    ${infrastructure_configurations['hive_cluster_name']}    console=True
    Oc Apply    kind=List    src=${template}    api_version=v1        
    ...    template_data=${infrastructure_configurations}

Select Provisioner Template
    IF    "${infrastructure_configurations}[provider]" == "AWS"
        Set Task Variable    ${template}    tasks/Resources/Provisioning/Hive/AWS/aws-cluster.yaml
        Log    Setting AWS Template ${template}   console=True
    ELSE IF    "${infrastructure_configurations}[provider]" == "GCP"
        Set Task Variable    ${template}    tasks/Resources/Provisioning/Hive/GCP/gcp-cluster.yaml
        Log    Setting GCP Template ${template}    console=True
    ELSE
        FAIL    Invalid provider name
    END
    RETURN    ${template}

Verify Cluster Is Successfully Provisioned
    [Arguments]    ${namespace}
    ${pod} =    Oc Get    kind=Pod    namespace=${namespace}
    Log    ${pod[0]['metadata']['name']}    console=True
    ${installation_log} =    Oc Get Pod Logs    name=${pod[0]['metadata']['name']}    container=hive    namespace=${namespace}
    Should Contain    ${installation_log}    install completed successfully

Wait For Cluster To Be Ready
    ${namespace} =    Wait Until Keyword Succeeds    2 min    2 s
    ...    Oc Get    kind=Namespace    label_selector=hive.openshift.io/cluster-pool-name=${infrastructure_configurations['hive_cluster_name']}
    Log    ${namespace[0]['metadata']['name']}    console=True
    ${result} =    Wait Until Keyword Succeeds    50 min    10 s 
    ...    Verify Cluster Is Successfully Provisioned    ${namespace[0]['metadata']['name']}
    IF    ${result} == False    Delete Cluster Configuration
    IF    ${result} == False    FAIL    
    ...    Cluster provisioning failed. Please look into the logs for more details.
    
Confirm Cluster Is Claimed
    ${status} =    Oc Get    kind=ClusterClaim    name=${infrastructure_configurations}[hive_claim_name]    namespace=rhods
    Should Be Equal As Strings    ${status[0]['status']['conditions'][0]['reason']}    ClusterClaimed