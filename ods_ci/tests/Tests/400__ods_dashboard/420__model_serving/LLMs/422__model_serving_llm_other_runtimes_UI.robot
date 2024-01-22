*** Settings ***
Documentation     Collection of UI tests to validate the model serving stack for Large Language Models (LLM).
...               These tests leverage on Caikit+TGIS combined Serving Runtime
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../../Resources/CLI/ModelServing/llm.resource
Suite Setup       Non-Admin Setup Kserve UI Test
Suite Teardown    Non-Admin Teardown Kserve UI Test
Test Tags         KServe


*** Variables ***
${LLM_RESOURCES_DIRPATH}=    ods_ci/tests/Resources/Files/llm
${TEST_NS}=    runtimes-ui
${EXP_RESPONSES_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/model_expected_responses.json
${FLAN_MODEL_S3_DIR}=    flan-t5-small/flan-t5-small-hf
${FLAN_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_MODEL_S3_DIR}/
${TGIS_RUNTIME_NAME}=    tgis-runtime


*** Test Cases ***
Verify Non Admin Can Serve And Query A Model Using The UI  # robocop: disable
    [Documentation]    Basic tests leveraging on a non-admin user for preparing, deploying and querying a LLM model
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Sanity    Tier1    ODS-XYZ
    ${test_namespace}=    Set Variable     ${TEST_NS}
    ${model_name}=    Set Variable    flan-t5-small-hf
    Deploy Kserve Model Via UI    model_name=${model_name}    serving_runtime=TGIS Standalone ServingRuntime for KServe (gRPC)
    ...    data_connection=kserve-connection    model_framework=pytorch    path=${FLAN_MODEL_S3_DIR}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    protocol=grpc
    Query Model Multiple Times    model_name=${model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    protocol=http    validate_response=$FALSE
    Delete Model Via UI    ${model_name}

##Verify Model Can Be Served And Query On A GPU Node Using The UI  # robocop: disable
##    [Documentation]    Basic tests for preparing, deploying and querying a LLM model on GPU node
##    ...                using Kserve and Caikit+TGIS runtime
##    [Tags]    Sanity    Tier1    ODS-XYZ   Resources-GPU

## Verify User Can Access Model Metrics From UWM Using The UI  # robocop: disable
##     [Documentation]    Verifies that model metrics are available for users in the
##     ...                OpenShift monitoring system (UserWorkloadMonitoring)
##     ...                PARTIALLY DONE: it is checking number of requests, number of successful requests
##     ...                and model pod cpu usage. Waiting for a complete list of expected metrics and
##     ...                derived metrics.
##     [Tags]    Sanity    Tier1    ODS-XYZ



*** Keywords ***
Non-Admin Setup Kserve UI Test
    [Documentation]    Instaling And Configuring dependency operators: Service Mesh and Serverless.
    ...                This is likely going to change in the future and it will include a way to skip installation.
    ...                Caikit runtime will be shipped Out-of-the-box and will be removed from here.
    [Arguments]    ${user}=${TEST_USER_3.USERNAME}    ${pw}=${TEST_USER_3.PASSWORD}    ${auth}=${TEST_USER_3.AUTH_TYPE}
    Set Library Search Order  SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    # RHOSi Setup
    Load Expected Responses
    Launch Dashboard    ${user}    ${pw}    ${auth}    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Set Up Project    namespace=${TEST_NS}    single_prj=${FALSE}
    Fetch CA Certificate If RHODS Is Self-Managed

Non-Admin Teardown Kserve UI Test
    Delete Data Science Project   project_title=${TEST_NS}
    # if UI deletion fails it will try deleting from CLI
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    SeleniumLibrary.Close All Browsers
    # RHOSi Teardown