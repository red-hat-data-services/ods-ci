*** Settings ***
Documentation       Main ODS resource file (includes ODHDashboard, ODHJupyterhub, Prometheus ... resources)
...                 with some useful keywords to control the operator and main deployments

Resource            ./Page/LoginPage.robot
Resource            ./Page/ODH/ODHDashboard/ODHDashboard.resource
Resource            ./Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource            ./Page/ODH/Prometheus/Prometheus.resource


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

Is Usage Data Collection Enabled
    [Documentation]    Returns a boolean with the value of configmap rhods-segment-key-config > segmentKeyEnabled
    ...    which can be seen also in ODS Dashboard > Cluster Settings > "Usage Data Collection"
    ${usage_data_collection_enabled}=    Run
    ...    oc get configmap rhods-segment-key-config -n redhat-ods-applications -o jsonpath='{.data.segmentKeyEnabled}'
    ${usage_data_collection_enabled}=  Convert To Boolean    ${usage_data_collection_enabled}
    [Return]    ${usage_data_collection_enabled}

Usage Data Collection Should Be Enabled
    [Documentation]    Fails if "Usage Data Collection" is not enabled in ODS Dashboard > Cluster Settings
    [Arguments]    ${msg}="Usage Data Collection" should be enabled
    ${enabled}=    ODS.Is Usage Data Collection Enabled
    Should Be True     ${enabled}     msg=${msg}

Usage Data Collection Should Not Be Enabled
    [Documentation]    Fails if "Usage Data Collection" is enabled in ODS Dashboard > Cluster Settings
    [Arguments]    ${msg}="Usage Data Collection" should not be enabled
    ${enabled}=    ODS.Is Usage Data Collection Enabled
    Should Not Be True     ${enabled}     msg=${msg}
