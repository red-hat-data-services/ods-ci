*** Settings ***
Library           OperatingSystem
Library           ../../../../libs/Helpers.py
Resource          ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/CLI/ModelServing/modelmesh.resource
Suite Setup       Model Serving Suite Setup
Suite Teardown    Model Serving Suite Teardown
Test Tags         ModelMesh

*** Variables ***
${INFERENCE_INPUT}=    @ods_ci/tests/Resources/Files/modelmesh-mnist-input.json
${INFERENCE_INPUT_OPENVINO}=    @ods_ci/tests/Resources/Files/openvino-example-input.json
${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"test-model__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}
${EXPECTED_INFERENCE_OUTPUT_OPENVINO}=    {"model_name":"test-model__isvc-8655dc7979","model_version":"1","outputs":[{"name":"Func/StatefulPartitionedCall/output/_13:0","datatype":"FP32","shape":[1,1],"data":[0.99999994]}]}
${PRJ_TITLE}=    model-serving-project
${PRJ_DESCRIPTION}=    project used for model serving tests
${MODEL_NAME}=    test-model
${MODEL_CREATED}=    False
${RUNTIME_NAME}=    Model Serving Test


*** Test Cases ***
Verify Model Serving Installation
    [Documentation]    Verifies that the core components of model serving have been
    ...    deployed in the ${APPLICATIONS_NAMESPACE} namespace
    [Tags]    Smoke
    ...       Tier1
    ...       OpenDataHub
    ...       ODS-1919
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify odh-model-controller Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify ModelMesh Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Etcd Pod

Verify Model Can Be Deployed Via UI
    [Documentation]    Verifies that a model can be deployed using only the UI.
    ...    At the end of the process, verifies the correct resources have been deployed.
    [Tags]    Sanity    Tier1
    ...    ODS-1921
    ${runtime_pod_name} =    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Open Model Serving Home Page
    Try Opening Create Server
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    server_name=${RUNTIME_NAME}
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=onnx    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=mnist-8.onnx
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    True
    [Teardown]    Run Keyword If Test Failed    Get Events And Pod Logs    namespace=${PRJ_TITLE}
    ...    label_selector=name=modelmesh-serving-${runtime_pod_name}

Test Inference With Token Authentication
    [Documentation]    Test the inference result after having deployed a model that requires Token Authentication
    [Tags]    Sanity    Tier1
    ...    ODS-1920
    # Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}    # robocop: disable
    Run Keyword And Continue On Failure    Verify Model Inference With Retries
    ...    ${MODEL_NAME}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}
    # Testing the same endpoint without token auth, should receive login page
    Open Model Serving Home Page
    ${out}=    Get Model Inference   ${MODEL_NAME}    ${INFERENCE_INPUT}    token_auth=${FALSE}
    Should Contain    ${out}    <button type="submit" class="btn btn-lg btn-primary">Log in with OpenShift</button>

Verify Openvino_IR Model Via UI
    [Documentation]    Test the deployment of an openvino_ir model
    [Tags]    Smoke
    ...    ODS-2054
    ${runtime_pod_name} =    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Open Model Serving Home Page
    Try Opening Create Server
    Open Data Science Projects Home Page
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=openvino_ir    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=openvino-example-model
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    True
    [Teardown]    Run Keyword If Test Failed    Get Events And Pod Logs    namespace=${PRJ_TITLE}
    ...    label_selector=name=modelmesh-serving-${runtime_pod_name}

Test Inference Without Token Authentication
    [Documentation]    Test the inference result after having deployed a model that doesn't require Token Authentication
    [Tags]    Smoke
    ...    ODS-2053
    Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT_OPENVINO}    ${EXPECTED_INFERENCE_OUTPUT_OPENVINO}    token_auth=${FALSE}

Verify Tensorflow Model Via UI
    [Documentation]    Test the deployment of a tensorflow (.pb) model
    [Tags]    Sanity    Tier1
    ...    ODS-2268
    ${runtime_pod_name} =    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Open Model Serving Home Page
    Try Opening Create Server
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=tensorflow    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=inception_resnet_v2.pb
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    True
    ${url}=    Get Model Route via UI    ${MODEL_NAME}
    ${status_code}    ${response_text} =    Send Random Inference Request     endpoint=${url}    name=input
    ...    shape={"B": 1, "H": 299, "W": 299, "C": 3}    no_requests=1
    Should Be Equal As Strings    ${status_code}    200
    [Teardown]    Run Keyword If Test Failed    Get Events And Pod Logs    namespace=${PRJ_TITLE}
    ...    label_selector=name=modelmesh-serving-${runtime_pod_name}

*** Keywords ***
Model Serving Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    Skip If Component Is Not Enabled    modelmeshserving
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Fetch CA Certificate If RHODS Is Self-Managed

Model Serving Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    # Even if kw fails, deleting the whole project will also delete the model
    # Failure will be shown in the logs of the run nonetheless
    IF    ${MODEL_CREATED}
        Run Keyword And Continue On Failure    Delete Model Via UI    test-model
    ELSE
        Log    Model not deployed, skipping deletion step during teardown    console=true
    END
    ${projects}=    Create List    ${PRJ_TITLE}
    Delete Data Science Projects From CLI   ocp_projects=${projects}
    # Will only be present on SM cluster runs, but keyword passes
    # if file does not exist
    Remove File    openshift_ca.crt
    Close All Browsers
    RHOSi Teardown

Clean Up DSP Page
    [Documentation]    Removes all DSP Projects, if any are present
    Open Data Science Projects Home Page
    WHILE    ${TRUE}
        ${projects} =    Get All Displayed Projects
        IF    len(${projects})==0
            BREAK
        END
        Delete Data Science Projects From CLI    ${projects}
        Reload Page
        Wait Until Page Contains    Data Science Projects
    END

Try Opening Create Server
    [Documentation]    Tries to clean up DSP and Model Serving pages
    ...    In order to deploy a single model in a new project. ${retries}
    ...    controls how many retries are made.
    [Arguments]    ${retries}=3
    FOR    ${try}    IN RANGE    0    ${retries}
        ${status} =    Run Keyword And Return Status    Page Should Contain    Select a project
        IF    ${status}
            Click Button    Select a project
            RETURN
        ELSE
            Clean Up Model Serving Page
            Clean Up DSP Page
            Open Model Serving Home Page
            Reload Page
            Sleep  5s
        END
    END

