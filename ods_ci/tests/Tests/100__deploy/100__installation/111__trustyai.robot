*** Settings ***
Documentation       Post install test cases that verify OCP KServe resources and objects
Library             OpenShiftLibrary


*** Variables ***
${TRUSTYAI_NS}=    ${APPLICATIONS_NAMESPACE}


*** Test Cases ***
Verify TrustyAI Operator Installation
    [Documentation]    Verifies that the TrustyAI operator has been
    ...    deployed in the ${APPLICATIONS_NAMESPACE} namespace in ODS
    [Tags]    Smoke
    ...       Tier1    ODS-2481
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  1 min  10 sec  Verify TrustyAI Deployment
    Wait Until Keyword Succeeds    10 times  5s    Verify TrustyAI ReplicaSets Info
    Wait Until Keyword Succeeds    10 times  5s    Verify TrustyAI Container Names


*** Keywords ***
Verify trustyai-service-operator-controller-manager Deployment
    [Documentation]    Verifies the  deployment of the trustyai operator in the namespace
    Wait For Pods To Be Ready   label_selector=app.kubernetes.io/created-by=trustyai-service-operator
    ...    namespace=${APPLICATIONS_NAMESPACE}    exp_replicas=1

Verify TrustyAI ReplicaSets Info
    [Documentation]    Fetches and verifies information from TrustyAI replicasets
    @{trustyai_replicasets_info} =    Oc Get    kind=ReplicaSet    api_version=v1    namespace=${TRUSTYAI_NS}
    ...    label_selector=app.kubernetes.io/part-of=trustyai-service-operator
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas
    ...    1    @{trustyai_replicasets_info}

Verify TrustyAI Container Names
    [Documentation]  Verifies RHODS TrustyAI deployment
    @{trustyai} =  Oc Get    kind=Pod    namespace=${TRUSTYAI_NS}    api_version=v1
    ...    label_selector=app.kubernetes.io/part-of=kserve
    ${containerNames} =    Create List    kube-rbac-proxy    manager
    Verify Deployment    ${trustyai}    1    1    ${containerNames}
