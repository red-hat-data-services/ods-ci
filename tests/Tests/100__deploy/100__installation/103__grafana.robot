*** Settings ***
Documentation       Post install test cases that verify OCP Grafana resources and objects

Library             OpenShiftLibrary
Resource            ../../../Resources/ODS.robot

*** Test Cases ***
Verify Grafana Is Shipped And Enabled Within ODS
    [Documentation]    Verify Grafana Is Shipped And Enabled Within ODS
    [Tags]    Sanity
    ...       Smoke
    ...       Tier1
    ...       ODS-231
    @{grafana_pods} =    Fetch Grafana Pods
    @{grafana_deployment} =    Fetch Grafana Deployments
    @{grafana_services} =    Fetch Grafana Services
    @{grafana_routes} =    Fetch Grafana Routes
    @{grafana_replicasets} =    Fetch Grafana ReplicaSets
    Verify Resources Values    status.phase    Running    @{grafana_pods}
    Verify Resources Values    status.containerStatuses[0].name    auth-proxy    @{grafana_pods}
    Verify Resources Values    status.containerStatuses[1].name    grafana    @{grafana_pods}
    Verify Resources Values    status.conditions[2].status    True    @{grafana_pods}
    Verify Resources Values    status.replicas    2    @{grafana_deployment}
    Verify Resources Values    status.readyReplicas    2    @{grafana_deployment}
    Verify Resources Values    spec.ports[0].name    https    @{grafana_services}
    Verify Resources Values    spec.ports[0].port    443    @{grafana_services}
    Verify Resources Values    spec.ports[0].protocol    TCP    @{grafana_services}
    Verify Resources Values    spec.ports[0].targetPort    8443    @{grafana_services}
    Verify Resources Values Using RegExp    spec.clusterIP    ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$
    ...    @{grafana_services}
    Verify Resources Values    status.readyReplicas    2    @{grafana_replicasets}
    Verify Resources Values    status.replicas    2    @{grafana_replicasets}
    Verify Resources Values    spec.port.targetPort    https    @{grafana_routes}
    Verify Resources Values    spec.to.name    grafana    @{grafana_routes}
    Verify Resources Values Using RegExp    spec.host    ^(grafana-redhat-ods-monitoring.*)    @{grafana_routes}


*** Keywords ***
Fetch Grafana Pods
    [Documentation]    () -> list(dict) 
    ...    Returns:
    ...        grafana_pods(list(dict)): Grafana pods selected by label and namespace   
    @{grafana_pods} =    Oc Get    kind=Pod    api_version=v1    namespace=redhat-ods-monitoring    label_selector=app=grafana
    [Return]    @{grafana_pods}

Fetch Grafana Deployments
    [Documentation]    () -> list(dict) 
    ...    Returns:
    ...        grafana_deployments(list(dict)): Grafana deployments selected by label and namespace   
    @{grafana_deployments} =    Oc Get    kind=Deployment    api_version=v1    namespace=redhat-ods-monitoring
    ...    label_selector=app=grafana
    [Return]    @{grafana_deployments}

Fetch Grafana Services
    [Documentation]    () -> list(dict) 
    ...    Returns:
    ...        grafana_services(list(dict)): Grafana services selected by name and namespace   
    @{grafana_services} =    Oc Get    kind=Service    api_version=v1    name=grafana    namespace=redhat-ods-monitoring
    [Return]    @{grafana_services}

Fetch Grafana Routes
    [Documentation]    () -> list(dict) 
    ...    Returns:
    ...        grafana_routes(list(dict)): Grafana routes selected by name and namespace   
    @{grafana_routes} =    Oc Get    kind=Route    api_version=route.openshift.io/v1    name=grafana
    ...    namespace=redhat-ods-monitoring
    [Return]    @{grafana_routes}

Fetch Grafana ReplicaSets
    [Documentation]    () -> list(dict) 
    ...    Returns:
    ...        grafana_replicasets(list(dict)): Grafana replicasets selected by label and namespace   
    @{grafana_replicasets} =    Oc Get    kind=ReplicaSet    api_version=v1    namespace=redhat-ods-monitoring
    ...    label_selector=app=grafana
    [Return]    @{grafana_replicasets}

