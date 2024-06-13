*** Settings ***
Documentation     Collection of CLI tests to validate the model serving stack for different Large Language Models (LLM).
...               These tests leverage on TGIS Standalone Serving Runtime
Resource          ../../../../Resources/OCP.resource
Resource          ../../../../Resources/CLI/ModelServing/llm.resource
Library            OpenShiftLibrary
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Tags         KServe-LLM


*** Variables ***
${TEST_NS}=    tgismodel
${RUNTIME_NAME}=  tgis-runtime   #vllm-runtime
${USE_PVC}=    ${TRUE}
${DOWNLOAD_IN_PVC}=    ${TRUE}
${USE_GPU}=    ${FALSE}
${KSERVE_MODE}=    RawDeployment   #Serverless
${MODEL_FORMAT}=   pytorch       #vLLM
${PROTOCOL}=     grpc         #http
${OVERLAY}=      ${EMPTY}               #vllm


*** Test Cases ***
Verify User Can Serve And Query A bigscience/mt0-xxl Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and TGIS runtime
    [Tags]    RHOAIENG-3477
    Setup Test Variables    model_name=mt0-xxl-hf    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}
    ...    storage_size=70Gi
    ${requests}=    Create Dictionary    memory=40Gi
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=900s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}   query_idx=2    validate_response=${TRUE}    # temp
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}    query_idx=2    validate_response=${FALSE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=tokenize    n_times=1    query_idx=2
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=model-info    n_times=1
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A google/flan-t5-xl Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and TGIS runtime
    [Tags]    RHOAIENG-3480
    Setup Test Variables    model_name=flan-t5-xl-hf    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}
    ${test_namespace}=   Set Variable    flant5xl-google
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}
    ...    storage_size=70Gi
    ${requests}=    Create Dictionary    memory=40Gi
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=900s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}   query_idx=3   validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}    query_idx=3    validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=tokenize    n_times=1    query_idx=3
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=model-info    n_times=1
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A google/flan-t5-xxl Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and TGIS runtime
    [Tags]    RHOAIENG-3481
    Setup Test Variables    model_name=flan-t5-xxl-hf    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}
    ${test_namespace}=   Set Variable    flant5xxl-google
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}
    ...    storage_size=70Gi
    ${requests}=    Create Dictionary    memory=40Gi
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=900s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}   query_idx=3   validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}    query_idx=3    validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=tokenize    n_times=1    query_idx=3
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=model-info    n_times=1
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A elyza/elyza-japanese-llama-2-7b-instruct Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and TGIS standalone or vllm runtime
    [Tags]    RHOAIENG-3479     VLLM
    Setup Test Variables    model_name=elyza-japanese    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}    model_path=ELYZA-japanese-Llama-2-7b-instruct-hf
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}   protocol=${PROTOCOL}
    ...    storage_size=70Gi    model_path=${model_path}
    ${requests}=    Create Dictionary    memory=40Gi
    IF    "${OVERLAY}" != "${EMPTY}"
          ${overlays}=   Create List    ${OVERLAY}
    ELSE
          ${overlays}=   Create List
    END
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    ...    overlays=${overlays}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=900s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    IF     "${RUNTIME_NAME}" == "tgis-runtime" or "${KSERVE_MODE}" == "RawDeployment"
            Set Test Variable    ${RUNTIME_NAME}    tgis-runtime
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
            ...    namespace=${test_namespace}   query_idx=4    validate_response=${FALSE}    # temp
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
            ...    namespace=${test_namespace}    query_idx=4    validate_response=${FALSE}
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=tokenize    n_times=1    query_idx=4
            ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=model-info    n_times=1
            ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
            ...    port_forwarding=${use_port_forwarding}
    ELSE IF    "${RUNTIME_NAME}" == "vllm-runtime" and "${KSERVE_MODE}" == "Serverless"
            Query Model Multiple Times    model_name=${model_name}      runtime=${RUNTIME_NAME}    protocol=http
            ...    inference_type=chat-completions    n_times=1    query_idx=9
            ...    namespace=${test_namespace}    string_check_only=${TRUE}
            Query Model Multiple Times    model_name=${model_name}      runtime=${RUNTIME_NAME}    protocol=http
            ...    inference_type=completions    n_times=1    query_idx=10
            ...    namespace=${test_namespace}    string_check_only=${TRUE}
    END
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A ibm/mpt-7b-instruct2 Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                (mpt-7b-instruct2) using Kserve and TGIS runtime
    [Tags]    RHOAIENG-4201
    Setup Test Variables    model_name=mpt-7b-instruct2    use_pvc=${USE_PVC}    use_gpu=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ${test_namespace}=   Set Variable    mpt-7b-instruct2-ibm
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}
    ...    storage_size=20Gi
    ${requests}=    Create Dictionary    memory=40Gi
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=900s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}   query_idx=0   validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}    query_idx=0    validate_response=${FALSE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=tokenize    n_times=1    query_idx=0
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=model-info    n_times=1
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A google/flan-ul-2 Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and TGIS runtime
    [Tags]    RHOAIENG-3482
    Setup Test Variables    model_name=flan-ul2-hf    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}   model_path=flan-ul2-hf
    ${test_namespace}=   Set Variable    flan-ul2-google
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}
    ...    storage_size=70Gi   model_path=${model_path}
    ${requests}=    Create Dictionary    memory=40Gi
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=900s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}   query_idx=3   validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}    query_idx=3    validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=tokenize    n_times=1    query_idx=3
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=model-info    n_times=1
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A codellama/codellama-34b-instruct-hf Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and TGIS runtime
    [Tags]    RHOAIENG-4200
    Setup Test Variables    model_name=codellama-34b-instruct-hf    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}   model_path=codellama-34b-instruct-hf
    ${test_namespace}=   Set Variable    codellama-34b
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}
    ...    storage_size=80Gi   model_path=${model_path}
    ${requests}=    Create Dictionary    memory=130Gi
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=3000s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}   query_idx=5   validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}    query_idx=5    validate_response=${FALSE}
    ...    port_forwarding=${use_port_forwarding}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A meta-llama/llama-2-13b-chat Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and TGIS standalone or vllm runtime
    [Tags]    RHOAIENG-3483    VLLM
    Setup Test Variables    model_name=llama-2-13b-chat    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}    model_path=Llama-2-13b-chat-hf
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}    protocol=${PROTOCOL}
    ...    storage_size=70Gi    model_path=${model_path}
    ${requests}=    Create Dictionary    memory=40Gi
    IF    "${OVERLAY}" != "${EMPTY}"
          ${overlays}=   Create List    ${OVERLAY}
    ELSE
          ${overlays}=   Create List
    END
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    ...    overlays=${overlays}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=900s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    IF     "${RUNTIME_NAME}" == "tgis-runtime" or "${KSERVE_MODE}" == "RawDeployment"
            Set Test Variable    ${RUNTIME_NAME}    tgis-runtime
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
            ...    namespace=${test_namespace}   query_idx=0   validate_response=${TRUE}    # temp
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
            ...    namespace=${test_namespace}    query_idx=0    validate_response=${FALSE}
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=model-info    n_times=0
            ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=tokenize    n_times=0    query_idx=0
            ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
            ...    port_forwarding=${use_port_forwarding}
    ELSE IF    "${RUNTIME_NAME}" == "vllm-runtime" and "${KSERVE_MODE}" == "Serverless"
            Query Model Multiple Times    model_name=${model_name}      runtime=${RUNTIME_NAME}    protocol=http
            ...    inference_type=chat-completions    n_times=1    query_idx=12
            ...    namespace=${test_namespace}    string_check_only=${TRUE}
            Query Model Multiple Times    model_name=${model_name}      runtime=${RUNTIME_NAME}    protocol=http
            ...    inference_type=completions    n_times=1    query_idx=11
            ...    namespace=${test_namespace}    string_check_only=${TRUE}
    END
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A google/flan-t5-xl Prompt Tuned Model
    [Documentation]    Tests for preparing, deploying and querying a prompt-tuned LLM model
    ...                using Kserve and TGIS runtime. It uses a google/flan-t5-xl prompt-tuned
    ...                to recognize customer complaints.
    [Tags]    RHOAIENG-3494
    Setup Test Variables    model_name=flan-t5-xl-hf-ptuned    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}    model_path=flan-t5-xl-hf
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}
    ...    storage_size=20Gi    model_path=${model_path}
    Download Prompts Weights In PVC    prompts_path=flan-t5-xl-tuned    model_name=${model_name}    namespace=${test_namespace}
    ...    bucket_name=${MODELS_BUCKET.NAME}    use_https=${USE_BUCKET_HTTPS}
    ...    storage_size=10Gi    model_path=${model_path}
    ${overlays}=    Create List    prompt-tuned
    ${requests}=    Create Dictionary    memory=40Gi
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    ...    overlays=${overlays}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=300s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    ${prompt_tuned_params}=    Create Dictionary    prefix_id=flan-t5-xl-tuned
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}   query_idx=6   validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}    body_params=${prompt_tuned_params}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}   query_idx=7   validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}    body_params=${prompt_tuned_params}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}    query_idx=6    validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}    body_params=${prompt_tuned_params}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
    ...    namespace=${test_namespace}    query_idx=7    validate_response=${TRUE}
    ...    port_forwarding=${use_port_forwarding}    body_params=${prompt_tuned_params}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=tokenize    n_times=1    query_idx=6
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}    body_params=&{EMPTY}
    Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
    ...    inference_type=model-info    n_times=1
    ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
    ...    port_forwarding=${use_port_forwarding}    body_params=&{EMPTY}
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A instructlab/merlinite-7b-lab Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve using TGIS standalone or vllm runtime
    [Tags]    RHOAIENG-7690    VLLM
    Setup Test Variables    model_name=merlinite-7b-lab    use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}    model_path=merlinite-7b-lab
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}    protocol=${PROTOCOL}
    ...    storage_size=70Gi    model_path=${model_path}
    ${requests}=    Create Dictionary    memory=40Gi
    IF    "${OVERLAY}" != "${EMPTY}"
          ${overlays}=   Create List    ${OVERLAY}
    ELSE
          ${overlays}=   Create List
    END
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    ...    overlays=${overlays}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=900s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    IF     "${RUNTIME_NAME}" == "tgis-runtime" or "${KSERVE_MODE}" == "RawDeployment"
            Set Test Variable    ${RUNTIME_NAME}    tgis-runtime
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
            ...    namespace=${test_namespace}   query_idx=0   validate_response=${FALSE}    # temp
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
            ...    namespace=${test_namespace}    query_idx=0    validate_response=${FALSE}
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=model-info    n_times=0
            ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=tokenize    n_times=0    query_idx=0
            ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
            ...    port_forwarding=${use_port_forwarding}
    ELSE IF    "${RUNTIME_NAME}" == "vllm-runtime" and "${KSERVE_MODE}" == "Serverless"
            Query Model Multiple Times    model_name=${model_name}      runtime=${RUNTIME_NAME}    protocol=http
            ...    inference_type=chat-completions    n_times=1    query_idx=12
            ...    namespace=${test_namespace}    string_check_only=${TRUE}
            Query Model Multiple Times    model_name=${model_name}      runtime=${RUNTIME_NAME}    protocol=http
            ...    inference_type=completions    n_times=1    query_idx=11
            ...    namespace=${test_namespace}    string_check_only=${TRUE}
    END
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A ibm-granite/granite-8b-code-base Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve using TGIS standalone or vllm runtime
    [Tags]    RHOAIENG-7689    VLLM
    Setup Test Variables    model_name=granite-8b-code-base   use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}    model_path=granite-8b-code-base
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}    protocol=${PROTOCOL}
    ...    storage_size=40Gi    model_path=${model_path}
    ${requests}=    Create Dictionary    memory=40Gi
    IF    "${OVERLAY}" != "${EMPTY}"
          ${overlays}=   Create List    ${OVERLAY}
    ELSE
          ${overlays}=   Create List
    END
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    ...    overlays=${overlays}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=900s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    IF     "${RUNTIME_NAME}" == "tgis-runtime" or "${KSERVE_MODE}" == "RawDeployment"
            Set Test Variable    ${RUNTIME_NAME}    tgis-runtime
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=all-tokens    n_times=1    protocol=${PROTOCOL}
            ...    namespace=${test_namespace}   query_idx=0   validate_response=${FALSE}   # temp
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=streaming    n_times=1    protocol=${PROTOCOL}
            ...    namespace=${test_namespace}    query_idx=0    validate_response=${FALSE}
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=model-info    n_times=0
            ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
            ...    port_forwarding=${use_port_forwarding}
            Query Model Multiple Times    model_name=${model_name}    runtime=${RUNTIME_NAME}
            ...    inference_type=tokenize    n_times=0    query_idx=0
            ...    namespace=${test_namespace}    validate_response=${TRUE}    string_check_only=${TRUE}
            ...    port_forwarding=${use_port_forwarding}
    ELSE IF    "${RUNTIME_NAME}" == "vllm-runtime" and "${KSERVE_MODE}" == "Serverless"
            Query Model Multiple Times    model_name=${model_name}      runtime=${RUNTIME_NAME}    protocol=http
            ...    inference_type=chat-completions    n_times=1    query_idx=12
            ...    namespace=${test_namespace}    string_check_only=${TRUE}
            Query Model Multiple Times    model_name=${model_name}      runtime=${RUNTIME_NAME}    protocol=http
            ...    inference_type=completions    n_times=1    query_idx=11
            ...    namespace=${test_namespace}    string_check_only=${TRUE}
    END
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

Verify User Can Serve And Query A intfloat/e5-mistral-7b-instruct Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve using TGIS standalone or vllm runtime
    [Tags]    RHOAIENG-7427    VLLM
    Setup Test Variables    model_name=e5-mistral-7b   use_pvc=${USE_PVC}    use_gpu=${USE_GPU}
    ...    kserve_mode=${KSERVE_MODE}    model_path=e5-mistral-7b-instruct
    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${test_namespace}
    ...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=${model_name}    protocol=${PROTOCOL}
    ...    storage_size=40Gi    model_path=${model_path}
    ${requests}=    Create Dictionary    memory=20Gi
    IF    "${OVERLAY}" != "${EMPTY}"
          ${overlays}=   Create List    ${OVERLAY}
    ELSE
          ${overlays}=   Create List
    END
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=${storage_uri}
    ...    model_format=${MODEL_FORMAT}    serving_runtime=${RUNTIME_NAME}
    ...    limits_dict=${limits}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    ...    overlays=${overlays}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}    timeout=900s
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${model_name}
    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"
    ...    Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}
    IF     "${RUNTIME_NAME}" == "tgis-runtime" or "${KSERVE_MODE}" == "RawDeployment"
            Skip   msg=Embedding endpoint is not supported for tgis as well as model architectures with "XXModel"
    ELSE IF    "${RUNTIME_NAME}" == "vllm-runtime" and "${KSERVE_MODE}" == "Serverless"
            Query Model Multiple Times    model_name=${model_name}      runtime=${RUNTIME_NAME}    protocol=http
            ...    inference_type=embeddings    n_times=1    query_idx=11
            ...    namespace=${test_namespace}    validate_response=${FALSE}
    END
    [Teardown]    Run Keywords
    ...    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    ...    AND
    ...    Run Keyword If    "${KSERVE_MODE}"=="RawDeployment"    Terminate Process    llm-query-process    kill=true

*** Keywords ***
Suite Setup
    [Documentation]
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Load Expected Responses
    Run    git clone https://github.com/IBM/text-generation-inference/
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
