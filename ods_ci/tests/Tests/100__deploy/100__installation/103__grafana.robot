*** Settings ***
Documentation     Post install test cases that verify OCP Grafana resources and objects
Library           OpenShiftLibrary
Resource          ../../../Resources/ODS.robot
Resource          ../../../Resources/RHOSi.resource
Suite Setup       RHOSi Setup
Suite Teardown    RHOSi Teardown


*** Test Cases ***
Verify Grafana Is Shipped And Enabled Within ODS
    [Documentation]    Verify Grafana Is Shipped And Enabled Within ODS
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-231
    Skip If RHODS Version Greater Or Equal Than    version=1.20.0
    @{grafana_pods_info} =    Fetch Grafana Pods Info
    @{grafana_deployment_info} =    Fetch Grafana Deployments Info
    @{grafana_services_info} =    Fetch Grafana Services Info
    @{grafana_routes_info} =    Fetch Grafana Routes Info
    OpenShift Resource Field Value Should Be Equal As Strings    status.phase    Running    @{grafana_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[0].name    auth-proxy    @{grafana_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[1].name    grafana    @{grafana_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.conditions[2].status    True    @{grafana_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas    2    @{grafana_deployment_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas    2    @{grafana_deployment_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].name    https    @{grafana_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].port    443    @{grafana_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].protocol    TCP    @{grafana_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].targetPort    8443    @{grafana_services_info}
    OpenShift Resource Field Value Should Match Regexp    spec.clusterIP    ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$
    ...    @{grafana_services_info}
    Wait Until Keyword Succeeds    10 times  5s    Verify Grafana ReplicaSets Info
    OpenShift Resource Field Value Should Be Equal As Strings    spec.port.targetPort    https    @{grafana_routes_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.to.name    grafana    @{grafana_routes_info}
    OpenShift Resource Field Value Should Match Regexp    spec.host    ^(grafana-redhat-ods-monitoring.*)    @{grafana_routes_info}


*** Keywords ***
Fetch Grafana Pods Info
    [Documentation]    Fetch information from Grafana pods
    ...    Args:
    ...        None
    ...    Returns:
    ...        grafana_pods_info(list(dict)): Grafana pods selected by label and namespace
    @{grafana_pods_info} =    Oc Get    kind=Pod    api_version=v1    namespace=${MONITORING_NAMESPACE}    label_selector=app=grafana
    RETURN    @{grafana_pods_info}

Fetch Grafana Deployments Info
    [Documentation]    Fetch information from Grafana Deployments
    ...    Args:
    ...        None
    ...    Returns:
    ...        grafana_deployments(list(dict)): Grafana deployments selected by label and namespace
    @{grafana_deployments} =    Oc Get    kind=Deployment    api_version=v1    namespace=${MONITORING_NAMESPACE}
    ...    label_selector=app=grafana
    RETURN    @{grafana_deployments}

Fetch Grafana Services Info
    [Documentation]    Fetch information from Grafana services
    ...    Args:
    ...        None
    ...    Returns:
    ...        grafana_services_info(list(dict)): Grafana services selected by name and namespace
    @{grafana_services_info} =    Oc Get    kind=Service    api_version=v1    name=grafana    namespace=${MONITORING_NAMESPACE}
    RETURN    @{grafana_services_info}

Fetch Grafana Routes Info
    [Documentation]    Fetch information from Grafana routes
    ...    Args:
    ...        None
    ...    Returns:
    ...        grafana_routes_info(list(dict)): Grafana routes selected by name and namespace
    @{grafana_routes_info} =    Oc Get    kind=Route    api_version=route.openshift.io/v1    name=grafana
    ...    namespace=${MONITORING_NAMESPACE}
    RETURN    @{grafana_routes_info}

Verify Grafana ReplicaSets Info
    [Documentation]    Fetchs and verifies information for Grafana replicasets
    @{grafana_replicasets_info} =    Oc Get    kind=ReplicaSet    api_version=v1    namespace=${MONITORING_NAMESPACE}
    ...    label_selector=app=grafana
    OpenShift Resource Field Value Should Be Equal As Strings
    ...     status.readyReplicas    2    @{grafana_replicasets_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas    2    @{grafana_replicasets_info}

