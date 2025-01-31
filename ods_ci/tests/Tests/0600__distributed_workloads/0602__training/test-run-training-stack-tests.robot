*** Settings ***
Documentation     Training Operator KFTO E2E tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/kfto
Suite Setup       Prepare Training Operator KFTO E2E Test Suite
Suite Teardown    Teardown Training Operator KFTO E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource



*** Test Cases ***

##Note: The testcases added below tagged with 'Kfto-MultiGpu' are meant for manual execution and must be skipped during QG tests

Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image using Single Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image using Single Node Single Gpu configuration
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeSingleGpuWithCuda    ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image using Single Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image using Single Node Multi Gpu configuration
    [Tags]  Kfto-MultiGpu
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeMultiGpuWithCuda   ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image using Multi Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image using Multi Node Single Gpu configuration
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeSingleGpuWithCuda    ${CUDA_TRAINING_IMAGE}


Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image using Multi Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image using Multi Node Multi Gpu configuration
    [Tags]  Kfto-MultiGpu
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeMultiGpuWithCuda   ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO Huggingface Trainer test with AMD ROCm image using Single Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image using Single Node Single Gpu configuration
    [Tags]  Resources-GPU    AMD-GPUs    ROCm
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeSingleGpuWithROCm    ${ROCM_TRAINING_IMAGE}

Run Training operator KFTO Huggingface Trainer test with AMD ROCm image using Single Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image using Single Node Multi Gpu configuration
    [Tags]  Kfto-MultiGpu
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeMultiGpuWithROCm    ${ROCM_TRAINING_IMAGE}

Run Training operator KFTO Huggingface Trainer test with AMD ROCm image using Multi Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image using Multi Node Single Gpu configuration
    [Tags]  Resources-GPU    AMD-GPUs    ROCm
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeSingleGpuWithROCm    ${ROCM_TRAINING_IMAGE}


Run Training operator KFTO Huggingface Trainer test with AMD ROCm image using Multi Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image using Multi Node Multi Gpu configuration
    [Tags]  Kfto-MultiGpu
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeMultiGpuWithROCm    ${ROCM_TRAINING_IMAGE}

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

## Note : For the disconnected environment, the KFTO Pytorch multi-node tests added below needs additional temporary workaround as a pre-requisite mentioned here
## Pre-requisite for disconnected : Update Kubeflow training operator deployment yaml to add additional arg in spec.containers.args : `--pytorch-init-container-image=quay.io/quay/busybox@sha256:92f3298bf80a1ba949140d77987f5de081f010337880cd771f7e7fc928f8c74d`

Run Training operator KFTO_MNIST multi-node single-CPU test with NVIDIA CUDA image
    [Documentation]    Run Go KFTO_MNIST multi-node single-CPU test for Training operator using PyTorch job with NVIDIA CUDA image - It requires 2 cluster-nodes with at least 1 CPUs each
    [Tags]  RHOAIENG-16556
    ...     Sanity
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeSingleCpu    ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO_MNIST multi-node multi-CPU test with NVIDIA CUDA image
    [Documentation]    Run Go KFTO_MNIST multi-node multi-CPU test for Training operator using PyTorch job with NVIDIA CUDA image - It requires 2 cluster-nodes with 2 CPUs each
    [Tags]  RHOAIENG-16556
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeMultiCpu    ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO_MNIST multi-node single-GPU test with NVIDIA CUDA image
    [Documentation]    Run Go KFTO_MNIST multi-node single-GPU test for Training operator using PyTorch job with NVIDIA CUDA image - It requires 2 cluster-nodes with 1 GPU each
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     RHOAIENG-16556
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeSingleGpuWithCuda    ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO_MNIST multi-node single-GPU test with AMD ROCm image
    [Documentation]    Run Go KFTO_MNIST multi-node single-GPU test for Training operator using PyTorch job with AMD ROCm image  - It requires 2 cluster-nodes with 1 GPU each
    [Tags]  Resources-GPU    AMD-GPUs    ROCm
    ...     RHOAIENG-16556
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeSingleGpuWithROCm    ${ROCM_TRAINING_IMAGE}

Run Training operator KFTO_MNIST multi-node multi-gpu test with NVIDIA CUDA image
    [Documentation]    Run Go KFTO_MNIST multi-node multi-gpu test for Training operator using PyTorch job with NVIDIA CUDA image - It requires 2 cluster-nodes with 2 GPUs each
    [Tags]  Kfto-MultiGpu
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeMultiGpuWithCuda    ${CUDA_TRAINING_IMAGE}

Run Training operator KFTO_MNIST multi-node multi-gpu test with AMD ROCm image
    [Documentation]    Run Go KFTO_MNIST multi-node multi-gpu test for Training operator using PyTorch job with AMD ROCm image  - It requires 2 cluster-nodes with 2 GPUs each
    [Tags]  Kfto-MultiGpu
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeMultiGpuWithROCm    ${ROCM_TRAINING_IMAGE}
