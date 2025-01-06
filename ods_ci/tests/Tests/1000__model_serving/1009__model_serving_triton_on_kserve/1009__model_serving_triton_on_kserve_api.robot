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
Resource          ../../../Resources/CLI/ModelServing/llm.resource
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Tags         Kserve

*** Variables ***
${PYTHON_MODEL_NAME}=   python
${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}=       {"modelName":"python","modelVersion":"1","id":"1","outputs":[{"name":"OUTPUT0","datatype":"FP32","shape":["4"]},{"name":"OUTPUT1","datatype":"FP32","shape":["4"]}],"rawOutputContents":["AgAAAAAAAAAAAAAAAAAAAA==","AAQAAAAAAAAAAAAAAAAAAA=="]}
${INFERENCE_GRPC_INPUT_PYTHONFILE}=       tests/Resources/Files/triton/kserve-triton-python-grpc-input.json
${KSERVE_MODE}=    Serverless   # Serverless
${PROTOCOL_GRPC}=     grpc
${TEST_NS}=        tritonmodel
${DOWNLOAD_IN_PVC}=    ${FALSE}
${MODELS_BUCKET}=    ${S3.BUCKET_1}
${LLM_RESOURCES_DIRPATH}=    tests/Resources/Files/llm
${INFERENCESERVICE_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/serving_runtimes/base/isvc.yaml
${INFERENCESERVICE_FILEPATH_NEW}=    ${LLM_RESOURCES_DIRPATH}/serving_runtimes/isvc
${INFERENCESERVICE_FILLED_FILEPATH}=    ${INFERENCESERVICE_FILEPATH_NEW}/isvc_filled.yaml
${KSERVE_RUNTIME_REST_NAME}=  triton-kserve-runtime
${PATTERN}=     https:\/\/([^\/:]+)
${PROTOBUFF_FILE}=      tests/Resources/Files/triton/grpc_predict_v2.proto



*** Test Cases ***
Test Python Model Grpc Inference Via API (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of python model in Kserve using Triton
    [Tags]    Tier2    RHOAIENG-16912

    Setup Test Variables    model_name=${PYTHON_MODEL_NAME}    use_pvc=${FALSE}    use_gpu=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}   model_path=triton/model_repository/
    Set Project And Runtime    runtime=${KSERVE_RUNTIME_REST_NAME}     protocol=${PROTOCOL_GRPC}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${PYTHON_MODEL_NAME}
    ...    storage_size=100Mi    memory_request=100Mi
    ${requests}=    Create Dictionary    memory=1Gi
    Compile Inference Service YAML    isvc_name=${PYTHON_MODEL_NAME}
    ...    sa_name=models-bucket-sa
    ...    model_storage_uri=${storage_uri}
    ...    model_format=python  serving_runtime=${KSERVE_RUNTIME_REST_NAME}
    ...    version="1"
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    # File is not needed anymore after applying
    Remove File    ${INFERENCESERVICE_FILLED_FILEPATH}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${PYTHON_MODEL_NAME}
    ...    namespace=${test_namespace}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}
    ...    label_selector=serving.kserve.io/inferenceservice=${PYTHON_MODEL_NAME}
    ${valued}  ${host}=    Run And Return Rc And Output    oc get ksvc ${PYTHON_MODEL_NAME}-predictor -o jsonpath='{.status.url}'
    Log    ${host}
    Log    ${valued}
    ${host}=    Evaluate    re.search(r"${PATTERN}", r"${host}").group(1)    re
    Log    ${host}
    ${inference_output}=    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint=inference.GRPCInferenceService/ModelInfer
    ...    json_body=@      input_filepath=${INFERENCE_GRPC_INPUT_PYTHONFILE}
    ...    insecure=${True}    protobuf_file=${PROTOBUFF_FILE}      json_header=${NONE}
    Log    ${inference_output}
    ${inference_output}=    Evaluate    json.dumps(${inference_output})
    Log    ${inference_output}
    Log    ${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}
    ${result}    ${list}=    Inference Comparison    ${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}    ${inference_output}
    Log    ${result}
    Log    ${list}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    triton-process    kill=true


*** Keywords ***
Suite Setup
    [Documentation]    Suite setup keyword
    Set Library Search Order  SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Load Expected Responses
    Set Default Storage Class In GCP    default=ssd-csi

Suite Teardown
    [Documentation]    Suite teardown keyword
    Set Default Storage Class In GCP    default=standard-csi
    RHOSi Teardown

Setup Test Variables    # robocop: off=too-many-calls-in-keyword
    [Documentation]    Sets up variables for the Suite
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
        Set Test Variable    ${storage_uri}    s3://${S3.BUCKET_1.NAME}/${model_path}
    END
    IF   ${use_gpu}
        ${supported_gpu_type}=   Convert To Lowercase         ${GPU_TYPE}
        Set Runtime Image    ${supported_gpu_type}
        IF  "${supported_gpu_type}" == "nvidia"
            ${limits}=    Create Dictionary    nvidia.com/gpu=1
        ELSE IF    "${supported_gpu_type}" == "amd"
            ${limits}=    Create Dictionary    amd.com/gpu=1
        ELSE
            FAIL   msg=Provided GPU type is not yet supported. Only nvidia and amd gpu type are supported
        END
        Set Test Variable    ${limits}
    ELSE
        Set Test Variable    ${limits}    &{EMPTY}
    END
    IF    "${KSERVE_MODE}" == "RawDeployment"    # robocop: off=inconsistent-variable-name
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

Set Runtime Image
    [Documentation]    Sets up runtime variables for the Suite
    [Arguments]    ${gpu_type}
    IF  "${RUNTIME_IMAGE}" == "${EMPTY}"
         IF  "${gpu_type}" == "nvidia"
            Set Test Variable    ${runtime_image}    quay.io/modh/vllm@sha256:c86ff1e89c86bc9821b75d7f2bbc170b3c13e3ccf538bf543b1110f23e056316
         ELSE IF    "${gpu_type}" == "amd"
            Set Test Variable    ${runtime_image}    quay.io/modh/vllm@sha256:10f09eeca822ebe77e127aad7eca2571f859a5536a6023a1baffc6764bcadc6e
         ELSE
             FAIL   msg=Provided GPU type is not yet supported. Only nvidia and amd gpu type are supported
         END
    ELSE
        Log To Console    msg= Using the image provided from terminal
    END

Compile Inference Service YAML
    [Documentation]    Prepare the Inference Service YAML file in order to deploy a model
    [Arguments]    ${isvc_name}    ${model_storage_uri}    ${model_format}=caikit    ${serving_runtime}=caikit-tgis-runtime
    ...            ${kserve_mode}=${NONE}    ${sa_name}=${DEFAULT_BUCKET_SA_NAME}    ${canaryTrafficPercent}=${EMPTY}    ${min_replicas}=1
    ...            ${scaleTarget}=1    ${scaleMetric}=concurrency  ${auto_scale}=${NONE}
    ...            ${requests_dict}=&{EMPTY}    ${limits_dict}=&{EMPTY}    ${overlays}=${EMPTY}   ${version}=${EMPTY}
    IF   '${auto_scale}' == '${NONE}'
        ${scaleTarget}=    Set Variable    ${EMPTY}
        ${scaleMetric}=    Set Variable    ${EMPTY}
    END
    Set Test Variable    ${isvc_name}
    Set Test Variable    ${min_replicas}
    Set Test Variable    ${sa_name}
    Set Test Variable    ${model_storage_uri}
    Set Test Variable    ${scaleTarget}
    Set Test Variable    ${scaleMetric}
    Set Test Variable    ${canaryTrafficPercent}
    Set Test Variable    ${model_format}
    Set Test Variable    ${version}
    Set Test Variable    ${serving_runtime}
    IF    len($overlays) > 0
        FOR    ${index}    ${overlay}    IN ENUMERATE    @{overlays}
            Log    ${index}: ${overlay}
            ${rc}    ${out}=    Run And Return Rc And Output
            ...    oc kustomize ${LLM_RESOURCES_DIRPATH}/serving_runtimes/overlay/${overlay} > ${INFERENCESERVICE_FILLED_FILEPATH}
            Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
        END
        Create File From Template    ${INFERENCESERVICE_FILLED_FILEPATH}    ${INFERENCESERVICE_FILLED_FILEPATH}
    ELSE
        Create File From Template    ${INFERENCESERVICE_FILEPATH}    ${INFERENCESERVICE_FILLED_FILEPATH}
    END
    IF    ${requests_dict} != &{EMPTY}
        Log    Adding predictor model requests to ${INFERENCESERVICE_FILLED_FILEPATH}: ${requests_dict}    console=True    # robocop: disable
        FOR    ${index}    ${resource}    IN ENUMERATE    @{requests_dict.keys()}
            Log    ${index}- ${resource}:${requests_dict}[${resource}]
            ${rc}    ${out}=    Run And Return Rc And Output
            ...    yq -i '.spec.predictor.model.resources.requests."${resource}" = "${requests_dict}[${resource}]"' ${INFERENCESERVICE_FILLED_FILEPATH}    # robocop: disable
            Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
        END
    END
    IF    ${limits_dict} != &{EMPTY}
        Log    Adding predictor model limits to ${INFERENCESERVICE_FILLED_FILEPATH}: ${limits_dict}    console=True    # robocop: disable
        FOR    ${index}    ${resource}    IN ENUMERATE    @{limits_dict.keys()}
            Log    ${index}- ${resource}:${limits_dict}[${resource}]
            ${rc}    ${out}=    Run And Return Rc And Output
            ...    yq -i '.spec.predictor.model.resources.limits."${resource}" = "${limits_dict}[${resource}]"' ${INFERENCESERVICE_FILLED_FILEPATH}    # robocop: disable
            Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
        END
    END
    IF    $kserve_mode is not None
        ${rc}    ${out}=    Run And Return Rc And Output
        ...    yq -i '.metadata.annotations."serving.kserve.io/deploymentMode" = "${kserve_mode}"' ${INFERENCESERVICE_FILLED_FILEPATH}    # robocop: disable
        Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
    ELSE
        ${exists}=    Run Keyword And Return Status    Variable Should Exist  ${DSC_KSERVE_MODE}
        IF    ${exists}    # done in this way because when use non-admin users they cannot fetch DSC
            ${mode}=    Set Variable    ${DSC_KSERVE_MODE}
        ELSE
            ${mode}=    Get KServe Default Deployment Mode From DSC
        END
        Log    message=Using defaultDeploymentMode set in the DSC: ${mode}S
    END

