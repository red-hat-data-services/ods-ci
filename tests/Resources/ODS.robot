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

Library  OpenShiftLibrary


*** Variables ***
${USAGE_DATA_COLLECTION_DEFAULT_SEGMENT_PUBLIC_KEY}     KRUhoAIEpWlGuz4sWixae1vAXKKGlD5K


*** Keywords ***
Scale Deployment
    [Documentation]    Sets the size (number of pods) for a deployment
    [Arguments]    ${namespace}    ${deployment-name}    ${replicas}=1    ${sleep-time}=10s
    Run    oc -n ${namespace} scale deployment ${deployment-name} --replicas=${replicas}
    Sleep    ${sleep-time}    reason=Wait until ${deployment-name} deployment is scaled to replicas=${replicas}

Restore Default Deployment Sizes
    [Documentation]    Restores the default sizes to all deployments in ODS
    ODS.Scale Deployment    redhat-ods-applications    rhods-dashboard    replicas=2
    ODS.Scale Deployment    redhat-ods-applications    traefik-proxy    replicas=3
    ODS.Scale Deployment    redhat-ods-monitoring    blackbox-exporter    replicas=1
    ODS.Scale Deployment    redhat-ods-monitoring    grafana    replicas=2
    ODS.Scale Deployment    redhat-ods-monitoring    prometheus    replicas=1
    ODS.Scale Deployment    redhat-ods-operator    rhods-operator    replicas=1    sleep-time=30s

Verify "Usage Data Collection" Key
    [Documentation]    Verifies that "Usage Data Collection" is using the expcected segment.io key
    ${version_check}=    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check}==True
        ${segment_key}=    ODS.Get "Usage Data Collection" Key
        Should Be Equal As Strings    ${segment_key}    ${USAGE_DATA_COLLECTION_DEFAULT_SEGMENT_PUBLIC_KEY}
        ...    msg=Unexpected "Usage Data Collection" Key
    END

Get "Usage Data Collection" Key
    [Documentation]    Returns the segment.io key used for usage data collection

    ${rc}    ${usage_data_collection_key_base64}=    Run And Return Rc And Output
    ...    oc get secret rhods-segment-key -n redhat-ods-applications -o jsonpath='{.data.segmentKey}'
    Should Be Equal As Integers    ${rc}    0    msg=rhods-segment-key secret not found or not having the right format

    ${usage_data_collection_key}=    Evaluate
    ...    base64.b64decode("${usage_data_collection_key_base64}").decode('utf-8')    modules=base64

    [Return]    ${usage_data_collection_key}

Is Usage Data Collection Enabled
    [Documentation]    Returns a boolean with the value of configmap rhods-segment-key-config > segmentKeyEnabled
    ...    which can be seen also in ODS Dashboard > Cluster Settings > "Usage Data Collection"
    ${usage_data_collection_enabled}=    Run
    ...    oc get configmap rhods-segment-key-config -n redhat-ods-applications -o jsonpath='{.data.segmentKeyEnabled}'
    ${usage_data_collection_enabled}=    Convert To Boolean    ${usage_data_collection_enabled}
    [Return]    ${usage_data_collection_enabled}

Usage Data Collection Should Be Enabled
    [Documentation]    Fails if "Usage Data Collection" is not enabled in ODS Dashboard > Cluster Settings
    [Arguments]    ${msg}="Usage Data Collection" should be enabled
    ${enabled}=    ODS.Is Usage Data Collection Enabled
    Should Be True    ${enabled}    msg=${msg}

Usage Data Collection Should Not Be Enabled
    [Documentation]    Fails if "Usage Data Collection" is enabled in ODS Dashboard > Cluster Settings
    [Arguments]    ${msg}="Usage Data Collection" should not be enabled
    ${enabled}=    ODS.Is Usage Data Collection Enabled
    Should Not Be True    ${enabled}    msg=${msg}

Set Standard RHODS Groups Variables
    [Documentation]     Sets the RHODS groups name based on RHODS version
    ${version_check}=    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check} == True
        Set Suite Variable    ${STANDARD_ADMINS_GROUP}      dedicated-admins
        Set Suite Variable    ${STANDARD_USERS_GROUP}       system:authenticated
        Set Suite Variable    ${STANDARD_GROUPS_MODIFIED}       true
    ELSE
        Set Suite Variable    ${STANDARD_ADMINS_GROUP}      rhods-admins
        Set Suite Variable    ${STANDARD_USERS_GROUP}       rhods-users
        Set Suite Variable    ${STANDARD_GROUPS_MODIFIED}       false
    END

Apply Access Groups Settings
    [Documentation]    Changes the rhods-groups config map to set the new access configuration
    [Arguments]     ${admins_group}   ${users_group}    ${groups_modified_flag}
    OpenShiftCLI.Patch    kind=ConfigMap
    ...                   src={"data":{"admin_groups": "${admins_group}","allowed_groups": "${users_group}"}}
    ...                   name=rhods-groups-config   namespace=redhat-ods-applications  type=merge
    OpenShiftCLI.Patch    kind=ConfigMap
    ...                   src={"metadata":{"labels": {"opendatahub.io/modified": "${groups_modified_flag}"}}}
    ...                   name=rhods-groups-config   namespace=redhat-ods-applications  type=merge
    # Rollout JupyterHub

Set Default Access Groups Settings
    [Documentation]    Restores the default rhods-groups config map
    Apply Access Groups Settings     admins_group=${STANDARD_ADMINS_GROUP}
    ...     users_group=${STANDARD_USERS_GROUP}   groups_modified_flag=${STANDARD_GROUPS_MODIFIED}
    Rollout JupyterHub

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
    Verify Project Does Not Exists  redhat-ods-monitoring
    Verify Project Does Not Exists  redhat-ods-applications
    Verify Project Does Not Exists  redhat-ods-operator

Get Notification Email From Addon-Managed-Odh-Parameters Secret
    [Documentation]    Gets email form addon-managed-odh-parameters secret
    ${resp} =    Oc Get  kind=Secret  namespace=redhat-ods-operator  name=addon-managed-odh-parameters
    ${resp} =  Evaluate  dict(${resp[0]["metadata"]["annotations"]["kubectl.kubernetes.io/last-applied-configuration"]})
    [Return]  ${resp["stringData"]["notification-email"]}

Notification Email In Alertmanager ConfigMap Should Be
    [Documentation]    Check expected email is present in Alertmanager
    [Arguments]        ${email_to_check}
    ${resp} =    Run  oc get configmap alertmanager -n redhat-ods-monitoring -o jsonpath='{.data.alertmanager\\.yml}' | yq '.receivers[] | select(.name == "user-notifications") | .email_configs[0].to'
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
    [Return]   ${href}

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
        Should Be Equal As Strings    ${dict.${actual}}    ${expected}
    END

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

Verify RHODS Groups Config Map Contains Expected Values
    [Documentation]    Verifies if the group contains the expected value
    [Arguments]        &{exp_values}
    ${configmap}=  Oc Get  kind=ConfigMap  namespace=redhat-ods-applications  name=rhods-groups-config
    FOR    ${group}    IN    @{exp_values.keys()}
        Should Be Equal As Strings  ${configmap[0]["data"]["${group}"]}   ${exp_values["${group}"]}
    END

Verify Default Access Groups Settings
    [Documentation]     Verifies that ODS contains the expected default groups settings
    ${version_check}=    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check} == True
        &{exp_values}=  Create Dictionary  admin_groups=dedicated-admins  allowed_groups=system:authenticated
        Verify RHODS Groups Config Map Contains Expected Values   &{exp_values}
    ELSE
        &{exp_values}=  Create Dictionary  admin_groups=rhods-admins  allowed_groups=rhods-users
        Verify RHODS Groups Config Map Contains Expected Values   &{exp_values}
    END

Enable Access To Grafana Using OpenShift Port Forwarding
    [Documentation]  Enable Access to Grafana Using OpenShift Port-Forwarding
    ${grafana_port_forwarding_process} =  Start Process   oc -n redhat-ods-monitoring port-forward $(oc get pods -n redhat-ods-monitoring | grep grafana | awk '{print $1}' | head -n 1) 3001  shell=True  # robocop: disable
    [Return]    ${grafana_port_forwarding_process}

Enable Access To Prometheus Using OpenShift Port Forwarding
    [Documentation]  Enable Access to Prometheus Using OpenShift Port-Forwarding
    ${promethues_port_forwarding_process} =  Start Process   oc -n redhat-ods-monitoring port-forward $(oc get pods -n redhat-ods-monitoring | grep prometheus | awk '{print $1}') 9090  shell=True  # robocop: disable
    [Return]    ${promethues_port_forwarding_process}

Enable Access To Alert Manager Using OpenShift Port Forwarding
    [Documentation]  Enable Access to Alert Manager Using OpenShift Port-Forwarding
    ${alertmanager_port_forwarding_process} =  Start Process   oc -n redhat-ods-monitoring port-forward $(oc get pods -n redhat-ods-monitoring | grep prometheus | awk '{print $1}') 9093   shell=True  # robocop: disable
    [Return]    ${alertmanager_port_forwarding_process}

Get Grafana Url
    [Documentation]  Returns Grafana URL
    ${grafana_url} =    Run    oc get routes/grafana -n redhat-ods-monitoring -o json | jq -r '.spec.host'
    [Return]    ${grafana_url}

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
    [Arguments]    ${container_info}
    &{container_info_dict} =    Set Variable    ${container_info}
    OpenShift Resource Component Should Contain Field     ${container_info_dict}    resources
    Run Keyword If   'resources' in ${container_info_dict}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources}    requests
    Run Keyword If   'resources' in ${container_info_dict}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources}    limits
    Run Keyword If   'requests' in ${container_info_dict.resources}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources.requests}    cpu
    Run Keyword If   'requests' in ${container_info_dict.resources}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources.requests}    memory
    Run Keyword If   'limits' in ${container_info_dict.resources}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources.limits}    cpu
    Run Keyword If   'limits' in ${container_info_dict.resources}
    ...    OpenShift Resource Component Should Contain Field     ${container_info_dict.resources.limits}    memory

Fetch Project Pods Info
    [Documentation]    Fetches information of all Pods for the specified Project
    ...    Args:
    ...        project: Project name
    ...    Returns:
    ...        project_pods_info: List of Project Pods information
    [Arguments]    ${project}
    @{project_pods_info}=    Oc Get    kind=Pod    api_version=v1    namespace=${project}
    [Return]    @{project_pods_info}

Fetch Cluster Platform Type
    [Documentation]  Fetches the platform type of the cluster
    ...    Args:
    ...        None
    ...    Returns:
    ...        cluster_platform_type(str): Platform type of the cluster
    &{cluster_infrastructure_info}=    Fetch Cluster Infrastructure Info
    ${cluster_platform_type}=    Set Variable    ${cluster_infrastructure_info.spec.platformSpec.type}
    [Return]    ${cluster_platform_type}


Fetch Cluster Infrastructure Info
    [Documentation]  Fetches information about the infrastructure of the cluster
    ...    Args:
    ...        None
    ...    Returns:
    ...        cluster_infrastructure_info(dict): Dictionary containing the information of the infrastructure of the cluster
    @{resources_info_list}=    Oc Get    kind=Infrastructure    api_version=config.openshift.io/v1    name=cluster
    &{cluster_infrastructure_info}=    Set Variable    ${resources_info_list}[0]
    [Return]    &{cluster_infrastructure_info}

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

