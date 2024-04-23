*** Settings ***
Documentation       Post install test cases that verify Model Registry
Library             OpenShiftLibrary
Resource            ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../../Resources/OCP.resource
Suite Setup         Registry Suite Setup
Suite Teardown      Teardown


*** Variables ***
${MODEL_REGISTRY_NS}=    ${APPLICATIONS_NAMESPACE}


*** Test Cases ***
Verify Model Registry Operator Installation
    [Documentation]    Verifies that the Model Registry operator has been
    ...    deployed in the ${APPLICATIONS_NAMESPACE} namespace in ODS
    [Tags]    OpenDataHub    robot:recursive-continue-on-failure
    Wait Until Keyword Succeeds  1 min  10 sec  Verify Model Registry Operator Deployment
    Wait Until Keyword Succeeds    10 times  5s    Verify Model Registry ReplicaSets Info
    Wait Until Keyword Succeeds    10 times  5s    Verify Model Registry Container Names


*** Keywords ***
Verify Model Registry Operator Deployment
    [Documentation]    Verifies the  deployment of the model registry operator in the Applications namespace
    Wait For Pods Number  1
    ...                   namespace=${MODEL_REGISTRY_NS}
    ...                   label_selector=app.kubernetes.io/part-of=model-registry-operator
    ...                   timeout=20

Verify Model Registry ReplicaSets Info
    [Documentation]    Fetches and verifies information from Model Registry replicasets
    @{model_registry_replicasets_info} =   Oc Get    kind=ReplicaSet    api_version=v1    namespace=${MODEL_REGISTRY_NS}
    ...    label_selector=app.kubernetes.io/part-of=model-registry-operator
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas
    ...    1    @{model_registry_replicasets_info}

Verify Model Registry Container Names
    [Documentation]  Verifies RHODS Model Registry deployment
    @{model_registry} =  Oc Get    kind=Pod    namespace=${MODEL_REGISTRY_NS}    api_version=v1
    ...    label_selector=app.kubernetes.io/part-of=model-registry-operator
    ${containerNames} =    Create List     manager   kube-rbac-proxy
    Verify Deployment    ${model_registry}    1    2    ${containerNames}

Registry Suite Setup
    [Documentation]  Model Registry suite setup
    ${REGISTRY} =    Is Component Enabled    modelregistry    ${DSC_NAME}
    IF    "${REGISTRY}" == "false"    Enable Component    modelregistry
    Set Suite Variable     ${REGISTRY}


Teardown
    [Documentation]    Disable Registry if Enabled
    SeleniumLibrary.Close Browser
    IF    "${REGISTRY}" == "false"    Disable Component     modelregistry
