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
    Rollout JupyterHub

Set Default Access Groups Settings
    [Documentation]    Restores the default rhods-groups config map
    Apply Access Groups Settings     admins_group=${STANDARD_ADMINS_GROUP}
    ...     users_group=${STANDARD_USERS_GROUP}   groups_modified_flag=${STANDARD_GROUPS_MODIFIED}

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

Disable Access To Grafana Using OpenShift Port Forwarding
    [Documentation]   Kill process running in background based on Id
    [Arguments]  ${PROC}
    Terminate Process   ${PROC}

Enable Access To Grafana Using OpenShift Port Forwarding
    [Documentation]  Enable Access to Grafana Using OpenShift Port-Forwarding
    ${PROC} =  Start Process   oc -n redhat-ods-monitoring port-forward $(oc get pods -n redhat-ods-monitoring | grep grafana | awk '{print $1}' | head -n 1) 3001  shell=True  # robocop: disable
    [Return]    ${PROC}

