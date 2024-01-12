*** Settings ***
Documentation    Test suite to validate caikit-nlp-client library usage with Kserve models.
...              These tests leverage on Caikit+TGIS combined Serving Runtime
...              PythonLibrary repo: https://github.com/opendatahub-io/caikit-nlp-client
Resource          ../../../../Resources/CLI/ModelServing/llm.resource
Suite Setup    Caikit Client Suite Setup
Suite Teardown    Caikit Client Suite Teardown
Test Teardown    SeleniumLibrary.Close All Browsers


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
${NOTEBOOK_FILENAME}=    caikit-py-query.ipynb
${CERTS_GENERATED}=    ${FALSE}
${WORKBENCH_TITLE}=    caikit-nlp-client-wrk
${NB_IMAGE}=        Minimal Python
@{FILES_TO_UPLOAD}=    ${CERTS_BASE_FOLDER}/${NOTEBOOK_FILENAME}    ${CERTS_BASE_FOLDER}/openshift_ca_istio_knative.crt
...    ${CERTS_BASE_FOLDER}/client_certs/public.crt    ${CERTS_BASE_FOLDER}/client_certs/private.key

 
*** Test Cases ***
Verify User Can Use Caikit Nlp Client From Workbenches
    [Documentation]    Deploy two KServe models with Caikit+TGIS runtime (one for grpc and one for HTTP protocol),
    ...                create a workbench and run a Jupyter notebook to query a kserve model
    ...                using the caikit-nlp-client python library
    [Tags]    Tier2    ODS-2595
    [Setup]    Run Keywords
    ...    Setup Models
    ...    AND
    ...    Generate Client TLS Certificates If Not Done
    Open Data Science Project Details Page       project_title=${HTTP_MODEL_NS}
    Create Workbench    workbench_title=${WORKBENCH_TITLE}    prj_title=${HTTP_MODEL_NS}
    ...    workbench_description=test caikit-nlp-client    image_name=${NB_IMAGE}   deployment_size=Small
    ...    storage=Persistent    pv_name=${NONE}  pv_existent=${NONE}    pv_description=${NONE}
    ...    pv_size=${NONE}    envs=${WORKBENCH_VARS}            
    Workbench Should Be Listed      workbench_title=${WORKBENCH_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE}
    Launch And Access Workbench    workbench_title=${WORKBENCH_TITLE}
    Upload Files In The Workbench    workbench_title=${WORKBENCH_TITLE}    workbench_namespace=${HTTP_MODEL_NS}
    ...    filepaths=${FILES_TO_UPLOAD}
    Caikit Nlp Client Jupyter Notebook Should Run Successfully


*** Keywords ***
Caikit Client Suite Setup
    [Documentation]    Suite setup which loads the expected model responses, fetch the knative self-signed certificate
    ...                and run the RHOSi Setup checks
    RHOSi Setup
    Set Library Search Order  SeleniumLibrary
    Load Expected Responses
    ${QUERY_TEXT}=    Set Variable    ${EXP_RESPONSES}[queries][0][query_text]
    ${cleaned_exp_response_text}=    Replace String Using Regexp    ${EXP_RESPONSES}[queries][0][models][${ISVC_NAME}][response_text]    \\s+    ${SPACE}
    Set Suite Variable    ${QUERY_TEXT}
    Set Suite Variable    ${QUERY_EXP_RESPONSE}    ${cleaned_exp_response_text}
    Fetch Knative CA Certificate    filename=${CERTS_BASE_FOLDER}/openshift_ca_istio_knative.crt

Caikit Client Suite Teardown
    [Documentation]    Suite teardown which cleans up the test DS Projects and run the RHOSi Setup checks
    ${isvc_names}=    Create List    ${ISVC_NAME}
    ${exists}=    Run And Return Rc    oc get project ${GRPC_MODEL_NS}
    IF    ${exists} == ${0}
        Clean Up Test Project    test_ns=${GRPC_MODEL_NS}    isvc_names=${isvc_names}
    ELSE
        Log    message=Skipping deletion of ${GRPC_MODEL_NS} project: cannot retrieve it from the cluster
    END
    ${exists}=    Run And Return Rc    oc get project ${HTTP_MODEL_NS}
    IF    ${exists} == ${0}
        Clean Up Test Project    test_ns=${HTTP_MODEL_NS}    isvc_names=${isvc_names}
    ELSE
        Log    message=Skipping deletion of ${HTTP_MODEL_NS} project: cannot retrieve it from the cluster
    END
    RHOSi Teardown

GRPC Model Setup
    [Documentation]    Test setup for Caikit+TGIS model with gRPC protocol: deploy model and retrieve URL
    IF    ${GPRC_MODEL_DEPLOYED} == ${FALSE}
        Set Project And Runtime    namespace=${GRPC_MODEL_NS}
        Compile Inference Service YAML    isvc_name=${ISVC_NAME}
        ...    model_storage_uri=${STORAGE_URI}
        Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
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
    [Documentation]    Test setup for Caikit+TGIS model with HTTP protocol: deploy model and retrieve URL
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

Setup Models
    [Documentation]    Test setup for Caikit+TGIS models: deploy models and set model details
    ...                in a dictionary to be used in the workbench
    GRPC Model Setup
    HTTP Model Setup
    ${env_vars}=    Create Dictionary    MODEL_ID=${ISVC_NAME}
    ...    HTTP_HOST=${HTTP_HOST}    GRPC_HOST=${GRPC_HOST}    PORT=${443}
    ...    QUERY_TEXT=${QUERY_TEXT}    EXPECTED_ANSWER=${QUERY_EXP_RESPONSE}
    ...    k8s_type=Secret  input_type=${KEYVALUE_TYPE}
    ${workbench_vars}=    Create List   ${env_vars}
    Set Suite Variable    ${WORKBENCH_VARS}    ${workbench_vars}

Generate Client TLS Certificates If Not Done
    [Documentation]    Generates a set of keys and a certificate to test model query using mTLS
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

Upload Files In The Workbench
    [Documentation]    Uploads the working files inside the workbench PVC
    [Arguments]    ${workbench_title}    ${workbench_namespace}    ${filepaths}
    FOR    ${index}    ${filepath}    IN ENUMERATE    @{filepaths}
        Log    ${index}: ${filepath}
        ${rc}    ${out}=    Run And Return Rc And Output    oc cp ${EXECDIR}/${filepath} ${workbench_title}-0:/opt/app-root/src -n ${workbench_namespace}
        Should Be Equal As Integers    ${rc}    ${0}
    END

Caikit Nlp Client Jupyter Notebook Should Run Successfully
    [Documentation]    Runs the test workbench and check if there was no error during execution
    [Arguments]    ${timeout}=120s
    Open Notebook File In JupyterLab    filepath=${NOTEBOOK_FILENAME}
    Open With JupyterLab Menu  Run  Run All Cells
    Sleep  1
    Wait Until JupyterLab Code Cell Is Not Active  timeout=${timeout}
    Sleep  1
    JupyterLab Code Cell Error Output Should Not Be Visible
    SeleniumLibrary.Capture Page Screenshot
