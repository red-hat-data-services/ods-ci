*** Settings ***
Documentation       Post install test cases that verify OCP Dashboard resources and objects
Library             Collections
Library             OpenShiftLibrary
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../../Resources/RHOSi.resource
Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown


*** Test Cases ***
Verify Dashboard Is Shipped And Enabled Within ODS
    [Documentation]    Verify Dashboard Is Shipped And Enabled Within ODS
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-233
    [Setup]     Set Expected Replicas Based On Version
    @{dashboard_pods_info} =    Fetch Dashboard Pods
    @{dashboard_deployments_info} =    Fetch Dashboard Deployments
    @{dashboard_services_info} =    Fetch Dashboard Services
    @{dashboard_routes_info} =    Fetch Dashboard Routes
    Verify Dashboard Deployment
    OpenShift Resource Field Value Should Be Equal As Strings    status.phase    Running    @{dashboard_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.conditions[2].status    True    @{dashboard_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].port    8443    @{dashboard_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].protocol    TCP    @{dashboard_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].targetPort    8443    @{dashboard_services_info}
    OpenShift Resource Field Value Should Match Regexp    spec.clusterIP    ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$
    ...    @{dashboard_services_info}
    Wait Until Keyword Succeeds    10 times  5s    Verify Dashboard ReplicaSets Info
    OpenShift Resource Field Value Should Be Equal As Strings    spec.port.targetPort    8443    @{dashboard_routes_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.to.name    rhods-dashboard    @{dashboard_routes_info}
    OpenShift Resource Field Value Should Match Regexp    spec.host    dashboard-${APPLICATIONS_NAMESPACE}.*    @{dashboard_routes_info}

Verify rhods-dashboard ClusterRole Rules
    [Documentation]    Verifies rhods-dashboard ClusterRole rules match expected values
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-644
    ...       AutomationBug
    &{rhodsdashboard_clusterrole_info}=    Fetch rhods-dashboard ClusterRole Info
    @{rhodsdashboard_clusterrole_rules}=    Set Variable    ${rhodsdashboard_clusterrole_info.rules}
    &{rule_1} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[0]
    @{rule_1_expected_verbs}=    Create List    get    list
    @{rule_1_expected_apigroups}=    Create List    machine.openshift.io    autoscaling.openshift.io
    @{rule_1_expected_resources}=    Create List    machineautoscalers    machinesets
    Verify rhods-dashboard ClusterRole Rule    ${rule_1}    ${rule_1_expected_verbs}    ${rule_1_expected_apigroups}    ${rule_1_expected_resources}
    &{rule_2} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[1]
    @{rule_2_expected_verbs}=    Create List    get    watch    list
    @{rule_2_expected_apigroups}=    Create List    ${EMPTY}    config.openshift.io
    @{rule_2_expected_resources}=    Create List    clusterversions
    Verify rhods-dashboard ClusterRole Rule    ${rule_2}    ${rule_2_expected_verbs}    ${rule_2_expected_apigroups}    ${rule_2_expected_resources}
    &{rule_3} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[2]
    @{rule_3_expected_verbs}=    Create List    get    list    watch
    @{rule_3_expected_apigroups}=    Create List    operators.coreos.com
    @{rule_3_expected_resources}=    Create List    clusterserviceversions    subscriptions
    Verify rhods-dashboard ClusterRole Rule    ${rule_3}    ${rule_3_expected_verbs}    ${rule_3_expected_apigroups}    ${rule_3_expected_resources}
    &{rule_4} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[3]
    @{rule_4_expected_verbs}=    Create List    get
    @{rule_4_expected_apigroups}=    Create List    ${EMPTY}    image.openshift.io
    @{rule_4_expected_resources}=    Create List    imagestreams/layers
    Verify rhods-dashboard ClusterRole Rule    ${rule_4}    ${rule_4_expected_verbs}    ${rule_4_expected_apigroups}    ${rule_4_expected_resources}
    &{rule_5} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[4]
    @{rule_5_expected_verbs}=    Create List    create    delete    get    list    patch    update    watch
    @{rule_5_expected_apigroups}=    Create List    ${EMPTY}
    @{rule_5_expected_resources}=    Create List    configmaps    persistentvolumeclaims    secrets
    Verify rhods-dashboard ClusterRole Rule    ${rule_5}    ${rule_5_expected_verbs}    ${rule_5_expected_apigroups}    ${rule_5_expected_resources}
    &{rule_6} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[5]
    @{rule_6_expected_verbs}=    Create List    get    list    watch
    @{rule_6_expected_apigroups}=    Create List    route.openshift.io
    @{rule_6_expected_resources}=    Create List    routes
    Verify rhods-dashboard ClusterRole Rule    ${rule_6}    ${rule_6_expected_verbs}    ${rule_6_expected_apigroups}    ${rule_6_expected_resources}
    &{rule_7} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[6]
    @{rule_7_expected_verbs}=    Create List    get    list    watch
    @{rule_7_expected_apigroups}=    Create List    console.openshift.io
    @{rule_7_expected_resources}=    Create List    consolelinks
    Verify rhods-dashboard ClusterRole Rule    ${rule_7}    ${rule_7_expected_verbs}    ${rule_7_expected_apigroups}    ${rule_7_expected_resources}
    &{rule_8} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[7]
    @{rule_8_expected_verbs}=    Create List    get    list    watch
    @{rule_8_expected_apigroups}=    Create List    operator.openshift.io
    @{rule_8_expected_resources}=    Create List    consoles
    Verify rhods-dashboard ClusterRole Rule    ${rule_8}    ${rule_8_expected_verbs}    ${rule_8_expected_apigroups}    ${rule_8_expected_resources}
    &{rule_9} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[8]
    @{rule_9_expected_verbs}=    Create List    get    watch    list
    @{rule_9_expected_apigroups}=    Create List    ${EMPTY}    integreatly.org
    @{rule_9_expected_resources}=    Create List    rhmis
    Verify rhods-dashboard ClusterRole Rule    ${rule_9}    ${rule_9_expected_verbs}   ${rule_9_expected_apigroups}    ${rule_9_expected_resources}
    &{rule_10} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[9]
    @{rule_10_expected_verbs}=    Create List    get    list    watch
    @{rule_10_expected_apigroups}=    Create List    user.openshift.io
    @{rule_10_expected_resources}=    Create List    groups
    Verify rhods-dashboard ClusterRole Rule    ${rule_10}    ${rule_10_expected_verbs}   ${rule_10_expected_apigroups}    ${rule_10_expected_resources}
    &{rule_11} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[10]
    @{rule_11_expected_verbs}=    Create List    get    list    watch
    @{rule_11_expected_apigroups}=    Create List    user.openshift.io
    @{rule_11_expected_resources}=    Create List    users
    Verify rhods-dashboard ClusterRole Rule    ${rule_11}    ${rule_11_expected_verbs}   ${rule_11_expected_apigroups}    ${rule_11_expected_resources}
    &{rule_12} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[11]
    @{rule_12_expected_verbs}=    Create List    get    list    watch
    @{rule_12_expected_apigroups}=    Create List    ${EMPTY}
    @{rule_12_expected_resources}=    Create List    pods    serviceaccounts    services    namespaces
    Verify rhods-dashboard ClusterRole Rule    ${rule_12}    ${rule_12_expected_verbs}    ${rule_12_expected_apigroups}    ${rule_12_expected_resources}
    &{rule_13} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[12]
    @{rule_13_expected_verbs}=    Create List    get    list    watch    create    update    patch    delete
    @{rule_13_expected_apigroups}=    Create List    rbac.authorization.k8s.io
    @{rule_13_expected_resources}=    Create List    rolebindings    clusterrolebindings    roles
    Verify rhods-dashboard ClusterRole Rule    ${rule_13}    ${rule_13_expected_verbs}    ${rule_13_expected_apigroups}    ${rule_13_expected_resources}
    &{rule_14} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[13]
    @{rule_14_expected_verbs}=    Create List    get    list    watch
    @{rule_14_expected_apigroups}=    Create List    ${EMPTY}    events.k8s.io
    @{rule_14_expected_resources}=    Create List    events
    Verify rhods-dashboard ClusterRole Rule    ${rule_14}    ${rule_14_expected_verbs}    ${rule_14_expected_apigroups}    ${rule_14_expected_resources}
    &{rule_15} =    Set Variable    ${rhodsdashboard_clusterrole_rules}[14]
    @{rule_15_expected_verbs}=    Create List    get    list    watch    create    update    patch    delete
    @{rule_15_expected_apigroups}=    Create List    kubeflow.org
    @{rule_15_expected_resources}=    Create List    notebooks
    Verify rhods-dashboard ClusterRole Rule    ${rule_15}    ${rule_15_expected_verbs}    ${rule_15_expected_apigroups}    ${rule_15_expected_resources}

*** Keywords ***
Set Expected Replicas Based On Version
    [Documentation]     Set the expected number of dashboard replicas changes based on RHODS version
    ${version_check}=    Is RHODS Version Greater Or Equal Than    1.17.0
    IF    ${version_check} == True
        Set Suite Variable    ${EXP_DASHBOARD_REPLICAS}       5
    ELSE
        Set Suite Variable    ${EXP_DASHBOARD_REPLICAS}       2
    END

Fetch Dashboard Pods
    [Documentation]    Fetch information from Dashboard pods
    ...    Args:
    ...        None
    ...    Returns:
    ...        dashboard_pods_info(list(dict)): Dashboard pods selected by label and namespace
    @{dashboard_pods_info} =    Oc Get    kind=Pod    api_version=v1    namespace=${APPLICATIONS_NAMESPACE}    label_selector=app=${DASHBOARD_APP_NAME}
    RETURN    @{dashboard_pods_info}

Fetch Dashboard Deployments
    [Documentation]    Fetch information from Dashboard deployments
    ...    Args:
    ...        None
    ...    Returns:
    ...        dashboard_deployments_info(list(dict)): Dashboard deployments selected by label and namespace
    @{dashboard_deployments_info} =    Oc Get    kind=Deployment    api_version=v1    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=${DASHBOARD_APP_NAME}
    RETURN    @{dashboard_deployments_info}

Fetch Dashboard Services
    [Documentation]    Fetch information from Dashboard services
    ...    Args:
    ...        None
    ...    Returns:
    ...        dashboard_services_info(list(dict)): Dashboard services selected by name and namespace
    @{dashboard_services_info} =    Oc Get    kind=Service    api_version=v1    name=${DASHBOARD_APP_NAME}    namespace=${APPLICATIONS_NAMESPACE}
    RETURN    @{dashboard_services_info}

Fetch Dashboard Routes
    [Documentation]    Fetch information from Dashboard routes
    ...    Args:
    ...        None
    ...    Returns:
    ...        dashboard_routes_info(list(dict)): Dashboard routes selected by name and namespace
    @{dashboard_routes_info} =    Oc Get    kind=Route    api_version=route.openshift.io/v1    name=${DASHBOARD_APP_NAME}
    ...    namespace=${APPLICATIONS_NAMESPACE}
    RETURN    @{dashboard_routes_info}

Verify Dashboard ReplicaSets Info
    [Documentation]    Fetchs and verifies information from Dashboard replicasets
    @{dashboard_replicasets_info} =    Oc Get    kind=ReplicaSet    api_version=v1    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=${DASHBOARD_APP_NAME}
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas
    ...    ${EXP_DASHBOARD_REPLICAS}    @{dashboard_replicasets_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas
    ...    ${EXP_DASHBOARD_REPLICAS}    @{dashboard_replicasets_info}

Verify Dashboard Deployment
    [Documentation]  Verifies RHODS Dashboard deployment
    @{dashboard} =  Oc Get    kind=Pod    namespace=${APPLICATIONS_NAMESPACE}    api_version=v1
    ...    label_selector=deployment = rhods-dashboard
    ${containerNames} =    Create List    rhods-dashboard    oauth-proxy
    Verify Deployment    ${dashboard}    ${EXP_DASHBOARD_REPLICAS}    2    ${containerNames}

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
    @{resources_info_list}=    Oc Get    kind=ClusterRole    api_version=rbac.authorization.k8s.io/v1    name=${DASHBOARD_APP_NAME}
    &{rhodsdashboard_clusterrole_info} =    Set Variable    ${resources_info_list}[0]
    RETURN    &{rhodsdashboard_clusterrole_info}
