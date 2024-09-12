*** Settings ***
Documentation     Codeflare operator E2E tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/odh
Suite Setup       Prepare Codeflare E2E Test Suite
Suite Teardown    Teardown Codeflare E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Test Cases ***
Run TestKueueRayCpu ODH test
    [Documentation]    Run Go ODH test: TestKueueRayCpu
    [Tags]  ODS-2514
    ...     Tier1
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistRayCpu

Run TestKueueRayGpu ODH test
    [Documentation]    Run Go ODH test: TestKueueRayGpu
    [Tags]  Resources-GPU
    ...     Tier1
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistRayGpu

Run TestRayTuneHPOCpu ODH test
    [Documentation]    Run Go ODH test: TestMnistRayTuneHpoCpu
    [Tags]  RHOAIENG-10004
    ...     Tier1
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistRayTuneHpoCpu

Run TestRayTuneHPOGpu ODH test
    [Documentation]    Run Go ODH test: TestMnistRayTuneHpoGpu
    [Tags]  Resources-GPU
    ...     Tier1
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistRayTuneHpoGpu
