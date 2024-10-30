*** Settings ***
Documentation    Smoke Test for Model Registry Deployment
Suite Setup        Setup Test Environment Non UI
Suite Teardown     Teardown Model Registry Test Setup Non UI
Library            Collections
Library            OperatingSystem
Library            Process
Library            OpenShiftLibrary
Library            RequestsLibrary
Resource           ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource           ../../Resources/Page/ModelRegistry/ModelRegistry.resource
Resource           ../../Resources/OCP.resource
Resource           ../../Resources/Common.robot


*** Variables ***
${MODELREGISTRY_BASE_FOLDER}=        tests/Resources/CLI/ModelRegistry
${MODEL_REGISTRY_DB_SAMPLES}=        ${MODELREGISTRY_BASE_FOLDER}/samples/istio/mysql
${DISABLE_COMPONENT}=                ${False}


*** Test Cases ***
Deploy Model Registry
    [Documentation]    Deployment test for Model Registry.
    [Tags]    Smoke    MR1302    ModelRegistry
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Enable Model Registry If Needed
    Sleep    90s
    Component Should Be Enabled    modelregistry
    Apply Db Config Samples    namespace=${NAMESPACE_MODEL_REGISTRY}

Registering A Model In The Registry
    [Documentation]    Registers a model in the model registry
    [Tags]    Smoke    MR1302    ModelRegistry
    Register A Model    ${URL}

Verify Model Registry
    [Documentation]    Deploy Python Client And Register Model.
    [Tags]    Smoke    MR1302    ModelRegistry
    Run Curl Command And Verify Response    ${URL}


*** Keywords ***
Setup Test Environment Non UI
    [Documentation]  Set Model Regisry Test Suite
    ${NAMESPACE_MODEL_REGISTRY}=    Get Model Registry Namespace From DSC
    Log    Set namespace to: ${NAMESPACE_MODEL_REGISTRY}
    Set Suite Variable    ${NAMESPACE_MODEL_REGISTRY}
    Fetch CA Certificate If RHODS Is Self-Managed
    Get Cluster Domain And Token
    Set Suite Variable    ${URL}    http://modelregistry-sample-rest.${DOMAIN}/api/model_registry/v1alpha3/registered_models

Teardown Model Registry Test Setup Non UI
    [Documentation]  Teardown Model Registry Suite
    Remove Model Registry Non UI
    Disable Model Registry If Needed
    RHOSi Teardown

Remove Model Registry Non UI
    [Documentation]    Run multiple oc delete commands to remove model registry components
    # We don't want to stop the teardown if any of these resources are not found
    Run Keyword And Continue On Failure
    ...    Run And Verify Command
    ...    oc delete -k ${MODELREGISTRY_BASE_FOLDER}/samples/istio/mysql -n ${NAMESPACE_MODEL_REGISTRY}

Run Curl Command And Verify Response
    [Documentation]    Runs a curl command to verify response from server
    [Arguments]    ${URL}
    ${result}=     Run Process    curl    -H    Authorization: Bearer ${TOKEN}
    ...        ${URL}    stdout=stdout    stderr=stderr
    Log    ${result.stderr}
    Log    ${result.stdout}
    Should Contain    ${result.stdout}    createTimeSinceEpoch
    Should Contain    ${result.stdout}    description
    Should Contain    ${result.stdout}    test-model
    Should Contain    ${result.stdout}    name
    Should Contain    ${result.stdout}    model-name
    Should Not Contain    ${result.stdout}    error

Register A Model
    [Documentation]    Registers a test model in the model-registry
    [Arguments]    ${URL}
    ${result}=    Run Process    curl    -X    POST
    ...    -H    Authorization: Bearer ${TOKEN}
    ...    -H    Content-Type: application/json
    ...    -d    {"name": "model-name", "description": "test-model"}
    ...    ${URL}    stdout=stdout    stderr=stderr
    Should Be Equal As Numbers    ${result.rc}    0
    Log    ${result.stderr}
    Log    ${result.stdout}
