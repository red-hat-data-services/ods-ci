*** Settings ***
Documentation       Main ODS resource file (includes ODHDashboard, ODHJupyterhub, Prometheus ... resources)
...                 with some useful keywords to control the operator and main deployments

Resource            ./Page/LoginPage.robot
Resource            ./Page/ODH/ODHDashboard/ODHDashboard.resource
Resource            ./Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource            ./Page/ODH/Prometheus/Prometheus.resource


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
