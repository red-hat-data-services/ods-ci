*** Settings ***
Library           OperatingSystem
Library           Process
Library           String

*** Variables ***
${GPU_INSTANCE_TYPE}    g4dn.xlarge
${GPU_PROVIDER}    AWS
${GPU_NODE_COUNT}    1
${GPU_COUNT_NVIDIA}    1
${GPU_GCP_INSTANCE_TYPE}    a2-ultragpu-1g

*** Keywords ***
Create GPU Node In Self Managed Cluster
    [Documentation]    Runs ``tasks/Resources/Provisioning/GPU/provision-gpu.sh`` from the ``ods_ci`` working directory.
    ...
    ...    On GCP, other zones in the same region are tried automatically if the first has no GPU capacity.
    ...
    ...    Override ``${GPU_INSTANCE_TYPE}``, ``${GPU_PROVIDER}``, ``${GPU_NODE_COUNT}``, ``${GPU_COUNT_NVIDIA}`` (suite/task) or pass arguments.
    [Arguments]    ${instance_type}=${GPU_INSTANCE_TYPE}    ${provider}=${GPU_PROVIDER}    ${node_count}=${GPU_NODE_COUNT}
    ...    ${gpu_count}=${GPU_COUNT_NVIDIA}
    Set Log Level    Info
    @{cmd}=    Create List    sh    tasks/Resources/Provisioning/GPU/provision-gpu.sh
    ...    ${instance_type}    ${provider}    ${node_count}
    ${nvidia}=    Run Keyword And Return Status    Should Start With    ${instance_type}    nvidia-
    IF    '${provider}' == 'GCP' and ${nvidia}
        Append To List    ${cmd}    ${gpu_count}
    END
    ${gpu_node}=    Run Process    @{cmd}
    Should Be Equal As Integers    ${gpu_node.rc}    0
    ...    msg=GPU node provisioning failed: ${gpu_node.stdout} ${gpu_node.stderr}
    Log    GPU node provisioning completed: ${gpu_node.stdout}    console=True

Create GPU Node In Self Managed AWS Cluster
    [Documentation]    Create GPU node on AWS (default ``g4dn.xlarge``). Same as ``Create GPU Node In Self Managed Cluster`` with AWS defaults.
    Create GPU Node In Self Managed Cluster    g4dn.xlarge    AWS    ${GPU_NODE_COUNT}

Create GPU Node In Self Managed GCP Cluster
    [Documentation]    Create GPU node on GCP using ``${GPU_GCP_INSTANCE_TYPE}`` (default ``a2-ultragpu-1g``). Other zones in the region are tried if the first has no GPU capacity.
    Create GPU Node In Self Managed Cluster    ${GPU_GCP_INSTANCE_TYPE}    GCP    ${GPU_NODE_COUNT}    ${GPU_COUNT_NVIDIA}

Delete GPU Node In Self Managed AWS Cluster
    ${gpu_nodes} =    Oc Get    kind=Machine    label_selector=machine.openshift.io/instance-type=g4dn.xlarge
    Log    ${gpu_nodes[0]['metadata']['name']}    console=True
    Run And Return Rc    oc annotate machine/${gpu_nodes[0]['metadata']['name']} -n openshift-machine-api machine.openshift.io/cluster-api-delete-machine="true"
    Run And Return Rc    oc adm cordon ${gpu_nodes[0]['metadata']['name']}
    Run And Return Rc    oc adm drain ${gpu_nodes[0]['metadata']['name']} --ignore-daemonsets --delete-local-data
    ${gpu_machineset} =    Oc Get    kind=MachineSet    label_selector=gpu-machineset=true
    Run And Return Rc    oc scale --replicas=0 machineset/${gpu_machineset[0]['metadata']['name']} -n openshift-machine-api

Install GPU Operator on Self Managed Cluster
   [Documentation]  Install GPU operator on Self Managed cluster
   ${gpu_install} =    Run Process    sh    tasks/Resources/Provisioning/GPU/gpu_deploy.sh   shell=yes
   Should Be Equal As Integers    ${gpu_install.rc}    0
   Should Not Contain    ${gpu_install.stdout}    FAIL
   Wait For Pods Status   namespace=nvidia-gpu-operator   timeout=600
