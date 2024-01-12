*** Settings ***
Documentation     Post install test cases that verify OCP Blackbox Exporter resources and objects
Library           OpenShiftLibrary
Resource          ../../../Resources/ODS.robot
Resource          ../../../Resources/RHOSi.resource
Suite Setup       RHOSi Setup
Suite Teardown    RHOSi Teardown


*** Test Cases ***
Verify Blackbox Exporter Is Shipped And Enabled Within ODS
    [Documentation]    Verify Blackbox Exporter Is Shipped And Enabled Within ODS
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-235
    Skip If RHODS Is Self-Managed
    @{blackbox_exporter_pods_info} =    Fetch Blackbox Exporter Pods Info
    @{blackbox_exporter_deployment_info} =    Fetch Blackbox Exporter Deployments Info
    @{blackbox_exporter_services_info} =    Fetch Blackbox Exporter Services Info
    OpenShift Resource Field Value Should Be Equal As Strings    status.phase    Running    @{blackbox_exporter_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[0].name    blackbox-exporter    @{blackbox_exporter_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[1].name    oauth-proxy    @{blackbox_exporter_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.conditions[2].status    True    @{blackbox_exporter_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas    1    @{blackbox_exporter_deployment_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas    1    @{blackbox_exporter_deployment_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].name    9114-tcp    @{blackbox_exporter_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].port    9114    @{blackbox_exporter_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].protocol    TCP    @{blackbox_exporter_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].targetPort    9114    @{blackbox_exporter_services_info}
    OpenShift Resource Field Value Should Match Regexp    spec.clusterIP    ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$
    ...    @{blackbox_exporter_services_info}
    Wait Until Keyword Succeeds    10 times  5s    Verify Blackbox Exporter ReplicaSets Info


*** Keywords ***
Fetch Blackbox Exporter Pods Info
    [Documentation]    Fetch information from Blackbox Exporter pods
    ...    Args:
    ...        None
    ...    Returns:
    ...        blackbox_exporter_pods_info(list(dict)): Blackbox Exporter pods selected by label and namespace
    @{blackbox_exporter_pods_info} =    Oc Get    kind=Pod    api_version=v1    namespace=${MONITORING_NAMESPACE}    label_selector=deployment=blackbox-exporter
    RETURN    @{blackbox_exporter_pods_info}

Fetch Blackbox Exporter Deployments Info
    [Documentation]    Fetch information from Blackbox Exporter Deployments
    ...    Args:
    ...        None
    ...    Returns:
    ...        blackbox_exporter_deployments(list(dict)): Blackbox Exporter deployments selected by label and namespace
    @{blackbox_exporter_deployments} =    Oc Get    kind=Deployment    api_version=v1    namespace=${MONITORING_NAMESPACE}
    ...    label_selector=deployment=blackbox-exporter
    RETURN    @{blackbox_exporter_deployments}

Fetch Blackbox Exporter Services Info
    [Documentation]    Fetch information from Blackbox Exporter services
    ...    Args:
    ...        None
    ...    Returns:
    ...        blackbox_exporter_services_info(list(dict)): Blackbox Exporter services selected by name and namespace
    @{blackbox_exporter_services_info} =    Oc Get    kind=Service    api_version=v1    name=blackbox-exporter    namespace=${MONITORING_NAMESPACE}
    RETURN    @{blackbox_exporter_services_info}

Verify Blackbox Exporter ReplicaSets Info
    [Documentation]    Fetch and verify information from Blackbox Exporter replicasets
    @{blackbox_exporter_replicasets_info} =    Oc Get    kind=ReplicaSet    api_version=v1    namespace=${MONITORING_NAMESPACE}
    ...    label_selector=deployment=blackbox-exporter
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas    1
    ...    @{blackbox_exporter_replicasets_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas    1
    ...    @{blackbox_exporter_replicasets_info}
