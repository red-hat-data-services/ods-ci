*** Settings ***
Documentation       Post install test cases that verify OCP Dashboard resources and objects

Library             OpenShiftLibrary
Resource            ../../../Resources/ODS.robot

*** Test Cases ***
Verify Dashboard Is Shipped And Enabled Within ODS
    [Documentation]    Verify Dashboard Is Shipped And Enabled Within ODS
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-233
    @{dashboard_pods_info} =    Fetch Dashboard Pods
    @{dashboard_deployments_info} =    Fetch Dashboard Deployments
    @{dashboard_services_info} =    Fetch Dashboard Services
    @{dashboard_routes_info} =    Fetch Dashboard Routes
    @{dashboard_replicasets_info} =    Fetch Dashboard ReplicaSets
    OpenShift Resource Field Value Should Be Equal As Strings    status.phase    Running    @{dashboard_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[0].name    oauth-proxy    @{dashboard_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[1].name    rhods-dashboard    @{dashboard_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.conditions[2].status    True    @{dashboard_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas    2    @{dashboard_deployments_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas    2    @{dashboard_deployments_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].port    8443    @{dashboard_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].protocol    TCP    @{dashboard_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].targetPort    8443    @{dashboard_services_info}
    OpenShift Resource Field Value Should Match Regexp    spec.clusterIP    ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$
    ...    @{dashboard_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas    2    @{dashboard_replicasets_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas    2    @{dashboard_replicasets_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.port.targetPort    8443    @{dashboard_routes_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.to.name    rhods-dashboard    @{dashboard_routes_info}
    OpenShift Resource Field Value Should Match Regexp    spec.host    dashboard-redhat-ods-applications.*    @{dashboard_routes_info}


*** Keywords ***
Fetch Dashboard Pods
    [Documentation]    Fetch information from Dashboard pods
    ...    Args:
    ...        None
    ...    Returns:
    ...        dashboard_pods_info(list(dict)): Dashboard pods selected by label and namespace   
    @{dashboard_pods_info} =    Oc Get    kind=Pod    api_version=v1    namespace=redhat-ods-applications    label_selector=app=rhods-dashboard
    [Return]    @{dashboard_pods_info}

Fetch Dashboard Deployments
    [Documentation]    Fetch information from Dashboard deployments   
    ...    Args:
    ...        None 
    ...    Returns:
    ...        dashboard_deployments_info(list(dict)): Dashboard deployments selected by label and namespace   
    @{dashboard_deployments_info} =    Oc Get    kind=Deployment    api_version=v1    namespace=redhat-ods-applications
    ...    label_selector=app=rhods-dashboard
    [Return]    @{dashboard_deployments_info}

Fetch Dashboard Services
    [Documentation]    Fetch information from Dashboard services
    ...    Args:
    ...        None 
    ...    Returns:
    ...        dashboard_services_info(list(dict)): Dashboard services selected by name and namespace   
    @{dashboard_services_info} =    Oc Get    kind=Service    api_version=v1    name=rhods-dashboard    namespace=redhat-ods-applications
    [Return]    @{dashboard_services_info}

Fetch Dashboard Routes
    [Documentation]    Fetch information from Dashboard routes
    ...    Args:
    ...        None
    ...    Returns:
    ...        dashboard_routes_info(list(dict)): Dashboard routes selected by name and namespace   
    @{dashboard_routes_info} =    Oc Get    kind=Route    api_version=route.openshift.io/v1    name=rhods-dashboard
    ...    namespace=redhat-ods-applications
    [Return]    @{dashboard_routes_info}

Fetch Dashboard ReplicaSets
    [Documentation]    Fetch information from Dashboard replicasets  
    ...    Args:
    ...        None 
    ...    Returns:
    ...        dashboard_replicasets_info(list(dict)): Dashboard replicasets selected by label and namespace   
    @{dashboard_replicasets_info} =    Oc Get    kind=ReplicaSet    api_version=v1    namespace=redhat-ods-applications
    ...    label_selector=app=rhods-dashboard
    [Return]    @{dashboard_replicasets_info}