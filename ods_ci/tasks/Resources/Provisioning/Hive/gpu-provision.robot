*** Settings ***
Library           Collections
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
    [Documentation]    Runs ``tasks/Resources/Provisioning/GPU/provision-gpu.sh`` from the
    ...                ``ods_ci`` working directory.
    ...
    ...    On GCP, other zones in the same region are tried automatically if the first has no GPU capacity.
    ...
    ...    Override ``${GPU_INSTANCE_TYPE}``, ``${GPU_PROVIDER}``, ``${GPU_NODE_COUNT}``,
    ...    ``${GPU_COUNT_NVIDIA}`` (suite/task) or pass arguments.
    [Arguments]    ${instance_type}=${GPU_INSTANCE_TYPE}
    ...    ${provider}=${GPU_PROVIDER}
    ...    ${node_count}=${GPU_NODE_COUNT}
    ...    ${gpu_count}=${GPU_COUNT_NVIDIA}
    Set Log Level    Info
    VAR    @{cmd}    sh
    ...    tasks/Resources/Provisioning/GPU/provision-gpu.sh
    ...    ${instance_type}
    ...    ${provider}
    ...    ${node_count}
    ${nvidia}=    Run Keyword And Return Status    Should Start With    ${instance_type}    nvidia-
    IF    '${provider}' == 'GCP' and ${nvidia}
        Append To List    ${cmd}    ${gpu_count}
    END
    ${gpu_node}=    Run Process    @{cmd}
    Should Be Equal As Integers    ${gpu_node.rc}    0
    ...    msg=GPU node provisioning failed: ${gpu_node.stdout} ${gpu_node.stderr}
    Log    GPU node provisioning completed: ${gpu_node.stdout}    console=True

Create GPU Node In Self Managed AWS Cluster
    [Documentation]    Create GPU node on AWS using ``${GPU_INSTANCE_TYPE}`` (default ``g4dn.xlarge``). Same as
    ...                ``Create GPU Node In Self Managed Cluster`` with AWS defaults.
    Create GPU Node In Self Managed Cluster    ${GPU_INSTANCE_TYPE}    AWS    ${GPU_NODE_COUNT}

Create GPU Node In Self Managed GCP Cluster
    [Documentation]    Create GPU node on GCP using ``${GPU_GCP_INSTANCE_TYPE}`` (default
    ...                ``a2-ultragpu-1g``). Other zones in the region are tried if the first has no GPU capacity.
    Create GPU Node In Self Managed Cluster    ${GPU_GCP_INSTANCE_TYPE}    GCP
    ...    ${GPU_NODE_COUNT}
    ...    ${GPU_COUNT_NVIDIA}

Delete Provisioned GPU Node
    [Documentation]    Delete a GPU ``Machine`` created by ``provision-gpu.sh`` and scale the GPU
    ...                ``MachineSet`` (``gpu-machineset=true``) to zero. ``oc annotate`` uses the
    ...                ``Machine`` name; ``oc adm cordon``/``drain`` use the linked Node
    ...                (``status.nodeRef.name``). Resolves candidates from that
    ...                ``MachineSet`` via ``machine.openshift.io/cluster-api-machineset``. If
    ...                ``${instance_type}`` is non-empty, prefers Machines whose label
    ...                ``machine.openshift.io/instance-type`` matches (e.g. ``${GPU_INSTANCE_TYPE}`` on AWS);
    ...                if none match, uses any Machine in the set (needed for GCP ``nvidia-*`` flavors where
    ...                the API machine type is the base shape, not the flavor string).
    [Arguments]    ${instance_type}=${EMPTY}
    ${effective_type}=    Strip String    ${instance_type}
    ${want_filter}=    Evaluate    len(r'''${effective_type}''') > 0
    ${gpu_machineset}=    Oc Get    kind=MachineSet    label_selector=gpu-machineset=true
    ${ms_name}=    Set Variable    ${gpu_machineset[0]['metadata']['name']}
    ${gpu_machines}=    Oc Get    kind=Machine
    ...    label_selector=machine.openshift.io/cluster-api-machineset=${ms_name}
    ${count}=    Get Length    ${gpu_machines}
    Should Be True    ${count} > ${0}    msg=No Machines found for GPU MachineSet ${ms_name}
    ${candidates}=    Copy List    ${gpu_machines}
    IF    ${want_filter}
        VAR    @{matching}    @{EMPTY}
        FOR    ${m}    IN    @{gpu_machines}
            ${labels}=    Get Variable Value    ${m}[metadata][labels]    ${NONE}
            IF    '${labels}' == '${NONE}'    CONTINUE
            ${status}    ${inst_lbl}=    Run Keyword And Ignore Error    Get From Dictionary    ${labels}
            ...    machine.openshift.io/instance-type
            ${is_eq}=    Run Keyword And Return Status    Should Be Equal As Strings    ${inst_lbl}
            ...    ${effective_type}
            IF    '${status}' == 'PASS' and ${is_eq}
                Append To List    ${matching}    ${m}
            END
        END
        ${match_len}=    Get Length    ${matching}
        IF    ${match_len} > ${0}
            ${candidates}=    Copy List    ${matching}
        END
    END
    ${gpu_machine}=    Set Variable    ${candidates}[0]
    ${gpu_machine_name}=    Set Variable    ${gpu_machine}[metadata][name]
    ${gpu_node_name}=    Get Variable Value    ${gpu_machine}[status][nodeRef][name]    ${EMPTY}
    Should Not Be Empty    ${gpu_node_name}
    ...    msg=Machine ${gpu_machine_name} has no status.nodeRef.name; cannot cordon/drain
    Log    ${gpu_machine_name}    console=True
    ${annotate_cmd}=    Catenate    SEPARATOR=${SPACE}    oc annotate machine/${gpu_machine_name}
    ...    -n openshift-machine-api
    ...    machine.openshift.io/cluster-api-delete-machine="true"
    ${annotate_rc}=    Run And Return Rc    ${annotate_cmd}
    Should Be Equal As Integers    ${annotate_rc}    ${0}    msg=oc annotate machine failed for ${gpu_machine_name}
    ${cordon_rc}=    Run And Return Rc    oc adm cordon ${gpu_node_name}
    Should Be Equal As Integers    ${cordon_rc}    ${0}    msg=oc adm cordon failed for node ${gpu_node_name}
    ${drain_rc}=    Run And Return Rc    oc adm drain ${gpu_node_name}    --ignore-daemonsets
    ...    --delete-emptydir-data
    Should Be Equal As Integers    ${drain_rc}    ${0}    msg=oc adm drain failed for node ${gpu_node_name}
    ${scale_cmd}=    Catenate    SEPARATOR=${SPACE}    oc scale --replicas=0 machineset/${ms_name}
    ...    -n openshift-machine-api
    ${scale_rc}=    Run And Return Rc    ${scale_cmd}
    Should Be Equal As Integers    ${scale_rc}    ${0}    msg=oc scale machineset failed for ${ms_name}

Delete GPU Node Self Managed AWS Cluster
    [Documentation]    Delete AWS GPU node. Prefers ``${GPU_INSTANCE_TYPE}`` (default ``g4dn.xlarge``) when
    ...                it matches ``Machine`` labels; otherwise any Machine from the GPU ``MachineSet``.
    Delete Provisioned GPU Node    ${GPU_INSTANCE_TYPE}

Delete GPU Node Self Managed GCP Cluster
    [Documentation]    Delete GCP GPU node. Prefers ``${GPU_GCP_INSTANCE_TYPE}`` when it matches ``Machine``
    ...                labels; otherwise any Machine from the GPU ``MachineSet`` (e.g. ``nvidia-*`` on n1).
    Delete Provisioned GPU Node    ${GPU_GCP_INSTANCE_TYPE}

Install GPU Operator On Self Managed Cluster
   [Documentation]  Install GPU operator on Self Managed cluster
   ${gpu_install} =    Run Process    sh    tasks/Resources/Provisioning/GPU/gpu_deploy.sh   shell=yes
   Should Be Equal As Integers    ${gpu_install.rc}    0
   Should Not Contain    ${gpu_install.stdout}    FAIL
   Wait For Pods Status   namespace=nvidia-gpu-operator   timeout=600
