*** Settings ***
Library           OperatingSystem
Library           ../../../../libs/Helpers.py
Resource          ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../Resources/CLI/DSProjects/DSProjects.resource
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/CLI/ModelServing/modelmesh.resource
Suite Setup       Model Serving Suite Setup
Suite Teardown    Model Serving Suite Teardown
Test Tags         ModelMesh

*** Variables ***
${INFERENCE_INPUT}=    @tests/Resources/Files/modelmesh-mnist-input.json
${INFERENCE_INPUT_OPENVINO}=    @tests/Resources/Files/openvino-example-input.json
${PRJ_TITLE}=    model-serving-project-420
${PRJ_DESCRIPTION}=    project used for model serving tests
${MODEL_CREATED}=    ${FALSE}
${MODEL_NAME}=    test-model
${RUNTIME_NAME}=    Model Serving Test
${SECOND_PROJECT}=    sec-model-serving-project-420
${SECURED_MODEL}=    test-model-secured
${SECURED_RUNTIME}=    Model Serving With Authentication
${EXPECTED_INFERENCE_SECURED_OUTPUT}=    {"model_name":"${SECURED_MODEL}__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}  #robocop: disable
${EXPECTED_INFERENCE_OUTPUT_OPENVINO}=    {"model_name":"${MODEL_NAME}__isvc-8655dc7979","model_version":"1","outputs":[{"name":"Func/StatefulPartitionedCall/output/_13:0","datatype":"FP32","shape":[1,1],"data":[0.99999994]}]}  #robocop: disable


*** Test Cases ***
Verify Model Serving Installation
    [Documentation]    Verifies that the core components of model serving have been
    ...    deployed in the ${APPLICATIONS_NAMESPACE} namespace
    [Tags]    Smoke
    ...       Tier1
    ...       OpenDataHub
    ...       ODS-1919
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec
    ...    Verify odh-model-controller Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify ModelMesh Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Etcd Pod

Verify Openvino_IR Model Via UI
    [Documentation]    Test the deployment of an openvino_ir model
    [Tags]    Smoke
    ...       ODS-2054
    Create Openvino Models    server_name=${RUNTIME_NAME}    model_name=${MODEL_NAME}    project_name=${PRJ_TITLE}
    ...    num_projects=1
    [Teardown]   Run Keyword If Test Failed    Get Modelmesh Events And Logs
    ...    server_name=${RUNTIME_NAME}    project_title=${PRJ_TITLE}

Test Inference Without Token Authentication
    [Documentation]    Test the inference result after having deployed a model that doesn't require Token Authentication
    ...                Intermittently failing: RHOAIENG-3115
    [Tags]    Smoke    FlakyTest
    ...       ODS-2053
    Depends On Test  Verify Openvino_IR Model Via UI
    # This inference request often fails because of timing, currently it is sent ~10 seconds after the model is shown as
    # ready, let's add 30 second on top.
    Sleep    30s
    Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT_OPENVINO}
    ...    ${EXPECTED_INFERENCE_OUTPUT_OPENVINO}    token_auth=${FALSE}
    [Teardown]   Run Keyword If Test Failed    Get Modelmesh Events And Logs
    ...    server_name=${RUNTIME_NAME}    project_title=${PRJ_TITLE}

Verify Tensorflow Model Via UI
    [Documentation]    Test the deployment of a tensorflow (.pb) model
    [Tags]    Sanity    Tier1
    ...       ODS-2268
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}-2268    description=${PRJ_DESCRIPTION}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}-2268    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}    existing_server=${TRUE}
    Serve Model    project_name=${PRJ_TITLE}-2268    model_name=${MODEL_NAME}    framework=tensorflow
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection
    ...    model_path=inception_resnet_v2.pb
    ${runtime_pod_name}=    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name}=    Convert To Lower Case    ${runtime_pod_name}
    Wait Until Keyword Succeeds    5 min  10 sec  Verify Openvino Deployment    runtime_name=${RUNTIME_POD_NAME}
    Wait Until Keyword Succeeds    5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    ${url}=    Get Model Route Via UI    ${MODEL_NAME}
    ${status_code}    ${response_text}=    Send Random Inference Request     endpoint=${url}    name=input
    ...    shape={"B": 1, "H": 299, "W": 299, "C": 3}    no_requests=1
    Should Be Equal As Strings    ${status_code}    200
    [Teardown]   Run Keywords    Run Keyword If Test Failed    Get Modelmesh Events And Logs
    ...    server_name=${RUNTIME_NAME}    project_title=${PRJ_TITLE}-2869
    ...    AND
    ...    Model Serving Test Teardown

Verify Secure Model Can Be Deployed In Same Project
    [Documentation]    Verifies that a model can be deployed in a secured server (with token) using only the UI.
    ...    At the end of the process, verifies the correct resources have been deployed.
    [Tags]    Sanity    Tier1
    ...       ODS-1921    ProductBug    RHOAIENG-2759
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}    existing_project=${TRUE}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${TRUE}    server_name=${SECURED_RUNTIME}    existing_server=${TRUE}
    Serve Model    project_name=${PRJ_TITLE}    model_name=${SECURED_MODEL}    model_server=${SECURED_RUNTIME}
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection    existing_model=${TRUE}
    ...    framework=onnx    model_path=mnist-8.onnx
    ${runtime_pod_name}=    Replace String Using Regexp    string=${SECURED_RUNTIME}    pattern=\\s    replace_with=-
    ${runtime_pod_name}=    Convert To Lower Case    ${runtime_pod_name}
    Wait Until Keyword Succeeds    5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}
    Wait Until Keyword Succeeds    5 min  10 sec  Verify Serving Service
    Verify Model Status    ${SECURED_MODEL}    success
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    [Teardown]   Run Keywords    Run Keyword If Test Failed    Get Modelmesh Events And Logs
    ...    server_name=${RUNTIME_NAME}    project_title=${PRJ_TITLE}-2869
    ...    AND
    ...    Model Serving Test Teardown

Test Inference With Token Authentication
    [Documentation]    Test the inference result after having deployed a model that requires Token Authentication
    [Tags]    Sanity    Tier1
    ...       ODS-1920
    Open Data Science Projects Home Page
    Create Data Science Project    title=${SECOND_PROJECT}    description=${PRJ_DESCRIPTION}    existing_project=${FALSE}
    Recreate S3 Data Connection    project_title=${SECOND_PROJECT}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${TRUE}    server_name=${SECURED_RUNTIME}    existing_server=${TRUE}
    Serve Model    project_name=${SECOND_PROJECT}    model_name=${SECURED_MODEL}    model_server=${SECURED_RUNTIME}
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection    existing_model=${TRUE}
    ...    framework=onnx    model_path=mnist-8.onnx
    # Run Keyword And Continue On Failure    Verify Model Inference    ${SECURED_MODEL}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_SECURED_OUTPUT}    token_auth=${TRUE}    # robocop: disable
    Run Keyword And Continue On Failure    Verify Model Inference With Retries
    ...    ${SECURED_MODEL}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_SECURED_OUTPUT}    token_auth=${TRUE}
    ...    project_title=${SECOND_PROJECT}
    # Testing the same endpoint without token auth, should receive login page
    Open Model Serving Home Page
    ${out}=    Get Model Inference   ${SECURED_MODEL}    ${INFERENCE_INPUT}    token_auth=${FALSE}
    Should Contain    ${out}    <button type="submit" class="btn btn-lg btn-primary">Log in with OpenShift</button>
    [Teardown]   Run Keywords    Run Keyword If Test Failed    Get Modelmesh Events And Logs
    ...    server_name=${RUNTIME_NAME}    project_title=${PRJ_TITLE}-2869
    ...    AND
    ...    Model Serving Test Teardown

Verify Multiple Projects With Same Model
    [Documentation]    Test the deployment of multiple DS project with same openvino_ir model
    [Tags]    Sanity    Tier1
    ...       RHOAIENG-549    RHOAIENG-2724
    Create Openvino Models    server_name=${RUNTIME_NAME}    model_name=${MODEL_NAME}    project_name=${PRJ_TITLE}
    ...    num_projects=4
    [Teardown]   Run Keyword If Test Failed    Get Modelmesh Events And Logs
    ...    server_name=${RUNTIME_NAME}    project_title=${PRJ_TITLE}

Verify Editing Existing Model Deployment
    [Documentation]    Tries editing an existing model deployment to see if the underlying deployment is updated
    [Tags]    Sanity    Tier1
    ...       RHOAIENG-2869
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}-2869    description=${PRJ_DESCRIPTION}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}-2869    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}    existing_server=${TRUE}
    Serve Model    project_name=${PRJ_TITLE}-2869    model_name=${MODEL_NAME}    framework=tensorflow
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection
    ...    model_path=inception_resnet_v2.pb
    ${runtime_pod_name}=    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name}=    Convert To Lower Case    ${runtime_pod_name}
    Wait Until Keyword Succeeds    5 min  10 sec  Verify Openvino Deployment    runtime_name=${RUNTIME_POD_NAME}
    Wait Until Keyword Succeeds    5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    ${url}=    Get Model Route Via UI    ${MODEL_NAME}
    ${status_code}    ${response_text}=    Send Random Inference Request     endpoint=${url}    name=input
    ...    shape={"B": 1, "H": 299, "W": 299, "C": 3}    no_requests=1
    Should Be Equal As Strings    ${status_code}    200
    Serve Model    project_name=${PRJ_TITLE}-2869    model_name=${MODEL_NAME}    framework=openvino_ir
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection
    ...    model_path=openvino-example-model    existing_model=${TRUE}
    ${runtime_pod_name}=    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name}=    Convert To Lower Case    ${runtime_pod_name}
    Wait Until Keyword Succeeds    5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}
    ...    project_name=${PRJ_TITLE}-2869
    Wait Until Keyword Succeeds    5 min  10 sec  Verify Serving Service    ${PRJ_TITLE}-2869
    Verify Model Status    ${MODEL_NAME}    success
    Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT_OPENVINO}
    ...    ${EXPECTED_INFERENCE_OUTPUT_OPENVINO}    token_auth=${FALSE}
    [Teardown]   Run Keywords    Run Keyword If Test Failed    Get Modelmesh Events And Logs
    ...    server_name=${RUNTIME_NAME}    project_title=${PRJ_TITLE}-2869
    ...    AND
    ...    Model Serving Test Teardown

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
    Clean All Models Of Current User

Create Openvino Models
    [Documentation]    Create Openvino model in N projects (more than 1 will add index to project name)
    [Arguments]    ${server_name}=${RUNTIME_NAME}    ${model_name}=${MODEL_NAME}    ${project_name}=${PRJ_TITLE}
    ...    ${num_projects}=1    ${token}=${FALSE}
    ${project_postfix}=    Set Variable    ${EMPTY}
    FOR  ${idx}  IN RANGE  0  ${num_projects}
        ${new_project}=    Set Variable    ${project_name}${project_postfix}
        Log To Console    Creating new DS Project '${new_project}' with Model '${model_name}'
        Open Data Science Projects Home Page
        Create Data Science Project    title=${new_project}    description=${PRJ_DESCRIPTION}    existing_project=${TRUE}
        Recreate S3 Data Connection    project_title=${new_project}    dc_name=model-serving-connection
        ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
        ...            aws_bucket_name=ods-ci-s3
        Create Model Server    token=${FALSE}    server_name=${server_name}    existing_server=${TRUE}
        Serve Model    project_name=${new_project}    model_name=${model_name}    framework=openvino_ir    existing_data_connection=${TRUE}
        ...    data_connection_name=model-serving-connection    model_path=openvino-example-model    existing_model=${TRUE}
        ${runtime_pod_name}=    Replace String Using Regexp    string=${server_name}    pattern=\\s    replace_with=-
        ${runtime_pod_name}=    Convert To Lower Case    ${runtime_pod_name}
        Wait Until Keyword Succeeds    5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}    project_name=${new_project}
        Wait Until Keyword Succeeds    5 min  10 sec  Verify Serving Service    ${new_project}
        Verify Model Status    ${model_name}    success
        ${project_postfix}=    Evaluate  ${idx}+1
        Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    END

Model Serving Suite Teardown
    [Documentation]    Teardown steps after testing the suite.
    Remove File    openshift_ca.crt
    Close All Browsers
    RHOSi Teardown

Model Serving Test Teardown
    [Documentation]    Test teardown steps after test. It Deletes
    ...                all the DS projects created by the tests
    # Deleting the whole project will also delete the model
    Delete All DS Projects With Name Like    ${PRJ_TITLE}
