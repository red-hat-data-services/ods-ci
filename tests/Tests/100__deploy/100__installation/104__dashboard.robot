*** Settings ***
Documentation       Post install test cases that verify OCP Dashboard resources and objects

Library             Collections
Library             OpenShiftLibrary
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot

*** Test Cases ***
Verify Dashboard Is Shipped And Enabled Within ODS
    [Documentation]    Verify Dashboard Is Shipped And Enabled Within ODS
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-233
    ...       ODS-546
    @{dashboard_pods_info} =    Fetch Dashboard Pods
    @{dashboard_deployments_info} =    Fetch Dashboard Deployments
    @{dashboard_services_info} =    Fetch Dashboard Services
    @{dashboard_routes_info} =    Fetch Dashboard Routes
    @{dashboard_replicasets_info} =    Fetch Dashboard ReplicaSets
    Verify Dashboard Deployment
    OpenShift Resource Field Value Should Be Equal As Strings    status.phase    Running    @{dashboard_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.conditions[2].status    True    @{dashboard_pods_info}
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

Verify rhods-dashboard ClusterRole Rules
    [Documentation]    Verifies rhods-dashboard ClusterRole rules match expected values
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-644
    &{rhodsdashboard_clusterrole_info}=    Fetch rhods-dashboard ClusterRole Info
    @{rhodsdashboard_clusterrole_rules}=    Set Variable    ${rhodsdashboard_clusterrole_info.rules}
    &{rule_1} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[0]
    @{rule_1_expected_verbs}=    Create List    get    watch    list
    @{rule_1_expected_apigroups}=    Create List    ${EMPTY}    config.openshift.io
    @{rule_1_expected_resources}=    Create List    clusterversions
    Verify rhods-dashboard ClusterRole Rule    ${rule_1}    ${rule_1_expected_verbs}    ${rule_1_expected_apigroups}    ${rule_1_expected_resources}
    &{rule_2} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[1]
    @{rule_2_expected_verbs}=    Create List    get    list    watch
    @{rule_2_expected_apigroups}=    Create List    operators.coreos.com
    @{rule_2_expected_resources}=    Create List    clusterserviceversions
    Verify rhods-dashboard ClusterRole Rule    ${rule_2}    ${rule_2_expected_verbs}    ${rule_2_expected_apigroups}    ${rule_2_expected_resources}
    &{rule_3} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[2]
    @{rule_3_expected_verbs}=    Create List    get    list    watch
    @{rule_3_expected_apigroups}=    Create List    ${EMPTY}
    @{rule_3_expected_resources}=    Create List    services    configmaps
    Verify rhods-dashboard ClusterRole Rule    ${rule_3}    ${rule_3_expected_verbs}    ${rule_3_expected_apigroups}    ${rule_3_expected_resources}
    &{rule_4} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[3]
    @{rule_4_expected_verbs}=    Create List    get    list    watch
    @{rule_4_expected_apigroups}=    Create List    route.openshift.io
    @{rule_4_expected_resources}=    Create List    routes
    Verify rhods-dashboard ClusterRole Rule    ${rule_4}    ${rule_4_expected_verbs}    ${rule_4_expected_apigroups}    ${rule_4_expected_resources}
    &{rule_5} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[4]
    @{rule_5_expected_verbs}=    Create List    get    list    watch
    @{rule_5_expected_apigroups}=    Create List    console.openshift.io
    @{rule_5_expected_resources}=    Create List    consolelinks
    Verify rhods-dashboard ClusterRole Rule    ${rule_5}    ${rule_5_expected_verbs}    ${rule_5_expected_apigroups}    ${rule_5_expected_resources}
    &{rule_6} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[5]
    @{rule_6_expected_verbs}=    Create List    get    list    watch
    @{rule_6_expected_apigroups}=    Create List    operator.openshift.io
    @{rule_6_expected_resources}=    Create List    consoles
    Verify rhods-dashboard ClusterRole Rule    ${rule_6}    ${rule_6_expected_verbs}    ${rule_6_expected_apigroups}    ${rule_6_expected_resources}
    &{rule_7} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[6]
    @{rule_7_expected_verbs}=    Create List    get    watch    list
    @{rule_7_expected_apigroups}=    Create List    ${EMPTY}    integreatly.org
    @{rule_7_expected_resources}=    Create List    rhmis
    Verify rhods-dashboard ClusterRole Rule    ${rule_7}    ${rule_7_expected_verbs}   ${rule_7_expected_apigroups}    ${rule_7_expected_resources}
    &{rule_8} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[7]
    @{rule_8_expected_verbs}=    Create List    get    list    watch
    @{rule_8_expected_apigroups}=    Create List    user.openshift.io
    @{rule_8_expected_resources}=    Create List    groups
    Verify rhods-dashboard ClusterRole Rule    ${rule_8}    ${rule_8_expected_verbs}   ${rule_8_expected_apigroups}    ${rule_8_expected_resources}


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

Verify Dashboard Deployment
    [Documentation]  Verifies RHODS Dashboard deployment
    @{dashboard} =  Oc Get    kind=Pod    namespace=redhat-ods-applications    api_version=v1
    ...    label_selector=deployment = rhods-dashboard
    ${containerNames} =    Create List    rhods-dashboard    oauth-proxy
    Verify Deployment    ${dashboard}    2    2    ${containerNames}

Verify rhods-dashboard ClusterRole Rule
    [Documentation]    Verifies rhods-dashboard ClusterRole rules matches expected values
    ...    Args:
    ...        rule(dict): Dictionary containing the rule info
    ...        rule_expected_apigroup(list): List containing the rule's expected apigroups
    ...        rule_expected_resources(list): List containing the rule's expected resources
    ...    Returns:
    ...        None
    [Arguments]    ${rule}   ${rule_expected_verbs}    ${rule_expected_apigroups}    ${rule_expected_resources}
    Run Keyword And Continue On Failure    Lists Should Be Equal    ${rule.verbs}    ${rule_expected_verbs}
    Run Keyword And Continue On Failure    Lists Should Be Equal    ${rule.apiGroups}    ${rule_expected_apigroups}
    Run Keyword And Continue On Failure    Lists Should Be Equal    ${rule.resources}    ${rule_expected_resources}

Fetch rhods-dashboard ClusterRole Info
    [Documentation]    Fetches information of rhods-dashboard ClusterRole
    ...    Args:
    ...        None
    ...    Returns:
    ...        rhodsdashboard_clusterrole_info(dict): Dictionary containing rhods-dashboard ClusterRole Information
    @{resources_info_list}=    Oc Get    kind=ClusterRole    api_version=rbac.authorization.k8s.io/v1    name=rhods-dashboard
    &{rhodsdashboard_clusterrole_info} =    Set Variable    ${resources_info_list}[0]
    [Return]    &{rhodsdashboard_clusterrole_info}
