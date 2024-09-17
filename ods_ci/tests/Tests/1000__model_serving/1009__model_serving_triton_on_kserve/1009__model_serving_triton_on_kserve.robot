*** Settings ***
Documentation     Suite of test cases for Triton in Kserve
Library           OperatingSystem
Library           ../../../../libs/Helpers.py
Resource          ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettingsRuntimes.resource
Resource          ../../../Resources/Page/ODH/Monitoring/Monitoring.resource
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/CLI/ModelServing/modelmesh.resource
Resource          ../../../Resources/Common.robot
Suite Setup       Triton On Kserve Suite Setup
#Suite Teardown    Triton On Kserve Suite Teardown
Test Tags         Kserve


*** Variables ***
${INFERENCE_GRPC_INPUT_ONNX}=    tests/Resources/Files/triton/kserve-triton-onnx-gRPC-input.json
${INFERENCE_REST_INPUT_ONNX}=    @tests/Resources/Files/triton/kserve-triton-onnx-rest-input.json
${PROTOBUFF_FILE}=      tests/Resources/Files/triton/grpc_predict_v2.proto
${PRJ_TITLE}=    ms-triton-project4
${PRJ_DESCRIPTION}=    project used for model serving triton runtime tests
${MODEL_CREATED}=    ${FALSE}
${ONNX_MODEL_NAME}=    densenet_onnx
${ONNX_MODEL_LABEL}=     densenetonnx
${ONNX_GRPC_RUNTIME_NAME}=    triton-kserve-grpc
${ONNX_RUNTIME_NAME}=    triton-kserve-rest
${RESOURCES_DIRPATH}=        tests/Resources/Files/triton
${ONNX_GRPC_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/triton_onnx_gRPC_servingruntime.yaml
${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE}=     tests/Resources/Files/triton/kserve-triton-onnx-gRPC-output.json
${ONNX_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/triton_onnx_rest_servingruntime.yaml
${EXPECTED_INFERENCE_REST_OUTPUT_FILE}=      tests/Resources/Files/triton/kserve-triton-onnx-rest-output.json
${PATTERN}=  https:\/\/([^\/:]+)


*** Test Cases ***
Test Onnx Model Rest Inference Via UI (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of an onnx model in Kserve using Triton
    [Tags]    Sanity    RHOAIENG-11565
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${ONNX_RUNTIME_FILEPATH}
    ...    serving_platform=single      runtime_protocol=REST
    Serving Runtime Template Should Be Listed    displayed_name=${ONNX_RUNTIME_NAME}
    ...    serving_platform=single
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${ONNX_MODEL_NAME}    serving_runtime=triton-kserve-rest
    ...    data_connection=model-serving-connection    path=triton/model_repository/    model_framework=onnx - 1
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${ONNX_MODEL_LABEL}
    ...    namespace=${PRJ_TITLE}
    ${EXPECTED_INFERENCE_REST_OUTPUT_ONNX}=     Load Json File     file_path=${EXPECTED_INFERENCE_REST_OUTPUT_FILE}
    ...     as_string=${TRUE}
    Run Keyword And Continue On Failure    Verify Model Inference With Retries
    ...    ${ONNX_MODEL_NAME}    ${INFERENCE_REST_INPUT_ONNX}    ${EXPECTED_INFERENCE_REST_OUTPUT_ONNX}
    ...    token_auth=${FALSE}    project_title=${PRJ_TITLE}
    [Teardown]  Run Keywords    Get Kserve Events And Logs      model_name=${ONNX_MODEL_NAME}
    ...  project_title=${PRJ_TITLE}
    ...  AND
    ...  Clean All Models Of Current User

Test Onnx Model Grpc Inference Via UI (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of an onnx model in Kserve using Triton
    [Tags]    Sanity    RHOAIENG-11565      RunThisTest
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    #Upload Serving Runtime Template    runtime_filepath=${ONNX_GRPC_RUNTIME_FILEPATH}
    #...    serving_platform=single      runtime_protocol=gRPC
    Serving Runtime Template Should Be Listed    displayed_name=${ONNX_GRPC_RUNTIME_NAME}
    ...    serving_platform=single
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${ONNX_MODEL_NAME}    serving_runtime=triton-kserve-grpc
    ...    data_connection=model-serving-connection    path=triton/model_repository/    model_framework=onnx - 1
    ...    token=${TRUE}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${ONNX_MODEL_LABEL}
    ...    namespace=${PRJ_TITLE}
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_ONNX}=     Load Json File     file_path=${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE}
    ...     as_string=${TRUE}
    Log     ${EXPECTED_INFERENCE_GRPC_OUTPUT_ONNX}
    Open Model Serving Home Page
    ${host_url}=    Get Model Route Via UI       model_name=${ONNX_MODEL_NAME}
    ${host}=    Evaluate    re.search(r"${PATTERN}", r"${host_url}").group(1)    re
    Log    ${host}
    Sleep    5s
    ${token}=   Get Access Token Via UI    single_model=${TRUE}      model_name=densenet_onnx   project_name=${PRJ_TITLE}
    Fetch Knative CA Certificate    filename=openshift_ca_istio_knative.crt
    ${cert}=    Set Variable    --cacert    openshift_ca_istio_knative.crt
    #Sleep    10s
    Run Keyword And Continue On Failure      Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint=inference.GRPCInferenceService/ModelInfer
    ...    json_body=${INFERENCE_GRPC_INPUT_ONNX}
    ...    cert=${cert}    protobuf_file=${PROTOBUFF_FILE}      json_header=${token}
    #[Teardown]  Run Keywords    Get Kserve Events And Logs      model_name=${ONNX_MODEL_NAME}
    #...  project_title=${PRJ_TITLE}
    #...  AND
    #...  Clean All Models Of Current User


*** Keywords ***
Triton On Kserve Suite Setup
    [Documentation]    Suite setup steps for testing Triton. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Fetch Knative CA Certificate    filename=openshift_ca_istio_knative.crt
    #Clean All Models Of Current User

Triton On Kserve Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    # Even if kw fails, deleting the whole project will also delete the model
    # Failure will be shown in the logs of the run nonetheless
    IF    ${MODEL_CREATED}
        #Clean All Models Of Current User
        Log    Skipped
    ELSE
        Log    Model not deployed, skipping deletion step during teardown    console=true
    END
    ${projects}=    Create List    ${PRJ_TITLE}
    #Delete List Of Projects Via CLI   ocp_projects=${projects}
    # Will only be present on SM cluster runs, but keyword passes
    # if file does not exist
    Remove File    openshift_ca_istio_knative.crt
    SeleniumLibrary.Close All Browsers
    #RHOSi Teardown
