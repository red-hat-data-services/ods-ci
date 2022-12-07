*** Settings ***
Documentation       Test suite testing SERH Metrics
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown


*** Variables ***
@{serh_querys}   node_namespace_pod_container:container_memory_working_set_bytes{namespace="redhat-starburst-operator"}
                ...  node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{namespace="redhat-starburst-operator"}
                ...  namespace_workload_pod:kube_pod_owner:relabel{namespace="redhat-starburst-operator"}
                ...  kube_pod_container_info{namespace="redhat-starburst-operator"}
                ...  kube_pod_status_ready{namespace="redhat-starburst-operator"}
                ...  kube_namespace_status_phase{namespace="redhat-starburst-operator"}
                ...  kube_pod_container_status_last_terminated_reason{namespace="redhat-starburst-operator"}
                ...  kube_pod_container_status_waiting{namespace="redhat-starburst-operator"}
                ...  kube_service_info{namespace="redhat-starburst-operator"}
                ...  cluster:namespace:pod_memory:active:kube_pod_container_resource_limits{namespace="redhat-starburst-operator"}
                ...  container_cpu_cfs_throttled_seconds_total{namespace="redhat-starburst-operator"}
                ...  container_fs_usage_bytes{namespace="redhat-starburst-operator"}
                ...  container_network_transmit_bytes_total{namespace="redhat-starburst-operator"}
                ...  kube_pod_container_resource_requests{namespace="redhat-starburst-operator"}
                ...  container_memory_usage_bytes{namespace="redhat-starburst-operator"}
                ...  container_network_receive_bytes_total{namespace="redhat-starburst-operator"}
                ...  kube_deployment_status_replicas_available{namespace="redhat-starburst-operator"}
                ...  kube_deployment_status_replicas_unavailable{namespace="redhat-starburst-operator"}
                ...  kube_persistentvolumeclaim_status_phase{namespace="redhat-starburst-operator"}
                ...  kube_pod_container_resource_limits{namespace="redhat-starburst-operator"}
                ...  cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits{namespace="redhat-starburst-operator"}
                ...  container_network_receive_packets_total{namespace="redhat-starburst-operator"}
                ...  container_network_transmit_packets_total{namespace="redhat-starburst-operator"}
                ...  kube_running_pod_ready{namespace="redhat-starburst-operator"}
                ...  container_cpu_usage_seconds_total{namespace="redhat-starburst-operator"}
                ...  kube_pod_container_status_restarts_total{namespace="redhat-starburst-operator"}
                ...  kube_pod_status_phase{namespace="redhat-starburst-operator"}
                ...  cluster:namespace:pod_memory:active:kube_pod_container_resource_requests{namespace="redhat-starburst-operator"}
                ...  jmx_config_reload_success_total{namespace="redhat-starburst-operator"}
                ...  jmx_scrape_duration_seconds{namespace="redhat-starburst-operator"}
                ...  jmx_scrape_cached_beans{namespace="redhat-starburst-operator"}
                ...  jmx_scrape_error{namespace="redhat-starburst-operator"}
                ...  jmx_exporter_build_info{namespace="redhat-starburst-operator"}
                ...  jmx_config_reload_failure_total{namespace="redhat-starburst-operator"}
                ...  jmx_config_reload_failure_created{namespace="redhat-starburst-operator"}
                ...  jmx_config_reload_success_created{namespace="redhat-starburst-operator"}
                ...  jvm_threads_current{namespace="redhat-starburst-operator"}
                ...  jvm_threads_daemon{namespace="redhat-starburst-operator"}
                ...  jvm_threads_peak{namespace="redhat-starburst-operator"}
                ...  jvm_threads_started_total{namespace="redhat-starburst-operator"}
                ...  jvm_threads_deadlocked{namespace="redhat-starburst-operator"}
                ...  jvm_threads_deadlocked_monitor{namespace="redhat-starburst-operator"}
                ...  jvm_threads_state{namespace="redhat-starburst-operator"}
                ...  jvm_buffer_pool_used_bytes{namespace="redhat-starburst-operator"}
                ...  jvm_buffer_pool_capacity_bytes{namespace="redhat-starburst-operator"}
                ...  jvm_buffer_pool_used_buffers{namespace="redhat-starburst-operator"}
                ...  jvm_info{namespace="redhat-starburst-operator"}
                ...  jvm_heap_memory_used{namespace="redhat-starburst-operator"}
                ...  jvm_heap_memory_commited{namespace="redhat-starburst-operator"}
                ...  jvm_memory_pool_allocated_bytes_total{namespace="redhat-starburst-operator"}
                ...  jvm_memory_bytes_used{namespace="redhat-starburst-operator"}
                ...  jvm_memory_bytes_committed{namespace="redhat-starburst-operator"}
                ...  jvm_memory_bytes_max{namespace="redhat-starburst-operator"}
                ...  jvm_memory_bytes_init{namespace="redhat-starburst-operator"}
                ...  jvm_memory_pool_bytes_used{namespace="redhat-starburst-operator"}
                ...  jvm_memory_pool_bytes_committed{namespace="redhat-starburst-operator"}
                ...  jvm_memory_pool_bytes_max{namespace="redhat-starburst-operator"}
                ...  jvm_memory_pool_bytes_init{namespace="redhat-starburst-operator"}
                ...  jvm_classes_loaded{namespace="redhat-starburst-operator"}
                ...  jvm_classes_loaded_total{namespace="redhat-starburst-operator"}
                ...  jvm_classes_unloaded_total{namespace="redhat-starburst-operator"}
                ...  jvm_gc_collection_seconds_count{namespace="redhat-starburst-operator"}
                ...  jvm_gc_collection_seconds_sum{namespace="redhat-starburst-operator"}
                ...  jvm_memory_pool_allocated_bytes_created{namespace="redhat-starburst-operator"}
                ...  failed_queries{namespace="redhat-starburst-operator"}
                ...  thread_count{namespace="redhat-starburst-operator"}
                ...  trino_active_nodes{namespace="redhat-starburst-operator"}
                ...  trino_free_memory{namespace="redhat-starburst-operator"}
                ...  queries_killed_oom{namespace="redhat-starburst-operator"}
                ...  trino_active_queries{namespace="redhat-starburst-operator"}
                ...  trino_queries_started{namespace="redhat-starburst-operator"}
                ...  trino_queries_failed_external{namespace="redhat-starburst-operator"}
                ...  trino_queries_failed_internal{namespace="redhat-starburst-operator"}
                ...  trino_queries_failed_all{namespace="redhat-starburst-operator"}
                ...  trino_failed_queries_user{namespace="redhat-starburst-operator"}
                ...  trino_execution_latency{namespace="redhat-starburst-operator"}
                ...  trino_input_data_rate{namespace="redhat-starburst-operator"}
                ...  input_data_bytes{namespace="redhat-starburst-operator"}
                ...  input_rows{namespace="redhat-starburst-operator"}
                ...  cluster_memory_bytes{namespace="redhat-starburst-operator"}
                ...  tasks_killed_oom{namespace="redhat-starburst-operator"}
                ...  kube_node_status_capacity{resource="cpu"}
                ...  node_namespace_pod:kube_pod_info:{namespace="redhat-starburst-operator"}


*** Test Cases ***
Verify Query And Check Values Are Not Empty
    [Documentation]    Verifies the Observatorium metrics values are not none
    [Tags]    MISV-94
    ${SSO_TOKEN}    Get Observatorium Token
    Run Query And Check Values Are Not Empty   ${SSO_TOKEN}


*** Keywords ***
Run Query And Check Values Are Not Empty
    [Documentation]  Run query and and check if Values Are Not Empty
    [Arguments]     ${SSO_TOKEN}
    FOR  ${query}   IN   @{serh_querys}
        ${obs_query_op}=    Prometheus.Run Query    ${STARBURST.OBS_URL}    ${SSO_TOKEN}
        ...   ${query}   project=SERH
        Run Keyword And Continue On Failure    Should Be Equal    ${obs_query_op.json()['status']}    success
        Run Keyword And Continue On Failure    Should Not Be Empty    ${obs_query_op.json()['data']['result']}
        FOR  ${data}    IN   @{obs_query_op.json()['data']['result']}
            Run Keyword And Continue On Failure    Should Not Be Empty    ${data['value']}
            Run Keyword And Continue On Failure    Should Not Be Equal    ${data['value'][0]}    ${EMPTY}
            Run Keyword And Continue On Failure    Should Not Be Equal    ${data['value'][1]}    ${EMPTY}
            Run Keyword And Continue On Failure    Should Not Be Equal    ${data['value'][0]}    ${NONE}
            Run Keyword And Continue On Failure    Should Not Be Equal    ${data['value'][1]}    ${NONE}
            Log    ${data['metric']['__name__']} |${data['metric']['pod']}| ${data['value']}
        END
    END
