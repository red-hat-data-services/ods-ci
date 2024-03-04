*** Settings ***
Documentation     Collection of CLI tests to validate the model serving stack for different Large Language Models (LLM).
...               These tests leverage on TGIS Standalone Serving Runtime
Resource          ../../../../Resources/OCP.resource
Resource          ../../../../Resources/CLI/ModelServing/llm.resource
Library            OpenShiftLibrary
Suite Setup       Suite Setup
Suite Teardown    RHOSi Teardown
Test Tags         KServe


*** Variables ***
${TEST_NS}=    tgis-models
${TGIS_RUNTIME_NAME}=    tgis-runtime
${USE_PVC}=    ${TRUE}
${DOWNLOAD_IN_PVC}=    ${TRUE}
${USE_GPU}=    ${FALSE}
${KSERVE_MODE}=    RawDeployment

 
*** Test Cases ***
Verify User Can Serve And Query A bigscience/mt0-xxl Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Tier1    RHOAIENG-3477
    Setup Test Variables    model_name=mt0-xxl-hf    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}
    Set Project And Runtime    runtime=${TGIS_RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}  
    ...    storage_size=70Gi  
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=pytorch    serving_runtime=${TGIS_RUNTIME_NAME}
    ...    limits_dict=${limits}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    timeout=900s
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    model_name=${model_name}
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1    protocol=grpc
    ...    namespace=${test_namespace}   query_idx=2    validate_response=${TRUE}    # temp
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    protocol=grpc
    ...    namespace=${test_namespace}    query_idx=2    validate_response=${FALSE}
    ...    port_forwarding=${use_port_forwarding}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true


*** Keywords ***
Suite Setup
    [Documentation]
    Skip If Component Is Not Enabled    kserve
    #RHOSi Setup
    Load Expected Responses
    Run    git clone https://github.com/IBM/text-generation-inference/

Setup Test Variables
    [Arguments]    ${model_name}    ${kserve_mode}=Serverless    ${use_pvc}=${FALSE}    ${use_gpu}=${FALSE}
    Set Test Variable    ${model_name}
    ${models_names}=    Create List    ${model_name}
    Set Test Variable    ${models_names}
    Set Test Variable    ${test_namespace}     ${TEST_NS}-${model_name}
    IF    ${use_pvc}
        Set Test Variable    ${storage_uri}    pvc://${model_name}-claim/${model_name}
    ELSE
        Set Test Variable    ${storage_uri}    s3://${S3.BUCKET_3.NAME}/${model_name}
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
    
    
Start Port-forwarding
    [Arguments]    ${namespace}    ${model_name}
    ${process}=    Start Process    oc -n ${namespace} port-forward svc/${model_name}-predictor 8033:80
    ...    alias=llm-query-process    stderr=STDOUT    shell=yes
