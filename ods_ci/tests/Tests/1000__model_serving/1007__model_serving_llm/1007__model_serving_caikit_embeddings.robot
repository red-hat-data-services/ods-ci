*** Settings ***
Documentation     Collection of CLI tests to validate the model serving stack for Embeddings Models.
...               These tests leverage on Caikit Standalone Serving Runtime
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/CLI/ModelServing/llm.resource
Resource          ../../../Resources/CLI/Minio.resource
Library            OpenShiftLibrary
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Tags         embeddings


*** Variables ***
${BGE_MODEL_NAME}=                    bge-large-en-caikit
${MINILM_MODEL_NAME}=                 all-minilm-caikit
${TEST_NS}=                           caikit-embeddings-test
${TEST_NS1}=                          caikit-embeddings
${RUNTIME_NAME}=                      caikit-standalone-runtime
${BGE_STORAGE_URI}=                   s3://${S3.BUCKET_3.NAME}/embeddingsmodel
${PROTOCOL}=                          http         # grpc
${KSERVE_MODE}=                       RawDeployment   # Serverless
@{PROJECTS_TO_DELETE}=                ${TEST_NS}    ${TEST_NS1}
${DOCUMENT}=                          [{'text': 'At what temperature does Nitrogen boil?', 'title': 'first title'},{'text': 'another sentence', 'more': 'more attributes here'},{'text': 'a doc with a nested metadata', 'meta': {'foo': 'bar', 'i': 999, 'f': 12.34}}]     # robocop: disable


*** Test Cases ***
Verify User Can Serve And Query An Embeddings Model On Raw Kserve Via CLI     # robocop: disable
    [Documentation]    Basic tests for deploying a model and verifying endpoints to verify embeddings model using
    ...                caikit-standalone runtime
    [Tags]    Sanity     RHOAIENG-11749
    [Setup]    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${TEST_NS}-cli     protocol=${PROTOCOL}
    ${test_namespace}=    Set Variable     ${TEST_NS}-cli
    ${model_id}=       Set Variable   bge-large-en-v1.5-caikit
    Compile Inference Service YAML    isvc_name=${BGE_MODEL_NAME}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${BGE_STORAGE_URI}
    ...    serving_runtime=${RUNTIME_NAME}
    ...    model_format=caikit    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${BGE_MODEL_NAME}
    ...    namespace=${test_namespace}    runtime=${RUNTIME_NAME}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${BGE_MODEL_NAME}     # robocop: disable
    IF  "${KSERVE_MODE}" == "RawDeployment"
      ${IS_KSERVE_RAW}=    Set Variable    ${TRUE}
    END
    IF    ${IS_KSERVE_RAW}     Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}    local_port=8080    remote_port=8080      # robocop: disable
    Query Model With Raw Kserve     model_id=${model_id}

Verify User Can Serve And Query An Embeddings Model On Serverless Kserve Using GRPC     # robocop: disable
    [Documentation]    Basic tests for preparing, deploying and querying an embeddings LLM model
    ...                using Kserve and Caikit standalone runtime
    [Tags]    Smoke     RHOAIENG-11749
    [Setup]    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${TEST_NS1}    protocol=grpc
    ${test_namespace}=    Set Variable     ${TEST_NS1}
    ${model_id}=       Set Variable   all-MiniLM-L12-v2-caikit
    Compile Inference Service YAML    isvc_name=${MINILM_MODEL_NAME}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${BGE_STORAGE_URI}
    ...    serving_runtime=${RUNTIME_NAME}-grpc
    ...    model_format=caikit    kserve_mode=Serverless
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    namespace=${test_namespace}
    ...        runtime=${RUNTIME_NAME}-grpc    label_selector=serving.kserve.io/inferenceservice=${MINILM_MODEL_NAME}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}    label_selector=serving.kserve.io/inferenceservice=${MINILM_MODEL_NAME}     # robocop: disable
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${MINILM_MODEL_NAME}   namespace=${test_namespace}
    ${body}=    Set Variable    '{"text": "At what temperature does liquid Nitrogen boil?"}'
    ${header}=    Set Variable    'mm-model-id: ${model_id}'
    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/EmbeddingTaskPredict"
    ...    json_body=${body}    json_header=${header}
    ...    insecure=${TRUE}
    ${sentence_body}=    Set Variable    '{"source_sentence": "At what temperature does liquid Nitrogen boil?", "sentences": ["At what temperature does liquid Nitrogen boil", "Hydrogen boils and cools at temperatures"]}'     # robocop: disable
    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/SentenceSimilarityTaskPredict"
    ...    json_body=${sentence_body}    json_header=${header}
    ...    insecure=${TRUE}


*** Keywords ***
Suite Setup
    [Documentation]    Embeddings suite setup
    Set Library Search Order  SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Fetch CA Certificate If RHODS Is Self-Managed
    ${dsc_kserve_mode}=    Get KServe Default Deployment Mode From DSC
    IF    "${dsc_kserve_mode}" == "RawDeployment"
        Set Suite Variable    ${IS_KSERVE_RAW}    ${TRUE}
    ELSE
        Set Suite Variable    ${IS_KSERVE_RAW}    ${FALSE}
    END

 Suite Teardown
     [Documentation]    Embeddings suite teardown
     Delete List Of Projects Via CLI   ocp_projects=${PROJECTS_TO_DELETE}
     RHOSi Teardown

Query Model With Raw Kserve
    [Documentation]    Query Embeddings Model on raw kserve
    [Arguments]    ${model_id}    ${port}=8080
    ${header}=   Set Variable    'Content-Type: application/json'
    ${body}=      Set Variable    '{"inputs": "At what temperature does Nitrogen boil?", "model_id":"${model_id}"}'
    ${endpoint}=    Set Variable     http://localhost:${port}/api/v1/task/embedding
    ${cmd}=    Set Variable    curl -ks
    ${cmd}=    Catenate    ${cmd}    -H ${header} -d ${body} ${endpoint}
    ${rc}  ${result}=    Run And Return Rc And Output    ${cmd}
    Should Be True    ${rc} == 0
    ${expected_string}=    Set Variable     {"data": {"values": [0.
    Should Contain    ${result}     ${expected_string}   msg="Expected vectors not found"
