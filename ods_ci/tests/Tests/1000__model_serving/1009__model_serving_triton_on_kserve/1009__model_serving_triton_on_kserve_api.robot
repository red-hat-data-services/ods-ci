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
${ONNX_MODEL_NAME}=     densenetonnx
${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}=       {"modelName":"python","modelVersion":"1","id":"1","outputs":[{"name":"OUTPUT0","datatype":"FP32","shape":["4"]},{"name":"OUTPUT1","datatype":"FP32","shape":["4"]}],"rawOutputContents":["AgAAAAAAAAAAAAAAAAAAAA==","AAQAAAAAAAAAAAAAAAAAAA=="]}
${INFERENCE_GRPC_INPUT_PYTHONFILE}=       tests/Resources/Files/triton/kserve-triton-python-grpc-input.json
${KSERVE_MODE}=    Serverless   # Serverless
${PROTOCOL_GRPC}=     grpc
${EXPECTED_INFERENCE_REST_OUTPUT_PYTHON}=       {"model_name":"python","model_version":"1","outputs":[{"name":"OUTPUT0","datatype":"FP32","shape":[4],"data":[0.921442985534668,0.6223347187042236,0.8059385418891907,1.2578542232513428]},{"name":"OUTPUT1","datatype":"FP32","shape":[4],"data":[0.49091365933418274,-0.027157962322235107,-0.5641784071922302,0.6906309723854065]}]}
${INFERENCE_REST_INPUT_PYTHON}=       @tests/Resources/Files/triton/kserve-triton-python-rest-input.json
${EXPECTED_INFERENCE_REST_OUTPUT_FILE_ONNX}=       tests/Resources/Files/triton/kserve-triton-onnx-rest-output.json
${INFERENCE_REST_INPUT_ONNX}=       @tests/Resources/Files/triton/kserve-triton-onnx-rest-input.json
${INFERENCE_GRPC_INPUT_ONNXFILE}=       tests/Resources/Files/triton/kserve-triton-onnx-grpc-input.json
${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE_ONNX}=    tests/Resources/Files/triton/kserve-triton-onnx-grpc-output.json
${KSERVE_MODE}=    Serverless   # Serverless
${PROTOCOL}=     http
${TEST_NS}=        tritonmodel
${DOWNLOAD_IN_PVC}=    ${FALSE}
${MODELS_BUCKET}=    ${S3.BUCKET_1}
${LLM_RESOURCES_DIRPATH}=    tests/Resources/Files/llm
${INFERENCESERVICE_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/serving_runtimes/base/isvc.yaml
${INFERENCESERVICE_FILEPATH_NEW}=    ${LLM_RESOURCES_DIRPATH}/serving_runtimes/isvc
${INFERENCESERVICE_FILLED_FILEPATH}=    ${INFERENCESERVICE_FILEPATH_NEW}/isvc_filled.yaml
${KSERVE_RUNTIME_REST_NAME}=  triton-kserve-runtime
${PYTORCH_MODEL_NAME}=    resnet50
${INFERENCE_REST_INPUT_PYTORCH}=    @tests/Resources/Files/triton/kserve-triton-resnet-rest-input.json
${EXPECTED_INFERENCE_REST_OUTPUT_FILE_PYTORCH}=        tests/Resources/Files/triton/kserve-triton-resnet-rest-output.json
${INFERENCE_REST_INPUT_KERAS}=    @tests/Resources/Files/triton/kserve-triton-keras-rest-input.json
${EXPECTED_INFERENCE_REST_OUTPUT_FILE_KERAS}=        tests/Resources/Files/triton/kserve-triton-keras-rest-output.json
${PATTERN}=     https:\/\/([^\/:]+)
${PROTOBUFF_FILE}=      tests/Resources/Files/triton/grpc_predict_v2.proto
${DALI_MODEL_NAME}=   daligpu
${INFERENCE_GRPC_INPUT_DALIFILE}=    tests/Resources/Files/triton/kserve-triton-dali-grpc-input.json
${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE_DALI}=        tests/Resources/Files/triton/kserve-triton-dali-grpc-output.json

*** Test Cases ***
Test Python Model Rest Inference Via API (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of python model in Kserve using Triton
    [Tags]    Tier2    RHOAIENG-16912
    Setup Test Variables    model_name=${PYTHON_MODEL_NAME}    use_pvc=${FALSE}    use_gpu=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}   model_path=triton/model_repository/
    Set Project And Runtime    runtime=${KSERVE_RUNTIME_REST_NAME}     protocol=${PROTOCOL}     namespace=${test_namespace}
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
    ${service_port}=    Extract Service Port    service_name=${PYTHON_MODEL_NAME}-predictor    protocol=TCP
    ...    namespace=${test_namespace}
    IF   "${KSERVE_MODE}"=="RawDeployment"
        Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}  local_port=${service_port}
        ...    remote_port=${service_port}    process_alias=triton-process
    END
    Verify Model Inference With Retries   model_name=${PYTHON_MODEL_NAME}    inference_input=${INFERENCE_REST_INPUT_PYTHON}
    ...    expected_inference_output=${EXPECTED_INFERENCE_REST_OUTPUT_PYTHON}   project_title=${test_namespace}
    ...    deployment_mode=Cli  kserve_mode=${KSERVE_MODE}    service_port=${service_port}
    ...    end_point=/v2/models/${model_name}/infer   retries=3
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    triton-process    kill=true

Test Pytorch Model Rest Inference Via API (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of pytorch model in Kserve using Triton
    [Tags]    Tier2    RHOAIENG-16909
    Setup Test Variables    model_name=${PYTORCH_MODEL_NAME}    use_pvc=${FALSE}    use_gpu=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}   model_path=triton/model_repository/
    Set Project And Runtime    runtime=${KSERVE_RUNTIME_REST_NAME}     protocol=${PROTOCOL}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${PYTORCH_MODEL_NAME}
    ...    storage_size=100Mi    memory_request=100Mi
    ${requests}=    Create Dictionary    memory=1Gi
    Compile Inference Service YAML    isvc_name=${PYTORCH_MODEL_NAME}
    ...    sa_name=models-bucket-sa
    ...    model_storage_uri=${storage_uri}
    ...    model_format=python  serving_runtime=${KSERVE_RUNTIME_REST_NAME}
    ...    version="1"
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    # File is not needed anymore after applying
    Remove File    ${INFERENCESERVICE_FILLED_FILEPATH}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${PYTORCH_MODEL_NAME}
    ...    namespace=${test_namespace}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}
    ...    label_selector=serving.kserve.io/inferenceservice=${PYTORCH_MODEL_NAME}
    ${service_port}=    Extract Service Port    service_name=${PYTORCH_MODEL_NAME}-predictor    protocol=TCP
    ...    namespace=${test_namespace}
    IF   "${KSERVE_MODE}"=="RawDeployment"
        Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}  local_port=${service_port}
        ...    remote_port=${service_port}    process_alias=triton-process
    END
    ${EXPECTED_INFERENCE_REST_OUTPUT_PYTORCH}=     Load Json File
    ...    file_path=${EXPECTED_INFERENCE_REST_OUTPUT_FILE_PYTORCH}    as_string=${TRUE}
    Verify Model Inference With Retries   model_name=${PYTORCH_MODEL_NAME}    inference_input=${INFERENCE_REST_INPUT_PYTORCH}
    ...    expected_inference_output=${EXPECTED_INFERENCE_REST_OUTPUT_PYTORCH}   project_title=${test_namespace}
    ...    deployment_mode=Cli  kserve_mode=${KSERVE_MODE}    service_port=${service_port}
    ...    end_point=/v2/models/${model_name}/infer   retries=3
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    triton-process    kill=true

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
    Log    ${valued}
    ${host}=    Evaluate    re.search(r"${PATTERN}", r"${host}").group(1)    re
    Log    ${host}
    ${inference_output}=    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint=inference.GRPCInferenceService/ModelInfer
    ...    json_body=@      input_filepath=${INFERENCE_GRPC_INPUT_PYTHONFILE}
    ...    insecure=${True}    protobuf_file=${PROTOBUFF_FILE}      json_header=${NONE}
    ${inference_output}=    Evaluate    json.dumps(${inference_output})
    Log    ${inference_output}
    ${result}    ${list}=    Inference Comparison    ${EXPECTED_INFERENCE_GRPC_OUTPUT_PYTHON}    ${inference_output}
    Log    ${result}
    Log    ${list}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    triton-process    kill=true

Test Onnx Model Rest Inference Via API (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of onnx model in Kserve using Triton
    [Tags]    Tier2    RHOAIENG-16908
    Setup Test Variables    model_name=${ONNX_MODEL_NAME}    use_pvc=${FALSE}    use_gpu=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}   model_path=triton/model_repository/
    Log    ${ONNX_MODEL_NAME}
    Set Project And Runtime    runtime=${KSERVE_RUNTIME_REST_NAME}     protocol=${PROTOCOL}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${ONNX_MODEL_NAME}
    ...    storage_size=100Mi    memory_request=100Mi
    ${requests}=    Create Dictionary    memory=1Gi
    Compile Inference Service YAML    isvc_name=${ONNX_MODEL_NAME}
    ...    sa_name=models-bucket-sa
    ...    model_storage_uri=${storage_uri}
    ...    model_format=onnx  serving_runtime=${KSERVE_RUNTIME_REST_NAME}
    ...    version="1"
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    # File is not needed anymore after applying
    Remove File    ${INFERENCESERVICE_FILLED_FILEPATH}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${ONNX_MODEL_NAME}
    ...    namespace=${test_namespace}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}
    ...    label_selector=serving.kserve.io/inferenceservice=${ONNX_MODEL_NAME}
    ${service_port}=    Extract Service Port    service_name=${ONNX_MODEL_NAME}-predictor    protocol=TCP
    ...    namespace=${test_namespace}
    IF   "${KSERVE_MODE}"=="RawDeployment"
        Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}  local_port=${service_port}
        ...    remote_port=${service_port}    process_alias=triton-process
    END
    ${EXPECTED_INFERENCE_REST_OUTPUT_ONNX}=     Load Json File
    ...    file_path=${EXPECTED_INFERENCE_REST_OUTPUT_FILE_ONNX}    as_string=${TRUE}
    Verify Model Inference With Retries   model_name=${ONNX_MODEL_NAME}    inference_input=${INFERENCE_REST_INPUT_ONNX}
    ...    expected_inference_output=${EXPECTED_INFERENCE_REST_OUTPUT_ONNX}   project_title=${test_namespace}
    ...    deployment_mode=Cli  kserve_mode=${KSERVE_MODE}    service_port=${service_port}
    ...    end_point=/v2/models/${model_name}/infer   retries=3
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    triton-process    kill=true

Test Onnx Model Grpc Inference Via API (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of onnx model in Kserve using Triton
    [Tags]    Tier2    RHOAIENG-16908
    Setup Test Variables    model_name=${ONNX_MODEL_NAME}    use_pvc=${FALSE}    use_gpu=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}   model_path=triton/model_repository/
    Set Project And Runtime    runtime=${KSERVE_RUNTIME_REST_NAME}     protocol=${PROTOCOL_GRPC}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${ONNX_MODEL_NAME}
    ...    storage_size=100Mi    memory_request=100Mi
    ${requests}=    Create Dictionary    memory=1Gi
    Compile Inference Service YAML    isvc_name=${ONNX_MODEL_NAME}
    ...    sa_name=models-bucket-sa
    ...    model_storage_uri=${storage_uri}
    ...    model_format=onnx  serving_runtime=${KSERVE_RUNTIME_REST_NAME}
    ...    version="1"
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    # File is not needed anymore after applying
    Remove File    ${INFERENCESERVICE_FILLED_FILEPATH}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${ONNX_MODEL_NAME}
    ...    namespace=${test_namespace}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}
    ...    label_selector=serving.kserve.io/inferenceservice=${ONNX_MODEL_NAME}
    ${valued}  ${host}=    Run And Return Rc And Output    oc get ksvc ${ONNX_MODEL_NAME}-predictor -o jsonpath='{.status.url}'
    Log    ${valued}
    ${host}=    Evaluate    re.search(r"${PATTERN}", r"${host}").group(1)    re
    Log    ${host}
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_ONNX}=     Load Json File
    ...    file_path=${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE_ONNX}    as_string=${TRUE}
    ${inference_output}=    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint=inference.GRPCInferenceService/ModelInfer
    ...    json_body=@      input_filepath=${INFERENCE_GRPC_INPUT_ONNXFILE}
    ...    insecure=${True}    protobuf_file=${PROTOBUFF_FILE}      json_header=${NONE}
    ${inference_output}=    Evaluate    json.dumps(${inference_output})
    Log    ${inference_output}
    ${result}    ${list}=    Inference Comparison    ${EXPECTED_INFERENCE_GRPC_OUTPUT_ONNX}    ${inference_output}
    Log    ${result}
    Log    ${list}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    triton-process    kill=true

Test Keras Model Rest Inference Via API (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of keras model in Kserve using Triton
    [Tags]    Tier2    RHOAIENG-16911
    Setup Test Variables    model_name=${PYTORCH_MODEL_NAME}    use_pvc=${FALSE}    use_gpu=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}   model_path=tritonkeras/model_repository/
    Set Project And Runtime    runtime=${KSERVE_RUNTIME_REST_NAME}     protocol=${PROTOCOL}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${PYTORCH_MODEL_NAME}
    ...    storage_size=100Mi    memory_request=100Mi
    ${requests}=    Create Dictionary    memory=1Gi
    Compile Inference Service YAML    isvc_name=${PYTORCH_MODEL_NAME}
    ...    sa_name=models-bucket-sa
    ...    model_storage_uri=${storage_uri}
    ...    model_format=python  serving_runtime=${KSERVE_RUNTIME_REST_NAME}
    ...    version="1"
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    # File is not needed anymore after applying
    Remove File    ${INFERENCESERVICE_FILLED_FILEPATH}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${PYTORCH_MODEL_NAME}
    ...    namespace=${test_namespace}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}
    ...    label_selector=serving.kserve.io/inferenceservice=${PYTORCH_MODEL_NAME}
    ${service_port}=    Extract Service Port    service_name=${PYTORCH_MODEL_NAME}-predictor    protocol=TCP
    ...    namespace=${test_namespace}
    IF   "${KSERVE_MODE}"=="RawDeployment"
        Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}  local_port=${service_port}
        ...    remote_port=${service_port}    process_alias=triton-process
    END
    ${EXPECTED_INFERENCE_REST_OUTPUT_KERAS}=     Load Json File
    ...    file_path=${EXPECTED_INFERENCE_REST_OUTPUT_FILE_KERAS}    as_string=${TRUE}
    Verify Model Inference With Retries   model_name=${PYTORCH_MODEL_NAME}    inference_input=${INFERENCE_REST_INPUT_KERAS}
    ...    expected_inference_output=${EXPECTED_INFERENCE_REST_OUTPUT_KERAS}   project_title=${test_namespace}
    ...    deployment_mode=Cli  kserve_mode=${KSERVE_MODE}    service_port=${service_port}
    ...    end_point=/v2/models/${model_name}/infer   retries=3
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    triton-process    kill=true


Test Dali Model Grpc Inference Via API (Triton on Kserve)    # robocop: off=too-long-test-case
    [Documentation]    Test the deployment of dali model in Kserve using Triton
    [Tags]    Tier2    RHOAIENG-16914       Resources-GPU    NVIDIA-GPUs     RunThisTest
    Setup Test Variables    model_name=${DALI_MODEL_NAME}    use_pvc=${FALSE}    use_gpu=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}   model_path=triton_gpu/model_repository/
    Set Project And Runtime    runtime=${KSERVE_RUNTIME_REST_NAME}     protocol=${PROTOCOL_GRPC}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${DALI_MODEL_NAME}
    ...    storage_size=100Mi    memory_request=100Mi
    ${requests}=    Create Dictionary    memory=1Gi
    Compile Inference Service YAML    isvc_name=${DALI_MODEL_NAME}
    ...    sa_name=models-bucket-sa
    ...    model_storage_uri=${storage_uri}
    ...    model_format=onnx  serving_runtime=${KSERVE_RUNTIME_REST_NAME}
    ...    version="1"
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    # File is not needed anymore after applying
    Remove File    ${INFERENCESERVICE_FILLED_FILEPATH}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${DALI_MODEL_NAME}
    ...    namespace=${test_namespace}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}
    ...    label_selector=serving.kserve.io/inferenceservice=${DALI_MODEL_NAME}
    ${valued}  ${host}=    Run And Return Rc And Output    oc get ksvc ${DALI_MODEL_NAME}-predictor -o jsonpath='{.status.url}'
    Log    ${valued}
    ${host}=    Evaluate    re.search(r"${PATTERN}", r"${host}").group(1)    re
    Log    ${host}
    ${EXPECTED_INFERENCE_GRPC_OUTPUT_DALI}=     Load Json File
    ...    file_path=${EXPECTED_INFERENCE_GRPC_OUTPUT_FILE_DALI}    as_string=${TRUE}
    ${inference_output}=    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint=inference.GRPCInferenceService/ModelInfer
    ...    json_body=@      input_filepath=${INFERENCE_GRPC_INPUT_DALIFILE}
    ...    insecure=${True}    protobuf_file=${PROTOBUFF_FILE}      json_header=${NONE}
    ${inference_output}=    Evaluate    json.dumps(${inference_output})
    Log    ${inference_output}
    ${result}    ${list}=    Inference Comparison    ${EXPECTED_INFERENCE_GRPC_OUTPUT_DALI}    ${inference_output}
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
    #Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Load Expected Responses
    Set Default Storage Class In GCP    default=ssd-csi

Suite Teardown
    [Documentation]    Suite teardown keyword
    Set Default Storage Class In GCP    default=standard-csi
    RHOSi Teardown

