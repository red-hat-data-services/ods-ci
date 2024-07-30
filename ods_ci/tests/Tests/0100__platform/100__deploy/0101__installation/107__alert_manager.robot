*** Settings ***
Documentation     Post install test cases that verify OCP Alert Manager resources and objects
Library           OpenShiftLibrary
Resource          ../../../../Resources/ODS.robot
Resource          ../../../../Resources/RHOSi.resource
Suite Setup       RHOSi Setup
Suite Teardown    RHOSi Teardown


*** Test Cases ***
Verify Alert Manager Is Shipped And Enabled Within ODS
    [Documentation]    Verify Alert Manager Is Shipped And Enabled Within ODS
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-238
    Skip If RHODS Is Self-Managed
    @{alertmanager_services_info} =    Fetch Alert Manager Services Info
    @{alertmanager_routes_info} =    Fetch Alert Manager Routes Info
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].name    alertmanager    @{alertmanager_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].port    443    @{alertmanager_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].protocol    TCP    @{alertmanager_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].targetPort    10443    @{alertmanager_services_info}
    OpenShift Resource Field Value Should Match Regexp    spec.clusterIP    ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$
    ...    @{alertmanager_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.port.targetPort    alertmanager    @{alertmanager_routes_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.to.name    alertmanager    @{alertmanager_routes_info}
    OpenShift Resource Field Value Should Match Regexp    spec.host    ^(alertmanager-${MONITORING_NAMESPACE}.*)    @{alertmanager_routes_info}


*** Keywords ***
Fetch Alert Manager Services Info
    [Documentation]    Fetch information from Alert Manager services
    ...    Args:
    ...        None
    ...    Returns:
    ...        alertmanager_services_info(list(dict)): Alert Manager services selected by name and namespace
    @{alertmanager_services_info} =    Oc Get    kind=Service    api_version=v1    name=alertmanager    namespace=${MONITORING_NAMESPACE}
    RETURN    @{alertmanager_services_info}

Fetch Alert Manager Routes Info
    [Documentation]    Fetch information from Alert Manager routes
    ...    Args:
    ...        None
    ...    Returns:
    ...        alertmanager_routes_info(list(dict)): Alert Manager routes selected by name and namespace
    @{alertmanager_routes_info} =    Oc Get    kind=Route    api_version=route.openshift.io/v1    name=alertmanager
    ...    namespace=${MONITORING_NAMESPACE}
    RETURN    @{alertmanager_routes_info}
