*** Settings ***
Documentation     Collection of CLI tests to validate the model serving stack for different Large Language Models (LLM).
...               These tests leverage on TGIS Standalone Serving Runtime
Resource          ../../Resources/OCP.resource
Resource          ../../Resources/CLI/ModelServing/llm.resource
Library           OpenShiftLibrary
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Tags         KServe-OVMS


*** Variables ***
${TEST_NS}=        ovmsmodel
${RUNTIME_NAME}=  ovms-runtime   
${USE_PVC}=    ${TRUE}
${DOWNLOAD_IN_PVC}=    ${TRUE}
${USE_GPU}=    ${FALSE}
${KSERVE_MODE}=    Serverless    #RawDeployment   #Serverless
${MODEL_FORMAT}=   onnx
${PROTOCOL}=     http
${OVERLAY}=      ${EMPTY}
${MODELS_BUCKET}=    ${S3.BUCKET_1}
${INFERENCE_INPUT}=    @tests/Resources/Files/modelmesh-mnist-input.json

*** Test Cases ***
Verify User Can Serve And Query ovms Model
    [Documentation]    Basic tests for preparing, deploying and querying model
    ...                using Kserve and ovms runtime
    [Tags]    OVMS
    ...       Tier1
    ...       Smoke
    ...       OpenDataHub
    ...       RHOAIENG-9045
    Setup Test Variables    model_name=test-dir    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}
    ${EXPECTED_INFERENCE_SECURED_OUTPUT}  Set Variable    {"model_name":"${model_name}__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}  #robocop: disable
    Set Project And Runtime    runtime=${RUNTIME_NAME}     protocol=${PROTOCOL}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}
    ...    storage_size=10Gi
    ${requests}=    Create Dictionary    memory=10Gi
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ${service_port}=    Extract Service Port    service_name=${model_name}-predictor    protocol=TCP    namespace=${test_namespace}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}  local_port=${service_port}
    ...    remote_port=${service_port}    process_alias=ovms-process
    Verify Model Inference With Retries   model_name=${model_name}    inference_input=${INFERENCE_INPUT}
    ...    expected_inference_output=${EXPECTED_INFERENCE_SECURED_OUTPUT}   project_title=${test_namespace}    deployment_mode="Cli"  kserve_mode=${KSERVE_MODE}
    ...    service_port=${service_port}   end_point=/v2/models/${model_name}/infer  retries=10

   [Teardown]    Run Keywords
   ...    Clean Up Test Project    test_ns=${test_namespace}
   ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}    kserve_mode=${KSERVE_MODE}
   ...    AND
   ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    ovms-process    kill=true


*** Keywords ***
Suite Setup
    [Documentation]
    Set Library Search Order  SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Load Expected Responses
    Set Default Storage Class In GCP    default=ssd-csi

Suite Teardown
    Set Default Storage Class In GCP    default=standard-csi
    RHOSi Teardown

Setup Test Variables
    [Arguments]    ${model_name}    ${kserve_mode}=Serverless    ${use_pvc}=${FALSE}    ${use_gpu}=${FALSE}
    ...    ${model_path}=${model_name}
    Set Test Variable    ${model_name}
    ${models_names}=    Create List    ${model_name}
    Set Test Variable    ${models_names}
    Set Test Variable    ${model_path}
    Set Test Variable    ${test_namespace}     ${TEST_NS}-${model_name}
    IF    ${use_pvc}
        Set Test Variable    ${storage_uri}    pvc://${model_name}-claim/${model_path}
    ELSE
        Set Test Variable    ${storage_uri}    s3://${S3.BUCKET_3.NAME}/${model_path}
    END
    IF   ${use_gpu}
        ${limits}=    Create Dictionary    nvidia.com/gpu=1
        Set Test Variable    ${limits}
    ELSE
        Set Test Variable    ${limits}    &{EMPTY}
    END
    IF    "${KSERVE_MODE}" == "RawDeployment"
        Set Test Variable    ${use_port_forwarding}    ${TRUE}
    ELSE
        Set Test Variable    ${use_port_forwarding}    ${FALSE}
    END
    Set Log Level    NONE
    Set Test Variable    ${access_key_id}    ${S3.AWS_ACCESS_KEY_ID}
    Set Test Variable    ${access_key}    ${S3.AWS_SECRET_ACCESS_KEY}
    Set Test Variable    ${endpoint}    ${MODELS_BUCKET.ENDPOINT}
    Set Test Variable    ${region}    ${MODELS_BUCKET.REGION}
    Set Log Level    INFO
