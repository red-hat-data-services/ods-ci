*** Settings ***
Documentation       Post install test cases that verify OCP KServe resources and objects
Library             OpenShiftLibrary
Resource            ../../../Resources/OCP.resource
Resource            ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot


*** Variables ***
${TRUSTYAI_NS}=    ${APPLICATIONS_NAMESPACE}


*** Test Cases ***
Verify TrustyAI Operator Installation
    [Documentation]    Verifies that the TrustyAI operator has been
    ...    deployed in the ${APPLICATIONS_NAMESPACE} namespace in ODS
    [Tags]    ODS-2481    robot:recursive-continue-on-failure
    Wait Until Keyword Succeeds  1 min  10 sec  Verify TrustyAI Operator Deployment
    Wait Until Keyword Succeeds    10 times  5s    Verify TrustyAI ReplicaSets Info
    Wait Until Keyword Succeeds    10 times  5s    Verify TrustyAI Container Names


*** Keywords ***
Verify TrustyAI Operator Deployment
    [Documentation]    Verifies the  deployment of the trustyai operator in the Applications namespace
    Wait For Pods Number  1
    ...                   namespace=${TRUSTYAI_NS}
    ...                   label_selector=app.kubernetes.io/part-of=trustyai
    ...                   timeout=200

Verify TrustyAI ReplicaSets Info
    [Documentation]    Fetches and verifies information from TrustyAI replicasets
    @{trustyai_replicasets_info} =    Oc Get    kind=ReplicaSet    api_version=v1    namespace=${TRUSTYAI_NS}
    ...    label_selector=app.kubernetes.io/part-of=trustyai
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas
    ...    1    @{trustyai_replicasets_info}

Verify TrustyAI Container Names
    [Documentation]  Verifies RHODS TrustyAI deployment
    @{trustyai} =  Oc Get    kind=Pod    namespace=${TRUSTYAI_NS}    api_version=v1
    ...    label_selector=app.kubernetes.io/part-of=trustyai
    ${containerNames} =    Create List     manager
    Verify Deployment    ${trustyai}    1    1    ${containerNames}
