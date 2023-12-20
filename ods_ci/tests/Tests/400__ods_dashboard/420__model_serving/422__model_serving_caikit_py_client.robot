*** Settings ***
Resource          ../../../Resources/CLI/ModelServing/llm.resource
Library           ../../../../libs/CaikitPythonClient.py
Suite Setup    Caikit Client Suite Setup
Suite Teardown    Caikit Client Suite Teardown

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
${CERTS_GENERATED}=    ${FALSE}

*** Test Cases ***
Verify User Can Use GRPC Without TLS Validation
    [Setup]    GRPC Model Setup
    ${client} =     CaikitPythonClient.Get Grpc Client Without Ssl Validation    ${GRPC_HOST}    443
    ${response}=    CaikitPythonClient.Query Endpoint    ${MODEL_ID}    ${QUERY_TEXT}
    Should Be Equal As Strings    ${response}    ${QUERY_EXP_RESPONSE}

Verify User Can Use GRPC With TLS
    [Setup]    GRPC Model Setup
    ${client} =     CaikitPythonClient.Get Grpc Client With Tls    ${GRPC_HOST}    443    ca_cert=${CERTS_BASE_FOLDER}/openshift_ca_istio_knative.crt
    ${response}=    CaikitPythonClient.Query Endpoint    ${MODEL_ID}    ${QUERY_TEXT}
    Should Be Equal As Strings    ${response}    ${QUERY_EXP_RESPONSE}
 
Verify User Can Use GRPC With mTLS
    [Setup]    Run Keywords
    ...    GRPC Model Setup
    ...    AND
    ...    Generate Client TLS Certificates If Not Done
    ${client} =     CaikitPythonClient.Get Grpc Client With Mtls    ${GRPC_HOST}    443    ca_cert=${CERTS_BASE_FOLDER}/openshift_ca_istio_knative.crt
    ...    client_cert=${CERTS_BASE_FOLDER}/client_certs/public.crt    client_key=${CERTS_BASE_FOLDER}/client_certs/private.key
    ${response}=    CaikitPythonClient.Query Endpoint    ${MODEL_ID}    ${QUERY_TEXT}
    Should Be Equal As Strings    ${response}    ${QUERY_EXP_RESPONSE}

Verify User Can Use HTTP Without SSL Validation
    [Setup]    HTTP Model Setup
    ${client} =     CaikitPythonClient.Get Http Client Without Ssl Validation    ${HTTP_HOST}    443
    ${response}=    CaikitPythonClient.Query Endpoint    ${MODEL_ID}    ${QUERY_TEXT}
    Should Be Equal As Strings    ${response}    ${QUERY_EXP_RESPONSE}

Verify User Can Use HTTP With TLS
    [Setup]    HTTP Model Setup
    ${client} =     CaikitPythonClient.Get Http Client With TLS    ${HTTP_HOST}    443
    ...    ca_cert_path=${CERTS_BASE_FOLDER}/openshift_ca_istio_knative.crt
    ${response}=    CaikitPythonClient.Query Endpoint    ${MODEL_ID}    ${QUERY_TEXT}
    Should Be Equal As Strings    ${response}    ${QUERY_EXP_RESPONSE}

Verify User Can Use HTTP With mTLS
    [Setup]    Run Keywords
    ...    HTTP Model Setup
    ...    AND
    ...    Generate Client TLS Certificates If Not Done
    ${client} =     CaikitPythonClient.Get Http Client With Mtls    ${HTTP_HOST}    443    ca_cert_path=${CERTS_BASE_FOLDER}/openshift_ca_istio_knative.crt
    ...    client_cert_path=${CERTS_BASE_FOLDER}/client_certs/public.crt    client_key_path=${CERTS_BASE_FOLDER}/client_certs/private.key
    ${response}=    CaikitPythonClient.Query Endpoint    ${MODEL_ID}    ${QUERY_TEXT}
    Should Be Equal As Strings    ${response}    ${QUERY_EXP_RESPONSE}


*** Keywords ***
Caikit Client Suite Setup
    [Documentation]
    RHOSi Setup
    Set Library Search Order  SeleniumLibrary
    Load Expected Responses
    ${QUERY_TEXT}=    Set Variable    ${EXP_RESPONSES}[queries][0][query_text]
    ${cleaned_exp_response_text}=    Replace String Using Regexp    ${EXP_RESPONSES}[queries][0][models][${ISVC_NAME}][response_text]    \\s+    ${SPACE}
    Set Suite Variable    ${QUERY_TEXT}
    Set Suite Variable    ${QUERY_EXP_RESPONSE}    ${cleaned_exp_response_text}
    Fetch Knative CA Certificate    filename=${CERTS_BASE_FOLDER}/openshift_ca_istio_knative.crt

Caikit Client Suite Teardown
    ${isvc_names}=    Create List    ${ISVC_NAME}
    Clean Up Test Project    test_ns=${GRPC_MODEL_NS}    isvc_names=${isvc_names}
    Clean Up Test Project    test_ns=${HTTP_MODEL_NS}    isvc_names=${isvc_names}
    RHOSi Teardown

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
        Set Suite Variable    ${GPRC_MODEL_DEPLOYED}    ${TRUE}
    ELSE
        Log    message=Skipping model deployment, it was marked as deployed in a previous test
    END
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${ISVC_NAME}   namespace=${GRPC_MODEL_NS}
    Set Suite Variable    ${GRPC_HOST}    ${host}

HTTP Model Setup
    [Arguments]    ${user}=${TEST_USER_3.USERNAME}    ${pw}=${TEST_USER_3.PASSWORD}    ${auth}=${TEST_USER_3.AUTH_TYPE}
    Launch Dashboard    ${user}    ${pw}    ${auth}    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    IF    ${HTTP_MODEL_DEPLOYED} == ${FALSE}
        Set Up Project    namespace=${HTTP_MODEL_NS}    single_prj=${FALSE}
        Open Data Science Project Details Page    ${HTTP_MODEL_NS}
        Deploy Kserve Model Via UI    model_name=${ISVC_NAME}    serving_runtime=Caikit
        ...    data_connection=kserve-connection    path=${MODEL_S3_DIR}
        Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${ISVC_NAME}
        ...    namespace=${HTTP_MODEL_NS}  
        Log    ${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}
        Query Model Multiple Times    model_name=${ISVC_NAME}
        ...    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    n_times=1
        ...    namespace=${HTTP_MODEL_NS}    protocol=http
        ...    timeout=20
        Set Suite Variable    ${HTTP_MODEL_DEPLOYED}    ${TRUE}
    ELSE
        Log    message=Skipping model deployment, it was marked as deployed in a previous test
        Open Data Science Project Details Page    ${HTTP_MODEL_NS}
    END
    ${host}=    Get Kserve Inference Host Via UI    ${ISVC_NAME}
    Set Suite Variable    ${HTTP_HOST}    ${host}

Generate Client TLS Certificates If Not Done
    IF    ${CERTS_GENERATED} == ${FALSE}
        ${status}=    Run Keyword And Return Status    Generate Client TLS Certificates    dirpath=${CERTS_BASE_FOLDER}
        IF    ${status} == ${TRUE}
            Set Suite Variable    ${CERTS_GENERATED}    ${TRUE}
        ELSE
            Fail    msg=Something went wrong with generation of client TLS certificates
        END
    ELSE
        Log    message=Skipping generation of client TLS certs, it was marked as done in a previous test
    END
