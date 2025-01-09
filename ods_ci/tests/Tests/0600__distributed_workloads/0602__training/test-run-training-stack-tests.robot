*** Settings ***
Documentation     Training Operator KFTO E2E tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/kfto
Suite Setup       Prepare Training Operator KFTO E2E Test Suite
Suite Teardown    Teardown Training Operator KFTO E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Test Cases ***
Run Training operator KFTO test with NVIDIA CUDA image
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     RHOAIENG-16035
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobWithCuda    ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO test with AMD ROCm image
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image
    [Tags]  Resources-GPU    AMD-GPUs    ROCm
    ...     RHOAIENG-16035
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobWithROCm    ${ROCM_TRAINING_IMAGE}

Run Training operator KFTO error handling test with NVIDIA CUDA image
    [Documentation]    Run Go KFTO error handling test for Training operator using PyTorch job with NVIDIA CUDA image
    [Tags]  RHOAIENG-14542
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobFailureWithCuda    ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO error handling test with AMD ROCm image
    [Documentation]    Run Go KFTO error handling test for Training operator using PyTorch job with AMD ROCm image
    [Tags]  RHOAIENG-14542
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobFailureWithROCm    ${ROCM_TRAINING_IMAGE}

Run Training operator KFTO_MNIST multi-node CPU test with NVIDIA CUDA image
    [Documentation]    Run Go KFTO_MNIST multi-node CPU test for Training operator using PyTorch job with NVIDIA CUDA image - It requires 2 cluster-nodes with 2 CPUs each
    [Tags]  RHOAIENG-16556
    ...     Sanity
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeCpu    ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO_MNIST multi-node test with NVIDIA CUDA image
    [Documentation]    Run Go KFTO_MNIST multi-node test for Training operator using PyTorch job with NVIDIA CUDA image - It requires 2 cluster-nodes with 1 GPUs each
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     RHOAIENG-16556
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeWithCuda    ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO_MNIST multi-node test with AMD ROCm image
    [Documentation]    Run Go KFTO_MNIST multi-node test for Training operator using PyTorch job with AMD ROCm image  - It requires 2 cluster-nodes with 1 GPUs each
    [Tags]  Resources-GPU    AMD-GPUs    ROCm
    ...     RHOAIENG-16556
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeWithROCm    ${ROCM_TRAINING_IMAGE}
