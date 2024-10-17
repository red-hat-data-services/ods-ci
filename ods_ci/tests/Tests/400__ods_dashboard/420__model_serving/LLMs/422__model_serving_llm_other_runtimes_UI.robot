*** Settings ***
Documentation     Collection of UI tests to validate the model serving stack for Large Language Models (LLM)
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../../Resources/CLI/ModelServing/llm.resource
Suite Setup       Non-Admin Setup Kserve UI Test
Suite Teardown    Non-Admin Teardown Kserve UI Test
Test Tags         KServe


*** Variables ***
${LLM_RESOURCES_DIRPATH}=    tests/Resources/Files/llm
${TEST_NS}=    runtimes-ui
${EXP_RESPONSES_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/model_expected_responses.json
${FLAN_MODEL_S3_DIR}=    flan-t5-small/flan-t5-small-hf
${FLAN_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_MODEL_S3_DIR}/
${TGIS_RUNTIME_NAME}=    tgis-runtime
@{SEARCH_METRICS}=    tgi_    istio_


*** Test Cases ***
Verify Non Admin Can Serve And Query A Model Using The UI  # robocop: disable
    [Documentation]    Basic tests leveraging on a non-admin user for preparing, deploying and querying a LLM model
    ...                using Single-model platform and TGIS Standalone runtime.
    [Tags]    Sanity    Tier1    ODS-2611
    [Setup]    Run Keywords
    ...    Run    git clone https://github.com/IBM/text-generation-inference/
    ...    AND
    ...    Configure User Workload Monitoring
    ...    AND
    ...    Enable User Workload Monitoring
    ${test_namespace}=    Set Variable     ${TEST_NS}
    ${model_name}=    Set Variable    flan-t5-small-hf
    Deploy Kserve Model Via UI    model_name=${model_name}
    ...    serving_runtime=TGIS Standalone ServingRuntime for KServe
    ...    data_connection=kserve-connection    model_framework=pytorch    path=${FLAN_MODEL_S3_DIR}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    protocol=grpc
    Query Model Multiple Times    model_name=${model_name}        runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    protocol=grpc    validate_response=${FALSE}
    Wait Until Keyword Succeeds    30 times    4s
    ...    Metrics Should Exist In UserWorkloadMonitoring
    ...    thanos_url=${THANOS_URL}    thanos_token=${THANOS_TOKEN}
    ...    search_metrics=${SEARCH_METRICS}
    Wait Until Keyword Succeeds    50 times    5s
    ...    User Can Fetch Number Of Requests Over Defined Time
    ...    thanos_url=${THANOS_URL}    thanos_token=${THANOS_TOKEN}
    ...    model_name=${model_name}    query_kind=single    namespace=${test_namespace}    period=5m    exp_value=1
    Delete Model Via UI    ${model_name}

Verify Model Can Be Served And Query On A GPU Node Using The UI  # robocop: disable
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model on GPU node
    ...                using Single-model platform and TGIS Standalone runtime.
    [Tags]    Sanity    Tier1    ODS-2612   Resources-GPU    NVIDIA-GPUs
    [Setup]    Run    git clone https://github.com/IBM/text-generation-inference/
    ${test_namespace}=    Set Variable     ${TEST_NS}
    ${isvc__name}=    Set Variable    flan-t5-small-hf-gpu
    ${model_name}=    Set Variable    flan-t5-small-hf
    ${requests}=    Create Dictionary    nvidia.com/gpu=1
    ${limits}=    Create Dictionary    nvidia.com/gpu=1
    Deploy Kserve Model Via UI    model_name=${isvc__name}    serving_runtime=TGIS Standalone ServingRuntime for KServe
    ...    data_connection=kserve-connection    model_framework=pytorch    path=${FLAN_MODEL_S3_DIR}
    ...    no_gpus=${1}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${isvc__name}
    ...    namespace=${test_namespace}
    Container Hardware Resources Should Match Expected    container_name=kserve-container
    ...    pod_label_selector=serving.kserve.io/inferenceservice=${isvc__name}
    ...    namespace=${test_namespace}    exp_requests=${requests}    exp_limits=${limits}
    Query Model Multiple Times    model_name=${model_name}    isvc_name=${isvc__name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    protocol=grpc
    Query Model Multiple Times    model_name=${model_name}    isvc_name=${isvc__name}    runtime=${TGIS_RUNTIME_NAME}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    protocol=grpc    validate_response=${FALSE}
    Delete Model Via UI    ${isvc__name}


*** Keywords ***
Non-Admin Setup Kserve UI Test
    [Documentation]    Instaling And Configuring dependency operators: Service Mesh and Serverless.
    ...                This is likely going to change in the future and it will include a way to skip installation.
    ...                Caikit runtime will be shipped Out-of-the-box and will be removed from here.
    [Arguments]    ${user}=${TEST_USER_3.USERNAME}    ${pw}=${TEST_USER_3.PASSWORD}    ${auth}=${TEST_USER_3.AUTH_TYPE}
    Set Library Search Order  SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Load Expected Responses
    Launch Dashboard    ${user}    ${pw}    ${auth}    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Set Up Project    namespace=${TEST_NS}    single_prj=${FALSE}    enable_metrics=${TRUE}
    ${PROJECTS_TO_DELETE}=    Create List    ${TEST_NS}
    Set Suite Variable    ${PROJECTS_TO_DELETE}
    Fetch CA Certificate If RHODS Is Self-Managed
    Set Thanos Credentials Variables

Non-Admin Teardown Kserve UI Test
    Delete Data Science Project   project_title=${TEST_NS}
    # if UI deletion fails it will try deleting from CLI
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown
