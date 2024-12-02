*** Settings ***
Documentation     Distributed Workloads Integration tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/odh
Suite Setup       Prepare DistributedWorkloads Integration Test Suite
Suite Teardown    Teardown DistributedWorkloads Integration Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Test Tags         DistributedWorkloads3.11


*** Variables ***
${RAY_CUDA_IMAGE_3.11}               quay.io/modh/ray@sha256:db667df1bc437a7b0965e8031e905d3ab04b86390d764d120e05ea5a5c18d1b4
${RAY_TORCH_CUDA_IMAGE_3.11}         quay.io/rhoai/ray@sha256:5077f9bb230dfa88f34089fecdfcdaa8abc6964716a8a8325c7f9dcdf11bbbb3
${RAY_ROCM_IMAGE_3.11}               quay.io/modh/ray@sha256:f8b4f2b1c954187753c1f5254f7bb6a4286cec5a4f1b43def7ef4e009f2d28cb
${NOTEBOOK_IMAGE_3.11}               quay.io/modh/odh-generic-data-science-notebook@sha256:7c1a4ca213b71d342a2d1366171304e469da06d5f15710fab5dd3ce013aa1b73


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

Run TestKueueCustomRayCpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestKueueCustomRayCpu
    [Tags]  RHOAIENG-10013
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistCustomRayImageCpu    ${RAY_TORCH_CUDA_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}

Run TestKueueCustomRayGpu ODH test with Python 3.11
    [Documentation]    Run Go ODH test: TestKueueCustomRayGpu
    [Tags]  RHOAIENG-10013
    ...     Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistCustomRayImageGpu    ${RAY_TORCH_CUDA_IMAGE_3.11}    ${NOTEBOOK_IMAGE_3.11}
