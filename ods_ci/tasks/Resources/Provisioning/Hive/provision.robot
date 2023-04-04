*** Settings ***
Resource    deprovision.robot

*** Keywords ***
Claim Cluster
    Log    Claiming cluster    console=True
    Oc Apply    kind=ClusterClaim    src=tasks/Resources/Provisioning/Hive/claim.yaml
    ...    template_data=${infrastructure_configurations}

Does ClusterName Exists
    @{clusterpoolname} =    Oc Get   kind=ClusterPool    namespace=${hive_namespace}    api_version=hive.openshift.io/v1
    Log Many    @{clusterpoolname}
    Log Many    ${cluster_name} 
    FOR    ${name}    IN    @{clusterpoolname}
        IF    "${name}[metadata][name]" == "${pool_name}"
            Log    ${name}[metadata][name]    console=True
            ${clustername_exists} =    Set Variable    "${name}[metadata][name]"
            RETURN    ${clustername_exists}
        END
    END
    RETURN    False

Get Clusters
    @{clusters} =    Oc Get    kind=ClusterClaim    namespace=${hive_namespace}
    FOR   ${cluster}    IN    @{clusters}
        Log    Name: "${cluster}[spec][clusterPoolName]"    console=True
    END

Provision Cluster
    Log    Setting cluster configuration    console=True
    Should Be True    "${hive_kubeconf}" != "${EMPTY}"
    ${clustername_exists} =    Does ClusterName Exists
    ${template} =    Select Provisioner Template    ${provider_type}
    IF    ${clustername_exists}
    ...    FAIL    Cluster name ${cluster_name} already exists. Please choose a different name.
    Log     Configuring cluster    console=True
    Log    ${cluster_name}    console=True
    Create Provider Resources

Create Provider Resources
    Log    Creating Hive resources for ${provider_type} according to: ${template}   console=True
    IF    "${provider_type}" == "AWS"
        Oc Apply    kind=List    src=${template}    api_version=v1
        ...    template_data=${infrastructure_configurations}
    ELSE IF    "${provider_type}" == "GCP"
        Oc Apply    kind=List    src=${template}    api_version=v1
        ...    template_data=${infrastructure_configurations}
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
    ${FIP_API}    Evaluate    ${infrastructure_configurations}.get('fip_api')
    ${FIP_APPS}    Evaluate    ${infrastructure_configurations}.get('fip_apps')
    Run Keyword If    "${FIP_API}" == "" or "${FIP_APPS}" == ""    Create Floating IPs
    Set Task Variable    ${FIP_API}
    Set Task Variable    ${FIP_APPS}
    Log    FIP_API = ${FIP_API}    console=True
    Log    FIP_APPS = ${FIP_APPS}    console=True
    ${hive_yaml} =    Set Variable    ${artifacts_dir}/${cluster_name}_hive.yaml
    Create File From Template    ${template}    ${hive_yaml}
    Log    Hive configuration for ${provider_type}: ${hive_yaml}    console=True
    Oc Apply    kind=List    src=${hive_yaml}    api_version=v1

Create Floating IPs
    ${osp_clouds_yaml} =    Set Variable    ~/.config/openstack/clouds.yaml
    ${result} 	Run Process 	echo '${infrastructure_configurations}[osp_yaml_encoded]' | base64 --decode    shell=yes
    Should Be True    ${result.rc} == 0
    Create File    ${osp_clouds_yaml}    ${result.stdout}
    File Should Not Be Empty    ${osp_clouds_yaml}
    ${shell_script} =     Set Variable     ${CURDIR}/OSP/create_fips.sh
    ${result} 	Run Process 	sh     ${shell_script}    ${cluster_name}    ${infrastructure_configurations}[aws_domain]
    ...    ${infrastructure_configurations}[osp_network]    ${artifacts_dir}/    shell=yes
    Log    ${shell_script}:\n${result.stdout}\n${result.stderr}     console=True
    Should Be True    ${result.rc} == 0
    ${fips_file_to_export} =    Set Variable    ${artifacts_dir}/${cluster_name}.${infrastructure_configurations}[aws_domain].fips
    Export Variables From File    ${fips_file_to_export}

Verify Cluster Is Successfully Provisioned
    [Arguments]    ${namespace}
    ${pod} =    Oc Get    kind=Pod    namespace=${namespace}
    Log To Console    .    no_newline=true
    ${install_log_data} = 	Get File 	${install_log_file}
    ${last_line_index} =    Get Line Count    ${install_log_data}
    ${install_log_data} =    Oc Get Pod Logs    name=${pod[0]['metadata']['name']}    container=hive    namespace=${namespace}    
    @{new_lines} =    Split To Lines    ${install_log_data}    ${last_line_index}
    FOR    ${line}    IN    @{new_lines}
        Log    ${line}    console=True
    END
    Create File    ${install_log_file}    ${install_log_data}
    Should Contain    ${install_log_data}    install completed successfully

Wait For Cluster To Be Ready
    ${pool_namespace} =    Get Cluster Pool Namespace    ${pool_name}
    Log    Watching Hive Pool namespace: ${pool_namespace}    console=True
    Set Task Variable    ${install_log_file}    ${artifacts_dir}/${cluster_name}_install.log
    Create File    ${install_log_file}
    ${result} =    Wait Until Keyword Succeeds    50 min    10 s
    ...    Verify Cluster Is Successfully Provisioned    ${pool_namespace}
    IF    ${result} == False    Delete Cluster Configuration
    IF    ${result} == False    FAIL
    ...    Cluster provisioning failed. Please look into the logs for more details.

Verify Cluster Claim
    Wait Until Keyword Succeeds    30 min    10 s
    ...    Confirm Cluster Is Claimed

Confirm Cluster Is Claimed
    ${status} =    Oc Get    kind=ClusterClaim    name=${claim_name}    namespace=${hive_namespace}
    Should Be Equal As Strings    ${status[0]['status']['conditions'][0]['reason']}    ClusterClaimed

Save Cluster Credentials
    Set Task Variable    ${cluster_details}    ${artifacts_dir}/${cluster_name}_details.txt
    Set Task Variable    ${cluster_kubeconf}    ${artifacts_dir}/kubeconfig
    ${pool_namespace} =    Get Cluster Pool Namespace    ${pool_name}
    ${result} 	Run Process 	oc -n ${pool_namespace} get cd ${pool_namespace} -o jsonpath\='{ .status.webConsoleURL }'    shell=yes
    Log    Cluster ${cluster_name} Web Console: ${result.stdout}     console=True
    Should Be True    ${result.rc} == 0
    Create File     ${cluster_details}    console=${result.stdout}\n
    ${ClusterDeployment} =    Oc Get    kind=ClusterDeployment    name=${pool_namespace}
    ...    namespace=${pool_namespace}    api_version=hive.openshift.io/v1
    ${apiURL} =    Set Variable    "${ClusterDeployment[0]['status']['apiURL']}"
    Append to File     ${cluster_details}     api=${apiURL}\n
    ${result} 	Run Process    oc extract -n ${pool_namespace} --confirm secret/$(oc -n ${pool_namespace} get cd ${pool_namespace} -o jsonpath\='{.spec.clusterMetadata.adminPasswordSecretRef.name}') --to\=${artifacts_dir}
    ...    shell=yes
    Should Be True    ${result.rc} == 0
    ${username} = 	Get File 	${artifacts_dir}/username
    ${password} = 	Get File 	${artifacts_dir}/password
    Append to File     ${cluster_details}     username=${username}\n
    Append to File     ${cluster_details}     password=${password}\n
    ${result} 	Run Process 	oc extract -n ${pool_namespace} --confirm secret/$(oc -n ${pool_namespace} get cd ${pool_namespace} -o jsonpath\='{.spec.clusterMetadata.adminKubeconfigSecretRef.name}') --to\=${artifacts_dir}
    ...    shell=yes
    Should Be True    ${result.rc} == 0
    RETURN    ${cluster_kubeconf}
    
Login To Cluster
    Export Variables From File    ${cluster_details}
    ${temp_kubeconfig} =    Set Variable    ${artifacts_dir}/temp_kubeconfig
    Create File     ${temp_kubeconfig}
    ${result} 	Run Process    KUBECONFIG\=${temp_kubeconfig} oc login --username\=${username} --password\=${password} ${api} --insecure-skip-tls-verify
    ...    shell=yes
    Should Be True    ${result.rc} == 0
    ${result} 	Run Process    KUBECONFIG\=${cluster_kubeconf} oc status    shell=yes
    Log    ${result.stdout}\n${result.stderr}     console=True
    Should Be True    ${result.rc} == 0

Set Cluster Storage
    ${result} 	Run Process 	oc --kubeconfig\=${cluster_kubeconf} patch StorageClass standard -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
    ...    shell=yes
    Log    StorageClass standard:\n${result.stdout}\n${result.stderr}     console=True
    ${result} 	Run Process 	oc --kubeconfig\=${cluster_kubeconf} patch StorageClass standard-csi -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
    ...    shell=yes
    Log    StorageClass standard-csi:\n${result.stdout}\n${result.stderr}     console=True
    Run Keyword And Ignore Error    Should Be True    ${result.rc} == 0

Get Cluster Pool Namespace
    [Arguments]    ${hive_pool_name}
    ${namespace} =    Wait Until Keyword Succeeds    2 min    2 s
    ...    Oc Get    kind=Namespace    label_selector=hive.openshift.io/cluster-pool-name=${hive_pool_name}
    ${pool_namespace} =    Set Variable   ${namespace[0]['metadata']['name']}
    RETURN    ${pool_namespace}