*** Settings ***
Documentation     Codeflare operator E2E tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/odh
Suite Setup       Prepare Codeflare E2E Test Suite
Suite Teardown    Teardown Codeflare E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Variables ***
${RAY_CUDA_IMAGE}                    quay.io/modh/ray@sha256:0d715f92570a2997381b7cafc0e224cfa25323f18b9545acfd23bc2b71576d06
${RAY_TORCH_CUDA_IMAGE}              quay.io/rhoai/ray@sha256:158b481b8e9110008d60ac9fb8d156eadd71cb057ac30382e62e3a231ceb39c0


*** Test Cases ***
Run TestKueueRayCpu ODH test
    [Documentation]    Run Go ODH test: TestKueueRayCpu
    [Tags]  ODS-2514
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistRayCpu    ${RAY_CUDA_IMAGE}

Run TestKueueRayGpu ODH test
    [Documentation]    Run Go ODH test: TestKueueRayGpu
    [Tags]  Resources-GPU
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistRayGpu    ${RAY_CUDA_IMAGE}

Run TestRayTuneHPOCpu ODH test
    [Documentation]    Run Go ODH test: TestMnistRayTuneHpoCpu
    [Tags]  RHOAIENG-10004
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistRayTuneHpoCpu    ${RAY_CUDA_IMAGE}

Run TestRayTuneHPOGpu ODH test
    [Documentation]    Run Go ODH test: TestMnistRayTuneHpoGpu
    [Tags]  Resources-GPU
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistRayTuneHpoGpu    ${RAY_CUDA_IMAGE}

Run TestKueueCustomRayCpu ODH test
    [Documentation]    Run Go ODH test: TestKueueCustomRayCpu
    [Tags]  RHOAIENG-10013
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistCustomRayImageCpu    ${RAY_TORCH_CUDA_IMAGE}

Run TestKueueCustomRayGpu ODH test
    [Documentation]    Run Go ODH test: TestKueueCustomRayGpu
    [Tags]  RHOAIENG-10013
    ...     Resources-GPU
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistCustomRayImageGpu    ${RAY_TORCH_CUDA_IMAGE}
