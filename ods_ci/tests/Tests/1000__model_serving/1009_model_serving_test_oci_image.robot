*** Settings ***
Documentation     Collection of CLI tests to validate the model serving stack for OVMS.
Resource          ../../Resources/OCP.resource
Resource          ../../Resources/CLI/ModelServing/llm.resource
Library    OpenShiftLibrary
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Tags         KServe-OCI


*** Variables ***
${TEST_NS}=        tgis-ns
${RUNTIME_NAME}=  tgis-runtime
${USE_GPU}=    ${FALSE}
${MODEL_FORMAT}=   pytorch
${KSERVE_MODE}=    Serverless
${MODEL_NAME}=    flan-t5-small-hf

*** Test Cases ***
Verify User Can Serve And flan ovms Model using OCI image
    [Documentation]    Basic tests for preparing, deploying and querying model
    ...                using Kserve and OCI image
    [Tags]    OVMS
    ...       Smoke
    ...       OpenDataHub
    ...       RHOAIENG-12306
    ...       RHOAIENG-13465

    Setup Test Variables    model_name=${MODEL_NAME}  use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}
    Set Project And Runtime    runtime=${RUNTIME_NAME}      namespace=${test_namespace}
    ...    model_name=${model_name}
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    # File is not needed anymore after applying
    Remove File    ${INFERENCESERVICE_FILLED_FILEPATH}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}
    ...    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}  port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    validate_response=${FALSE}    port_forwarding=${use_port_forwarding}
    ${pod_names}=   Create List    ${pod_name}
    ${pod_restarts}=    Get Containers With Non Zero Restart Counts   ${pod_names}   namespace=${test_namespace}

    ${kserve_container_value}=    Get From Dictionary    ${pod_restarts}[${pod_name}]    kserve-container
    # Below check is for race condition ,
    Run Keyword If    ${kserve_container_value} > 1    Fail    The kserve-container restart should not be greater than 1


   [Teardown]    Run Keywords
   ...    Clean Up Test Project    test_ns=${test_namespace}
   ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}    kserve_mode=${KSERVE_MODE}
   ...    AND
   ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true


*** Keywords ***
Suite Setup
    [Documentation]
    Set Library Search Order  SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Load Expected Responses
    Set Default Storage Class In GCP    default=ssd-csi
    Run    git clone https://github.com/IBM/text-generation-inference/

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
    Set Test Variable    ${storage_uri}   oci://quay.io/mwaykole/test@sha256:c526a1a3697253eb09adc65da6efaf7f36150205c3a51ab8d13b92b6a3af9c1c
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
