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
    [Tags]    Tier2    RHOAIENG-16912       RunThisTest

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






