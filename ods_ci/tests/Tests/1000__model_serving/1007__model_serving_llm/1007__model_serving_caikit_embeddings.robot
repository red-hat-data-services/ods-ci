*** Settings ***
Documentation     Collection of CLI tests to validate the model serving stack for Embeddings Models.
...               These tests leverage on Caikit Standalone Serving Runtime
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/CLI/ModelServing/llm.resource
Resource          ../../../Resources/CLI/Minio.resource
Library            OpenShiftLibrary
Suite Setup       Suite Setup
Suite Teardown    RHOSi Teardown
Test Tags         embeddings


*** Variables ***
${BGE_MODEL_NAME}=                    bge-large-en-caikit
${MINILM_MODEL_NAME}=                 all-minilm-caikit
${TEST_NS}=                           caikit-embeddings-cli
${TEST_NS1}=                          caikit-embeddings
${RUNTIME_NAME}=                      caikit-standalone-runtime
${BGE_STORAGE_URI}=                   s3://${S3.BUCKET_3.NAME}/embeddingsmodel
${PROTOCOL}=                          http         # grpc
${KSERVE_MODE}=                       RawDeployment   # Serverless
${DOCUMENT_QUERY}=                    [{"text": "At what temperature does Nitrogen boil?", "title": "Nitrogen Boil"}, {"text": "Cooling Temperature for Nitrogen is different", "more": "There are other features on Nitrogen"}, {"text": "What elements could be used Nitrogen, Helium", "meta": {"date": "today", "i": 999, "f": 12.34}}]    # robocop: disable
${SIMILAR_QUERY_BODY}=                '{"source_sentence": "At what temperature does liquid Nitrogen boil?", "sentences": ["At what temperature does liquid Nitrogen boil", "Hydrogen boils and cools at temperatures"]}'     # robocop: disable
${RERANK_QUERY_BODY}=                 '{"documents": ${DOCUMENT_QUERY},"query": "At what temperature does liquid Nitrogen boil?","top_n": 293}'     # robocop: disable
${EMBEDDINGS_QUERY_BODY}=             '{"text":"At what temperature does liquid Nitrogen boil?"}'


*** Test Cases ***
Verify User Can Serve And Query An Embeddings Model On Raw Kserve Via CLI     # robocop: disable
    [Documentation]    Basic tests for deploying a model and verifying endpoints to verify embeddings model using
    ...                caikit-standalone runtime
    [Tags]    Smoke     RHOAIENG-11749
    [Setup]    Set Project And Runtime    runtime=${RUNTIME_NAME}     namespace=${TEST_NS}     protocol=${PROTOCOL}
    ${test_namespace}=    Set Variable     ${TEST_NS}
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
    [Teardown]    Delete Project Via CLI    namespace=${TEST_NS}

Verify User Can Serve And Query An Embeddings Model On Serverless Kserve Using GRPC     # robocop: disable
    [Documentation]    Basic tests for preparing, deploying and querying an embeddings LLM model
    ...                using Kserve and Caikit standalone runtime
    [Tags]    Tier1     RHOAIENG-11749
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
    ${header}=    Set Variable    "mm-model-id: ${model_id}"
    Run Keyword And Continue On Failure      Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/EmbeddingTaskPredict"
    ...    json_body=${EMBEDDINGS_QUERY_BODY}    json_header=${header}
    ...    insecure=${TRUE}
    Run Keyword And Continue On Failure     Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/RerankTaskPredict"
    ...    json_body=${RERANK_QUERY_BODY}    json_header=${header}
    ...    insecure=${TRUE}
    Run Keyword And Continue On Failure     Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/SentenceSimilarityTaskPredict"
    ...    json_body=${SIMILAR_QUERY_BODY}    json_header=${header}
    ...    insecure=${TRUE}
    [Teardown]    Delete Project Via CLI    namespace=${TEST_NS1}


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

#robocop: disable: line-too-long
Query Model With Raw Kserve
    [Documentation]    Query Embeddings Model on raw kserve
    [Arguments]    ${model_id}    ${port}=8080
    ${embedding_body}=  Set Variable    '{"inputs": "At what temperature does liquid Nitrogen boil?", "model_id":"${model_id}"}'
    ${embedding_endpoint}=    Set Variable     http://localhost:${port}/api/v1/task/embedding
    ${embedding_expected_string}=    Set Variable     "values": [0.
    Run Model Query Command   body=${embedding_body}   endpoint=${embedding_endpoint}    expected_string=${embedding_expected_string}
    ${reranking_body}=      Set Variable    '{"model_id":"${model_id}", "inputs": {"documents": ${DOCUMENT_QUERY}, "query": "At what temperature does liquid Nitrogen boil?"},"parameters": {"top_n":293}}'
    ${reranking_endpoint}=    Set Variable     http://localhost:${port}/api/v1/task/rerank
    ${reranking_expected_string}=    Set Variable     "score": 0.
    Run Model Query Command   body=${reranking_body}   endpoint=${reranking_endpoint}    expected_string=${reranking_expected_string}
    ${similarity_body}=   Set Variable   '{"model_id":"${model_id}", "inputs": {"source_sentence": "At what temperature does liquid Nitrogen boil?", "sentences": ["At what temperature does liquid Nitrogen boil", "Hydrogen boils and cools at temperatures"]}}'
    ${similarity_endpoint}=    Set Variable    http://localhost:${port}/api/v1/task/sentence-similarity
    ${similarity_expected_string}=    Set Variable     "scores": [0.
    Run Model Query Command   body=${similarity_body}   endpoint=${similarity_endpoint}    expected_string=${similarity_expected_string}

Run Model Query Command
    [Documentation]    Query Embeddings Model using given endpoints and body
    [Arguments]    ${body}   ${endpoint}     ${expected_string}
    ${header}=   Set Variable    'Content-Type: application/json'
    ${cmd}=    Set Variable    curl -ks
    ${cmd}=    Catenate    ${cmd}    -H ${header} -d ${body} ${endpoint}
    ${rc}  ${result}=    Run And Return Rc And Output    ${cmd}
    Should Be True    ${rc} == 0
    Should Contain    ${result}     ${expected_string}   msg="Expected vectors not found"
