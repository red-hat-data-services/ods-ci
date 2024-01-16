*** Settings ***
Documentation     Collection of UI tests to validate the model serving stack for Large Language Models (LLM).
...               These tests leverage on Caikit+TGIS combined Serving Runtime
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../../Resources/OCP.resource
Resource          ../../../../Resources/Page/Operators/ISVs.resource
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHDashboardAPI.resource
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../../Resources/CLI/ModelServing/llm.resource
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Permissions.resource
Library            OpenShiftLibrary
Suite Setup       Setup Kserve UI Test
Suite Teardown    RHOSi Teardown
Test Tags         KServe


*** Variables ***
${LLM_RESOURCES_DIRPATH}=    ods_ci/tests/Resources/Files/llm
${TEST_NS}=    singlemodel
${EXP_RESPONSES_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/model_expected_responses.json
${FLAN_MODEL_S3_DIR}=    flan-t5-small/flan-t5-small-caikit
${FLAN_GRAMMAR_MODEL_S3_DIR}=    flan-t5-large-grammar-synthesis-caikit/flan-t5-large-grammar-synthesis-caikit
${FLAN_LARGE_MODEL_S3_DIR}=    flan-t5-large/flan-t5-large
${BLOOM_MODEL_S3_DIR}=    bloom-560m/bloom-560m-caikit


*** Test Cases ***
Verify User Can Serve And Query A Model Using The UI
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and Caikit runtime
    [Tags]    Smoke    Tier1    ODS-2519    ODS-2522
    [Setup]    Set Up Project    namespace=${TEST_NS}
    ${test_namespace}=    Set Variable     ${TEST_NS}
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    Deploy Kserve Model Via UI    ${flan_model_name}    Caikit    kserve-connection    flan-t5-small/${flan_model_name}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    protocol=http    validate_response=${FALSE}
    Delete Model Via UI    ${flan_model_name}
    [Teardown]    Clean Up DSP Page

Verify User Can Deploy Multiple Models In The Same Namespace Using The UI  # robocop: disable
    [Documentation]    Checks if user can deploy and query multiple models in the same namespace
    [Tags]    Sanity    Tier1    ODS-2548
    [Setup]    Set Up Project    namespace=${TEST_NS}-multisame
    ${test_namespace}=    Set Variable     ${TEST_NS}-multisame
    ${model_one_name}=    Set Variable    bloom-560m-caikit
    ${model_two_name}=    Set Variable    flan-t5-small-caikit
    Deploy Kserve Model Via UI    ${model_one_name}    Caikit    kserve-connection
    ...    ${BLOOM_MODEL_S3_DIR}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_one_name}
    ...    namespace=${test_namespace}
    Deploy Kserve Model Via UI    ${model_two_name}    Caikit    kserve-connection
    ...    flan-t5-small/${model_two_name}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_two_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    inference_type=all-tokens    model_name=${model_one_name}
    ...    n_times=5    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    inference_type=all-tokens    model_name=${model_two_name}
    ...    n_times=10    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    inference_type=streaming    model_name=${model_one_name}
    ...    n_times=5    namespace=${test_namespace}    protocol=http    validate_response=${FALSE}
    Query Model Multiple Times    inference_type=streaming    model_name=${model_two_name}
    ...    n_times=10    namespace=${test_namespace}    protocol=http    validate_response=${FALSE}
    [Teardown]    Clean Up DSP Page

Verify User Can Deploy Multiple Models In Different Namespaces Using The UI  # robocop: disable
    [Documentation]    Checks if user can deploy and query multiple models in the different namespaces
    [Tags]    Sanity    Tier1    ODS-2549
    [Setup]    Set Up Project    namespace=singlemodel-multi1
    ${model_one_name}=    Set Variable    bloom-560m-caikit
    ${model_two_name}=    Set Variable    flan-t5-small-caikit
    Deploy Kserve Model Via UI    ${model_one_name}    Caikit    kserve-connection
    ...    bloom-560m/${model_one_name}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_one_name}
    ...    namespace=singlemodel-multi1
    Query Model Multiple Times    inference_type=all-tokens    model_name=${model_one_name}
    ...    n_times=2    namespace=singlemodel-multi1    protocol=http
    Open Data Science Projects Home Page
    Set Up Project    namespace=singlemodel-multi2    single_prj=${FALSE}    dc_name=kserve-connection-2
    Deploy Kserve Model Via UI    ${model_two_name}    Caikit    kserve-connection-2
    ...    flan-t5-small/${model_two_name}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_two_name}
    ...    namespace=singlemodel-multi2
    Query Model Multiple Times    inference_type=all-tokens    model_name=${model_two_name}
    ...    n_times=2    namespace=singlemodel-multi2    protocol=http
    [Teardown]    Clean Up DSP Page

Verify Model Pods Are Deleted When No Inference Service Is Present Using The UI  # robocop: disable
    [Documentation]    Checks if model pods gets successfully deleted after
    ...                deleting the KServe InferenceService object
    [Tags]    Tier2    ODS-2550
    [Setup]    Set Up Project    namespace=no-infer-kserve
    ${flan_isvc_name}=    Set Variable    flan-t5-small-caikit
    ${model_name}=    Set Variable    flan-t5-small-caikit
    Deploy Kserve Model Via UI    ${model_name}    Caikit    kserve-connection    flan-t5-small/${model_name}
    Delete InfereceService    isvc_name=${flan_isvc_name}    namespace=no-infer-kserve
    ${rc}    ${out}=    Run And Return Rc And Output    oc wait pod -l serving.kserve.io/inferenceservice=${flan_isvc_name} -n no-infer-kserve --for=delete --timeout=200s  #robocop: disable
    Should Be Equal As Integers    ${rc}    ${0}
    [Teardown]   Clean Up DSP Page

Verify User Can Set Requests And Limits For A Model Using The UI  # robocop: disable
    [Documentation]    Checks if user can set HW request and limits on their inference service object
    [Tags]    Sanity    Tier1    ODS-2551
    [Setup]    Set Up Project    namespace=hw-res
    ${test_namespace}=    Set Variable    hw-res
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${requests}=    Create Dictionary    cpu=1    memory=4Gi
    ${limits}=    Create Dictionary    cpu=2    memory=8Gi
    Deploy Kserve Model Via UI    ${flan_model_name}    Caikit    kserve-connection    flan-t5-small/${flan_model_name}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    # ${rev_id}=    Get Current Revision ID    model_name=${flan_model_name}
    # ...    namespace=${test_namespace}
    Query Model Multiple Times    inference_type=all-tokens    model_name=${flan_model_name}
    ...    n_times=1    namespace=${test_namespace}    protocol=http
    Container Hardware Resources Should Match Expected    container_name=kserve-container
    ...    pod_label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    exp_requests=${requests}    exp_limits=${limits}
    ${new_requests}=    Create Dictionary    cpu=4    memory=8Gi
    ${new_limits}=    Create Dictionary    cpu=8    memory=10Gi
    # Set Model Hardware Resources    model_name=${flan_model_name}    namespace=hw-res
    # ...    requests=${new_requests}    limits=${NONE}
    # Wait For Pods To Be Terminated    label_selector=serving.knative.dev/revisionUID=${rev_id}
    # ...    namespace=${test_namespace}
    #### Editing the size of an existing model does not work in 2.5, deploying a different one with different size
    Deploy Kserve Model Via UI    ${flan_model_name}-medium    Caikit    kserve-connection
    ...    flan-t5-small/${flan_model_name}  size=Medium
    # Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    # ...    namespace=${test_namespace}    exp_replicas=1
    ##### Usually our clusters won't have enough resource to actually spawn this, don't wait for pods to be ready
    Sleep    5
    Container Hardware Resources Should Match Expected    container_name=kserve-container
    ...    pod_label_selector=serving.kserve.io/inferenceservice=${flan_model_name}-medium
    ...    namespace=${test_namespace}    exp_requests=${new_requests}    exp_limits=${new_limits}
    [Teardown]   Clean Up DSP Page

Verify Model Can Be Served And Query On A GPU Node Using The UI  # robocop: disable
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model on GPU node
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Sanity    Tier1    ODS-2523   Resources-GPU
    [Setup]    Set Up Project    namespace=singlemodel-gpu
    ${test_namespace}=    Set Variable    singlemodel-gpu
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${requests}=    Create Dictionary    nvidia.com/gpu=1
    ${limits}=    Create Dictionary    nvidia.com/gpu=1
    Deploy Kserve Model Via UI    ${model_name}    Caikit    kserve-connection
    ...    flan-t5-small/${model_name}    no_gpus=${1}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    Container Hardware Resources Should Match Expected    container_name=kserve-container
    ...    pod_label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    exp_requests=${requests}    exp_limits=${limits}
    Model Pod Should Be Scheduled On A GPU Node    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}    n_times=10
    ...    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    model_name=${model_name}    n_times=5
    ...    namespace=${test_namespace}    inference_type=streaming
    ...    validate_response=${FALSE}    protocol=http
    [Teardown]   Clean Up DSP Page

Verify Non Admin Can Serve And Query A Model Using The UI  # robocop: disable
    [Documentation]    Basic tests leveraging on a non-admin user for preparing, deploying and querying a LLM model
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Smoke    Tier1    ODS-2552
    [Setup]    Run Keywords    Setup Kserve UI Test    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}  AND
    ...        Set Up Project    namespace=non-admin-test    single_prj=${FALSE}
    ${test_namespace}=    Set Variable     non-admin-test
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    Deploy Kserve Model Via UI    ${flan_model_name}    Caikit    kserve-connection    flan-t5-small/${flan_model_name}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    # ${host}=    Get KServe Inference Host Via CLI    isvc_name=${flan_model_name}   namespace=${test_namespace}
    # ${body}=    Set Variable    '{"text": "${EXP_RESPONSES}[queries][0][query_text]"}'
    # ${header}=    Set Variable    'mm-model-id: ${flan_model_name}'
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    protocol=http    validate_response=$FALSE
    [Teardown]    Run Keywords    Clean Up DSP Page    AND    Close Browser    AND    Switch Browser    1

Verify User Can Serve And Query Flan-t5 Grammar Syntax Corrector Using The UI  # robocop: disable
    [Documentation]    Deploys and queries flan-t5-large-grammar-synthesis model
    [Tags]    Tier2    ODS-2553
    [Setup]    Set Up Project    namespace=grammar-model
    ${test_namespace}=    Set Variable     grammar-model
    ${flan_model_name}=    Set Variable    flan-t5-large-grammar-synthesis-caikit
    Deploy Kserve Model Via UI    ${flan_model_name}    Caikit
    ...    kserve-connection    flan-t5-large-grammar-synthesis-caikit/${flan_model_name}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Sleep    30s
    Query Model Multiple Times    inference_type=all-tokens    model_name=${flan_model_name}
    ...    n_times=1    namespace=${test_namespace}    query_idx=${1}    protocol=http
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1    protocol=http
    ...    namespace=${test_namespace}    query_idx=${1}    validate_response=${FALSE}
    [Teardown]    Clean Up DSP Page

Verify User Can Serve And Query Flan-t5 Large Using The UI  # robocop: disable
    [Documentation]    Deploys and queries flan-t5-large model
    [Tags]    Tier2    ODS-2554
    [Setup]    Set Up Project    namespace=flan-t5-large3
    ${test_namespace}=    Set Variable     flan-t5-large3
    ${flan_model_name}=    Set Variable    flan-t5-large
    Deploy Kserve Model Via UI    ${flan_model_name}    Caikit
    ...    kserve-connection    flan-t5-large/flan-t5-large
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Sleep    30s
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}    protocol=http
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}    protocol=http    validate_response=${FALSE}
    [Teardown]    Clean Up DSP Page

Verify User Can Access Model Metrics From UWM Using The UI  # robocop: disable
    [Documentation]    Verifies that model metrics are available for users in the
    ...                OpenShift monitoring system (UserWorkloadMonitoring)
    ...                PARTIALLY DONE: it is checking number of requests, number of successful requests
    ...                and model pod cpu usage. Waiting for a complete list of expected metrics and
    ...                derived metrics.
    [Tags]    Smoke    Tier1    ODS-2555
    [Setup]    Set Up Project   namespace=singlemodel-metrics    enable_metrics=${TRUE}
    ${test_namespace}=    Set Variable     singlemodel-metrics
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${thanos_url}=    Get OpenShift Thanos URL
    ${token}=    Generate Thanos Token
    Deploy Kserve Model Via UI    ${flan_model_name}    Caikit    kserve-connection    flan-t5-small/${flan_model_name}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Wait Until Keyword Succeeds    30 times    4s
    ...    TGI Caikit And Istio Metrics Should Exist    thanos_url=${thanos_url}    thanos_token=${token}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=3
    ...    namespace=${test_namespace}   protocol=http
    Wait Until Keyword Succeeds    50 times    5s
    ...    User Can Fetch Number Of Requests Over Defined Time    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    query_kind=single    namespace=${test_namespace}    period=5m    exp_value=3
    Wait Until Keyword Succeeds    20 times    5s
    ...    User Can Fetch Number Of Successful Requests Over Defined Time    thanos_url=${thanos_url}
    ...    thanos_token=${token}    model_name=${flan_model_name}    namespace=${test_namespace}    period=5m
    ...    exp_value=3
    Wait Until Keyword Succeeds    20 times    5s
    ...    User Can Fetch CPU Utilization    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    namespace=${test_namespace}    period=5m
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}    protocol=http    validate_response=${FALSE}
    Wait Until Keyword Succeeds    30 times    5s
    ...    User Can Fetch Number Of Requests Over Defined Time    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    query_kind=stream    namespace=${test_namespace}    period=5m    exp_value=1
    [Teardown]    Clean Up DSP Page

Verify User With Edit Permission Can Deploy Query And Delete A LLM
    [Documentation]    This test case verifies that a user with Edit permission on a DS Project can still deploy, query
    ...    and delete a LLM served with caikit
    ...    ProductBug: https://issues.redhat.com/browse/RHOAIENG-548
    [Tags]    Sanity    Tier1    ODS-2581    ProductBug
    [Setup]    Set Up Project    namespace=${TEST_NS}-edit-permission
    ${test_namespace}=    Set Variable     ${TEST_NS}-edit-permission
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    Move To Tab    Permissions
    Assign Edit Permissions To User ${TEST_USER_3.USERNAME}
    Move To Tab    Components
    Logout From RHODS Dashboard
    Login To RHODS Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}
    Wait for RHODS Dashboard to Load    expected_page=${test_namespace}    wait_for_cards=${FALSE}
    Run Keyword And Continue On Failure    Deploy Kserve Model Via UI    ${flan_model_name}    Caikit    kserve-connection    flan-t5-small/${flan_model_name}
    # Needed because of ProductBug
    ${modal} =    Run Keyword And Return Status    Page Should Contain Element    xpath=${KSERVE_MODAL_HEADER}
    IF  ${modal}==${TRUE}
        Click Element    //button[@aria-label="Close"]
    END
    Run Keyword And Continue On Failure    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Run Keyword And Continue On Failure    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    protocol=http
    Run Keyword And Continue On Failure    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    protocol=http    validate_response=${FALSE}
    Run Keyword And Continue On Failure    Delete Model Via UI    ${flan_model_name}
    Logout From RHODS Dashboard
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load    expected_page=${test_namespace}    wait_for_cards=${FALSE}
    [Teardown]    Clean Up DSP Page

Verify User With Admin Permission Can Deploy Query And Delete A LLM
    [Documentation]    This test case verifies that a user with Admin permission on a DS Project can still deploy, query
    ...    and delete a LLM served with caikit
    [Tags]    Sanity    Tier1    ODS-2582
    [Setup]    Set Up Project    namespace=${TEST_NS}-admin-permission
    ${test_namespace}=    Set Variable     ${TEST_NS}-admin-permission
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    Move To Tab    Permissions
    Assign Admin Permissions To User ${TEST_USER_3.USERNAME}
    Move To Tab    Components
    Logout From RHODS Dashboard
    Login To RHODS Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}
    Wait for RHODS Dashboard to Load    expected_page=${test_namespace}    wait_for_cards=${FALSE}
    Deploy Kserve Model Via UI    ${flan_model_name}    Caikit    kserve-connection    flan-t5-small/${flan_model_name}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    protocol=http    validate_response=${FALSE}
    Delete Model Via UI    ${flan_model_name}
    Logout From RHODS Dashboard
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load    expected_page=${test_namespace}    wait_for_cards=${FALSE}
    [Teardown]    Clean Up DSP Page


*** Keywords ***
Setup Kserve UI Test
    [Documentation]    Instaling And Configuring dependency operators: Service Mesh and Serverless.
    ...                This is likely going to change in the future and it will include a way to skip installation.
    ...                Caikit runtime will be shipped Out-of-the-box and will be removed from here.
    [Arguments]    ${user}=${TEST_USER.USERNAME}    ${pw}=${TEST_USER.PASSWORD}    ${auth}=${TEST_USER.AUTH_TYPE}
    Set Library Search Order  SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Load Expected Responses
    Launch Dashboard    ${user}    ${pw}    ${auth}    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Fetch CA Certificate If RHODS Is Self-Managed
