*** Settings ***
Documentation     Training Hub RayJob Integration tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/odh
Suite Setup       Prepare DistributedWorkloads Integration Test Suite
Suite Teardown    Teardown DistributedWorkloads Integration Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Test Cases ***
Run TestSftRayJobSingleGpu ODH test
    [Documentation]    Run Go ODH test: TestSftRayJobSingleGpu
    [Tags]  RHOAIENG-65214
    ...     Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingRay
    ...     TrainingHub
    Run DistributedWorkloads Training Hub ODH Test    TestSftRayJobSingleGpu    ${RAY_TRAINING_HUB_IMAGE}    ${NOTEBOOK_IMAGE_3.12}

Run TestOsftRayJobSingleGpu ODH test
    [Documentation]    Run Go ODH test: TestOsftRayJobSingleGpu
    [Tags]  RHOAIENG-65214
    ...     Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingRay
    ...     TrainingHub
    Run DistributedWorkloads Training Hub ODH Test    TestOsftRayJobSingleGpu    ${RAY_TRAINING_HUB_IMAGE}    ${NOTEBOOK_IMAGE_3.12}

Run TestLoraRayJobSingleGpu ODH test
    [Documentation]    Run Go ODH test: TestLoraRayJobSingleGpu
    [Tags]  RHOAIENG-65214
    ...     Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingRay
    ...     TrainingHub
    Run DistributedWorkloads Training Hub ODH Test    TestLoraRayJobSingleGpu    ${RAY_TRAINING_HUB_IMAGE}    ${NOTEBOOK_IMAGE_3.12}

Run TestGrpoRayJobSingleNodeMultiGpu ODH test
    [Documentation]    Run Go ODH test: TestGrpoRayJobSingleNodeMultiGpu
    [Tags]  RHOAIENG-63702
    ...     Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingRay
    ...     TrainingHub
    Run DistributedWorkloads Training Hub ODH Test    TestGrpoRayJobSingleNodeMultiGpu    ${RAY_TRAINING_HUB_IMAGE}    ${NOTEBOOK_IMAGE_3.12}
