*** Settings ***
Documentation       Test suite testing SERH Metrics
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot


*** Variables ***
@{serh_querys}   node_namespace_pod_container:container_memory_working_set_bytes  node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate
                ...  namespace_workload_pod:kube_pod_owner:relabel  kube_pod_container_info  kube_pod_status_ready
                ...  kube_namespace_status_phase  node_namespace_pod:kube_pod_info  kube_pod_container_status_last_terminated_reason    kube_pod_container_status_waiting
                ...  kube_service_info   cluster:namespace:pod_memory:active:kube_pod_container_resource_limits  container_cpu_cfs_throttled_seconds_total
                ...  container_fs_usage_bytes  container_network_transmit_bytes_total  kube_pod_container_resource_requests    container_memory_usage_bytes
                ...  container_network_receive_bytes_total  kube_deployment_status_replicas_available  kube_node_status_capacity
                ...  kube_deployment_status_replicas_unavailable  kube_persistentvolumeclaim_status_phase  kube_pod_container_resource_limits
                ...  node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate  cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits
                ...  container_network_receive_packets_total  container_network_transmit_packets_total  kube_running_pod_ready
                ...  container_cpu_usage_seconds_total  kube_pod_container_status_restarts_total  kube_pod_status_phase  cluster:namespace:pod_memory:active:kube_pod_container_resource_requests
                ...  jmx_config_reload_success_total  jmx_scrape_duration_seconds  jmx_scrape_cached_beans  jmx_scrape_error
                ...  jmx_exporter_build_info  jmx_config_reload_failure_total
                ...  jmx_config_reload_failure_created  jmx_config_reload_success_created  jvm_threads_current  jvm_threads_daemon  jvm_threads_peak
                ...  jvm_threads_started_total  jvm_threads_deadlocked  jvm_threads_deadlocked_monitor  jvm_threads_state  jvm_buffer_pool_used_bytes
                ...  jvm_buffer_pool_capacity_bytes  jvm_buffer_pool_used_buffers  jvm_info  jvm_heap_memory_used  jvm_heap_memory_commited
                ...  jvm_memory_pool_allocated_bytes_total  jvm_memory_bytes_used  jvm_memory_bytes_committed  jvm_memory_bytes_max  jvm_memory_bytes_init
                ...  jvm_memory_pool_bytes_used  jvm_memory_pool_bytes_committed  jvm_memory_pool_bytes_max  jvm_memory_pool_bytes_init  jvm_classes_loaded
                ...  jvm_classes_loaded_total  jvm_classes_unloaded_total  jvm_gc_collection_seconds_count  jvm_gc_collection_seconds_sum
                ...  jvm_memory_pool_allocated_bytes_created  failed_queries  jvm_heap_memory_commited  jvm_heap_memory_used  thread_count  trino_active_nodes
                ...  trino_free_memory  queries_killed_oom  trino_active_queries  trino_queries_started  trino_queries_failed_external  trino_queries_failed_internal
                ...  trino_queries_failed_all  trino_failed_queries_user  trino_execution_latency  trino_input_data_rate  input_data_bytes  input_rows
                ...  cluster_memory_bytes  tasks_killed_oom


*** Test Cases ***
Verify STARBURST Query For Observatorium
    [Documentation]    Verifies the Observatorium metrics values are not none
    [Tags]    MISV-94
    ${SSO_TOKEN}    Prometheus.Get Observatorium Token
    @{value}=    Create List
    FOR  ${query}   IN   @{serh_querys}
        ${obs_query_op}=    Prometheus.Run Query    ${STARBURST.OBS_URL}    ${SSO_TOKEN}
        ...   ${query}{namespace="redhat-starburst-operator"}   project=SERH
        Should Be Equal    ${obs_query_op.json()['status']}    success
        FOR  ${data}    IN   @{obs_query_op.json()['data']['result']}
            Should Not Be Empty    ${data['value']}
            Length Should Be   ${data['value']}   ${2}

            Log  ${data['metric']['__name__']} |${data['metric']['pod']}| ${data['value']}
            Append To List  ${value}    ${data['value']}
        END
    END
    ${count}    Get Length    ${value}
    Should Be Equal   ${count}   ${1239}
