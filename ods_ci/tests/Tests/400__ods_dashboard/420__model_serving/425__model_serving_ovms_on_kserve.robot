*** Settings ***
Documentation     Suite of test cases for OVMS in Kserve
Library           OperatingSystem
Library           ../../../../libs/Helpers.py
Resource          ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/CLI/ModelServing/modelmesh.resource
Suite Setup       OVMS On Kserve Suite Setup
Suite Teardown    OVMS On Kserve Suite Teardown
Test Tags         Kserve


*** Variables ***
${INFERENCE_INPUT}=    @ods_ci/tests/Resources/Files/modelmesh-mnist-input.json
${INFERENCE_INPUT_OPENVINO}=    @ods_ci/tests/Resources/Files/openvino-example-input.json
${PRJ_TITLE}=    model-serving-project
${PRJ_DESCRIPTION}=    project used for model serving tests
${MODEL_CREATED}=    ${FALSE}
${MODEL_NAME}=    test-model
${RUNTIME_NAME}=    Model Serving Test
${SECOND_PROJECT}=    sec-model-serving-project
${SECURED_MODEL}=    test-model-secured
${EXPECTED_INFERENCE_SECURED_OUTPUT}=    {"model_name":"${SECURED_MODEL}__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}  #robocop: disable
${EXPECTED_INFERENCE_OUTPUT_OPENVINO}=    {"model_name":"${MODEL_NAME}__isvc-8655dc7979","model_version":"1","outputs":[{"name":"Func/StatefulPartitionedCall/output/_13:0","datatype":"FP32","shape":[1,1],"data":[0.99999994]}]}  #robocop: disable

${PRJ_TITLE_GPU}=    model-serving-project-gpu
${PRJ_DESCRIPTION_GPU}=    project used for model serving tests (with GPUs)
${MODEL_NAME_GPU}=    vehicle-detection
${MODEL_CREATED}=    ${FALSE}
${RUNTIME_NAME_GPU}=    Model Serving GPU Test

*** Test Cases ***
Verify Openvino_IR Model Via UI (OVMS on Kserve)
    [Documentation]    Test the deployment of an openvino_ir model in Kserve using OVMS
    [Tags]    Smoke
    ...       ODS-2626
    Create Openvino Models For Kserve    server_name=${RUNTIME_NAME}    model_name=${MODEL_NAME}
    ...    project_name=${PRJ_TITLE}   num_projects=1
    Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT_OPENVINO}
    ...    ${EXPECTED_INFERENCE_OUTPUT_OPENVINO}    token_auth=${FALSE}
    [Teardown]    Run Keywords    Clean All Models Of Current User    AND
    ...    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${MODEL_NAME}    project_title=${PRJ_TITLE}

Verify Tensorflow Model Via UI (OVMS on Kserve)
    [Documentation]    Test the deployment of a tensorflow (.pb) model in Kserve using OVMS
    [Tags]    Sanity    Tier1
    ...       ODS-2627
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}    existing_project=${TRUE}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${MODEL_NAME}     serving_runtime=OpenVINO Model Server
    ...    data_connection=model-serving-connection    path=tf-kserve    model_framework=tensorflow - 2
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${MODEL_NAME}
    ...    namespace=${PRJ_TITLE}
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    ${url}    ${kserve}=    Get Model Route via UI    ${MODEL_NAME}
    ${status_code}    ${response_text}=    Send Random Inference Request     endpoint=${url}    name=input
    ...    shape={"B": 1, "H": 299, "W": 299, "C": 3}    no_requests=1
    Should Be Equal As Strings    ${status_code}    200
    [Teardown]    Run Keywords    Clean All Models Of Current User    AND
    ...    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${MODEL_NAME}    project_title=${PRJ_TITLE}

Test Onnx Model Via UI (OVMS on Kserve)
    [Documentation]    Test the deployment of an onnx model in Kserve using OVMS
    [Tags]    Sanity    Tier1
    ...       ODS-2628
    Open Data Science Projects Home Page
    Create Data Science Project    title=${SECOND_PROJECT}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Recreate S3 Data Connection    project_title=${SECOND_PROJECT}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${SECURED_MODEL}    serving_runtime=OpenVINO Model Server
    ...    data_connection=model-serving-connection    path=test-dir    model_framework=onnx
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${SECURED_MODEL}
    ...    namespace=${SECOND_PROJECT}
    Run Keyword And Continue On Failure    Verify Model Inference With Retries
    ...    ${SECURED_MODEL}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_SECURED_OUTPUT}    token_auth=${FALSE}
    ...    project_title=${SECOND_PROJECT}
    [Teardown]    Run Keywords    Clean All Models Of Current User    AND
    ...    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${SECURED_MODEL}    project_title=${SECOND_PROJECT}

Verify Multiple Projects With Same Model (OVMS on Kserve)
    [Documentation]    Test the deployment of multiple DS project with same openvino_ir model (kserve)
    [Tags]    Sanity
    ...       ODS-2629    RHOAIENG-549
    Create Openvino Models For Kserve    server_name=${RUNTIME_NAME}    model_name=${MODEL_NAME}
    ...    project_name=${PRJ_TITLE}    num_projects=3
    [Teardown]    Run Keywords    Clean All Models Of Current User    AND
    ...    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${MODEL_NAME}    project_title=${PRJ_TITLE}

Verify GPU Model Deployment Via UI (OVMS on Kserve)
    [Documentation]    Test the deployment of an openvino_ir model on a model server with GPUs attached
    [Tags]    Sanity    Tier1    Resources-GPU
    ...       ODS-XXXX
    Clean All Models Of Current User
    Open Data Science Projects Home Page
    Wait For RHODS Dashboard To Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
    Create Data Science Project    title=${PRJ_TITLE_GPU}    description=${PRJ_DESCRIPTION_GPU}
    Create S3 Data Connection    project_title=${PRJ_TITLE_GPU}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${MODEL_NAME_GPU}    serving_runtime=OpenVINO Model Server
    ...    data_connection=model-serving-connection    path=vehicle-detection-kserve    model_framework=openvino_ir
    ...    no_gpus=1
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${MODEL_NAME_GPU}
    ...    namespace=${PRJ_TITLE_GPU}
    Verify Displayed GPU Count In Single Model Serving    model_name=${MODEL_NAME_GPU}    no_gpus=1
    ${requests} =    Get Container Requests    namespace=${PRJ_TITLE_GPU}
    ...    label=serving.kserve.io/inferenceservice=${MODEL_NAME_GPU}    container_name=kserve-container
    Should Contain    ${requests}    "nvidia.com/gpu": "1"
    ${node} =    Get Node Pod Is Running On    namespace=${PRJ_TITLE_GPU}
    ...    label=serving.kserve.io/inferenceservice=${MODEL_NAME_GPU}
    ${type} =    Get Instance Type Of Node    ${node}
    Should Be Equal As Strings    ${type}    "g4dn.xlarge"
    Verify Model Status    ${MODEL_NAME_GPU}    success
    Set Suite Variable    ${MODEL_CREATED}    True
    ${url}    ${kserve}=    Get Model Route via UI    ${MODEL_NAME_GPU}
    Send Random Inference Request     endpoint=${url}    no_requests=100
    # Verify metric DCGM_FI_PROF_GR_ENGINE_ACTIVE goes over 0
    ${prometheus_route}=    Get OpenShift Prometheus Route
    ${sa_token}=    Get OpenShift Prometheus Service Account Token
    ${expression}=    Set Variable    DCGM_FI_PROF_GR_ENGINE_ACTIVE
    ${resp}=    Prometheus.Run Query    ${prometheus_route}    ${sa_token}    ${expression}
    Log    DCGM_FI_PROF_GR_ENGINE_ACTIVE: ${resp.json()["data"]["result"][0]["value"][-1]}
    Should Be True    ${resp.json()["data"]["result"][0]["value"][-1]} > ${0}
    [Teardown]    Run Keywords    Clean All Models Of Current User    AND
    ...    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${MODEL_NAME_GPU}    project_title=${PRJ_TITLE_GPU}


*** Keywords ***
OVMS On Kserve Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Fetch CA Certificate If RHODS Is Self-Managed
    Clean All Models Of Current User

Create Openvino Models For Kserve
    [Documentation]    Create Openvino model in N projects (more than 1 will add index to project name)
    [Arguments]    ${server_name}=${RUNTIME_NAME}    ${model_name}=${MODEL_NAME}    ${project_name}=${PRJ_TITLE}
    ...    ${num_projects}=1    ${token}=${FALSE}
    ${project_postfix}=    Set Variable    ${EMPTY}
    FOR  ${idx}  IN RANGE  0  ${num_projects}
        ${new_project}=    Set Variable    ${project_name}${project_postfix}
        Log To Console    Creating new DS Project '${new_project}' with Model '${model_name}'
        Open Data Science Projects Home Page
        Create Data Science Project    title=${new_project}    description=${PRJ_DESCRIPTION}
        ...    existing_project=${TRUE}
        Recreate S3 Data Connection    project_title=${new_project}    dc_name=model-serving-connection
        ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
        ...            aws_bucket_name=ods-ci-s3
        Deploy Kserve Model Via UI    model_name=${model_name}    serving_runtime=OpenVINO Model Server
        ...    data_connection=model-serving-connection    path=kserve-openvino-test/openvino-example-model
        ...    model_framework=openvino_ir
        Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
        ...    namespace=${new_project}
        Verify Model Status    ${model_name}    success
        ${project_postfix}=    Evaluate  ${idx}+1
        Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    END

OVMS On Kserve Suite Teardown
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
    Delete Data Science Projects From CLI   ocp_projects=${projects}
    # Will only be present on SM cluster runs, but keyword passes
    # if file does not exist
    Remove File    openshift_ca_istio_knative.crt
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown
