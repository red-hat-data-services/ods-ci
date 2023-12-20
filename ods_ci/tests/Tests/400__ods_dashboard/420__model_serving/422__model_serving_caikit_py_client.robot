*** Settings ***
Resource          ../../../Resources/CLI/ModelServing/llm.resource
Library           ../../../../libs/CaikitPythonClient.py
Suite Setup    Caikit Client Suite Setup

*** Variables ***
${GPRC_MODEL_DEPLOYED}=    ${FALSE}
${HTTP_MODEL_DEPLOYED}=    ${FALSE}
${GRPC_MODEL_NS}=    caikit-grpc
${HTTP_MODEL_NS}=    caikit-http
${MODEL_S3_DIR}=    bloom-560m/bloom-560m-caikit
${ISVC_NAME}=    bloom-560m-caikit
${MODEL_ID}=    ${ISVC_NAME}
${STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${MODEL_S3_DIR}/
${CERTS_BASE_FOLDER}=    ods_ci/tests/Resources/CLI/ModelServing


*** Test Cases ***
Verify User Can Use GRPC Without TLS Validation
    [Setup]    GRPC Model Setup
    Log    ${GPRC_MODEL_DEPLOYED}
    ${client} =     CaikitPythonClient.Get Grpc Client Without Ssl Validation    ${GRPC_HOST}    443
    ${response}=    CaikitPythonClient.Query Endpoint    ${MODEL_ID}    ${QUERY_TEXT}
    Should Be Equal As Strings    ${response}    ${QUERY_EXP_RESPONSE}

Verify User Can Use GRPC With TLS
    [Setup]    GRPC Model Setup
    ${client} =     CaikitPythonClient.Get Grpc Client With Tls    ${GRPC_HOST}    443    ca_cert_path=openshift_ca_istio_knative.crt
    ${response}=    CaikitPythonClient.Query Endpoint    ${MODEL_ID}    ${QUERY_TEXT}
    Should Be Equal As Strings    ${response}    ${QUERY_EXP_RESPONSE}
 
Verify User Can Use GRPC With mTLS
    [Setup]    Run Keywords
    ...    GRPC Model Setup
    ...    AND
    ...    Generate Client Certificates    dirpath=${CERTS_BASE_FOLDER}
    Log    ${GPRC_MODEL_DEPLOYED}
    ${client} =     CaikitPythonClient.Get Grpc Client With Mtls    ${GRPC_HOST}    443    ca_cert=${CERTS_BASE_FOLDER}/openshift_ca_istio_knative.crt
    ...    client_cert=${CERTS_BASE_FOLDER}/client_certs/public.crt    client_key=${CERTS_BASE_FOLDER}/client_certs/private.key
    ${response}=    CaikitPythonClient.Query Endpoint    ${MODEL_ID}    ${QUERY_TEXT}
    Should Be Equal As Strings    ${response}    ${QUERY_EXP_RESPONSE}


Verify User Can Use HTTP Without TLS
    # TO DO

Verify User Can Use HTTP With TLS
    # TO DO

Verify User Can Use HTTP With mTLS
    # TO DO

*** Keywords ***
Caikit Client Suite Setup
    [Documentation]
    # RHOSi Setup
    Load Expected Responses
    ${QUERY_TEXT}=    Set Variable    ${EXP_RESPONSES}[queries][0][query_text]
    ${cleaned_exp_response_text}=    Replace String Using Regexp    ${EXP_RESPONSES}[queries][0][models][${ISVC_NAME}][response_text]    \\s+    ${SPACE}
    Set Suite Variable    ${QUERY_TEXT}
    Set Suite Variable    ${QUERY_EXP_RESPONSE}    ${cleaned_exp_response_text}
    Fetch Knative CA Certificate    filename=${CERTS_BASE_FOLDER}/openshift_ca_istio_knative.crt

GRPC Model Setup
    IF    ${GPRC_MODEL_DEPLOYED} == ${FALSE}
        Set Project And Runtime    namespace=${GRPC_MODEL_NS}
        Compile Inference Service YAML    isvc_name=${ISVC_NAME}
        ...    model_storage_uri=${STORAGE_URI}
        Deploy Model Via CLI    isvc_filepath=${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
        ...    namespace=${GRPC_MODEL_NS}
        Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${ISVC_NAME}
        ...    namespace=${GRPC_MODEL_NS}
        Query Model Multiple Times    model_name=${ISVC_NAME}
        ...    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT}    n_times=1
        ...    namespace=${GRPC_MODEL_NS}    validate_response=${FALSE}
        ${GPRC_MODEL_DEPLOYED}=    Set Variable    ${TRUE}
        # Set Suite Variable    ${GPRC_MODEL_DEPLOYED}    ${TRUE}
    ELSE
        Log    message=Skipping model deployment, it was marked as deployed in a previous test
    END
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${ISVC_NAME}   namespace=${GRPC_MODEL_NS}
    Set Suite Variable    ${GRPC_HOST}    ${host}

# HTTP Model Setup
