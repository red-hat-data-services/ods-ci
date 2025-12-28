*** Settings ***
Library           OperatingSystem

*** Keywords ***
Create GPU Node In Self Managed AWS Cluster
    [Documentation]    Create GPU node(s) in self-managed AWS cluster. For backward compatibility, defaults to 1 node.
    [Arguments]    ${instance_type}=g4dn.xlarge    ${gpu_node_count}=1
    Set Log Level    Info
    ${gpu_node} =    Run Process    sh    tasks/Resources/Provisioning/GPU/provision-gpu.sh
    ...    ${instance_type}
    ...    AWS
    ...    1
    ...    ${gpu_node_count}
    Should Be Equal As Integers    ${gpu_node.rc}    0
    ...    msg=AWS GPU node provisioning failed: ${gpu_node.stdout} ${gpu_node.stderr}
    Log    AWS GPU node provisioning completed: ${gpu_node.stdout}    console=True

Delete GPU Node In Self Managed AWS Cluster
    ${gpu_nodes} =    Oc Get    kind=Machine    label_selector=machine.openshift.io/instance-type=g4dn.xlarge
    Log    ${gpu_nodes[0]['metadata']['name']}    console=True
    Run And Return Rc    oc annotate machine/${gpu_nodes[0]['metadata']['name']} -n openshift-machine-api machine.openshift.io/cluster-api-delete-machine="true"
    Run And Return Rc    oc adm cordon ${gpu_nodes[0]['metadata']['name']}
    Run And Return Rc    oc adm drain ${gpu_nodes[0]['metadata']['name']} --ignore-daemonsets --delete-local-data
    ${gpu_machineset} =    Oc Get    kind=MachineSet    label_selector=gpu-machineset=true
    Run And Return Rc    oc scale --replicas=0 machineset/${gpu_machineset[0]['metadata']['name']} -n openshift-machine-api

Create GPU Nodes
    [Documentation]    Create GPU nodes in both managed and self-managed clusters.
    ...    Parameters: cluster_type (managed/self-managed), instance_type (g4dn.xlarge),
    ...    provider (AWS/GCP/AZURE/IBM), gpu_node_count (1), gpu_count (1), cluster_name (for managed).
    [Arguments]    ${cluster_type}=self-managed
    ...    ${instance_type}=g4dn.xlarge
    ...    ${provider}=AWS
    ...    ${gpu_node_count}=1
    ...    ${gpu_count}=1
    ...    ${cluster_name}=${EMPTY}
    Set Log Level    Info

    IF    '${cluster_type}' == 'managed'
        Create GPU Nodes For Managed Cluster    ${cluster_name}    ${instance_type}    ${gpu_node_count}
    ELSE IF    '${cluster_type}' == 'self-managed'
        Create GPU Nodes For Self Managed Cluster    ${instance_type}    ${provider}    ${gpu_node_count}    ${gpu_count}
    ELSE
        Fail    Invalid cluster_type: ${cluster_type}. Must be 'managed' or 'self-managed'
    END

Create GPU Nodes For Managed Cluster
    [Documentation]    Create GPU machine pool for managed cluster using OCM
    [Arguments]    ${cluster_name}    ${instance_type}    ${gpu_node_count}

    IF    '${cluster_name}' == '${EMPTY}'
        Fail    cluster_name is required for managed clusters
    END

    # Generate unique pool name with timestamp
    ${timestamp} =    Get Current Date    result_format=%Y%m%d-%H%M%S
    ${clean_instance} =    Replace String    ${instance_type}    .    -
    ${pool_name} =    Set Variable    gpu-${clean_instance}-${gpu_node_count}-${timestamp}
    Log    Using machine pool name: ${pool_name}    console=True

    ${result} =    Run Process    python    utils/scripts/ocm/ocm.py    add_machine_pool
    ...    --cluster-name    ${cluster_name}
    ...    --instance-type    ${instance_type}
    ...    --worker-node-count    ${gpu_node_count}
    ...    --pool-name    ${pool_name}
    Should Be Equal As Integers    ${result.rc}    0
    ...    msg=Managed cluster GPU machine pool creation failed: ${result.stdout} ${result.stderr}
    Log    Managed cluster GPU machine pool created: ${result.stdout}    console=True
    # Wait for machine pool to be ready
    Wait For Machine Pool Ready    ${cluster_name}    ${pool_name}

Create GPU Nodes For Self Managed Cluster
    [Documentation]    Create GPU nodes for self-managed cluster using provision script
    ...                For GCP nvidia-* flavors: supports comma format (flavor, GCP, "gpu_count,node_count")
    ...                For all others: 3 params (instance_type, provider, node_count)
    [Arguments]    ${instance_type}    ${provider}    ${gpu_node_count}    ${gpu_count}=1

    # Script supports both comma-separated format and separate parameters for backward compatibility
    ${result} =    Run Process    sh    tasks/Resources/Provisioning/GPU/provision-gpu.sh
    ...    ${instance_type}
    ...    ${provider}
    ...    ${gpu_count}
    ...    ${gpu_node_count}
    Should Be Equal As Integers    ${result.rc}    0
    ...    msg=Self-managed cluster GPU node provisioning failed: ${result.stdout} ${result.stderr}
    Log    Self-managed cluster GPU nodes created: ${result.stdout}    console=True

Install GPU Operator on Self Managed Cluster
   [Documentation]  Install GPU operator on Self Managed cluster
   ${gpu_install} =    Run Process    sh    tasks/Resources/Provisioning/GPU/gpu_deploy.sh   shell=yes
   Should Not Contain    ${gpu_install.stdout}    FAIL
   Wait For Pods Status   namespace=nvidia-gpu-operator   timeout=600

Wait For Machine Pool Ready
    [Documentation]    Wait for machine pool to be ready in managed cluster
    [Arguments]    ${cluster_name}    ${pool_name}    ${timeout}=600
    Set Log Level    Info
    Log    Waiting for machine pool ${pool_name} to be ready in cluster ${cluster_name}    console=True

    # Use Robot Framework's Wait Until Keyword Succeeds for robust waiting
    Wait Until Keyword Succeeds    ${timeout}s    30s
    ...    Check Machine Pool Status    ${cluster_name}    ${pool_name}
    Log    Machine pool ${pool_name} is ready    console=True

Check Machine Pool Status
    [Documentation]    Check if machine pool is ready by verifying OCM status
    [Arguments]    ${cluster_name}    ${pool_name}

    ${result} =    Run Process    python    utils/scripts/ocm/ocm.py    get_cluster_info
    ...    --cluster-name    ${cluster_name}
    Should Be Equal As Integers    ${result.rc}    0
    ...    msg=Failed to get cluster info: ${result.stdout} ${result.stderr}

    # Check if machine pool exists and has nodes
    ${pool_check} =    Run Process    bash    -c
    ...    ocm list machinepools --cluster ${cluster_name} | grep -w ${pool_name} | wc -l
    Should Be Equal As Strings    ${pool_check.stdout.strip()}    1
    ...    msg=Machine pool ${pool_name} not found in cluster ${cluster_name}

    # Verify nodes are ready (this is the key check)
    ${nodes_ready} =    Run Process    bash    -c
    ...    ocm describe machinepool ${pool_name} --cluster ${cluster_name} --output json | jq -r '.replicas // 0'
    Should Not Be Equal As Strings    ${nodes_ready.stdout.strip()}    0
    ...    msg=Machine pool ${pool_name} has no ready nodes

