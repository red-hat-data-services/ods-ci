*** Settings ***
Documentation  Set of Keywords for GPU support
Resource    ../../../OCP.resource
Library     OperatingSystem


*** Keywords ***
Verify Installed CUDA Version
    [Documentation]  Checks the installed CUDA version
    [Arguments]  ${expected_version}
    Run Cell And Check Output    !nvidia-smi | grep "CUDA Version:" | awk '{split($0,a); print a[9]}'
    ...    ${expected_version}

Verify CUDA Is Not Installed
    [Documentation]  Verifies that CUDA is not installed
    Run Cell And Check Output    !nvidia-smi    /usr/bin/sh: nvidia-smi: command not found

Verify Pytorch Can See GPU
    [Documentation]    Verifies that PyTorch can see a GPU
    [Arguments]    ${install}=False
    IF  ${install}==True
        # TODO: use Install And Import Package In JupyterLab after #202 is merged
        Run Cell And Check For Errors    !pip install torch==1.8 numpy==1.19    timeout=300s
    END
    Run Cell And Check Output
    ...    import torch; device = "cuda" if torch.cuda.is_available() else "cpu"; print(f"Using {device} device")
    ...    Using cuda device

Verify Tensorflow Can See GPU
    [Documentation]    Verifies that Tensorflow can see a GPU
    [Arguments]    ${install}=False
    IF  ${install}==True
        # This installs the latest .z stream available for 2.7 to avoid the protobuf bug
        Run Cell And Check For Errors    !pip install tensorflow~=2.7    timeout=300s
    END
    # Need to wrap output in double quotes
    ${out} =    Run Cell And Get Output    import tensorflow as tf; import os; os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'; tf.config.list_physical_devices('GPU')  # robocop: disable
    Should Be Equal    "${out}"    "[PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]"

Find Max Number Of GPUs In One Node
    [Documentation]    Returns the maximum number of GPUs present in a single node
    ${max_gpus} =  Set Variable  ${0}
    @{node_names} =    Get GPU nodes
    FOR  ${node}  IN  @{node_names}
        ${node_gpu_num} =    Run    oc describe node ${node} | grep nvidia.com/gpu.count | awk '{split($0,a); print a[1]}' | awk '{split($0,b,"="); printf "%s", b[2]}'
        ${node_gpu_num} =    Convert To Integer    ${node_gpu_num}
        IF  ${node_gpu_num} > ${max_gpus}
            ${max_gpus} =    Set Variable    ${node_gpu_num}
        END
    END
    RETURN    ${max_gpus}

Get GPU nodes
    [Documentation]    Returns a list containing all nodes with GPUs
    ${nodes_from_oc} =    Run    oc get nodes -l nvidia.com/gpu.present=true | grep ip | awk '{split($0,a); print a[1]}'
    @{node_names} =    Split To Lines    ${nodes_from_oc}
    RETURN    @{node_names}

Get GPU Serial Number
    [Documentation]    Returns GPU Serial Number attached to server
    ${serial_no} =    Run Cell And Get Output    !nvidia-smi -q | grep "Serial Number" | awk '{split($0,a,": "); print a[2]}'
    RETURN    ${serial_no}

Find Max Number Of GPUs In One MachineSet
    [Documentation]    Returns the max number of GPUs present in a single MachineSet
    ${max_gpus} =    Set Variable    ${0}
    @{machinesets} =    Get MachineSets
    FOR    ${ms}    IN    @{machinesets}
        ${ms_gpu_num} =    Run    oc get MachineSet ${ms} -n openshift-machine-api -o json | jq '.metadata.annotations["machine.openshift.io/GPU"]' | sed 's/"//g'
        ${ms_gpu_num} =    Convert To Integer    ${ms_gpu_num}
        IF  ${ms_gpu_num} > ${max_gpus}
            ${max_gpus} =    Set Variable    ${ms_gpu_num}
        END
    END
    RETURN    ${max_gpus}

Is GPU Autoscaling Enabled
    [Documentation]    Returns ${True} if a machine autoscaler with gpu nodes is found
    ${autoscaling_enabled} =  Set Variable  ${False}
    @{machinesets} =    Get MachineSets
    FOR    ${ms}    IN    @{machinesets}
        ${ms_gpu_num} =    Run    oc get MachineSet ${ms} -n openshift-machine-api -o json | jq '.metadata.annotations["machine.openshift.io/GPU"]' | sed 's/"//g'
        ${ms_gpu_num} =    Convert To Integer    ${ms_gpu_num}
        IF  ${ms_gpu_num} > 0
            ${autoscaler} =  Run    oc get MachineSet ${ms} -n openshift-machine-api -o json | jq '.metadata.annotations["autoscaling.openshift.io/machineautoscaler"]'
            # Cannot compare directly since one of the values could be `null`
            ${autoscaler_status} =  Run Keyword And Return Status  Should Not Be Equal As Strings  ${autoscaler}  null
            IF  ${autoscaler_status}
                ${autoscaling_enabled} =  Set Variable  ${True}
            END
        END
    END
    RETURN    ${autoscaling_enabled}
