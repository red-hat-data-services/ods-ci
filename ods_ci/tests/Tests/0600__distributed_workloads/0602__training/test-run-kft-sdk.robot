*** Settings ***
Documentation     KFTO SDK tests - https://github.com/opendatahub-io/distributed-workloads/blob/main/tests/kfto/kfto_mnist_sdk_test.go
Resource          ../../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Suite Setup       Prepare Training Operator SDK Test Suite
Suite Teardown    Teardown Training Operator SDK Test Suite

*** Test Cases ***
Run TestMnistSDK KFTO SDK test with NVIDIA CUDA image (PyTorch 2_4_1)
    [Documentation]    Run Go KFTO SDK test: TestMnistSDK
    [Tags]  Tier1
    ...     KFTOSDK
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    Run Training Operator KFTO SDK Test    TestMnistSDK   ${CUDA_TRAINING_IMAGE_TORCH241}

Run TestMnistSDK KFTO SDK test with NVIDIA CUDA image (PyTorch 2_5_1)
    [Documentation]    Run Go KFTO SDK test: TestMnistSDK
    [Tags]  Tier1
    ...     KFTOSDK
    ...     DistributedWorkloads
    ...     TrainingKubeflow
    Run Training Operator KFTO SDK Test    TestMnistSDK   ${CUDA_TRAINING_IMAGE_TORCH251}
