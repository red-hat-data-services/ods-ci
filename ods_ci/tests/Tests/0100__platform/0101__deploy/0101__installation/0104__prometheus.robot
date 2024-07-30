*** Settings ***
Documentation     Post install test cases that verify OCP Prometheus resources and objects
Library           OpenShiftLibrary
Resource          ../../../../Resources/ODS.robot
Resource            ../../../../Resources/RHOSi.resource
Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown


*** Test Cases ***
Verify Prometheus Is Shipped And Enabled Within ODS
    [Documentation]    Verify Prometheus Is Shipped And Enabled Within ODS
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-232
    Skip If RHODS Is Self-Managed
    @{prometheus_pods_info} =    Fetch Prometheus Pods Info
    @{prometheus_deployment_info} =    Fetch Prometheus Deployments Info
    @{prometheus_services_info} =    Fetch Prometheus Services Info
    @{prometheus_routes_info} =    Fetch Prometheus Routes Info
    OpenShift Resource Field Value Should Be Equal As Strings    status.phase    Running    @{prometheus_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[0].name    alertmanager    @{prometheus_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[1].name    alertmanager-proxy    @{prometheus_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[2].name    oauth-proxy    @{prometheus_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[3].name    prometheus    @{prometheus_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.conditions[2].status    True    @{prometheus_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas    1    @{prometheus_deployment_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas    1    @{prometheus_deployment_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].name    https    @{prometheus_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].port    9091    @{prometheus_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].protocol    TCP    @{prometheus_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].targetPort    https    @{prometheus_services_info}
    OpenShift Resource Field Value Should Match Regexp    spec.clusterIP    ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$
    ...    @{prometheus_services_info}
    Wait Until Keyword Succeeds    10 times  5s    Verify Prometheus ReplicaSets Info
    OpenShift Resource Field Value Should Be Equal As Strings    spec.port.targetPort    https    @{prometheus_routes_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.to.name    prometheus    @{prometheus_routes_info}
    OpenShift Resource Field Value Should Match Regexp    spec.host    ^(prometheus-redhat-ods-monitoring.*)    @{prometheus_routes_info}


*** Keywords ***
Fetch Prometheus Pods Info
    [Documentation]    Fetch information from Prometheus pods
    ...    Args:
    ...        None
    ...    Returns:
    ...        prometheus_pods_info(list(dict)): Prometheus pods selected by label and namespace
    @{prometheus_pods_info} =    Oc Get    kind=Pod    api_version=v1    namespace=${MONITORING_NAMESPACE}    label_selector=deployment=prometheus
    RETURN    @{prometheus_pods_info}

Fetch Prometheus Deployments Info
    [Documentation]    Fetch information from Prometheus Deployments
    ...    Args:
    ...        None
    ...    Returns:
    ...        prometheus_deployments(list(dict)): Prometheus deployments selected by label and namespace
    @{prometheus_deployments_info} =    Oc Get    kind=Deployment    api_version=v1    namespace=${MONITORING_NAMESPACE}
    ...    label_selector=app=prometheus
    RETURN    @{prometheus_deployments_info}

Fetch Prometheus Services Info
    [Documentation]    Fetch information from Prometheus services
    ...    Args:
    ...        None
    ...    Returns:
    ...        prometheus_services_info(list(dict)): Prometheus services selected by name and namespace
    @{prometheus_services_info} =    Oc Get    kind=Service    api_version=v1    name=prometheus    namespace=${MONITORING_NAMESPACE}
    RETURN    @{prometheus_services_info}

Fetch Prometheus Routes Info
    [Documentation]    Fetch information from Prometheus routes
    ...    Args:
    ...        None
    ...    Returns:
    ...        prometheus_routes_info(list(dict)): Prometheus routes selected by name and namespace
    @{prometheus_routes_info} =    Oc Get    kind=Route    api_version=route.openshift.io/v1    name=prometheus
    ...    namespace=${MONITORING_NAMESPACE}
    RETURN    @{prometheus_routes_info}

Verify Prometheus ReplicaSets Info
    [Documentation]    Fetches and verifies information from Prometheus replicasets
    @{prometheus_replicasets_info} =    Oc Get    kind=ReplicaSet    api_version=v1    namespace=${MONITORING_NAMESPACE}
    ...    label_selector=deployment=prometheus
    OpenShift Resource Field Value Should Be Equal As Strings
    ...    status.readyReplicas    1    @{prometheus_replicasets_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas    1    @{prometheus_replicasets_info}
