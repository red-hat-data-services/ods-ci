*** Settings ***
Documentation    Smoke Test for Model Registry Deployment
Suite Setup        Setup Test Environment
Suite Teardown     Teardown Model Registry Test Setup
Library            Collections
Library            OperatingSystem
Library            Process
Library            OpenShiftLibrary
Library            RequestsLibrary
Resource           ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
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
    Component Should Be Enabled    modelregistry
    Apply Db Config Samples
    Sleep    90s

Registering A Model In The Registry
    [Documentation]    Registers a model in the model registry
    [Tags]    Smoke    MR1302    ModelRegistry
    Register A Model    ${URL}

Verify Model Registry
    [Documentation]    Deploy Python Client And Register Model.
    [Tags]    Smoke    MR1302    ModelRegistry
    Run Curl Command And Verify Response    ${URL}


*** Keywords ***
Setup Test Environment
    [Documentation]  Set Model Regisry Test Suite
    ${NAMESPACE_MODEL_REGISTRY}=    Get Model Registry Namespace From DSC
    Log    Set namespace to: ${NAMESPACE_MODEL_REGISTRY}
    Set Suite Variable    ${NAMESPACE_MODEL_REGISTRY}
    Fetch CA Certificate If RHODS Is Self-Managed
    Get Cluster Domain And Token
    Set Suite Variable    ${URL}    http://modelregistry-sample-rest.${DOMAIN}/api/model_registry/v1alpha3/registered_models

Teardown Model Registry Test Setup
    [Documentation]  Teardown Model Registry Suite
    Remove Model Registry
    Disable Model Registry If Needed
    RHOSi Teardown

Apply Db Config Samples
    [Documentation]    Applying the db config samples from https://github.com/opendatahub-io/model-registry-operator
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -k ${MODEL_REGISTRY_DB_SAMPLES} -n ${NAMESPACE_MODEL_REGISTRY}
    Should Be Equal As Integers	  ${rc}	 0   msg=${out}
    Wait For Model Registry Containers To Be Ready

Wait For Model Registry Containers To Be Ready
    [Documentation]    Wait for model-registry-deployment to be ready
    ${result}=    Run Process
    ...        oc wait --for\=condition\=Available --timeout\=5m -n ${NAMESPACE_MODEL_REGISTRY} deployment/model-registry-db      # robocop: disable:line-too-long
    ...        shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    ${result}=    Run Process
    ...        oc wait --for\=condition\=Available --timeout\=5m -n ${NAMESPACE_MODEL_REGISTRY} deployment/model-registry-sample     # robocop: disable:line-too-long
    ...        shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}

Remove Model Registry
    [Documentation]    Run multiple oc delete commands to remove model registry components
    # We don't want to stop the teardown if any of these resources are not found
    Run Keyword And Continue On Failure
    ...    Run And Verify Command
    ...    oc delete -k ${MODELREGISTRY_BASE_FOLDER}/samples/istio/mysql -n ${NAMESPACE_MODEL_REGISTRY}

Install Python Client And Dependencies
    [Documentation]  Download the model-registry package for a specific platform
    ${result}=    Run Process    command=pip install --pre model-registry    # robocop: disable:line-too-long
    ...    shell=yes
    Should Be Equal As Numbers  ${result.rc}  0  ${result.stderr}

Get Model Registry Namespace From DSC
    [Documentation]    Fetches the namespace defined for model registry in the DSC
    ${rc}  ${ns}=    Run And Return Rc And Output
    ...    oc get dsc default-dsc -o json | jq '.spec.components.modelregistry.registriesNamespace'
    Should Be Equal As Integers    ${rc}    0
    Log    ${ns}
    # Remove double quotes
    ${ns}=    Get Substring    ${ns}    1    -1
    Log    ${ns}
    RETURN    ${ns}

Enable Model Registry If Needed
    [Documentation]    While in tech preview the component will not be enabled by default. This keyword enables it.
    ${management_state}=    Get DSC Component State    default-dsc    modelregistry    ${OPERATOR_NAMESPACE}
    IF    "${management_state}" != "Managed"
            Set Component State    modelregistry    Managed
            Set Suite Variable    ${DISABLE_COMPONENT}    ${True}
            Wait For Namespace To Be Active    ${NAMESPACE_MODEL_REGISTRY}    timeout=5m
    END

Disable Model Registry If Needed
    [Documentation]    If we had to enable the component before the test run, let's also disable it at the end to leave
    ...    the cluster in the same state we found it in
    IF    ${DISABLE_COMPONENT}==${True}
        Set Component State    modelregistry    Removed
        Run And Verify Command    oc delete namespace ${NAMESPACE_MODEL_REGISTRY} --force
    END

Get Cluster Domain And Token
    [Documentation]  Logs the Domain and Token capture.
    ${domain}=    Get Domain
    ${token}=    Get Token
    Set Suite Variable    ${DOMAIN}    ${domain}
    Set Suite Variable    ${TOKEN}    ${token}
    Log    Domain: ${DOMAIN}

Get Domain
    [Documentation]  Gets the Domain and returns it to 'Get Cluster Domain And Token'.
    # Run the command to get the ingress domain
    ${domain_result}=    Run Process    oc    get    ingresses.config/cluster
    ...    -o    yaml    stdout=PIPE    stderr=PIPE
    ${rc}=    Set Variable    ${domain_result.rc}
    IF    $rc > 0    Fail    Command 'oc whoami -t' returned non-zero exit code: ${rc}
    ${domain_yaml_output}=    Set Variable    ${domain_result.stdout}

    # Return the domain from stdout
    ${domain_parsed_yaml}=    Evaluate    yaml.load('''${domain_yaml_output}''', Loader=yaml.FullLoader)
    ${ingress_domain}=    Set Variable    ${domain_parsed_yaml['spec']['domain']}

    # Return both results
    RETURN    ${ingress_domain}

Get Token
    [Documentation]    Gets the Token and returns it to 'Get Cluster Domain And Token'.
    ${token_result}=    Run Process    oc    whoami    -t    stdout=YES
    ${rc}=    Set Variable    ${token_result.rc}
    IF    ${rc} > 0    Fail    Command 'oc whoami -t' returned non-zero exit code: ${rc}
    ${token}=    Set Variable    ${token_result.stdout}
    RETURN    ${token}

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
