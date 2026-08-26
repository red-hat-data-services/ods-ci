*** Settings ***
Documentation       Post install test cases that verify Model Registry
Library             OpenShiftLibrary
Resource            ../../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../../../Resources/OCP.resource
Suite Setup         Registry Suite Setup
Suite Teardown      Teardown


*** Variables ***
${MODEL_REGISTRY_NS}=    ${APPLICATIONS_NAMESPACE}


*** Test Cases ***
Verify Model Registry Operator Installation
    [Documentation]    Verifies that the Model Registry operator has been
    ...    deployed in the ${APPLICATIONS_NAMESPACE} namespace in ODS
    [Tags]    Operator
    ...       ModelRegistry
    ...       ExcludeOnRHOAI
    ...       OpenDataHub    robot:recursive-continue-on-failure
    Wait Until Keyword Succeeds  1 min  10 sec  Verify Model Registry Operator Deployment
    Wait Until Keyword Succeeds    10 times  5s    Verify Model Registry ReplicaSets Info
    Wait Until Keyword Succeeds    10 times  5s    Verify Model Registry Container Names


*** Keywords ***
Verify Model Registry Operator Deployment
    [Documentation]    Verifies the  deployment of the model registry operator in the Applications namespace
    ${legacy_mr}=    Wait For Deployment Replica If Present    namespace=${MODEL_REGISTRY_NS}
    ...    label_selector=control-plane=model-registry-operator    timeout=20s
    ${aihub}=    Wait For Deployment Replica If Present    namespace=${MODEL_REGISTRY_NS}
    ...    label_selector=control-plane=aihub-controller-manager    timeout=20s
    ${catalog}=    Wait For Deployment Replica If Present    namespace=${MODEL_REGISTRY_NS}
    ...    label_selector=control-plane=catalog-controller-manager    timeout=20s
    IF    not ${legacy_mr} and not ${aihub} and not ${catalog}
        Fail    msg=No model-registry-operator, aihub-controller-manager, or catalog-controller-manager Deployment was found
    END

Verify Model Registry ReplicaSets Info
    [Documentation]    Fetches and verifies information from Model Registry replicasets
    ${selector}=    Get Model Registry Controller Label Selector    ${MODEL_REGISTRY_NS}
    @{model_registry_replicasets_info} =   Oc Get    kind=ReplicaSet    api_version=v1    namespace=${MODEL_REGISTRY_NS}
    ...    label_selector=${selector}
    OpenShift Resource Field Value Should Be Equal As Strings    status.readyReplicas
    ...    1    @{model_registry_replicasets_info}

Verify Model Registry Container Names
    [Documentation]  Verifies RHODS Model Registry deployment
    ${selector}=    Get Model Registry Controller Label Selector    ${MODEL_REGISTRY_NS}
    @{model_registry} =  Oc Get    kind=Pod    namespace=${MODEL_REGISTRY_NS}    api_version=v1
    ...    label_selector=${selector}
    ${containerNames} =    Create List     manager
    Verify Deployment    ${model_registry}    1    1    ${containerNames}

Registry Suite Setup
    [Documentation]  Model Registry suite setup
    ${REGISTRY} =    Is Component Enabled    modelregistry    ${DSC_NAME}
    IF    "${REGISTRY}" == "false"    Enable Component    modelregistry
    Set Suite Variable     ${REGISTRY}

Teardown
    [Documentation]    Disable Registry if Enabled
    SeleniumLibrary.Close Browser
    IF    "${REGISTRY}" == "false"    Disable Component     modelregistry
