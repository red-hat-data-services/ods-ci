*** Settings ***
Documentation       Post install test cases that verify OCP Dashboard resources and objects
Library             Collections
Library             OperatingSystem
Library             OpenShiftLibrary
Resource            ../../../../Resources/ODS.robot
Resource            ../../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../../../Resources/RHOSi.resource
Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown


*** Test Cases ***
Verify Dashboard Is Shipped And Enabled Within ODS
    [Documentation]    Verify Dashboard Is Shipped And Enabled Within ODS
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-233
    ...       deprecatedTest
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
    [Documentation]    Verifies the rhods-dashboard ClusterRole grants exactly the expected set of
    ...    rules, compared order-insensitively (rule order and verb/apiGroup/resource order are not
    ...    significant). Missing and unexpected rules are reported separately. Expected rules live in
    ...    Resources/Files/rhods-dashboard-clusterrole-rules.json; update it when the ClusterRole
    ...    legitimately changes.
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-644
    &{rhodsdashboard_clusterrole_info}=    Fetch rhods-dashboard ClusterRole Info
    @{actual_rules}=    Set Variable    ${rhodsdashboard_clusterrole_info.rules}
    @{expected_rules}=    Get Expected rhods-dashboard ClusterRole Rules
    @{actual_canonical}=    Canonicalize ClusterRole Rules    ${actual_rules}
    @{expected_canonical}=    Canonicalize ClusterRole Rules    ${expected_rules}
    ${missing_rules}=    Evaluate    sorted(set($expected_canonical) - set($actual_canonical))
    ${unexpected_rules}=    Evaluate    sorted(set($actual_canonical) - set($expected_canonical))
    Run Keyword And Continue On Failure    Should Be Empty    ${missing_rules}
    ...    msg=Expected rhods-dashboard ClusterRole rules missing from the live role: ${missing_rules}
    Run Keyword And Continue On Failure    Should Be Empty    ${unexpected_rules}
    ...    msg=Unexpected rhods-dashboard ClusterRole rules present in the live role: ${unexpected_rules}


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

Get Expected rhods-dashboard ClusterRole Rules
    [Documentation]    Loads the expected rhods-dashboard ClusterRole rules (a list of dictionaries
    ...    with apiGroups, resources and verbs) from the data file. Ordering is irrelevant; the caller
    ...    compares the rule sets order-insensitively.
    ${rules_file}=    Set Variable    ${CURDIR}/../../../../Resources/Files/rhods-dashboard-clusterrole-rules.json
    ${rules_json}=    Get File    ${rules_file}
    ${expected_rules}=    Evaluate    json.loads($rules_json)    modules=json
    RETURN    ${expected_rules}

Canonicalize ClusterRole Rules
    [Documentation]    Converts a list of ClusterRole rule dictionaries into a list of canonical
    ...    strings (apiGroups, resources and verbs each sorted) so that the rules can be compared
    ...    independently of ordering.
    [Arguments]    ${rules}
    @{canonical}=    Create List
    FOR    ${rule}    IN    @{rules}
        @{apigroups}=    Copy List    ${rule}[apiGroups]
        @{resources}=    Copy List    ${rule}[resources]
        @{verbs}=    Copy List    ${rule}[verbs]
        Sort List    ${apigroups}
        Sort List    ${resources}
        Sort List    ${verbs}
        ${key}=    Catenate    SEPARATOR=|    ${apigroups}    ${resources}    ${verbs}
        Append To List    ${canonical}    ${key}
    END
    RETURN    @{canonical}

Fetch rhods-dashboard ClusterRole Info
    [Documentation]    Fetches information of rhods-dashboard ClusterRole
    ...    Args:
    ...        None
    ...    Returns:
    ...        rhodsdashboard_clusterrole_info(dict): Dictionary containing rhods-dashboard ClusterRole Information
    @{resources_info_list}=    Oc Get    kind=ClusterRole    api_version=rbac.authorization.k8s.io/v1    name=${DASHBOARD_APP_NAME}
    &{rhodsdashboard_clusterrole_info} =    Set Variable    ${resources_info_list}[0]
    RETURN    &{rhodsdashboard_clusterrole_info}
