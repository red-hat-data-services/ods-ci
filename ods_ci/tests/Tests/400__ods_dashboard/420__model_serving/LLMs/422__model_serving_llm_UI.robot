*** Settings ***
Documentation     Collection of UI tests to validate the model serving stack for Large Language Models (LLM)
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
# ${CAIKIT_ALLTOKENS_ENDPOINT}=    caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict  # grpc - not supported
# ${CAIKIT_STREAM_ENDPOINT}=    caikit.runtime.Nlp.NlpService/ServerStreamingTextGenerationTaskPredict  # grpc
${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}=    api/v1/task/text-generation
${CAIKIT_STREAM_ENDPOINT_HTTP}=    api/v1/task/server-streaming-text-generation


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
    ...    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    n_times=1
    ...    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    endpoint=${CAIKIT_STREAM_ENDPOINT_HTTP}    n_times=1    streamed_response=${TRUE}
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
    Query Model Multiple Times    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    model_name=${model_one_name}
    ...    n_times=5    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    model_name=${model_two_name}
    ...    n_times=10    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    endpoint=${CAIKIT_STREAM_ENDPOINT_HTTP}    model_name=${model_one_name}
    ...    n_times=5    namespace=${test_namespace}    protocol=http    validate_response=${FALSE}
    Query Model Multiple Times    endpoint=${CAIKIT_STREAM_ENDPOINT_HTTP}    model_name=${model_two_name}
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
    Query Model Multiple Times    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    model_name=${model_one_name}
    ...    n_times=2    namespace=singlemodel-multi1    protocol=http
    Open Data Science Projects Home Page
    Set Up Project    namespace=singlemodel-multi2    single_prj=${FALSE}    dc_name=kserve-connection-2
    Deploy Kserve Model Via UI    ${model_two_name}    Caikit    kserve-connection-2
    ...    flan-t5-small/${model_two_name}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_two_name}
    ...    namespace=singlemodel-multi2
    Query Model Multiple Times    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    model_name=${model_two_name}
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
    Query Model Multiple Times    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    model_name=${flan_model_name}
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
    ...    namespace=${test_namespace}    endpoint=${CAIKIT_STREAM_ENDPOINT_HTTP}
    ...    streamed_response=${TRUE}    validate_response=${FALSE}    protocol=http
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
    ...    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    n_times=1
    ...    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    endpoint=${CAIKIT_STREAM_ENDPOINT_HTTP}    n_times=1    streamed_response=${TRUE}
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
    Query Model Multiple Times    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    model_name=${flan_model_name}
    ...    n_times=1    namespace=${test_namespace}    query_idx=${1}    protocol=http
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    endpoint=${CAIKIT_STREAM_ENDPOINT_HTTP}    n_times=1    streamed_response=${TRUE}    protocol=http
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
    ...    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}    protocol=http
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    endpoint=${CAIKIT_STREAM_ENDPOINT_HTTP}    n_times=1    streamed_response=${TRUE}
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
    ...    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    n_times=3
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
    ...    endpoint=${CAIKIT_STREAM_ENDPOINT_HTTP}    n_times=1    streamed_response=${TRUE}
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
    ...    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    n_times=1
    ...    namespace=${test_namespace}    protocol=http
    Run Keyword And Continue On Failure    Query Model Multiple Times    model_name=${flan_model_name}
    ...    endpoint=${CAIKIT_STREAM_ENDPOINT_HTTP}    n_times=1    streamed_response=${TRUE}
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
    ...    endpoint=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    n_times=1
    ...    namespace=${test_namespace}    protocol=http
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    endpoint=${CAIKIT_STREAM_ENDPOINT_HTTP}    n_times=1    streamed_response=${TRUE}
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

Load Expected Responses
    [Documentation]    Loads the json file containing the expected answer for each
    ...                query and model
    ${exp_responses}=    Load Json File    ${EXP_RESPONSES_FILEPATH}
    Set Suite Variable    ${EXP_RESPONSES}    ${exp_responses}

Model Response Should Match The Expectation  # robocop: disable
    [Documentation]    Checks that the actual model response matches the expected answer.
    ...                The goals are:
    ...                   - to ensure we are getting an answer from the model (e.g., not an empty text)
    ...                   - to check that we receive the answer from the right model
    ...                when multiple ones are deployed
    [Arguments]    ${model_response}    ${model_name}    ${query_idx}    ${streamed_response}=${FALSE}
    IF    ${streamed_response} == ${FALSE}
        Should Be Equal As Integers    ${model_response}[generated_tokens]
        ...    ${EXP_RESPONSES}[queries][${query_idx}][models][${model_name}][generatedTokenCount]
        ${cleaned_response_text}=    Replace String Using Regexp
        ...    ${model_response}[generated_text]    \\s+    ${SPACE}
        ${cleaned_exp_response_text}=    Replace String Using Regexp
        ...    ${EXP_RESPONSES}[queries][${query_idx}][models][${model_name}][response_text]    \\s+    ${SPACE}
        ${cleaned_response_text}=    Strip String    ${cleaned_response_text}
        ${cleaned_exp_response_text}=    Strip String    ${cleaned_exp_response_text}
        Should Be Equal    ${cleaned_response_text}    ${cleaned_exp_response_text}
    ELSE
        # temporarily disabling these lines - will be finalized in later stage due to a different format
        # of streamed reponse when using http protocol instead of grpc
        # ${cleaned_response_text}=    Replace String Using Regexp    ${model_response}    data:(\\s+)?"    "
        # ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    data:(\\s+)?{    {
        # ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    data:(\\s+)?}    }
        # ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    data:(\\s+)?]    ]
        # ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    data:(\\s+)?\\[    [
        ${cleaned_response_text}=    Replace String Using Regexp    ${model_response}    \\s+    ${EMPTY}
        ${rc}    ${cleaned_response_text}=    Run And Return Rc And Output    echo -e '${cleaned_response_text}'
        ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    "    '
        ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}
        ...    [-]?\\d.\\d+[e]?[-]?\\d+    <logprob_removed>
        Log    ${cleaned_response_text}
        ${cleaned_exp_response_text}=    Replace String Using Regexp
        ...    ${EXP_RESPONSES}[queries][${query_idx}][models][${model_name}][streamed_response_text]
        ...    [-]?\\d.\\d+[e]?[-]?\\d+    <logprob_removed>
        ${cleaned_exp_response_text}=    Replace String Using Regexp    ${cleaned_exp_response_text}    \\s+    ${EMPTY}
        Should Be Equal    ${cleaned_response_text}    ${cleaned_exp_response_text}
    END

Query Model Multiple Times  # robocop: disable
    [Documentation]    Queries and checks the responses of the given models in a loop
    ...                running ${n_times}. For each loop run it queries all the model in sequence
    [Arguments]    ${model_name}    ${namespace}    ${isvc_name}=${model_name}
    ...            ${endpoint}=${CAIKIT_ALLTOKENS_ENDPOINT_HTTP}    ${n_times}=10
    ...            ${streamed_response}=${FALSE}    ${query_idx}=0    ${validate_response}=${TRUE}
    ...            ${protocol}=grpc    &{args}
    IF    ${validate_response} == ${FALSE}
        ${skip_json_load_response}=    Set Variable    ${TRUE}
    ELSE
        ${skip_json_load_response}=    Set Variable    ${streamed_response}    # always skip if using streaming endpoint
    END
    ${host}=    Get Kserve Inference Host Via UI    ${model_name}
    IF    "${protocol}" == "grpc"
        ${body}=    Set Variable    '{"text": "${EXP_RESPONSES}[queries][${query_idx}][query_text]"}'
        ${header}=    Set Variable    'mm-model-id: ${model_name}'
    ELSE IF    "${protocol}" == "http"
        ${body}=    Set Variable
        ...    {"model_id": "${model_name}","inputs": "${EXP_RESPONSES}[queries][${query_idx}][query_text]"}
        ${headers}=    Create Dictionary     Cookie=${EMPTY}    Content-type=application/json
    ELSE
        Fail    msg=The ${protocol} protocol is not supported by ods-ci. Please use either grpc or http.
    END
    FOR    ${counter}    IN RANGE    0    ${n_times}    1
        Log    ${counter}
        IF    "${protocol}" == "grpc"
            ${res}=    Query Model With GRPCURL   host=${host}    port=443
            ...    endpoint=${endpoint}
            ...    json_body=${body}    json_header=${header}
            ...    insecure=${TRUE}    skip_res_json=${skip_json_load_response}
            ...    &{args}
        ELSE IF    "${protocol}" == "http"
            ${payload}=     Prepare Payload     body=${body}    str_to_json=${TRUE}
            &{args}=       Create Dictionary     url=${host}:443/${endpoint}   expected_status=any
            ...             headers=${headers}   json=${payload}    timeout=10  verify=${False}
            ${res}=    Run Keyword And Continue On Failure     Perform Request     request_type=POST
            ...    skip_res_json=${skip_json_load_response}    &{args}
            Run Keyword And Continue On Failure    Status Should Be  200
        END
        Log    ${res}
        IF    ${validate_response}
            Run Keyword And Continue On Failure
            ...    Model Response Should Match The Expectation    model_response=${res}    model_name=${model_name}
            ...    streamed_response=${streamed_response}    query_idx=${query_idx}
        END
    END

# Upgrade Caikit Runtime Image
#     [Documentation]    Replaces the image URL of the Caikit Runtim with the given
#     ...    ${new_image_url}
#     [Arguments]    ${new_image_url}    ${namespace}
#     ${rc}    ${out}=    Run And Return Rc And Output
#     ...    oc patch ServingRuntime caikit-tgis-runtime -n ${namespace} --type=json -p="[{'op': 'replace', 'path': '/spec/containers/0/image', 'value': '${new_image_url}'}]"    # robocop: disable
#     Should Be Equal As Integers    ${rc}    ${0}

# Get Model Pods Creation Date And Image URL
#     [Documentation]    Fetches the creation date and the caikit runtime image URL.
#     ...                Useful in upgrade scenarios
#     [Arguments]    ${model_name}    ${namespace}
#     ${created_at}=    Oc Get    kind=Pod    label_selector=serving.kserve.io/inferenceservice=${model_name}
#     ...    namespace=${namespace}    fields=["metadata.creationTimestamp"]
#     ${rc}    ${caikitsha}=    Run And Return Rc And Output
#     ...    oc get pod --selector serving.kserve.io/inferenceservice=${model_name} -n ${namespace} -ojson | jq '.items[].spec.containers[].image' | grep caikit-tgis    # robocop: disable
#     Should Be Equal As Integers    ${rc}    ${0}
#     RETURN    ${created_at}    ${caikitsha}

User Can Fetch Number Of Requests Over Defined Time  # robocop: disable
    [Documentation]    Fetches the `tgi_request_count` metric and checks that it reports the expected
    ...                model information (name, namespace, pod name and type of request).
    ...                If ${exp_value} is given, it checks also the metric value
    [Arguments]    ${thanos_url}    ${thanos_token}    ${model_name}    ${namespace}
    ...           ${query_kind}=single    ${period}=30m    ${exp_value}=${EMPTY}
    ${resp}=    Prometheus.Run Query    https://${thanos_url}    ${thanos_token}    tgi_request_count[${period}]
    Log    ${resp.json()["data"]}
    Check Query Response Values    response=${resp}    exp_namespace=${namespace}
    ...    exp_model_name=${model_name}    exp_query_kind=${query_kind}    exp_value=${exp_value}

User Can Fetch Number Of Successful Requests Over Defined Time  # robocop: disable
    [Documentation]    Fetches the `tgi_request_success` metric and checks that it reports the expected
    ...                model information (name, namespace and type of request).
    ...                If ${exp_value} is given, it checks also the metric value
    [Arguments]    ${thanos_url}    ${thanos_token}    ${model_name}    ${namespace}
    ...            ${query_kind}=single    ${period}=30m    ${exp_value}=${EMPTY}
    ${resp}=    Prometheus.Run Query    https://${thanos_url}    ${thanos_token}    tgi_request_success[${period}]
    Log    ${resp.json()["data"]}
    Check Query Response Values    response=${resp}    exp_namespace=${namespace}
    ...    exp_model_name=${model_name}    exp_query_kind=${query_kind}    exp_value=${exp_value}

User Can Fetch CPU Utilization  # robocop: disable
    [Documentation]    Fetches the `pod:container_cpu_usage:sum` metric and checks that it reports the expected
    ...                model information (pod name and namespace).
    ...                If ${exp_value} is given, it checks also the metric value
    [Arguments]    ${thanos_url}    ${thanos_token}    ${namespace}    ${model_name}
    ...    ${period}=30m    ${exp_value}=${EMPTY}
    ${resp}=    Prometheus.Run Query    https://${thanos_url}    ${thanos_token}
    ...    pod:container_cpu_usage:sum{namespace="${namespace}"}[${period}]
    ${pod_name}=    Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    fields=['metadata.name']
    Log    ${resp.json()["data"]}
    Check Query Response Values    response=${resp}    exp_namespace=${namespace}
    ...    exp_pod_name=${pod_name}[0][metadata.name]    exp_value=${exp_value}

TGI Caikit And Istio Metrics Should Exist
    [Documentation]    Checks that the `tgi_`, `caikit_` and `istio_` metrics exist.
    ...                Returns the list of metrics names
    [Arguments]    ${thanos_url}    ${thanos_token}
    ${tgi_metrics_names}=    Get Thanos Metrics List    thanos_url=${thanos_url}    thanos_token=${thanos_token}
    ...    search_text=tgi
    Should Not Be Empty    ${tgi_metrics_names}
    ${tgi_metrics_names}=    Split To Lines    ${tgi_metrics_names}
    ${caikit_metrics_names}=    Get Thanos Metrics List    thanos_url=${thanos_url}    thanos_token=${thanos_token}
    ...    search_text=caikit
    ${caikit_metrics_names}=    Split To Lines    ${caikit_metrics_names}
    ${istio_metrics_names}=    Get Thanos Metrics List    thanos_url=${thanos_url}    thanos_token=${thanos_token}
    ...    search_text=istio
    ${istio_metrics_names}=    Split To Lines    ${istio_metrics_names}
    ${metrics}=    Append To List    ${tgi_metrics_names}    @{caikit_metrics_names}    @{istio_metrics_names}
    RETURN    ${metrics}

Check Query Response Values    # robocop:disable
    [Documentation]    Implements the metric checks for `User Can Fetch Number Of Requests Over Defined Time`
    ...                `User Can Fetch Number Of Successful Requests Over Defined Time` and `User Can Fetch CPU Utilization`.
    ...                It searches among the available metric values for the specific model
    [Arguments]    ${response}    ${exp_namespace}    ${exp_model_name}=${EMPTY}
    ...    ${exp_query_kind}=${EMPTY}    ${exp_value}=${EMPTY}    ${exp_pod_name}=${EMPTY}
    ${json_results}=    Set Variable    ${response.json()["data"]["result"]}
    FOR    ${index}    ${result}    IN ENUMERATE    @{json_results}
        Log    ${index}: ${result}
        ${value_keyname}=    Run Keyword And Return Status
        ...    Dictionary Should Contain Key    ${result}    value
        IF    ${value_keyname}
            ${curr_value}=    Set Variable    ${result["value"][-1]}
        ELSE
            ${curr_value}=    Set Variable    ${result["values"][-1][-1]}
        END
        ${source_namespace}=    Set Variable    ${result["metric"]["namespace"]}
        ${checked}=    Run Keyword And Return Status    Should Be Equal As Strings
        ...    ${source_namespace}    ${exp_namespace}
        IF    ${checked} == ${FALSE}
            CONTINUE
        ELSE
            Log    message=Metrics source namespaced succesfully checked. Going to next step.
        END
        IF    "${exp_model_name}" != "${EMPTY}"
            ${source_model}=    Set Variable    ${result["metric"]["job"]}
            ${checked}=    Run Keyword And Return Status    Should Be Equal As Strings    ${source_model}
            ...    ${exp_model_name}-metrics
            IF    ${checked} == ${FALSE}
                CONTINUE
            ELSE
                Log    message=Metrics source model succesfully checked. Going to next step.
            END
            IF    "${exp_query_kind}" != "${EMPTY}"
                ${source_query_kind}=    Set Variable    ${result["metric"]["kind"]}
                ${checked}=    Run Keyword And Return Status    Should Be Equal As Strings    ${source_query_kind}
                ...    ${exp_query_kind}
                IF    ${checked} == ${FALSE}
                    CONTINUE
                ELSE
                    Log    message=Metrics query kind succesfully checked. Going to next step.
                END
            END
        END
        IF    "${exp_pod_name}" != "${EMPTY}"
            ${source_pod}=    Set Variable    ${result["metric"]["pod"]}
            ${checked}=    Run Keyword And Return Status    Should Be Equal As Strings    ${source_pod}
            ...    ${exp_pod_name}
            IF    ${checked} == ${FALSE}
                CONTINUE
            ELSE
                Log    message=Metrics source pod succesfully checked. Going to next step.
            END
        END
        IF    "${exp_value}" != "${EMPTY}"
            Run Keyword And Continue On Failure    Should Be Equal As Strings    ${curr_value}    ${exp_value}
        ELSE
            Run Keyword And Continue On Failure    Should Not Be Empty    ${curr_value}
        END
        IF    ${checked}
            Log    message=The desired query result has been found.
            Exit For Loop
        END
    END
    IF    ${checked} == ${FALSE}
        Fail    msg=The metric you are looking for has not been found. Check the query parameter and try again
    END
