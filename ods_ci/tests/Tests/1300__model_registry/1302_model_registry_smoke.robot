*** Settings ***
Documentation    Smoke Test for Model Registry Deployment
Suite Setup        Setup Test Environment Non UI
Suite Teardown     Teardown Model Registry Test Setup Non UI
Library            Collections
Library            OperatingSystem
Library            Process
Library            OpenShiftLibrary
Library            RequestsLibrary
Library            BuiltIn
Resource           ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource           ../../Resources/Page/ModelRegistry/ModelRegistry.resource
Resource           ../../Resources/Page/Components/Components.resource
Resource           ../../Resources/OCP.resource
Resource           ../../Resources/Common.robot


*** Variables ***
${MODELREGISTRY_BASE_FOLDER}=        tests/Resources/CLI/ModelRegistry
${MODEL_REGISTRY_DB_SAMPLES}=        ${MODELREGISTRY_BASE_FOLDER}/samples/istio/mysql
${OPERATOR_NS}                       ${OPERATOR_NAMESPACE}
${APPLICATIONS_NS}                   ${APPLICATIONS_NAMESPACE}
${DSC_NAME}                          default-dsc

@{REDHATIO_PATH_CHECK_EXCLUSTION_LIST}    model-registry-operator-controller-manager


*** Test Cases ***
Deploy Model Registry
    [Documentation]    Deployment test for Model Registry.
    [Tags]    Smoke    MR1302    ModelRegistry
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Enable Model Registry If Needed
    Set DSC Component Managed State And Wait For Completion   modelregistry
    ...    model-registry-operator-controller-manager
    ...    control-plane=model-registry-operator
    Component Should Be Enabled    modelregistry
    Sleep    60s    reason=Wait for webhook endpoint
    Apply Db Config Samples    namespace=${NAMESPACE_MODEL_REGISTRY}    samples=${MODEL_REGISTRY_DB_SAMPLES}
    # After the MR instance is seen as Available, the rest container might take a little bit of additional time to
    # properly connect to the MLMD server (I'm assuming it's based on how often it retries and when the DB actually
    # becomes available). I've tested this multiple times locally and the longest time I've seen this keyword retry for
    # is 20 seconds. Setting it to 60 to give it ample time to do its thing.
    Wait Until Keyword Succeeds    60 s    2 s    Verify Model Registry Can Accept Requests

Registering A Model In The Registry
    [Documentation]    Registers a model in the model registry
    [Tags]    Smoke    MR1302    ModelRegistry
    Depends On Test    Deploy Model Registry
    Register A Model    ${URL}

Verify Model Registry
    [Documentation]    Verify the registered model.
    [Tags]    Smoke    MR1302    ModelRegistry
    Depends On Test    Registering A Model In The Registry
    Log    Attempting to verify Model Registry
    Wait Until Keyword Succeeds    10 s    2 s    Run Curl Command And Verify Response


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

Verify Model Registry Can Accept Requests
    [Documentation]    Runs a curl command to verify response from server
    ${result}=     Run Process    curl    -H    Authorization: Bearer ${TOKEN}
    ...        ${URL}    stdout=stdout    stderr=stderr
    Log    ${result.stderr}
    Log    ${result.stdout}
    Should Contain    ${result.stdout}    items
    Should Contain    ${result.stdout}    nextPageToken
    Should Contain    ${result.stdout}    pageSize
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
