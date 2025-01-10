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
${EXPECTED_INFERENCE_REST_OUTPUT_PYTHON}=       {"model_name":"python","model_version":"1","outputs":[{"name":"OUTPUT0","datatype":"FP32","shape":[4],"data":[0.921442985534668,0.6223347187042236,0.8059385418891907,1.2578542232513428]},{"name":"OUTPUT1","datatype":"FP32","shape":[4],"data":[0.49091365933418274,-0.027157962322235107,-0.5641784071922302,0.6906309723854065]}]}
${INFERENCE_REST_INPUT_PYTHON}=       @tests/Resources/Files/triton/kserve-triton-python-rest-input.json
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

