*** Settings ***
Documentation     Basic vLLM deploy test to validate metrics being correctly exposed in OpenShift
Resource          ../../../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../../../Resources/OCP.resource
Resource          ../../../../../Resources/Page/Operators/ISVs.resource
Resource          ../../../../../Resources/Page/ODH/ODHDashboard/ODHDashboardAPI.resource
Resource          ../../../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../../../Resources/CLI/ModelServing/llm.resource
Resource          ../../../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Permissions.resource
Library           OpenShiftLibrary
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Tags         KServe


*** Variables ***
${VLLM_RESOURCES_DIRPATH}=    ods_ci/tests/Resources/Files/llm/vllm
${DL_POD_FILEPATH}=           ${VLLM_RESOURCES_DIRPATH}/download_model.yaml
${SR_FILEPATH}=               ${VLLM_RESOURCES_DIRPATH}/vllm_servingruntime.yaml
${IS_FILEPATH}=               ${VLLM_RESOURCES_DIRPATH}/vllm-gpt2_inferenceservice.yaml
${TEST_NS}=                   vllm-gpt2
@{SEARCH_METRICS}=            vllm:cache_config_info
...                           vllm:num_requests_running
...                           vllm:num_requests_swapped
...                           vllm:num_requests_waiting
...                           vllm:gpu_cache_usage_perc
...                           vllm:cpu_cache_usage_perc
...                           vllm:prompt_tokens_total
...                           vllm:generation_tokens_total
...                           vllm:time_to_first_token_seconds_bucket
...                           vllm:time_to_first_token_seconds_count
...                           vllm:time_to_first_token_seconds_sum
...                           vllm:time_per_output_token_seconds_bucket
...                           vllm:time_per_output_token_seconds_count
...                           vllm:time_per_output_token_seconds_sum
...                           vllm:e2e_request_latency_seconds_bucket
...                           vllm:e2e_request_latency_seconds_count
...                           vllm:e2e_request_latency_seconds_sum
...                           vllm:request_prompt_tokens_bucket
...                           vllm:request_prompt_tokens_count
...                           vllm:request_prompt_tokens_sum
...                           vllm:request_generation_tokens_bucket
...                           vllm:request_generation_tokens_count
...                           vllm:request_generation_tokens_sum
...                           vllm:request_params_best_of_bucket
...                           vllm:request_params_best_of_count
...                           vllm:request_params_best_of_sum
...                           vllm:request_params_n_bucket
...                           vllm:request_params_n_count
...                           vllm:request_params_n_sum
...                           vllm:request_success_total
...                           vllm:avg_prompt_throughput_toks_per_s
...                           vllm:avg_generation_throughput_toks_per_s


*** Test Cases ***
Verify User Can Deploy A Model With Vllm Via CLI
    [Documentation]    Deploy a model (gpt2) using the vllm runtime and confirm that it's running
    [Tags]    Tier1    Sanity    Resources-GPU    RHOAIENG-6264   VLLM
    ${rc}    ${out}=    Run And Return Rc And Output    oc apply -f ${DL_POD_FILEPATH}
    Should Be Equal As Integers    ${rc}    ${0}
    Wait For Pods To Succeed    label_selector=gpt-download-pod=true    namespace=${TEST_NS}
    ${rc}    ${out}=    Run And Return Rc And Output    oc apply -f ${SR_FILEPATH}
    Should Be Equal As Integers    ${rc}    ${0}
    #TODO: Switch to common keyword for model DL and SR deploy
    #Set Project And Runtime    runtime=vllm     namespace=${TEST_NS}
    #...    download_in_pvc=${DOWNLOAD_IN_PVC}    model_name=gpt2
    #...    storage_size=10Gi
    Deploy Model Via CLI    ${IS_FILEPATH}    ${TEST_NS}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=vllm-gpt2-openai
    ...    namespace=${TEST_NS}
    # Disable response validation, keeps changing
    Query Model Multiple Times    model_name=gpt2    isvc_name=vllm-gpt2-openai    runtime=vllm-runtime   protocol=http
    ...    inference_type=chat-completions    n_times=3    query_idx=8
    ...    namespace=${TEST_NS}    string_check_only=${TRUE}    validate_response=${FALSE}

Verify Vllm Metrics Are Present
    [Documentation]    Confirm vLLM metrics are exposed in OpenShift metrics
    [Tags]    Tier1    Sanity    Resources-GPU    RHOAIENG-6264    VLLM
    Depends On Test    Verify User Can Deploy A Model With Vllm Via CLI
    ${host}=    llm.Get KServe Inference Host Via CLI    isvc_name=vllm-gpt2-openai    namespace=${TEST_NS}
    ${rc}    ${out}=    Run And Return Rc And Output    curl -ks https://${host}/metrics/
    Should Be Equal As Integers    ${rc}    ${0}
    Log    ${out}
    ${thanos_url}=    Get OpenShift Thanos URL
    Set Suite Variable    ${thanos_url}
    ${token}=    Generate Thanos Token
    Set Suite Variable    ${token}
    Metrics Should Exist In UserWorkloadMonitoring    ${thanos_url}    ${token}    ${SEARCH_METRICS}

Verify Vllm Metrics Values Match Between UWM And Endpoint
    [Documentation]  Confirm the values returned by UWM and by the model endpoint match for each metric
    [Tags]    Tier1    Sanity    Resources-GPU    RHOAIENG-6264    RHOAIENG-7687    VLLM
    Depends On Test    Verify User Can Deploy A Model With Vllm Via CLI
    Depends On Test    Verify Vllm Metrics Are Present
    ${host}=    llm.Get KServe Inference Host Via CLI    isvc_name=vllm-gpt2-openai    namespace=${TEST_NS}
    ${metrics_endpoint}=    Get Vllm Metrics And Values    https://${host}/metrics/
    FOR    ${index}    ${item}    IN ENUMERATE    @{metrics_endpoint}
        ${metric} =    Set Variable    ${item}[0]
        ${value} =    Set Variable    ${item}[1]
        ${resp} =    Prometheus.Run Query    https://${thanos_url}    ${token}    ${metric}
        Log    ${resp.json()["data"]}
        Run Keyword And Warn On Failure
        ...    Should Be Equal As Numbers    ${value}    ${resp.json()["data"]["result"][0]["value"][1]}
    END


*** Keywords ***
Suite Setup
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Set Default Storage Class In GCP    default=ssd-csi
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    ${is_self_managed}
        Configure User Workload Monitoring
        Enable User Workload Monitoring
        #TODO: Find reliable signal for UWM being ready
        #Sleep    10m
    END
    Load Expected Responses

Suite Teardown
    Set Default Storage Class In GCP    default=standard-csi
    ${rc}=    Run And Return Rc    oc delete inferenceservice -n ${TEST_NS} --all
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}=    Run And Return Rc    oc delete servingruntime -n ${TEST_NS} --all
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}=    Run And Return Rc    oc delete pod -n ${TEST_NS} --all
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}=    Run And Return Rc    oc delete namespace ${TEST_NS}
    Should Be Equal As Integers    ${rc}    ${0}
    RHOSi Teardown
