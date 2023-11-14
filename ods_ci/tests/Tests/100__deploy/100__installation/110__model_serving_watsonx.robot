*** Settings ***
Documentation       Post install test cases that verify OCP KServe resources and objects
Library             OpenShiftLibrary
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
# Resource            ../../../Resources/RHOSi.resource
# Suite Setup         RHOSi Setup
# Suite Teardown      RHOSi Teardown


*** Variables ***
${KSERVE_NS}=    ${APPLICATIONS_NAMESPACE}


*** Test Cases ***
Verify KServe Is Shipped
    [Documentation]    Verify KServe Is Shipped And Enabled Within ODS
    [Tags]    WatsonX
    ...       ODS-2325
    @{kserve_pods_info} =    Fetch KServe Pods
    @{kserve_services_info} =    Fetch KServe Controller Services
    @{kserve_wh_services_info} =    Fetch KServe Webhook Services
    Verify KServe Deployment
    Run Keyword And Continue On Failure
    ...    OpenShift Resource Field Value Should Be Equal As Strings    status.phase    Running    @{kserve_pods_info}
    Run Keyword And Continue On Failure
    ...    OpenShift Resource Field Value Should Be Equal As Strings    status.conditions[2].status    True    @{kserve_pods_info}
    Run Keyword And Continue On Failure
    ...    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].port    8443    @{kserve_services_info}
    Run Keyword And Continue On Failure
    ...    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].protocol    TCP    @{kserve_services_info}
    Run Keyword And Continue On Failure
    ...    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].port    443    @{kserve_wh_services_info}
    Run Keyword And Continue On Failure
    ...    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].protocol    TCP    @{kserve_wh_services_info}
    Run Keyword And Continue On Failure
    ...    OpenShift Resource Field Value Should Match Regexp    spec.clusterIP    ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$
    ...    @{kserve_services_info}
    Run Keyword And Continue On Failure
    ...    OpenShift Resource Field Value Should Match Regexp    spec.clusterIP    ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$
    ...    @{kserve_wh_services_info}
    Wait Until Keyword Succeeds    10 times  5s    Verify KServe ReplicaSets Info
    ServingRuntime CustomResourceDefinition Should Exist
    InferenceService CustomResourceDefinition Should Exist


*** Keywords ***
Fetch KServe Pods
    [Documentation]    Fetches information from KServe pods
    ...    Args:
    ...        None
    ...    Returns:
    ...        kserve_pods_info(list(dict)): KServe pods selected by label and namespace
    @{kserve_pods_info} =    Oc Get    kind=Pod    api_version=v1    namespace=${KSERVE_NS}
    ...    label_selector=app.kubernetes.io/part-of=kserve
    RETURN    @{kserve_pods_info}

Fetch KServe Controller Services
    [Documentation]    Fetches information from KServe services
    ...    Args:
    ...        None
    ...    Returns:
    ...        kserve_services_info(list(dict)): KServe services selected by name and namespace
    @{kserve_services_info} =    Oc Get    kind=Service    api_version=v1    label_selector=control-plane=kserve-controller-manager
    ...    namespace=${KSERVE_NS}
    RETURN    @{kserve_services_info}

Fetch KServe Webhook Services
    [Documentation]    Fetches information from KServe services
    ...    Args:
    ...        None
    ...    Returns:
    ...        kserve_services_info(list(dict)): KServe services selected by name and namespace
    @{kserve_wh_services_info} =    Oc Get    kind=Service    api_version=v1    name=kserve-webhook-server-service
    ...    namespace=${KSERVE_NS}
    RETURN    @{kserve_wh_services_info}

Verify KServe ReplicaSets Info
    [Documentation]    Fetches and verifies information from KServe replicasets
    @{kserve_replicasets_info} =    Oc Get    kind=ReplicaSet    api_version=v1    namespace=${KSERVE_NS}
    ...    label_selector=app.kubernetes.io/part-of=kserve
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas
    ...    1    @{kserve_replicasets_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas
    ...    1    @{kserve_replicasets_info}

Verify Kserve Deployment
    [Documentation]  Verifies RHODS KServe deployment
    @{kserve} =  Oc Get    kind=Pod    namespace=${KSERVE_NS}    api_version=v1
    ...    label_selector=app.opendatahub.io/kserve=true
    ${containerNames} =    Create List    manager
    Verify Deployment    ${kserve}    4    1    ${containerNames}

ServingRuntime CustomResourceDefinition Should Exist
    [Documentation]    Checks that the ServingRuntime CRD is present
    ${sr_crd}=    Oc Get    kind=CustomResourceDefinition    field_selector=metadata.name=servingruntimes.serving.kserve.io
    Should Not Be Empty    ${sr_crd}

InferenceService CustomResourceDefinition Should Exist
    [Documentation]    Checks that the InferenceService CRD is present
    ${is_crd}=    Oc Get    kind=CustomResourceDefinition    field_selector=metadata.name=inferenceservices.serving.kserve.io
    Should Not Be Empty    ${is_crd}
