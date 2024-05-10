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
${INFERENCE_INPUT}=           @${VLLM_RESOURCES_DIRPATH}/query.json
${INFERENCE_URL}=             http://localhost:8080/v1/chat/completions
${METRICS_URL}=               http://localhost:8080/metrics/
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
...                           vllm:avg_prompt_throughput_toks_per_s
...                           vllm:avg_generation_throughput_toks_per_s


*** Test Cases ***
Verify User Can Deploy A Model With Vllm Via CLI
    [Documentation]    Deploy a model (gpt2) using the vllm runtime and confirm that it's running
    [Tags]    Tier1    Sanity    Resources-GPU    ODS-XXX
    ${rc}    ${out}=    Run And Return Rc And Output    oc apply -f ${DL_POD_FILEPATH}
    Should Be Equal As Integers    ${rc}    ${0}
    Wait For Pods To Succeed    label_selector=gpt-download-pod=true    namespace=${TEST_NS}
    ${rc}    ${out}=    Run And Return Rc And Output    oc apply -f ${SR_FILEPATH}
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output    oc apply -f ${IS_FILEPATH}
    Should Be Equal As Integers    ${rc}    ${0}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=vllm-gpt2-openai
    ...    namespace=${TEST_NS}
    ${pod_name}=  Get Pod Name    namespace=${TEST_NS}
    ...    label_selector=serving.kserve.io/inferenceservice=vllm-gpt2-openai
    Start Port-forwarding    namespace=${TEST_NS}    pod_name=${pod_name}    local_port=8080   remote_port=8080
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    curl -ks ${INFERENCE_URL} -H "Content-Type: application/json" -d ${INFERENCE_INPUT} | jq .
    Should Be Equal As Integers    ${rc}    ${0}
    Log    ${out}

Verify Vllm Metrics Are Present
    [Documentation]    Confirm vLLM metrics are exposed in OpenShift metrics
    [Tags]    Tier1    Sanity    Resources-GPU    ODS-XXX
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    curl -ks ${METRICS_URL}
    Should Be Equal As Integers    ${rc}    ${0}
    Log    ${out}
    ${thanos_url}=    Get OpenShift Thanos URL
    ${token}=    Generate Thanos Token
    Metrics Should Exist In UserWorkloadMonitoring    ${thanos_url}    ${token}    ${SEARCH_METRICS}


*** Keywords ***
Suite Setup
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Set Default Storage Class In GCP    default=ssd-csi
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    ${is_self_managed}
        Configure User Workload Monitoring
        Enable User Workload Monitoring
    END

Suite Teardown
    Set Default Storage Class In GCP    default=standard-csi
    Terminate Process    llm-query-process    kill=true
    ${rc}=    Run And Return Rc    oc delete inferenceservice -n ${TEST_NS} --all
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}=    Run And Return Rc    oc delete servingruntime -n ${TEST_NS} --all
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}=    Run And Return Rc    oc delete pod -n ${TEST_NS} --all
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}=    Run And Return Rc    oc delete namespace ${TEST_NS}
    Should Be Equal As Integers    ${rc}    ${0}
    RHOSi Teardown

Set Default Storage Class In GCP
    [Documentation]    If the storage class exists we can assume we are in GCP. We force ssd-csi to be the default class
    ...    for the duration of this test suite.
    [Arguments]    ${default}
    ${rc}=    Run And Return Rc    oc get storageclass ${default}
    IF    ${rc} == ${0}
        IF    "${default}" == "ssd-csi"
            Run    oc patch storageclass standard-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'  #robocop: disable
            Run    oc patch storageclass ssd-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'  #robocop: disable
        ELSE
            Run    oc patch storageclass ssd-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'  #robocop: disable
            Run    oc patch storageclass standard-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'  #robocop: disable
        END
    ELSE
        Log    Proceeding with default storage class because we're not in GCP
    END
