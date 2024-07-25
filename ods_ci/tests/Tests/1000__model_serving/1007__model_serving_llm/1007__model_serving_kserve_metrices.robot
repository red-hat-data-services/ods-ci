*** Settings ***
Documentation     Basic Test to check if kserve Perf metrices is present
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/Operators/ISVs.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/CLI/ModelServing/llm.resource
Library           OpenShiftLibrary
Suite Setup       Suite Setup

*** Variables ***
${TEST_NS}=    singlemodel
${FLAN_MODEL_S3_DIR}=    flan-t5-small/flan-t5-small-caikit
${FLAN_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_MODEL_S3_DIR}/
${CAIKIT_TGIS_RUNTIME_NAME}=    caikit-tgis-runtime

*** Test Cases ***
Verify User Can Serve And Query A Model
    [Documentation]    Basic tests for chekcing configmapby deploying and querying a LLM model
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Sanity    Tier1   ODS-milind
    [Setup]    Set Project And Runtime    namespace=${TEST_NS}
    ${test_namespace}=    Set Variable     ${TEST_NS}
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Query Model Multiple Times    model_name=${flan_model_name}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    validate_response=${FALSE}
    Verify Metrics Dashboard Is Present
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup for model deployment
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Load Expected Responses
    Set Suite Variable    ${GPU_LIMITS}    &{EMPTY}
    ${dsc_kserve_mode}=    Get KServe Default Deployment Mode From DSC
    Set Suite Variable    ${KSERVE_MODE}   Serverless
    Set Suite Variable    ${IS_KSERVE_RAW}    ${FALSE}

Verify Metrics Dashboard Is Present
    [Documentation]    Check if Metrics Dashboard Is Present
    ${rc}    ${output}=    Run And Return Rc And Output    oc get cm -n ${TEST_NS} ${MODEL_NAME}-metrics-dashboard -o jsonpath='{.data.supported}'
    Should Be Equal As Numbers    ${rc}    0
    Should Be Equal    true    ${output}
