*** Settings ***
Documentation       Main ODS resource file (includes ODHDashboard, ODHJupyterhub, Prometheus ... resources)
...                 with some useful keywords to control the operator and main deployments

Resource            ./Page/LoginPage.robot
Resource            ./Page/ODH/ODHDashboard/ODHDashboard.resource
Resource            ./Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource            ./Page/ODH/Prometheus/Prometheus.resource
Resource            ./Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../tasks/Resources/RHODS_OLM/uninstall/uninstall.robot
Resource            ../../tasks/Resources/RHODS_OLM/uninstall/oc_uninstall.robot
Resource            ../../tasks/Resources/RHODS_OLM/config/cluster.robot
Resource            ../../tests/Resources/Common.robot

Library  OpenShiftLibrary


*** Variables ***
${USAGE_DATA_COLLECTION_DEFAULT_SEGMENT_PUBLIC_KEY}     KRUhoAIEpWlGuz4sWixae1vAXKKGlD5K


*** Keywords ***
Scale Deployment
    [Documentation]    Sets the size (number of pods) for a deployment
    [Arguments]    ${namespace}    ${deployment-name}    ${replicas}=1    ${sleep-time}=10s
    Run    oc -n ${namespace} scale deployment ${deployment-name} --replicas=${replicas}
    Sleep    ${sleep-time}    reason=Wait until ${deployment-name} deployment is scaled to replicas=${replicas}

Scale DeploymentConfig
    [Documentation]    Sets the size (number of pods) for a deploymentconfig
    [Arguments]    ${namespace}    ${deploymentconfig-name}    ${replicas}=1    ${sleep-time}=10s
    Run    oc -n ${namespace} scale deploymentconfig ${deploymentconfig-name} --replicas=${replicas}
    Sleep    ${sleep-time}    reason=Wait until ${deploymentconfig-name} deploymentconfig is scaled to replicas=${replicas}

Restore Default Deployment Sizes
    [Documentation]    Restores the default sizes to all deployments in ODS
    ODS.Scale Deployment    ${APPLICATIONS_NAMESPACE}    notebook-controller-deployment     replicas=1
    ODS.Scale Deployment    ${APPLICATIONS_NAMESPACE}    odh-notebook-controller-manager    replicas=1
    ODS.Scale Deployment    ${APPLICATIONS_NAMESPACE}    rhods-dashboard                    replicas=2
    ODS.Scale Deployment    ${MONITORING_NAMESPACE}      blackbox-exporter                  replicas=1
    ODS.Scale Deployment    ${MONITORING_NAMESPACE}      grafana                            replicas=2
    ODS.Scale Deployment    ${MONITORING_NAMESPACE}      prometheus                         replicas=1
    ODS.Scale Deployment    ${OPERATOR_NAMESPACE}        rhods-operator                     replicas=1    sleep-time=30s

Verify "Usage Data Collection" Key
    [Documentation]    Verifies that "Usage Data Collection" is using the expected segment.io key
    ${segment_key}=    ODS.Get "Usage Data Collection" Key
    Should Be Equal As Strings    ${segment_key}    ${USAGE_DATA_COLLECTION_DEFAULT_SEGMENT_PUBLIC_KEY}
    ...    msg=Unexpected "Usage Data Collection" Key

Get "Usage Data Collection" Key
    [Documentation]    Returns the segment.io key used for usage data collection

    ${rc}    ${usage_data_collection_key_base64}=    Run And Return Rc And Output
    ...    oc get secret odh-segment-key -n ${APPLICATIONS_NAMESPACE} -o jsonpath='{.data.segmentKey}'
    Should Be Equal As Integers    ${rc}    0    msg=odh-segment-key secret not found or not having the right format

    ${usage_data_collection_key}=    Evaluate
    ...    base64.b64decode("${usage_data_collection_key_base64}").decode('utf-8')    modules=base64

    RETURN    ${usage_data_collection_key}

Is Usage Data Collection Enabled
    [Documentation]    Returns a boolean with the value of configmap odh-segment-key-config > segmentKeyEnabled
    ...    which can be seen also in ODS Dashboard > Cluster settings > "Usage Data Collection"
    ${usage_data_collection_enabled}=    Run
    ...    oc get configmap odh-segment-key-config -n ${APPLICATIONS_NAMESPACE} -o jsonpath='{.data.segmentKeyEnabled}'
    ${usage_data_collection_enabled}=    Convert To Boolean    ${usage_data_collection_enabled}
    RETURN    ${usage_data_collection_enabled}

Usage Data Collection Should Be Enabled
    [Documentation]    Fails if "Usage Data Collection" is not enabled in ODS Dashboard > Cluster settings
    [Arguments]    ${msg}="Usage Data Collection" should be enabled
    ${enabled}=    ODS.Is Usage Data Collection Enabled
    Should Be True    ${enabled}    msg=${msg}

Usage Data Collection Should Not Be Enabled
    [Documentation]    Fails if "Usage Data Collection" is enabled in ODS Dashboard > Cluster settings
    [Arguments]    ${msg}="Usage Data Collection" should not be enabled
    ${enabled}=    ODS.Is Usage Data Collection Enabled
    Should Not Be True    ${enabled}    msg=${msg}

Set Standard RHODS Groups Variables
    [Documentation]     Sets the RHODS groups name based on RHODS version
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    ${is_self_managed} == False
        Set Suite Variable    ${STANDARD_ADMINS_GROUP}    dedicated-admins
    ELSE
        Set Suite Variable    ${STANDARD_ADMINS_GROUP}    rhods-admins
    END
    Set Suite Variable    ${STANDARD_SYSTEM_GROUP}    system:authenticated
    Set Suite Variable    ${STANDARD_USERS_GROUP}    rhods-users


Apply Access Groups Settings
    [Documentation]    Changes the rhods-groups config map to set the new access configuration
    ...                and rolls out JH to make the changes effecting in Jupyter
    [Arguments]     ${admins_group}   ${users_group}
    Set Access Groups Settings    admins_group=${admins_group}   users_group=${users_group}
    Sleep    120     reason=Wait for Dashboard to get the updated configuration...

Set Access Groups Settings
    [Documentation]    Changes the rhods-groups config map to set the new access configuration
    [Arguments]     ${admins_group}   ${users_group}
    ${return_code}    ${output}    Run And Return Rc And Output    oc patch OdhDashboardConfig odh-dashboard-config -n ${APPLICATIONS_NAMESPACE} --type=merge -p '{"spec": {"groupsConfig": {"adminGroups": "${admins_group}","allowedGroups": "${users_group}"}}}'   #robocop:disable
    Should Be Equal As Integers	${return_code}	 0    msg=Patch to group settings failed

Set Default Access Groups Settings
    [Documentation]    Restores the default rhods-groups config map
    Apply Access Groups Settings     admins_group=${STANDARD_ADMINS_GROUP}
    ...     users_group=${STANDARD_SYSTEM_GROUP}

Uninstall RHODS From OSD Cluster
    [Documentation]    Selects the cluster type and triggers the RHODS uninstallation
    [Arguments]     ${clustername}
    ${addon_installed}=     Is Rhods Addon Installed    ${clustername}
    Uninstall RHODS Using OLM
    # IF    ${addon_installed} == ${TRUE}
    #     Uninstall Rhods Using Addon    ${clustername}
    # ELSE
    #     Uninstall RHODS Using OLM
    # END

Uninstall RHODS Using OLM
    [Documentation]     Uninstalls RHODS using OLM script
    Selected Cluster Type OSD
    Uninstall RHODS

Wait Until RHODS Uninstallation Is Completed
    [Documentation]     Waits until RHODS uninstallation process is completed.
    ...                 It finishes when all the RHODS namespaces have been deleted.
    [Arguments]     ${retries}=1   ${retries_interval}=2min
    FOR  ${retry_idx}  IN RANGE  0  1+${retries}
        Log To Console    checking RHODS uninstall status: retry ${retry_idx}
        ${ns_deleted}=     Run Keyword And Return Status    RHODS Namespaces Should Not Exist
        Exit For Loop If    $ns_deleted == True
        Sleep    ${retries_interval}
    END
    IF    $ns_deleted == False
        Fail    RHODS didn't get "complete" stage after ${retries} retries
        ...     (time between retries: ${retries_interval}). Check the cluster..
    END

RHODS Namespaces Should Not Exist
    [Documentation]     Checks if the RHODS namespace do not exist on openshift
    Verify Project Does Not Exists  rhods-notebook
    Verify Project Does Not Exists  ${MONITORING_NAMESPACE}
    Verify Project Does Not Exists  ${APPLICATIONS_NAMESPACE}
    Verify Project Does Not Exists  ${OPERATOR_NAMESPACE}

Get Notification Email From Addon-Managed-Odh-Parameters Secret
    [Documentation]    Gets email form addon-managed-odh-parameters secret
    ${resp} =    Oc Get  kind=Secret  namespace=${OPERATOR_NAMESPACE}  name=addon-managed-odh-parameters
    ${resp} =  Evaluate  dict(${resp[0]["metadata"]["annotations"]["kubectl.kubernetes.io/last-applied-configuration"]})
    RETURN  ${resp["stringData"]["notification-email"]}

Notification Email In Alertmanager ConfigMap Should Be
    [Documentation]    Check expected email is present in Alertmanager
    [Arguments]        ${email_to_check}
    ${resp} =    Run  oc get configmap alertmanager -n ${MONITORING_NAMESPACE} -o jsonpath='{.data.alertmanager\\.yml}' | yq '.receivers[] | select(.name == "user-notifications") | .email_configs[0].to'
    Should Be Equal As Strings    "${email_to_check}"    ${resp}

Email In Addon-Managed-Odh-Parameters Secret Should Be
    [Documentation]     Verifies the email is same with expected-email
    [Arguments]     ${expected_email}
    ${email_from_secret} =    Get Notification Email From Addon-Managed-Odh-Parameters Secret
    Should Be Equal As Strings    ${expected_email}    ${email_from_secret}

Wait Until Notification Email From Addon-Managed-Odh-Parameters Contains
    [Documentation]     Wait unitl notification email is changed in Addon-Managed-Odh-Parameters
    [Arguments]    ${email}  ${timeout}=5 min
    Wait Until Keyword Succeeds    ${timeout}    30s
    ...    Email In Addon-Managed-Odh-Parameters Secret Should Be    ${email}

Wait Until Notification Email In Alertmanager ConfigMap Is
    [Documentation]     Wait unitl notification email is changed in Alertmanager ConfigMap
    [Arguments]    ${email}  ${timeout}=5 min
    Wait Until Keyword Succeeds    ${timeout}    30s
    ...    Notification Email In Alertmanager ConfigMap Should Be    ${email}

Get RHODS URL From OpenShift Using UI
    [Documentation]    Capture and return rhods url from
    ...     OpenShift console
    Click Element     //button[@aria-label="Application launcher"]
    Wait Until Element Is Visible    //a[@data-test="application-launcher-item"]
    ${link_elements}  Get WebElements
    ...     //a[@data-test="application-launcher-item" and starts-with(@href,'https://rhods')]
    ${href}  Get Element Attribute    ${link_elements}    href
    RETURN   ${href}

OpenShift Resource Field Value Should Be Equal As Strings
    [Documentation]
    ...    Args:
    ...        actual(str): Field with the actual value of the resource
    ...        expected(str): Expected value
    ...        resources(list(dict)): Resources from OpenShiftLibrary
    ...    Returns:
    ...        None
    [Arguments]    ${actual}    ${expected}    @{resources}
    FOR    ${resource}    IN    @{resources}
        &{dict} =    Set Variable    ${resource}
        ${status} =    Run Keyword And Return Status    Should Be Equal As Strings    ${dict.${actual}}    ${expected}
        Exit For Loop If    ${status}
    END
    IF    not ${status}   Fail     msg: Expected value didn't match with actual value

OpenShift Resource Field Value Should Match Regexp
    [Documentation]
    ...    Args:
    ...        actual(str): Field with the actual value of the resource
    ...        expected(str): Expected regular expression
    ...        resources(list(dict)): Resources from OpenShiftLibrary
    ...    Returns:
    ...        None
    [Arguments]    ${actual}    ${expected}    @{resources}
    FOR    ${resource}    IN    @{resources}
        &{dict} =    Set Variable    ${resource}
        Should Match Regexp    ${dict.${actual}}    ${expected}
    END

OpenShift Resource Component Should Contain Field
    [Documentation]    Checks if the specified OpenShift resource component contains
    ...                the specified field
    ...    Args:
    ...        resource_component: Resource component
    ...        field: Field
    ...    Returns:
    ...        None
    [Arguments]    ${resource_component}    ${field}
    Run Keyword And Continue On Failure    Should Contain    ${resource_component}    ${field}

Verify RHODS Dashboard CR Contains Expected Values
    [Documentation]    Verifies if the group contains the expected value
    [Arguments]        &{exp_values}
    ${config_cr}=  Oc Get  kind=OdhDashboardConfig  namespace=${APPLICATIONS_NAMESPACE}  name=odh-dashboard-config
    FOR    ${json_path}    IN    @{exp_values.keys()}
        ${value}=    Extract Value From JSON Path    json_dict=${config_cr[0]}
        ...    path=${json_path}
        Should Be Equal As Strings  ${value}   ${exp_values["${json_path}"]}
    END

Verify Default Access Groups Settings
    [Documentation]     Verifies that ODS contains the expected default groups settings
    &{exp_values}=  Create Dictionary  spec.groupsConfig.adminGroups=${STANDARD_ADMINS_GROUP}
    ...    spec.groupsConfig.allowedGroups=${STANDARD_SYSTEM_GROUP}
    Verify RHODS Dashboard CR Contains Expected Values   &{exp_values}

Enable Access To Grafana Using OpenShift Port Forwarding
    [Documentation]  Enable Access to Grafana Using OpenShift Port-Forwarding
    ${grafana_port_forwarding_process} =  Start Process   oc -n ${MONITORING_NAMESPACE} port-forward $(oc get pods -n ${MONITORING_NAMESPACE} | grep grafana | awk '{print $1}' | head -n 1) 3001  shell=True  # robocop: disable
    RETURN    ${grafana_port_forwarding_process}

Enable Access To Prometheus Using OpenShift Port Forwarding
    [Documentation]  Enable Access to Prometheus Using OpenShift Port-Forwarding
    ${promethues_port_forwarding_process} =  Start Process   oc -n ${MONITORING_NAMESPACE} port-forward $(oc get pods -n ${MONITORING_NAMESPACE} | grep prometheus | awk '{print $1}') 9090  shell=True  # robocop: disable
    RETURN    ${promethues_port_forwarding_process}

Enable Access To Alert Manager Using OpenShift Port Forwarding
    [Documentation]  Enable Access to Alert Manager Using OpenShift Port-Forwarding
    ${alertmanager_port_forwarding_process} =  Start Process   oc -n ${MONITORING_NAMESPACE} port-forward $(oc get pods -n ${MONITORING_NAMESPACE} | grep prometheus | awk '{print $1}') 9093   shell=True  # robocop: disable
    RETURN    ${alertmanager_port_forwarding_process}

Get Grafana Url
    [Documentation]  Returns Grafana URL
    ${grafana_url} =    Run    oc get routes/grafana -n ${MONITORING_NAMESPACE} -o json | jq -r '.spec.host'
    RETURN    ${grafana_url}

Verify CPU And Memory Requests And Limits Are Defined For Pod
    [Documentation]    Verifies that CPU and memory requests and limits are defined
    ...                for the specified pod
    ...    Args:
    ...        pod_info: Pod information
    ...    Returns:
    ...        None
    [Arguments]    ${pod_info}
    &{pod_info_dict}=    Set Variable    ${pod_info}
    FOR    ${container_info}    IN    @{pod_info_dict.spec.containers}
        Verify CPU And Memory Requests And Limits Are Defined For Pod Container    ${container_info}
    END

Verify CPU And Memory Requests And Limits Are Defined For Pod Container
    [Documentation]    Verifies that CPU and memory requests and limits are defined
    ...                for the specified container
    ...    Args:
    ...        container_info: Container information
    ...    Returns:
    ...        None
    [Arguments]    ${container_info}    ${nvidia_gpu}=${FALSE}
    &{container_info_dict} =    Set Variable    ${container_info}
    OpenShift Resource Component Should Contain Field     ${container_info_dict}    resources
    IF   'resources' in ${container_info_dict}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources}    requests
    IF   'resources' in ${container_info_dict}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources}    limits
    IF   'requests' in ${container_info_dict.resources}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources.requests}    cpu
    IF   'requests' in ${container_info_dict.resources}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources.requests}    memory
    IF   'limits' in ${container_info_dict.resources}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources.limits}    cpu
    IF   'limits' in ${container_info_dict.resources}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources.limits}    memory
    IF    ${nvidia_gpu} == ${TRUE}
        IF   'requests' in ${container_info_dict.resources}
        ...    OpenShift Resource Component Should Contain Field
        ...    ${container_info_dict.resources.requests}    nvidia.com/gpu
        IF   'limits' in ${container_info_dict.resources}
        ...    OpenShift Resource Component Should Contain Field
        ...    ${container_info_dict.resources.limits}    nvidia.com/gpu
    END

Fetch Project Pods Info
    [Documentation]    Fetches information of all Pods for the specified Project
    ...    Args:
    ...        project: Project name
    ...    Returns:
    ...        project_pods_info: List of Project Pods information
    [Arguments]    ${project}
    @{project_pods_info}=    Oc Get    kind=Pod    api_version=v1    namespace=${project}
    RETURN    @{project_pods_info}

Fetch Cluster Platform Type
    [Documentation]  Fetches the platform type of the cluster (AWS, GCP, OpenStack, ...)
    ...    Args:
    ...        None
    ...    Returns:
    ...        cluster_platform_type(str): Platform type of the cluster
    &{cluster_infrastructure_info}=    Fetch Cluster Infrastructure Info
    ${cluster_platform_type}=    Set Variable    ${cluster_infrastructure_info.spec.platformSpec.type}
    RETURN    ${cluster_platform_type}


Fetch Cluster Infrastructure Info
    [Documentation]  Fetches information about the infrastructure of the cluster
    ...    Args:
    ...        None
    ...    Returns:
    ...        cluster_infrastructure_info(dict): Dictionary containing the information of the infrastructure of the cluster
    @{resources_info_list}=    Oc Get    kind=Infrastructure    api_version=config.openshift.io/v1    name=cluster
    &{cluster_infrastructure_info}=    Set Variable    ${resources_info_list}[0]
    RETURN    &{cluster_infrastructure_info}

Fetch ODS Cluster Environment
   [Documentation]  Fetches the environment type of the cluster
   ...        Returns:
   ...        Cluster Environment (str)
   ${match}=    Fetch Cluster Platform Type
   IF    '${match}'!='AWS' and '${match}'!='GCP'    FAIL    msg=This keyword should be used only in OSD clusters
   ${match}  ${status}=    Run Keyword And Ignore Error  Should Contain    ${OCP_CONSOLE_URL}    devshift.org
   IF    "${match}" == "PASS"
       ${cluster_type}=  Set Variable  stage
   ELSE
       ${cluster_type}=  Set Variable  production
   END
   RETURN    ${cluster_type}

OpenShift Resource Component Field Should Not Be Empty
    [Documentation]    Checks if the specified OpenShift resource component field is not empty
    ...                the specified field
    ...    Args:
    ...        resource_component_field: Resource component field
    ...        field: Field
    ...    Returns:
    ...        None
    [Arguments]    ${resource_component_field}
    Run Keyword And Continue On Failure    Should Not Be Empty    ${resource_component_field}

Force Reboot OpenShift Cluster Node
    [Documentation]    Reboots the specified node of the cluster
    ...    Args:
    ...        node(str): Name of the node to reboot
    ...    Returns:
    ...        None
    [Arguments]    ${node}
    Run    oc debug node/"${node}" -T -- sh -c "echo b > /proc/sysrq-trigger"

Fetch Cluster Worker Nodes Info
    [Documentation]    Fetch information about the nodes of the cluster
    ...    Args:
    ...        None
    ...    Returns:
    ...        cluster_nodes_info(list(dict)): Cluster nodes information
    @{cluster_nodes_info}=    Oc Get    kind=Node    api_version=v1
    ...    label_selector=node-role.kubernetes.io/worker=,node-role.kubernetes.io!=master,node-role.kubernetes.io!=infra
    RETURN    @{cluster_nodes_info}

Delete RHODS Config Map
    [Documentation]    Deletes the given config map. It assumes the namespace is
    ...                ${APPLICATIONS_NAMESPACE}, but can be changed using the
    ...                corresponding argument
    [Arguments]     ${name}  ${namespace}=${APPLICATIONS_NAMESPACE}
    OpenShiftLibrary.Oc Delete    kind=ConfigMap  name=${name}  namespace=${namespace}
