***Variables***
${cluster_name}          ${infrastructure_configurations['hive_cluster_name']}
${provider_type}         ${infrastructure_configurations['provider']}

*** Keywords ***
Claim Cluster
    Log    Claiming cluster    console=True
    Oc Apply    kind=ClusterClaim    src=tasks/Resources/Provisioning/Hive/claim.yaml
    ...    template_data=${infrastructure_configurations}

Does ClusterName Exists
    @{clusterpoolname} =    Oc Get   kind=ClusterPool    namespace=rhods    api_version=hive.openshift.io/v1
    Log Many    @{clusterpoolname}
    Log Many    ${cluster_name} 
    FOR    ${name}    IN    @{clusterpoolname}
        IF    "${name}[metadata][name]" == "${cluster_name} "
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
    ${ns} =    Oc Get    kind=Namespace    label_selector=hive.openshift.io/cluster-pool-name=${cluster_name} 
    ${consoleURL} =    Run and Return Rc And Output    oc -n ${ns[0]['metadata']['name']} get cd ${ns[0]['metadata']['name']} -o jsonpath='{ .status.webConsoleURL }'
    Create File  cluster_details.txt  consoleUrl=${consoleURL}\n
    ${credentials} =    Run and Return Rc And Output    oc extract -n ${ns[0]['metadata']['name']} secret/$(oc -n ${ns[0]['metadata']['name']} get cd ${ns[0]['metadata']['name']} -o jsonpath='{.spec.clusterMetadata.adminPasswordSecretRef.name}') --to=-
    ${credentials_splited} =    Split To Lines    ${credentials[1]}
    Append to File  cluster_details.txt  username=${credentials_splited[3]}\n
    Append to File  cluster_details.txt  password=${credentials_splited[1]}\n

Login To Cluster
    ${ns} =    Oc Get    kind=Namespace    label_selector=hive.openshift.io/cluster-pool-name=${cluster_name} 
    ${ClusterDeployment} =    Oc Get    kind=ClusterDeployment    name=${ns[0]['metadata']['name']}
    ...    namespace=${ns[0]['metadata']['name']}    api_version=hive.openshift.io/v1
    ${apiURL} =    Set Variable    "${ClusterDeployment[0]['status']['apiURL']}"
    ${credentials} =    Run and Return Rc And Output    oc extract -n ${ns[0]['metadata']['name']} secret/$(oc -n ${ns[0]['metadata']['name']} get cd ${ns[0]['metadata']['name']} -o jsonpath='{.spec.clusterMetadata.adminPasswordSecretRef.name}') --to=-
    ${credentials_splited} =    Split To Lines    ${credentials[1]}
    Run And Return Rc    oc login --username=${credentials_splited[3]} --password=${credentials_splited[1]} ${apiURL} --insecure-skip-tls-verify
    Log    Logged in to Hive cluster    console=True

Provision Cluster
    Log    Setting cluster configuration    console=True
    ${clustername_exists} =    Does ClusterName Exists
    ${template} =    Select Provisioner Template    ${provider_type}
    IF    ${clustername_exists}
    ...    FAIL    Cluster name ${cluster_name} already exists. Please choose a different name.
    Log     Configuring cluster    console=True
    Log    ${cluster_name}    console=True
    Create Provider Resources

Create Provider Resources
    Log    Applying hive template for ${provider_type}: ${template}   console=True 
    IF    "${provider_type}" == "AWS"
        Oc Apply    kind=List    src=${template}    api_version=v1
        ...    template_data=${template}
    ELSE IF    "${provider_type}" == "GCP"
        Oc Apply    kind=List    src=${template}    api_version=v1
        ...    template_data=${template}
    ELSE IF    "${provider_type}" == "OSP"
        Create Openstack Resources
    ELSE
        FAIL    Invalid provider name
    END
    
Select Provisioner Template
    [Arguments]    ${provider_type}
    IF    "${provider_type}" == "AWS"
        Set Task Variable    ${template}    tasks/Resources/Provisioning/Hive/AWS/aws-cluster.yaml
        Log    Setting AWS Template ${template}   console=True
    ELSE IF    "${provider_type}" == "GCP"
        Set Task Variable    ${template}    tasks/Resources/Provisioning/Hive/GCP/gcp-cluster.yaml
        Log    Setting GCP Template ${template}    console=True
    ELSE IF    "${provider_type}" == "OSP"
        Set Task Variable    ${template}    tasks/Resources/Provisioning/Hive/OSP/hive_osp_cluster_template.yaml
        Log    Setting OSP Template ${template}    console=True
    ELSE
        FAIL    Invalid provider name
    END
    RETURN    ${template}

Create Openstack Resources
    ${output_dir} =    Set Variable If    "${OUTPUT DIR}" != "${EMPTY}"    ${OUTPUT DIR}/
    ${osp_clouds_yaml} =    Set Variable    ~/.config/openstack/clouds.yaml
    ${result} 	Run Process 	echo '${PSI_CLOUD_YAML_ECODED}' | base64 --decode    shell=yes
    Should Be True    ${result.rc} == 0
    Create File    ${osp_clouds_yaml}    ${result.stdout}
    File Should Not Be Empty    ${osp_clouds_yaml}
    ${shell_script} =     Set Variable     ${CURDIR}/OSP/create_fips.sh
    ${result} 	Run Process 	sh     ${shell_script}    ${cluster_name}    ${infrastructure_configurations}[aws_domain]
    ...    ${infrastructure_configurations}[osp_network]    ${output_dir}    shell=yes
    Log    ${shell_script}:\n${result.stdout}\n${result.stderr}     console=True
    ${fips_file_to_export} =    Set Variable    ${output_dir}${cluster_name}.${infrastructure_configurations}[aws_domain].fips
    Export Variables From File    ${fips_file_to_export}
    Log    FIP_API = ${FIP_API}    console=True
    Log    FIP_APPS = ${FIP_APPS}    console=True
    Should Be True    ${result.rc} == 0
    ${hive_yaml} =    Set Variable    ${output_dir}${cluster_name}_hive.yaml
    Create File From Template    ${template}    ${hive_yaml}
    Log    HIVE template: ${hive_yaml}    console=True
    Oc Apply    kind=List    src=${hive_yaml}    api_version=v1

Verify Cluster Is Successfully Provisioned
    [Arguments]    ${namespace}
    ${pod} =    Oc Get    kind=Pod    namespace=${namespace}
    Log    ${pod[0]['metadata']['name']}    console=True
    ${installation_log} =    Oc Get Pod Logs    name=${pod[0]['metadata']['name']}    container=hive    namespace=${namespace}
    Should Contain    ${installation_log}    install completed successfully

Wait For Cluster To Be Ready
    ${namespace} =    Wait Until Keyword Succeeds    2 min    2 s
    ...    Oc Get    kind=Namespace    label_selector=hive.openshift.io/cluster-pool-name=${cluster_name} 
    Log    ${namespace[0]['metadata']['name']}    console=True
    ${result} =    Wait Until Keyword Succeeds    50 min    10 s
    ...    Verify Cluster Is Successfully Provisioned    ${namespace[0]['metadata']['name']}
    IF    ${result} == False    Delete Cluster Configuration
    IF    ${result} == False    FAIL
    ...    Cluster provisioning failed. Please look into the logs for more details.

Verify Cluster Claim
    Wait Until Keyword Succeeds    30 min    10 s
    ...    Confirm Cluster Is Claimed

Confirm Cluster Is Claimed
    ${status} =    Oc Get    kind=ClusterClaim    name=${infrastructure_configurations}[hive_claim_name]    namespace=rhods
    Should Be Equal As Strings    ${status[0]['status']['conditions'][0]['reason']}    ClusterClaimed
