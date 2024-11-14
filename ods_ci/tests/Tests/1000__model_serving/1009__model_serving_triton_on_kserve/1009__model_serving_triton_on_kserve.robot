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
Suite Teardown    Triton On Kserve Suite Teardown
Test Tags         Kserve


*** Variables ***
${INFERENCE_GRPC_INPUT_ONNX}=    tests/Resources/Files/triton/kserve-triton-onnx-gRPC-input.json
${INFERENCE_REST_INPUT_ONNX}=    @tests/Resources/Files/triton/kserve-triton-onnx-rest-input.json
${PROTOBUFF_FILE}=      tests/Resources/Files/triton/grpc_predict_v2.proto
${PRJ_TITLE}=    ms-triton-project1
${PRJ_DESCRIPTION}=    project used for model serving triton runtime tests
${MODEL_CREATED}=    ${FALSE}
${PATTERN}=     https:\/\/([^\/:]+)
${ONNX_MODEL_NAME}=    densenet_onnx
${ONNX_MODEL_LABEL}=     densenetonnx
${ONNX_GRPC_RUNTIME_NAME}=    triton-kserve-grpc
${ONNX_RUNTIME_NAME}=    triton-kserve-rest
${RESOURCES_DIRPATH}=        tests/Resources/Files/triton
${ONNX_GRPC_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/triton_onnx_gRPC_servingruntime.yaml
${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE}=     tests/Resources/Files/triton/kserve-triton-onnx-gRPC-output.json
${ONNX_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/triton_onnx_rest_servingruntime.yaml
${EXPECTED_INFERENCE_REST_OUTPUT_FILE}=      tests/Resources/Files/triton/kserve-triton-onnx-rest-output.json
${INFERENCE_REST_INPUT_PYTORCH}=    @tests/Resources/Files/triton/kserve-triton-resnet-rest-input.json
${PYTORCH_MODEL_NAME}=    resnet50
${PYTORCH_RUNTIME_NAME}=    triton-kserve-rest
${PYTORCH_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/triton_onnx_rest_servingruntime.yaml
${EXPECTED_INFERENCE_REST_OUTPUT_FILE_PYTORCH}=       tests/Resources/Files/triton/kserve-triton-resnet-rest-output.json
${INFERENCE_GRPC_INPUT_TENSORFLOW}=    tests/Resources/Files/triton/kserve-triton-inception_graphdef-gRPC-input.json
${TENSORFLOW_MODEL_NAME}=    inception_graphdef
${TENSORFLOW_MODEL_LABEL}=     inceptiongraphdef
${TENSORFLOW_RUNTIME_NAME}=    triton-tensorflow-grpc
${TENSORFLOW_GRPC_RUNTIME_NAME}=    triton-tensorflow-grpc
${TENSORFLOW_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/triton_tensorflow_gRPC_servingruntime.yaml
${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE_TENSORFLOW}=       tests/Resources/Files/triton/kserve-triton-inception_graphdef-gRPC-output.json
${KERAS_RUNTIME_NAME}=    triton-keras-rest
${KERAS_MODEL_NAME}=      resnet50
${KERAS_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/triton_keras_rest_servingruntime.yaml
${INFERENCE_REST_INPUT_KERAS}=    @tests/Resources/Files/triton/kserve-triton-keras-rest-input.json
${EXPECTED_INFERENCE_REST_OUTPUT_FILE_KERAS}=       tests/Resources/Files/triton/kserve-triton-keras-rest-output.json
${PYTHON_MODEL_NAME}=   python
${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE_PYTHON}=       tests/Resources/Files/triton/kserve-triton-python-gRPC-output.json
${INFERENCE_GRPC_INPUT_PYTHON}=     tests/Resources/Files/triton/kserve-triton-python-gRPC-input.json


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
    ...  AND
    ...  Delete Serving Runtime Template From CLI    displayed_name=triton-kserve-rest


Test PYTORCH Model Inference Via UI(Triton on Kserve)
    [Documentation]    Test the deployment of an pytorch model in Kserve using Triton
    [Tags]    Sanity           RHOAIENG-11561

    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${PYTORCH_RUNTIME_FILEPATH}
    ...    serving_platform=single     runtime_protocol=REST
    Serving Runtime Template Should Be Listed    displayed_name=${PYTORCH_RUNTIME_NAME}
    ...    serving_platform=single
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${PYTORCH_MODEL_NAME}    serving_runtime=triton-kserve-rest
    ...    data_connection=model-serving-connection    path=triton/model_repository/    model_framework=pytorch - 1
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${PYTORCH_MODEL_NAME}
    ...    namespace=${PRJ_TITLE}
    ${EXPECTED_INFERENCE_REST_OUTPUT_PYTORCH}=     Load Json File
    ...    file_path=${EXPECTED_INFERENCE_REST_OUTPUT_FILE_PYTORCH}    as_string=${TRUE}
    Log    ${EXPECTED_INFERENCE_REST_OUTPUT_PYTORCH}
    Run Keyword And Continue On Failure    Verify Model Inference With Retries
    ...    ${PYTORCH_MODEL_NAME}    ${INFERENCE_REST_INPUT_PYTORCH}    ${EXPECTED_INFERENCE_REST_OUTPUT_PYTORCH}
    ...    token_auth=${FALSE}    project_title=${PRJ_TITLE}
    [Teardown]  Run Keywords    Get Kserve Events And Logs      model_name=${PYTORCH_MODEL_NAME}
    ...  project_title=${PRJ_TITLE}
    ...  AND
    ...  Clean All Models Of Current User
    ...  AND
    ...  Delete Serving Runtime Template From CLI    displayed_name=triton-kserve-rest

Test Onnx Model Grpc Inference Via UI (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of an onnx model in Kserve using Triton
    [Tags]    Sanity    RHOAIENG-9053
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${ONNX_GRPC_RUNTIME_FILEPATH}
    ...    serving_platform=single      runtime_protocol=gRPC
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
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_ONNX}=     Load Json String    ${EXPECTED_INFERENCE_GRPC_OUTPUT_ONNX}
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_ONNX}=     Evaluate    json.dumps(${EXPECTED_INFERENCE_GRPC_OUTPUT_ONNX})
    Log     ${EXPECTED_INFERENCE_GRPC_OUTPUT_ONNX}
    Open Model Serving Home Page
    ${host_url}=    Get Model Route Via UI       model_name=${ONNX_MODEL_NAME}
    ${host}=    Evaluate    re.search(r"${PATTERN}", r"${host_url}").group(1)    re
    Log    ${host}
    ${token}=   Get Access Token Via UI    single_model=${TRUE}      model_name=densenet_onnx   project_name=${PRJ_TITLE}
    ${inference_output}=    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint=inference.GRPCInferenceService/ModelInfer
    ...    json_body=@      input_filepath=${INFERENCE_GRPC_INPUT_ONNX}
    ...    insecure=${True}    protobuf_file=${PROTOBUFF_FILE}      json_header="Authorization: Bearer ${token}"
    Log    ${inference_output}
    ${inference_output}=    Evaluate    json.dumps(${inference_output})
    Log    ${inference_output}
    ${result}    ${list}=    Inference Comparison    ${EXPECTED_INFERENCE_GRPC_OUTPUT_ONNX}    ${inference_output}
    Log    ${result}
    Log    ${list}
    [Teardown]  Run Keywords    Get Kserve Events And Logs      model_name=${ONNX_MODEL_NAME}
    ...  project_title=${PRJ_TITLE}
    ...  AND
    ...  Clean All Models Of Current User
    ...  AND
    ...  Delete Serving Runtime Template From CLI    displayed_name=triton-kserve-grpc

Test Tensorflow Model Grpc Inference Via UI (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of an tensorflow model in Kserve using Triton
    [Tags]    Sanity    RHOAIENG-9052
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${TENSORFLOW_RUNTIME_FILEPATH}
    ...    serving_platform=single      runtime_protocol=gRPC
    Serving Runtime Template Should Be Listed    displayed_name=${TENSORFLOW_GRPC_RUNTIME_NAME}
    ...    serving_platform=single
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${TENSORFLOW_MODEL_NAME}    serving_runtime=triton-tensorflow-grpc
    ...    data_connection=model-serving-connection    path=triton/model_repository/    model_framework=tensorflow - 2
    ...    token=${TRUE}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${TENSORFLOW_MODEL_LABEL}
    ...    namespace=${PRJ_TITLE}    timeout=180s
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_TENSORFLOW}=     Load Json File     file_path=${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE_TENSORFLOW}
    ...     as_string=${TRUE}
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_TENSORFLOW}=     Load Json String    ${EXPECTED_INFERENCE_GRPC_OUTPUT_TENSORFLOW}
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_TENSORFLOW}=     Evaluate    json.dumps(${EXPECTED_INFERENCE_GRPC_OUTPUT_TENSORFLOW})
    Log     ${EXPECTED_INFERENCE_GRPC_OUTPUT_TENSORFLOW}
    Open Model Serving Home Page
    ${host}=    Get Model Route for gRPC Via UI    model_name=${TENSORFLOW_MODEL_NAME}
    Log    ${host}
    ${token}=   Get Access Token Via UI    single_model=${TRUE}      model_name=${TENSORFLOW_MODEL_NAME}   project_name=${PRJ_TITLE}
    ${inference_output}=    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint=inference.GRPCInferenceService/ModelInfer
    ...    json_body=@      input_filepath=${INFERENCE_GRPC_INPUT_TENSORFLOW}
    ...    insecure=${True}    protobuf_file=${PROTOBUFF_FILE}      json_header="Authorization: Bearer ${token}"
    Log    ${inference_output}
    ${inference_output}=    Evaluate    json.dumps(${inference_output})
    Log    ${inference_output}
    ${result}    ${list}=    Inference Comparison    ${EXPECTED_INFERENCE_GRPC_OUTPUT_TENSORFLOW}    ${inference_output}
    Log    ${result}
    Log    ${list}
    [Teardown]  Run Keywords    Get Kserve Events And Logs      model_name=${TENSORFLOW_MODEL_NAME}
    ...  project_title=${PRJ_TITLE}
    ...  AND
    ...  Clean All Models Of Current User
    ...  AND
    ...  Delete Serving Runtime Template From CLI    displayed_name=triton-tensorflow-grpc

Test KERAS Model Inference Via UI(Triton on Kserve)
    [Documentation]    Test the deployment of an keras model in Kserve using Triton
    [Tags]    Sanity           RHOAIENG-10328

    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${KERAS_RUNTIME_FILEPATH}
    ...    serving_platform=single     runtime_protocol=REST
    Serving Runtime Template Should Be Listed    displayed_name=${KERAS_RUNTIME_NAME}
    ...    serving_platform=single
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${KERAS_MODEL_NAME}    serving_runtime=triton-keras-rest
    ...    data_connection=model-serving-connection    path=tritonkeras/model_repository/    model_framework=tensorflow - 2
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${KERAS_MODEL_NAME}
    ...    namespace=${PRJ_TITLE}    timeout=180s
    ${EXPECTED_INFERENCE_REST_OUTPUT_KERAS}=     Load Json File
    ...    file_path=${EXPECTED_INFERENCE_REST_OUTPUT_FILE_KERAS}    as_string=${TRUE}
    Log    ${EXPECTED_INFERENCE_REST_OUTPUT_KERAS}
    Run Keyword And Continue On Failure    Verify Model Inference With Retries
    ...    ${KERAS_MODEL_NAME}    ${INFERENCE_REST_INPUT_KERAS}    ${EXPECTED_INFERENCE_REST_OUTPUT_KERAS}
    ...    token_auth=${FALSE}    project_title=${PRJ_TITLE}
    [Teardown]  Run Keywords    Get Kserve Events And Logs      model_name=${KERAS_MODEL_NAME}
    ...  project_title=${PRJ_TITLE}
    ...  AND
    ...  Clean All Models Of Current User
    ...  AND
    ...  Delete Serving Runtime Template From CLI    displayed_name=triton-keras-rest


Test Python Model Grpc Inference Via UI (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of an onnx model in Kserve using Triton
    [Tags]    Tier2    RHOAIENG-15374
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${ONNX_GRPC_RUNTIME_FILEPATH}
    ...    serving_platform=single      runtime_protocol=gRPC
    Serving Runtime Template Should Be Listed    displayed_name=${ONNX_GRPC_RUNTIME_NAME}
    ...    serving_platform=single
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${PYTHON_MODEL_NAME}    serving_runtime=triton-kserve-grpc
    ...    data_connection=model-serving-connection    path=triton/model_repository/    model_framework=python - 1
    ...    token=${TRUE}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${PYTHON_MODEL_NAME}
    ...    namespace=${PRJ_TITLE}
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}=     Load Json File     file_path=${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE_PYTHON}
    ...     as_string=${TRUE}
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}=     Load Json String    ${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}=     Evaluate    json.dumps(${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON})
    Log     ${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}
    Open Model Serving Home Page
    ${host_url}=    Get Model Route Via UI       model_name=${PYTHON_MODEL_NAME}
    ${host}=    Evaluate    re.search(r"${PATTERN}", r"${host_url}").group(1)    re
    Log    ${host}
    ${token}=   Get Access Token Via UI    single_model=${TRUE}      model_name=python   project_name=${PRJ_TITLE}
    ${inference_output}=    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint=inference.GRPCInferenceService/ModelInfer
    ...    json_body=@      input_filepath=${INFERENCE_GRPC_INPUT_PYTHON}
    ...    insecure=${True}    protobuf_file=${PROTOBUFF_FILE}      json_header="Authorization: Bearer ${token}"
    Log    ${inference_output}
    ${inference_output}=    Evaluate    json.dumps(${inference_output})
    Log    ${inference_output}
    ${result}    ${list}=    Inference Comparison    ${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}    ${inference_output}
    Log    ${result}
    Log    ${list}
    [Teardown]  Run Keywords    Get Kserve Events And Logs    model_name= ${PYTHON_MODEL_NAME}
    ...   project_title= ${PRJ_TITLE}
    ...  AND
    ...  Clean All Models Of Current User
    ...  AND
    ...  Delete Serving Runtime Template From CLI    displayed_name=triton-kserve-grpc

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
    Clean All Models Of Current User

Triton On Kserve Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    # Even if kw fails, deleting the whole project will also delete the model
    # Failure will be shown in the logs of the run nonetheless
    IF    ${MODEL_CREATED}
       Clean All Models Of Current User
    ELSE
        Log    Model not deployed, skipping deletion step during teardown    console=true
    END
    ${projects}=    Create List    ${PRJ_TITLE}
    Delete List Of Projects Via CLI   ocp_projects=${projects}
    # Will only be present on SM cluster runs, but keyword passes
    # if file does not exist
    Remove File    openshift_ca_istio_knative.crt
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown
