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
    ...    provider (AWS/GCP/AZURE/IBM), gpu_node_count (1), cluster_name (for managed).
    [Arguments]    ${cluster_type}=self-managed
    ...    ${instance_type}=g4dn.xlarge
    ...    ${provider}=AWS
    ...    ${gpu_node_count}=1
    ...    ${cluster_name}=${EMPTY}
    Set Log Level    Info

    IF    '${cluster_type}' == 'managed'
        # For managed clusters, use OCM to add machine pool
        IF    '${cluster_name}' == '${EMPTY}'
            Fail    cluster_name is required for managed clusters
        END
        ${result} =    Run Process    python    utils/scripts/ocm/ocm.py    add_machine_pool
        ...    --cluster-name    ${cluster_name}
        ...    --instance-type    ${instance_type}
        ...    --worker-node-count    ${gpu_node_count}
        ...    --pool-name    gpu-pool-${gpu_node_count}
        Should Be Equal As Integers    ${result.rc}    0
        ...    msg=Managed cluster GPU machine pool creation failed: ${result.stdout} ${result.stderr}
        Log    Managed cluster GPU machine pool created: ${result.stdout}    console=True
    ELSE IF    '${cluster_type}' == 'self-managed'
        # For self-managed clusters, use existing provision-gpu.sh script
        # gpu_count is only relevant for GCP, defaults to 1 for other providers
        ${gpu_count} =    Set Variable If    '${provider}' == 'GCP'    1    1
        ${result} =    Run Process    sh    tasks/Resources/Provisioning/GPU/provision-gpu.sh
        ...    ${instance_type}
        ...    ${provider}
        ...    ${gpu_count}
        ...    ${gpu_node_count}
        Should Be Equal As Integers    ${result.rc}    0
        ...    msg=Self-managed cluster GPU node provisioning failed: ${result.stdout} ${result.stderr}
        Log    Self-managed cluster GPU nodes created: ${result.stdout}    console=True
    ELSE
        Fail    Invalid cluster_type: ${cluster_type}. Must be 'managed' or 'self-managed'
    END

Install GPU Operator on Self Managed Cluster
   [Documentation]  Install GPU operator on Self Managed cluster
   ${gpu_install} =    Run Process    sh    tasks/Resources/Provisioning/GPU/gpu_deploy.sh   shell=yes
   Should Not Contain    ${gpu_install.stdout}    FAIL
   Wait For Pods Status   namespace=nvidia-gpu-operator   timeout=600
