*** Settings ***
Documentation     Collection of CLI tests to validate fetching models from different object storages
...               in the scope of model serving stack for Large Language Models (LLM).
...               These tests leverage on TGIS Standalone Serving Runtime
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/CLI/ModelServing/llm.resource
Resource          ../../../Resources/CLI/Minio.resource
Library           OpenShiftLibrary
Suite Setup       Suite Setup
Suite Teardown    RHOSi Teardown
Test Tags         KServe


*** Variables ***
${MODEL_S3_DIR}=    flan-t5-small-hf
${TEST_NS}=    tgis-storages
${TGIS_RUNTIME_NAME}=    tgis-runtime

  
*** Test Cases ***
Verify User Can Serve And Query A Model From Minio
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and TGIS runtime fetching models from a MinIO server
    [Tags]    Tier1    RHOAIENG-3490
    ${minio_namespace}=    Set Variable    minio-models
    ${minio_endpoint}=    Deploy MinIO    namespace=${minio_namespace}
    ${key}    ${pw}=    Get Minio Credentials    namespace=${minio_namespace}
    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=${TEST_NS}-minio
    ...    access_key_id=${key}    access_key=${pw}
    ...    endpoint=${minio_endpoint}
    ...    verify_ssl=${FALSE}    # temporary
    ${test_namespace}=    Set Variable     ${TEST_NS}-minio
    ${model_name}=    Set Variable    flan-t5-small-hf
    ${models_names}=    Create List    ${model_name}
    ${storage_uri}=    Set Variable    s3://models/${MODEL_S3_DIR}/
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    validate_response=${FALSE}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    AND
    ...    Clean Up Minio Namespace    namespace=${minio_namespace}


*** Keywords ***
Suite Setup
    [Documentation]
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Load Expected Responses
    Run    git clone https://github.com/IBM/text-generation-inference/
