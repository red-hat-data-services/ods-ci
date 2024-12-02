*** Settings ***
Documentation     Kuberay E2E tests - https://github.com/opendatahub-io/kuberay/tree/dev/ray-operator/test/e2e
Suite Setup       Prepare Kuberay E2E Test Suite
Suite Teardown    Teardown Kuberay E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource

*** Variables ***
${KUBERAY_RELEASE_ASSETS}     %{KUBERAY_RELEASE_ASSETS=https://github.com/opendatahub-io/kuberay/releases/latest/download}
${KUBERAY_TEST_RAY_IMAGE}     quay.io/modh/ray@sha256:db667df1bc437a7b0965e8031e905d3ab04b86390d764d120e05ea5a5c18d1b4

*** Test Cases ***
Run TestRayJob test
    [Documentation]    Run Go E2E test: TestRayJob
    [Tags]  Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     Kuberay
    Run Kuberay E2E Test    "^TestRayJob$"

Run TestRayJobWithClusterSelector test
    [Documentation]    Run Go E2E test: TestRayJobWithClusterSelector
    [Tags]  Sanity
    ...     DistributedWorkloads
    ...     Training
    ...     Kuberay
    Run Kuberay E2E Test    TestRayJobWithClusterSelector

Run TestRayJobSuspend test
    [Documentation]    Run Go E2E test: TestRayJobSuspend
    [Tags]  Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     Kuberay
    Run Kuberay E2E Test    TestRayJobSuspend

Run TestRayJobLightWeightMode test
    [Documentation]    Run Go E2E test: TestRayJobLightWeightMode
    [Tags]  Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     Kuberay
    ...     ProductBug:RHOAIENG-6614
    Run Kuberay E2E Test    TestRayJobLightWeightMode


*** Keywords ***
Prepare Kuberay E2E Test Suite
    [Documentation]    Prepare Kuberay E2E Test Suite
    Log To Console    "Downloading compiled test binary e2e"
    ${result} =    Run Process    curl --location --silent --output e2e ${KUBERAY_RELEASE_ASSETS}/e2e && chmod +x e2e
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve e2e compiled binary
    END
    Create Directory    %{WORKSPACE}/kuberay-logs
    RHOSi Setup

Teardown Kuberay E2E Test Suite
    Log To Console    "Removing test binaries"
    ${result} =    Run Process    rm -f e2e
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to remove compiled binaries
    END
    RHOSi Teardown

Run Kuberay E2E Test
    [Documentation]    Run Kuberay E2E Test
    [Arguments]    ${test_name}
    Log To Console    Running Kuberay E2E test: ${test_name}
    ${result} =    Run Process    ./e2e -test.timeout 30m -test.parallel 1 -test.run ${test_name}
    ...    env:KUBERAY_TEST_TIMEOUT_SHORT=2m
    ...    env:KUBERAY_TEST_TIMEOUT_MEDIUM=10m
    ...    env:KUBERAY_TEST_TIMEOUT_LONG=12m
    ...    env:KUBERAY_TEST_RAY_IMAGE=${KUBERAY_TEST_RAY_IMAGE}
    ...    env:KUBERAY_TEST_OUTPUT_DIR=%{WORKSPACE}/kuberay-logs
    ...    shell=true
    ...    stderr=STDOUT
    ...    timeout=20m
    ...    stdout=${TEMPDIR}/output.txt
    Log To Console    ${result.stdout}
    Check missing Go test    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${test_name} failed
    END
