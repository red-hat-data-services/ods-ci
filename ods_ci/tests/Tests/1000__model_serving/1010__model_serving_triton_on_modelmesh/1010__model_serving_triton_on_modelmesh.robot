*** Settings ***
Documentation     Suite of test cases for Triton in Modelmesh
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
${INFERENCE_REST_INPUT_ONNX_FILE}=    @${RESOURCES_DIRPATH}/kserve-triton-onnx-rest-input.json
${PRJ_TITLE}=    ms-triton-project-mm
${PRJ_DESCRIPTION}=    project used for model serving triton runtime tests
${MODEL_CREATED}=    ${FALSE}
${ONNX_MODEL_NAME}=    densenet_onnx
${ONNX_MODEL_LABEL}=     densenetonnx
${ONNX_RUNTIME_NAME}=    modelmesh-triton
${RESOURCES_DIRPATH}=        tests/Resources/Files/triton
${ONNX_MODELMESH_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/triton_onnx_modelmesh_runtime.yaml
${EXPECTED_INFERENCE_REST_OUTPUT_FILE}=      ${RESOURCES_DIRPATH}/modelmesh-triton-onnx-rest-output.json
${INFERENCE_REST_INPUT_PYTORCH}=    @tests/Resources/Files/triton/modelmesh-triton-pytorch-rest-input.json
${PYTORCH_MODEL_NAME}=    resnet50
${TENSORFLOW_MODEL_NAME}=       inception_graphdef
${PYTORCH_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/triton_pytorch_modelmesh_runtime.yaml
${EXPECTED_INFERENCE_REST_OUTPUT_FILE_PYTORCH}=       tests/Resources/Files/triton/modelmesh-triton-pytorch-rest-output.json
${INFERENCE_REST_INPUT_TENSORFLOW_FILE}=    @${RESOURCES_DIRPATH}/modelmesh-triton-tensorflow-input.json
${EXPECTED_INFERENCE_TENSORFLOW_OUTPUT_FILE}=      ${RESOURCES_DIRPATH}/modelmesh-triton-tensorflow-output.json
${TENSORFLOW_RUNTIME_FILEPATH}=      ${RESOURCES_DIRPATH}/triton_tensorflow_modelmesh_runtime.yaml
${PYTHON_MODEL_NAME}=    python
${INFERENCE_REST_INPUT_PYTHON_FILE}=    @${RESOURCES_DIRPATH}/modelmesh-triton-python-input.json
${EXPECTED_INFERENCE_PYTHON_OUTPUT_FILE}=      ${RESOURCES_DIRPATH}/modelmesh-triton-python-output.json


*** Test Cases ***
Test Onnx Model Rest Inference Via UI (Triton on Modelmesh)
    [Documentation]    Test the deployment of an onnx model in Kserve using Triton
    [Tags]    Sanity    RHOAIENG-9070

    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${ONNX_MODELMESH_RUNTIME_FILEPATH}
    ...    serving_platform=multi      runtime_protocol=REST
    Serving Runtime Template Should Be Listed    displayed_name=${ONNX_RUNTIME_NAME}
    ...    serving_platform=multi
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${TRUE}    runtime=${ONNX_RUNTIME_NAME}    server_name=${ONNX_RUNTIME_NAME}    existing_server=${FALSE}
    Sleep    10s
    Serve Model    project_name=${PRJ_TITLE}    model_name=${ONNX_MODEL_NAME}    framework=onnx - 1
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection
    ...    model_path=triton/model_repository/densenet_onnx/        model_server=${ONNX_RUNTIME_NAME}
    Wait Until Runtime Pod Is Running    server_name=${ONNX_RUNTIME_NAME}
    ...    project_title=${PRJ_TITLE}    timeout=5m
    Verify Model Status    ${ONNX_MODEL_NAME}    success
    ${EXPECTED_INFERENCE_REST_OUTPUT_ONNX}=     Load Json File      file_path=${EXPECTED_INFERENCE_REST_OUTPUT_FILE}
    ...     as_string=${TRUE}
    Log     ${EXPECTED_INFERENCE_REST_OUTPUT_ONNX}
    Verify Model Inference With Retries    ${ONNX_MODEL_NAME}    ${INFERENCE_REST_INPUT_ONNX_FILE}
    ...    ${EXPECTED_INFERENCE_REST_OUTPUT_ONNX}
    ...    token_auth=${TRUE}
    ...    project_title=${PRJ_TITLE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Delete Serving Runtime Template         displayed_name=modelmesh-triton
    [Teardown]  Run Keywords    Get Modelmesh Events And Logs      model_name=${ONNX_MODEL_NAME}
    ...  project_title=${PRJ_TITLE}
    ...  AND
    ...  Clean All Models Of Current User

Test Pytorch Model Rest Inference Via UI (Triton on Modelmesh)
    [Documentation]    Test the deployment of an onnx model in Kserve using Triton
    [Tags]    Sanity    RHOAIENG-11561

    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${PYTORCH_RUNTIME_FILEPATH}
    ...    serving_platform=multi      runtime_protocol=REST
    Serving Runtime Template Should Be Listed    displayed_name=${ONNX_RUNTIME_NAME}
    ...    serving_platform=multi
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${TRUE}    runtime=${ONNX_RUNTIME_NAME}    server_name=${ONNX_RUNTIME_NAME}    existing_server=${TRUE}
    Sleep    10s
    Serve Model    project_name=${PRJ_TITLE}    model_name=${PYTORCH_MODEL_NAME}    framework=pytorch - 1
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection
    ...    model_path=triton/model_repository/resnet50/        model_server=${ONNX_RUNTIME_NAME}
    Wait Until Runtime Pod Is Running    server_name=${ONNX_RUNTIME_NAME}
    ...    project_title=${PRJ_TITLE}    timeout=5m
    Verify Model Status    ${PYTORCH_MODEL_NAME}    success
    ${EXPECTED_INFERENCE_REST_OUTPUT_PYTORCH}=     Load Json File      file_path=${EXPECTED_INFERENCE_REST_OUTPUT_FILE_PYTORCH}
    ...     as_string=${TRUE}
    Log     ${EXPECTED_INFERENCE_REST_OUTPUT_PYTORCH}
    Verify Model Inference With Retries    ${PYTORCH_MODEL_NAME}    ${INFERENCE_REST_INPUT_PYTORCH}
    ...    ${EXPECTED_INFERENCE_REST_OUTPUT_PYTORCH}
    ...    token_auth=${TRUE}
    ...    project_title=${PRJ_TITLE}
    Open Dashboard Settings    settings_page=Serving runtimes
    [Teardown]  Run Keywords    Get Modelmesh Events And Logs      model_name=${PYTORCH_MODEL_NAME}
    ...  project_title=${PRJ_TITLE}
    ...  AND
    ...  Clean All Models Of Current User
    ...  AND
    ...  Delete Serving Runtime Template From CLI    displayed_name=modelmesh-triton


Test Tensorflow Model Rest Inference Via UI (Triton on Modelmesh)
    [Documentation]    Test the deployment of an onnx model in Kserve using Triton
    [Tags]    Sanity    RHOAIENG-9069

    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${TENSORFLOW_RUNTIME_FILEPATH}
    ...    serving_platform=multi      runtime_protocol=REST
    Serving Runtime Template Should Be Listed    displayed_name=${ONNX_RUNTIME_NAME}
    ...    serving_platform=multi
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${TRUE}    runtime=${ONNX_RUNTIME_NAME}    server_name=${ONNX_RUNTIME_NAME}    existing_server=${FALSE}
    Sleep    10s
    Serve Model    project_name=${PRJ_TITLE}    model_name=${TENSORFLOW_MODEL_NAME}    framework=tensorflow - 2
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection
    ...    model_path=triton/model_repository/inception_graphdef/        model_server=${ONNX_RUNTIME_NAME}
    Wait Until Runtime Pod Is Running    server_name=${ONNX_RUNTIME_NAME}
    ...    project_title=${PRJ_TITLE}    timeout=5m
    Verify Model Status    ${TENSORFLOW_MODEL_NAME}    success
    ${EXPECTED_INFERENCE_REST_OUTPUT_TENSORFLOW}=     Load Json File      file_path=${EXPECTED_INFERENCE_TENSORFLOW_OUTPUT_FILE}
    ...     as_string=${TRUE}
    Log     ${EXPECTED_INFERENCE_REST_OUTPUT_TENSORFLOW}
    Verify Model Inference With Retries    ${TENSORFLOW_MODEL_NAME}    ${INFERENCE_REST_INPUT_TENSORFLOW_FILE}
    ...    ${EXPECTED_INFERENCE_REST_OUTPUT_TENSORFLOW}
    ...    token_auth=${TRUE}
    ...    project_title=${PRJ_TITLE}
    [Teardown]  Run Keywords    Get Modelmesh Events And Logs      model_name=${TENSORFLOW_MODEL_NAME}
    ...  project_title=${PRJ_TITLE}
    ...  AND
    ...  Clean All Models Of Current User


Test Python Model Rest Inference Via UI (Triton on Modelmesh)
    [Documentation]    Test the deployment of an onnx model in Kserve using Triton
    [Tags]    Sanity    RHOAIENG-11564

    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${ONNX_MODELMESH_RUNTIME_FILEPATH}
    ...    serving_platform=multi      runtime_protocol=REST
    Serving Runtime Template Should Be Listed    displayed_name=${ONNX_RUNTIME_NAME}
    ...    serving_platform=multi
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${TRUE}    runtime=${ONNX_RUNTIME_NAME}    server_name=${ONNX_RUNTIME_NAME}    existing_server=${TRUE}
    Sleep    10s
    Serve Model    project_name=${PRJ_TITLE}    model_name=${PYTHON_MODEL_NAME}    framework=python - 1
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection
    ...    model_path=triton/model_repository/python/        model_server=${ONNX_RUNTIME_NAME}
    Wait Until Runtime Pod Is Running    server_name=${ONNX_RUNTIME_NAME}
    ...    project_title=${PRJ_TITLE}    timeout=5m
    Verify Model Status    ${PYTHON_MODEL_NAME}    success
    ${EXPECTED_INFERENCE_REST_OUTPUT_PYTHON}=     Load Json File      file_path=${EXPECTED_INFERENCE_PYTHON_OUTPUT_FILE}
    ...     as_string=${TRUE}
    Log     ${EXPECTED_INFERENCE_REST_OUTPUT_PYTHON}
    Verify Model Inference With Retries    ${PYTHON_MODEL_NAME}    ${INFERENCE_REST_INPUT_PYTHON_FILE}
    ...    ${EXPECTED_INFERENCE_REST_OUTPUT_PYTHON}
    ...    token_auth=${TRUE}
    ...    project_title=${PRJ_TITLE}
    Open Dashboard Settings    settings_page=Serving runtimes
    Delete Serving Runtime Template         displayed_name=modelmesh-triton
    [Teardown]  Run Keywords    Get Modelmesh Events And Logs      model_name=${PYTHON_MODEL_NAME}
    ...  project_title=${PRJ_TITLE}
    ...  AND
    ...  Clean All Models Of Current User

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
    #Delete List Of Projects Via CLI   ocp_projects=${projects}
    # Will only be present on SM cluster runs, but keyword passes
    # if file does not exist
    Remove File    openshift_ca_istio_knative.crt
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown
