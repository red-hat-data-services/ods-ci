*** Settings ***
Documentation     Distributed Workloads Integration tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/odh
Suite Setup       Prepare DistributedWorkloads Integration Test Suite for 3.9
Suite Teardown    Teardown DistributedWorkloads Integration Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Test Tags         DistributedWorkloads3.9


*** Variables ***
# This is the last and latest distributed workloads release assest which contains test binaries compatible with python 3.9
${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS_3.9}   https://github.com/opendatahub-io/distributed-workloads/releases/download/v2.14.0-09-24-2024_adjustments_1
${RAY_CUDA_IMAGE_3.9}                         quay.io/modh/ray@sha256:0d715f92570a2997381b7cafc0e224cfa25323f18b9545acfd23bc2b71576d06
${RAY_TORCH_CUDA_IMAGE_3.9}                   quay.io/rhoai/ray@sha256:158b481b8e9110008d60ac9fb8d156eadd71cb057ac30382e62e3a231ceb39c0
${NOTEBOOK_IMAGE_3.9}                         quay.io/modh/odh-generic-data-science-notebook@sha256:b1066204611b4bcfa6172c3115650a8e8393089d5606458fa0d8c53633d2ce17


*** Test Cases ***
Run TestKueueRayCpu ODH test with Python 3.9
    [Documentation]    Run Go ODH test: TestKueueRayCpu
    [Tags]  ODS-2514
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistRayCpu    ${RAY_CUDA_IMAGE_3.9}    ${NOTEBOOK_IMAGE_3.9}

Run TestKueueRayGpu ODH test with Python 3.9
    [Documentation]    Run Go ODH test: TestKueueRayGpu
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistRayGpu    ${RAY_CUDA_IMAGE_3.9}    ${NOTEBOOK_IMAGE_3.9}

Run TestRayTuneHPOCpu ODH test with Python 3.9
    [Documentation]    Run Go ODH test: TestMnistRayTuneHpoCpu
    [Tags]  RHOAIENG-10004
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistRayTuneHpoCpu    ${RAY_CUDA_IMAGE_3.9}    ${NOTEBOOK_IMAGE_3.9}

Run TestRayTuneHPOGpu ODH test with Python 3.9
    [Documentation]    Run Go ODH test: TestMnistRayTuneHpoGpu
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistRayTuneHpoGpu    ${RAY_CUDA_IMAGE_3.9}    ${NOTEBOOK_IMAGE_3.9}

Run TestKueueCustomRayCpu ODH test with Python 3.9
    [Documentation]    Run Go ODH test: TestKueueCustomRayCpu
    [Tags]  RHOAIENG-10013
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistCustomRayImageCpu    ${RAY_TORCH_CUDA_IMAGE_3.9}    ${NOTEBOOK_IMAGE_3.9}

Run TestKueueCustomRayGpu ODH test with Python 3.9
    [Documentation]    Run Go ODH test: TestKueueCustomRayGpu
    [Tags]  RHOAIENG-10013
    ...     Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     WorkloadsOrchestration
    Run DistributedWorkloads ODH Test    TestMnistCustomRayImageGpu    ${RAY_TORCH_CUDA_IMAGE_3.9}    ${NOTEBOOK_IMAGE_3.9}


*** Keywords ***
Prepare DistributedWorkloads Integration Test Suite for 3.9
    [Documentation]    Prepare DistributedWorkloads Integration Test Suite for 3.9
    # The bug fix for self signed certificate error is not available in codeflare-sdk version "v0.21.1" which is the
    # last supported release for python 3.9 and hence skipping tests for self managed installtion
    Skip If RHODS Is Self-Managed
    Log To Console    "Downloading compiled test binary ${ODH_BINARY_NAME}"

    ${result} =    Run Process    curl --location --silent --output ${ODH_BINARY_NAME} ${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS_3.9}/${ODH_BINARY_NAME} && chmod +x ${ODH_BINARY_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve odh compiled binary
    END
    Create Directory    %{WORKSPACE}/distributed-workloads-odh-logs
    Log To Console    "Retrieving user tokens"
    ${common_user_token} =    Generate User Token    ${NOTEBOOK_USER_NAME}    ${NOTEBOOK_USER_PASSWORD}
    Set Suite Variable    ${NOTEBOOK_USER_TOKEN}   ${common_user_token}
    Log To Console    "Log back as cluster admin"
    Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}
    RHOSi Setup
