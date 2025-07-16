*** Settings ***
Documentation     Training Operator KFTO E2E tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/kfto
Suite Setup       Prepare Training Operator KFTO E2E Test Suite
Suite Teardown    Teardown Training Operator KFTO E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource



*** Test Cases ***

##Note: The testcases added below tagged with 'Kfto-CUDA' and 'Kfto-ROCm' are meant for manual execution and must be skipped during QG tests

Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image (PyTorch 2_4_1) using Single Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_4_1)  using Single Node Single Gpu configuration
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeSingleGpuWithCudaPyTorch241

Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image (PyTorch 2_5_1) using Single Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_5_1) using Single Node Single Gpu configuration
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeSingleGpuWithCudaPyTorch251

Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image (PyTorch 2_4_1) using Single Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_4_1)  using Single Node Multi Gpu configuration
    [Tags]  Kfto-CUDA
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeMultiGpuWithCudaPyTorch241

Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image (PyTorch 2_5_1) using Single Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_5_1) using Single Node Multi Gpu configuration
    [Tags]  Kfto-CUDA
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeMultiGpuWithCudaPyTorch251

Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image (PyTorch 2_4_1) using Multi Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_4_1)  using Multi Node Single Gpu configuration
    [Tags]  Kfto-CUDA
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeSingleGpuWithCudaPyTorch241

Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image (PyTorch 2_5_1) using Multi Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_5_1) using Multi Node Single Gpu configuration
    [Tags]  Kfto-CUDA
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeSingleGpuWithCudaPyTorch251


Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image (PyTorch 2_4_1) using Multi Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_4_1)  using Multi Node Multi Gpu configuration
    [Tags]  Kfto-CUDA
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeMultiGpuWithCudaPyTorch241

Run Training operator KFTO Huggingface Trainer test with NVIDIA CUDA image (PyTorch 2_5_1) using Multi Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_5_1) using Multi Node Multi Gpu configuration
    [Tags]  Kfto-CUDA
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeMultiGpuWithCudaPyTorch251

Run Training operator KFTO Huggingface Trainer test with AMD ROCm image (PyTorch 2_4_1) using Single Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_4_1)  using Single Node Single Gpu configuration
    [Tags]  Resources-GPU    AMD-GPUs    ROCm
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeSingleGpuWithROCmPyTorch241

Run Training operator KFTO Huggingface Trainer test with AMD ROCm image (PyTorch 2_5_1) using Single Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_5_1) using Single Node Single Gpu configuration
    [Tags]  Resources-GPU    AMD-GPUs    ROCm
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeSingleGpuWithROCmPyTorch251

Run Training operator KFTO Huggingface Trainer test with AMD ROCm image (PyTorch 2_4_1) using Single Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_4_1)  using Single Node Multi Gpu configuration
    [Tags]  Kfto-ROCm
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeMultiGpuWithROCmPyTorch241

Run Training operator KFTO Huggingface Trainer test with AMD ROCm image (PyTorch 2_5_1) using Single Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_5_1) using Single Node Multi Gpu configuration
    [Tags]  Kfto-ROCm
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobSingleNodeMultiGpuWithROCmPyTorch251

Run Training operator KFTO Huggingface Trainer test with AMD ROCm image (PyTorch 2_4_1) using Multi Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_4_1)  using Multi Node Single Gpu configuration
    [Tags]  Kfto-ROCm
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeSingleGpuWithROCmPyTorch241

Run Training operator KFTO Huggingface Trainer test with AMD ROCm image (PyTorch 2_5_1) using Multi Node Single Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_5_1) using Multi Node Single Gpu configuration
    [Tags]  Kfto-ROCm
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeSingleGpuWithROCmPyTorch251


Run Training operator KFTO Huggingface Trainer test with AMD ROCm image (PyTorch 2_4_1) using Multi Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_4_1)  using Multi Node Multi Gpu configuration
    [Tags]  Kfto-ROCm
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeMultiGpuWithROCmPyTorch241

Run Training operator KFTO Huggingface Trainer test with AMD ROCm image (PyTorch 2_5_1) using Multi Node Multi Gpu
    [Documentation]    Run Go KFTO test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_5_1) using Multi Node Multi Gpu configuration
    [Tags]  Kfto-ROCm
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMultiNodeMultiGpuWithROCmPyTorch251

Run Training operator KFTO error handling test with NVIDIA CUDA image (PyTorch 2_4_1)
    [Documentation]    Run Go KFTO error handling test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_4_1)
    [Tags]  RHOAIENG-14542
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobFailureWithCudaPyTorch241

Run Training operator KFTO error handling test with NVIDIA CUDA image (PyTorch 2_5_1)
    [Documentation]    Run Go KFTO error handling test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_5_1)
    [Tags]  RHOAIENG-14542
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobFailureWithCudaPyTorch251

Run Training operator KFTO error handling test with AMD ROCm image (PyTorch 2_4_1)
    [Documentation]    Run Go KFTO error handling test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_4_1)
    [Tags]  RHOAIENG-14542
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobFailureWithROCmPyTorch241

Run Training operator KFTO error handling test with AMD ROCm image (PyTorch 2_5_1)
    [Documentation]    Run Go KFTO error handling test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_5_1)
    [Tags]  RHOAIENG-14542
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobFailureWithROCmPyTorch251

## Note : For the disconnected environment, the KFTO Pytorch multi-node tests added below needs additional temporary workaround as a pre-requisite mentioned here
## Pre-requisite for disconnected : Update Kubeflow training operator deployment yaml to add additional arg in spec.containers.args : `--pytorch-init-container-image=quay.io/quay/busybox@sha256:92f3298bf80a1ba949140d77987f5de081f010337880cd771f7e7fc928f8c74d`

Run Training operator KFTO_MNIST multi-node single-CPU test with NVIDIA CUDA image (PyTorch 2_5_1)
    [Documentation]    Run Go KFTO_MNIST multi-node single-CPU test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_5_1) - It requires 2 cluster-nodes with at least 1 CPUs each
    [Tags]  RHOAIENG-16556
    ...     Sanity
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeSingleCpu

Run Training operator KFTO_MNIST multi-node multi-CPU test with NVIDIA CUDA image (PyTorch 2_5_1)
    [Documentation]    Run Go KFTO_MNIST multi-node multi-CPU test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_5_1) - It requires 2 cluster-nodes with 2 CPUs each
    [Tags]  RHOAIENG-16556
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeMultiCpu

Run Training operator KFTO_MNIST multi-node single-GPU test with NVIDIA CUDA image (PyTorch 2_4_1)
    [Documentation]    Run Go KFTO_MNIST multi-node single-GPU test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_4_1)  - It requires 2 cluster-nodes with 1 GPU each
    [Tags]  Kfto-CUDA
    ...     RHOAIENG-16556
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeSingleGpuWithCudaPyTorch241

Run Training operator KFTO_MNIST multi-node single-GPU test with NVIDIA CUDA image (PyTorch 2_5_1)
    [Documentation]    Run Go KFTO_MNIST multi-node single-GPU test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_5_1) - It requires 2 cluster-nodes with 1 GPU each
    [Tags]  Kfto-CUDA
    ...     RHOAIENG-16556
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeSingleGpuWithCudaPyTorch251

Run Training operator KFTO_MNIST multi-node single-GPU test with AMD ROCm image (PyTorch 2_4_1)
    [Documentation]    Run Go KFTO_MNIST multi-node single-GPU test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_4_1)   - It requires 2 cluster-nodes with 1 GPU each
    [Tags]  Resources-GPU    AMD-GPUs    ROCm
    ...     RHOAIENG-16556
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeSingleGpuWithROCmPyTorch241

Run Training operator KFTO_MNIST multi-node single-GPU test with AMD ROCm image (PyTorch 2_5_1)
    [Documentation]    Run Go KFTO_MNIST multi-node single-GPU test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_5_1)  - It requires 2 cluster-nodes with 1 GPU each
    [Tags]  Resources-GPU    AMD-GPUs    ROCm
    ...     RHOAIENG-16556
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeSingleGpuWithROCmPyTorch251

Run Training operator KFTO_MNIST multi-node multi-gpu test with NVIDIA CUDA image (PyTorch 2_4_1)
    [Documentation]    Run Go KFTO_MNIST multi-node multi-gpu test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_4_1)  - It requires 2 cluster-nodes with 2 GPUs each
    [Tags]  Kfto-CUDA
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeMultiGpuWithCudaPyTorch241

Run Training operator KFTO_MNIST multi-node multi-gpu test with NVIDIA CUDA image (PyTorch 2_5_1)
    [Documentation]    Run Go KFTO_MNIST multi-node multi-gpu test for Training operator using PyTorch job with NVIDIA CUDA image (PyTorch 2_5_1) - It requires 2 cluster-nodes with 2 GPUs each
    [Tags]  Kfto-CUDA
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeMultiGpuWithCudaPyTorch251

Run Training operator KFTO_MNIST multi-node multi-gpu test with AMD ROCm image (PyTorch 2_4_1)
    [Documentation]    Run Go KFTO_MNIST multi-node multi-gpu test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_4_1)   - It requires 2 cluster-nodes with 2 GPUs each
    [Tags]  Kfto-ROCm
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeMultiGpuWithROCmPyTorch241

Run Training operator KFTO_MNIST multi-node multi-gpu test with AMD ROCm image (PyTorch 2_5_1)
    [Documentation]    Run Go KFTO_MNIST multi-node multi-gpu test for Training operator using PyTorch job with AMD ROCm image (PyTorch 2_5_1)  - It requires 2 cluster-nodes with 2 GPUs each
    [Tags]  Kfto-ROCm
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestPyTorchJobMnistMultiNodeMultiGpuWithROCmPyTorch251

Run Kueue Validating Admission Policy tests for Training operator's Pytorchjob
    [Documentation]    Run Go Kueue Validating Admission Policy tests for Training operator's Pytorchjob'
    [Tags]  DistributedWorkloads
    ...     TrainingKubeflow
    ...     TrainingOperator
    ...     deprecatedTest
    Run Training Operator KFTO Test    TestValidatingAdmissionPolicy
