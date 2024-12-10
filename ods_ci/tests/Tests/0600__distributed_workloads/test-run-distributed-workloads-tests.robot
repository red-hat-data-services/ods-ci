*** Settings ***
Documentation     Distributed Workloads Integration tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/odh
Suite Setup       Prepare DistributedWorkloads Integration Test Suite
Suite Teardown    Teardown DistributedWorkloads Integration Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Test Tags         DistributedWorkloads3.11


*** Test Cases ***
Run TestKueueRayCpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestKueueRayCpu
    [Tags]  ODS-2514
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistRayCpu    ${RAY_CUDA_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}

Run TestKueueRayCudaGpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestKueueRayCudaGpu
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistRayCudaGpu    ${RAY_CUDA_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}

Run TestKueueRayROCmGpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestKueueRayROCmGpu
    [Tags]  Resources-GPU    AMD-GPUs    ROCm
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistRayROCmGpu    ${RAY_ROCM_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}

Run TestRayTuneHPOCpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestMnistRayTuneHpoCpu
    [Tags]  RHOAIENG-10004
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistRayTuneHpoCpu    ${RAY_CUDA_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}

Run TestRayTuneHPOGpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestMnistRayTuneHpoGpu
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistRayTuneHpoGpu    ${RAY_CUDA_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}

Run TestKueueCustomRayCudaCpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestKueueCustomRayCudaCpu
    [Tags]  RHOAIENG-10013
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistCustomRayCudaCpu    ${RAY_TORCH_CUDA_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}

Run TestKueueCustomRayCudaGpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestKueueCustomRayCudaGpu
    [Tags]  RHOAIENG-10013
    ...     Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistCustomRayCudaGpu    ${RAY_TORCH_CUDA_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}

Run TestKueueCustomRayRocmCpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestKueueCustomRayRocmCpu
    [Tags]  RHOAIENG-12484
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistCustomRayRocmCpu    ${RAY_TORCH_ROCM_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}

Run TestKueueCustomRayRocmGpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestKueueCustomRayRocmGpu
    [Tags]  RHOAIENG-12484
    ...     Resources-GPU    AMD-GPUs    ROCm
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistCustomRayRocmGpu    ${RAY_TORCH_ROCM_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}
