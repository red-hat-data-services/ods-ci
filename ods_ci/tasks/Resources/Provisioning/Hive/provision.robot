*** Settings ***
Resource    ../../../../tests/Resources/Common.robot
Library    Process

*** Keywords ***
Claim Cluster
    Log    Claiming cluster ${cluster_name}    console=True
    Oc Apply    kind=ClusterClaim    src=tasks/Resources/Provisioning/Hive/claim.yaml
    ...    template_data=${infrastructure_configurations}

Does ClusterName Exists
    [Arguments]    ${use_pool}=${TRUE}
    IF    ${use_pool}
        @{clusterpoolname} =    Oc Get   kind=ClusterPool    namespace=${hive_namespace}
        ...    api_version=hive.openshift.io/v1
        Log Many    @{clusterpoolname}
        Log Many    ${cluster_name}
        FOR    ${name}    IN    @{clusterpoolname}
            IF    "${name}[metadata][name]" == "${pool_name}"
                Log    ${name}[metadata][name]    console=True
                ${clustername_exists} =    Set Variable    "${name}[metadata][name]"
                RETURN    ${clustername_exists}
            END
        END
    ELSE
        ${anycluster} =    Run Keyword And Return Status
        ...    Oc Get   kind=ClusterDeployment    namespace=${hive_namespace}
        ...    api_version=hive.openshift.io/v1
        IF    ${anycluster}
            ${clusterdeploymentname} =    Oc Get   kind=ClusterDeployment    namespace=${hive_namespace}
            ...    api_version=hive.openshift.io/v1    fields=['spec.clusterName']
            ${clusterdeploymentname}=    Set Variable    ${clusterdeploymentname}[0][spec.clusterName]
            Log    ${clusterdeploymentname}
            Log    ${cluster_name}
            IF    "${clusterdeploymentname}" == "${cluster_name}"
                RETURN    True
            END
        ELSE
            Log    message=No ClusterDeployment found in ${hive_namespace}.
        END
    END
    RETURN    False

Get Clusters
    @{clusters} =    Oc Get    kind=ClusterClaim    namespace=${hive_namespace}
    FOR   ${cluster}    IN    @{clusters}
        Log    Name: "${cluster}[spec][clusterPoolName]"    console=True
    END

Provision Cluster
    [Documentation]    If cluster does not exist already, it selects the
    ...                resource provisioning template based on the Cloud provider
    ...                and starts the creationg of cloud resources
    Log    Setting cluster ${cluster_name} configuration    console=True
    Should Be True    "${hive_kubeconf}" != "${EMPTY}"
    ${clustername_exists} =    Does ClusterName Exists    use_pool=${use_cluster_pool}
    ${template} =    Select Provisioner Template    ${provider_type}
    IF    ${clustername_exists}    Handle Already Existing Cluster
    Log     Configuring cluster ${cluster_name}    console=True
    Create Provider Resources

Handle Already Existing Cluster
    [Documentation]    Fails if the cluster already exists. It works with both ClusterPools
    ...                and ClusterDeployment provisioning type.
    IF    ${use_cluster_pool}
        Log    Cluster name '${cluster_name}' already exists in Hive pool '${pool_name}' - Checking if it has a valid web-console      console=True    # robocop: disable:line-too-long
        ${pool_namespace} =    Get Cluster Pool Namespace    ${pool_name}
        ${result} =    Run Process    oc -n ${pool_namespace} get cd ${pool_namespace} -o json | jq -r '.status.webConsoleURL' --exit-status    shell=yes    # robocop: disable:line-too-long
    ELSE
        Log    Cluster name '${cluster_name}' already exists as Hive ClusterDeployment - Checking if it has a valid web-console      console=True    # robocop: disable:line-too-long
        ${result} =    Run Process    oc -n ${hive_namespace} get cd ${cluster_name} -o json | jq -r '.status.webConsoleURL' --exit-status    shell=yes        # robocop: disable:line-too-long
    END
    IF    ${result.rc} != 0
        FAIL    Cluster '${cluster_name}' is already in use and it has previously failed to be provisioned.
    ELSE
        FAIL    Cluster '${cluster_name}' is already in use, please choose a different name.
    END

Create Provider Resources
    Log    Creating Hive resources for cluster ${cluster_name} on ${provider_type} according to: ${template}   console=True
    IF    "${provider_type}" in ["AWS", "GCP", "AZURE"]
        Oc Apply    kind=List    src=${template}    api_version=v1
        ...    template_data=${infrastructure_configurations}
    ELSE IF    "${provider_type}" == "OSP"
        Create Openstack Resources
    ELSE IF    "${provider_type}" == "IBM"
        Create IBM CredentialsRequests And Service IDs
        Create IBM Manifests Secret
        ${hive_yaml} =    Set Variable    ${artifacts_dir}/${cluster_name}_hive.yaml
        Create File From Template    ${template}    ${hive_yaml}
        Oc Apply    kind=List    src=${hive_yaml}    api_version=v1
    ELSE
        FAIL    Invalid provider name
    END

Select Provisioner Template
    [Arguments]    ${provider_type}
    IF    "${provider_type}" == "AWS"
        Set Task Variable    ${template}    tasks/Resources/Provisioning/Hive/AWS/aws-cluster.yaml
    ELSE IF    "${provider_type}" == "GCP"
        Set Task Variable    ${template}    tasks/Resources/Provisioning/Hive/GCP/gcp-cluster.yaml
    ELSE IF    "${provider_type}" == "OSP"
        Set Task Variable    ${template}    tasks/Resources/Provisioning/Hive/OSP/hive_osp_cluster_template.yaml
    ELSE IF    "${provider_type}" == "IBM"
        Set Task Variable    ${template}    tasks/Resources/Provisioning/Hive/IBM/ibmcloud-cluster.yaml
    ELSE IF    "${provider_type}" == "AZURE"
        Set Task Variable    ${template}    tasks/Resources/Provisioning/Hive/AZURE/azure-cluster.yaml
    ELSE
        FAIL    Invalid provider name
    END
    Log    Setting ${provider_type} Hive Template ${template}    console=True
    RETURN    ${template}

Create Openstack Resources
    Log    Creating OSP resources in Cloud '${infrastructure_configurations}[osp_cloud_name]'    console=True
    ${result}    Run Process 	echo '${infrastructure_configurations}[osp_cloud_name]' | base64 -w0    shell=yes
    Should Be True    ${result.rc} == 0
    Set Task Variable    ${OSP_CLOUD}    ${result.stdout}
    ${FIP_API}    Evaluate    ${infrastructure_configurations}.get('fip_api')
    ${FIP_APPS}    Evaluate    ${infrastructure_configurations}.get('fip_apps')
    Run Keyword If    "${FIP_API}" == "" or "${FIP_APPS}" == ""    Create Floating IPs
    ...    ELSE    Log    Reusing existing Floating IPs    console=True
    Set Task Variable    ${FIP_API}
    Set Task Variable    ${FIP_APPS}
    Log    FIP_API = ${FIP_API}    console=True
    Log    FIP_APPS = ${FIP_APPS}    console=True
    ${hive_yaml} =    Set Variable    ${artifacts_dir}/${cluster_name}_hive.yaml
    Create File From Template    ${template}    ${hive_yaml}
    Log    OSP Hive configuration for cluster ${cluster_name}: ${hive_yaml}    console=True
    Oc Apply    kind=List    src=${hive_yaml}    api_version=v1

Create Floating IPs
    Log    Creating Openstack Floating IPs and AWS DNS Records    console=True
    ${osp_clouds_yaml} =    Set Variable    ~/.config/openstack/clouds.yaml
    ${result} 	Run Process 	echo '${infrastructure_configurations}[osp_yaml_encoded]' | base64 --decode    shell=yes
    Should Be True    ${result.rc} == 0
    Create File    ${osp_clouds_yaml}    ${result.stdout}
    File Should Not Be Empty    ${osp_clouds_yaml}
    ${shell_script} =     Catenate
    ...    ${CURDIR}/OSP/create_fips.sh ${cluster_name} ${infrastructure_configurations}[base_domain]
    ...    ${infrastructure_configurations}[osp_network] ${infrastructure_configurations}[osp_cloud_name] ${artifacts_dir}/
    ...    ${infrastructure_configurations}[AWS_ACCESS_KEY_ID] ${infrastructure_configurations}[AWS_SECRET_ACCESS_KEY]
    ${return_code} =    Run and Watch Command    ${shell_script}    output_should_contain=Exporting Floating IPs
    Should Be Equal As Integers	${return_code}	 0   msg=Error creating floating IPs for cluster '${cluster_name}'
    ${fips_file_to_export} =    Set Variable
    ...    ${artifacts_dir}/${cluster_name}.${infrastructure_configurations}[base_domain].fips
    Export Variables From File    ${fips_file_to_export}

Watch Hive Install Log
    [Arguments]    ${pool_name}    ${namespace}    ${hive_timeout}=80m
    ${label_selector} =    Set Variable    hive.openshift.io/cluster-deployment-name=${cluster_name}
    IF    ${use_cluster_pool}
        ${label_selector} =    Set Variable    hive.openshift.io/clusterpool-name=${pool_name}
    END
    ${label_selector} =    Catenate    SEPARATOR=    ${label_selector}    ,hive.openshift.io/job-type=provision
    ${logs_cmd} =     Set Variable    oc logs -f -l ${label_selector} -n ${namespace}
    Wait For Pods To Be Ready    label_selector=${label_selector}    namespace=${namespace}    timeout=5m
    TRY
        ${return_code} =    Run And Watch Command    ${logs_cmd}    timeout=${hive_timeout}
        ...    output_should_contain=install completed successfully
    EXCEPT
        Log To Console    ERROR: Check Hive Logs if present or you may have hit timeout ${hive_timeout}.
    END
    Should Be Equal As Integers    ${return_code}    ${0}
    ${hive_pods_status} =    Run And Return Rc
    ...    oc get pod -n ${namespace} --no-headers | awk '{print $3}' | grep -v 'Completed'
    IF    ${hive_pods_status} != 0
        Log    All Hive pods in ${namespace} have completed    console=True
    END
    Sleep   10s    reason=Let's wait some seconds before proceeding with next checks

Wait For Cluster To Be Ready
    IF    ${use_cluster_pool}
        ${pool_namespace} =    Get Cluster Pool Namespace    ${pool_name}
        Set Task Variable    ${pool_namespace}
        Set Task Variable    ${clusterdeployment_name}    ${pool_namespace}
        Log    Watching Hive Pool namespace: ${pool_namespace}    console=True
    ELSE
        Set Task Variable    ${pool_namespace}    ${hive_namespace}
        Set Task Variable    ${clusterdeployment_name}    ${cluster_name}
        Log    Watching Hive ClusterDeployment namespace: ${pool_namespace}    console=True
    END
    ${install_log_file} =    Set Variable    ${artifacts_dir}/${cluster_name}_install.log
    Create File    ${install_log_file}
    Run Keyword And Continue On Failure    Watch Hive Install Log    ${pool_name}    ${pool_namespace}
    Log    Verifying that Cluster '${cluster_name}' has been provisioned and is running according to Hive Pool namespace '${pool_namespace}'      console=True    # robocop: disable:line-too-long
    ${provision_status} =    Run Process
    ...    oc -n ${pool_namespace} wait --for\=condition\=ProvisionFailed\=False cd ${clusterdeployment_name} --timeout\=15m    # robocop: disable:line-too-long
    ...    shell=yes
    ${web_access} =    Run Process
    ...    oc -n ${pool_namespace} get cd ${clusterdeployment_name} -o json | jq -r '.status.webConsoleURL' --exit-status    # robocop: disable:line-too-long
    ...    shell=yes
    IF    ${use_cluster_pool}
        ${custer_status} =    Run Process
        ...    oc -n ${hive_namespace} wait --for\=condition\=ClusterRunning\=True clusterclaim ${claim_name} --timeout\=15m    shell=yes    # robocop: disable:line-too-long
    ELSE
        ${custer_status} =    Run Process
        ...    oc -n ${hive_namespace} wait --for\=condition\=Ready\=True clusterdeployment ${clusterdeployment_name} --timeout\=15m    shell=yes    # robocop: disable:line-too-long
    END
    # Workaround for old Hive with Openstack - Cluster is displayed as Resuming even when it is Running
    # add also support to the new Hive where the Cluster is displayed as Running
    IF    "${provider_type}" == "OSP"
        ${custer_status} =    Run Process
        ...	oc -n ${hive_namespace} get clusterclaim ${claim_name} -o json | jq '.status.conditions[] | select(.type\=\="ClusterRunning" and (.reason\=\="Resuming" or .reason\=\="Running"))' --exit-status    shell=yes    # robocop: disable:line-too-long
    END
    IF    ${provision_status.rc} != 0 or ${web_access.rc} != 0 or ${custer_status.rc} != 0
        ${provision_status} =    Run Process    oc -n ${pool_namespace} get cd ${clusterdeployment_name} -o json    shell=yes    # robocop: disable:line-too-long
        ${custer_status} =    Run Process    oc -n ${hive_namespace} get clusterclaim ${claim_name} -o json    shell=yes
        Log    Cluster '${cluster_name}' deployment had errors, see: ${\n}${provision_status.stdout}${\n}${custer_status.stdout}    level=ERROR    # robocop: disable:line-too-long
        Log    Cluster '${cluster_name}' install completed, but it is not accessible
        ...    console=True
        FAIL    Cluster '${cluster_name}' provisioning failed. Please look into the logs for more details.
    END
    Log    Cluster '${cluster_name}' install completed and accessible at: ${web_access.stdout}     console=True

Save Cluster Credentials
    Set Task Variable    ${cluster_details}    ${artifacts_dir}/${cluster_name}_details.txt
    ${result} =    Run Process
    ...    oc -n ${pool_namespace} get cd ${clusterdeployment_name} -o json | jq -r '.status.webConsoleURL' --exit-status    # robocop: disable:line-too-long
    ...    shell=yes
    Should Be True    ${result.rc} == 0
    ...    Hive Cluster deployment '${clusterdeployment_name}' does not have a valid webConsoleURL access
    Create File     ${cluster_details}    console=${result.stdout}\n
    ${result} =    Run Process
    ...    oc -n ${pool_namespace} get cd ${clusterdeployment_name} -o json | jq -r '.status.apiURL' --exit-status
    ...    shell=yes
    Append To File     ${cluster_details}     api=${result.stdout}\n
    ${result} =    Run Process    oc extract -n ${pool_namespace} --confirm secret/$(oc -n ${pool_namespace} get cd ${clusterdeployment_name} -o jsonpath\='{.spec.clusterMetadata.adminPasswordSecretRef.name}') --to\=${artifacts_dir}    # robocop: disable:line-too-long
    ...    shell=yes
    Should Be True    ${result.rc} == 0
    ${username} = 	Get File 	${artifacts_dir}/username
    ${password} = 	Get File 	${artifacts_dir}/password
    Append To File     ${cluster_details}     username=${username}\n
    Append To File     ${cluster_details}     password=${password}\n
    ${result} =    Run Process    oc extract -n ${pool_namespace} --confirm secret/$(oc -n ${pool_namespace} get cd ${clusterdeployment_name} -o jsonpath\='{.spec.clusterMetadata.adminKubeconfigSecretRef.name}') --to\=${artifacts_dir}    # robocop: disable:line-too-long
    ...    shell=yes
    Should Be True    ${result.rc} == 0

Login To Cluster
    ${cluster_kubeconf} =    Set Variable    ${artifacts_dir}/kubeconfig
    Export Variables From File    ${cluster_details}
    Create File     ${cluster_kubeconf}
    # Test the extracted credentials
    ${result} =    Run Process    KUBECONFIG\=${cluster_kubeconf} oc login --username\=${username} --password\=${password} ${api} --insecure-skip-tls-verify    shell=yes
    Should Be True    ${result.rc} == 0
    # Test the kubeconfig file that was also extracted
    ${result} =    Run Process    KUBECONFIG\=${cluster_kubeconf} oc status    shell=yes
    Log    ${result.stdout}\n${result.stderr}     console=True
    Should Be True    ${result.rc} == 0

Get Cluster Pool Namespace
    [Arguments]    ${hive_pool_name}
    Log    Cluster pool name is: ${hive_pool_name}     console=True
    ${namespace} =    Wait Until Keyword Succeeds    2 min    2 s
    ...    Oc Get    kind=Namespace    label_selector=hive.openshift.io/cluster-pool-name=${hive_pool_name}
    ${pool_namespace} =    Set Variable   ${namespace[0]['metadata']['name']}
    RETURN    ${pool_namespace}

Create IBM CredentialsRequests And Service IDs
    [Documentation]    Creates the credentials requests manifests and Service IDs resources
    ...                necessary for creating IBM Cloud resources
    ...                ref: https://github.com/openshift/cloud-credential-operator/blob/master/docs/ccoctl.md#ibmcloud
    ${result}=    Run Process    command=mkdir credreqs ; oc adm release extract --cloud=ibmcloud --credentials-requests ${release_image} --to=./credreqs    # robocop: disable:line-too-long
    ...    shell=yes
    Should Be True    ${result.rc} == 0    msg=${result.stderr}
    Set Log Level    NONE
    ${result}=    Run Process    command=export IC_API_KEY=${infrastructure_configurations}[ibmcloud_api_key] && ccoctl ibmcloud create-service-id --credentials-requests-dir ./credreqs --name ${cluster_name}    # robocop: disable:line-too-long
    ...    shell=yes
    Set Log Level    INFO
    Should Be True    ${result.rc} == 0    msg=${result.stderr}

Create IBM Manifests Secret
    [Documentation]    Creates Secrets in hive containing the CredentialsRequests manifests
    ${result}=    Run Process    command=oc create secret generic ${cluster_name}-manifests -n ${hive_namespace} --from-file=./manifests    # robocop: disable:line-too-long
    ...    shell=yes
    Log    ${result.stderr}
    Should Be True    ${result.rc} == 0    msg=${result.stderr}
