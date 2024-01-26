*** Settings ***
Documentation     Codeflare-sdk E2E tests - https://github.com/project-codeflare/codeflare-sdk/tree/main/tests/e2e
Suite Setup       Prepare Codeflare-sdk E2E Test Suite
Suite Teardown    Teardown Codeflare-sdk E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/RHOSi.resource


*** Variables ***
${CODEFLARE-SDK_DIR}                codeflare-sdk
${CODEFLARE-SDK_REPO_URL}           %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}
${CODEFLARE-SDK_REPO_BRANCH}        %{CODEFLARE-SDK_REPO_BRANCH=main}


*** Test Cases ***
Run TestMNISTRayClusterSDK test
    [Documentation]    Run Go E2E test: TestMNISTRayClusterSDK
    [Tags]  ODS-2544
    ...     Sanity    Tier1
    ...     DistributedWorkloads
    ...     Codeflare-sdk
    Run Codeflare-sdk E2E Test    TestMNISTRayClusterSDK


*** Keywords ***
Prepare Codeflare-sdk E2E Test Suite
    [Documentation]    Prepare codeflare-sdk E2E Test Suite
    ${result} =    Run Process    git clone -b ${CODEFLARE-SDK_REPO_BRANCH} ${CODEFLARE-SDK_REPO_URL} ${CODEFLARE-SDK_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone codeflare-sdk repo ${CODEFLARE-SDK_REPO_URL}:${CODEFLARE-SDK_REPO_BRANCH}:${CODEFLARE-SDK_DIR}
    END
    Enable Component    codeflare
    Enable Component    ray
    Create Directory    %{WORKSPACE}/codeflare-sdk-e2e-logs
    RHOSi Setup

Teardown Codeflare-sdk E2E Test Suite
    [Documentation]    Teardown codeflare-sdk E2E Test Suite
    Disable Component    codeflare
    Disable Component    ray
    RHOSi Teardown

Run Codeflare-sdk E2E Test
    [Documentation]    Run codeflare-sdk E2E Test
    [Arguments]    ${test_name}
    Log To Console    Running codeflare-sdk test: ${test_name}
    ${result} =    Run Process    go test -timeout 30m -v ./tests/e2e -run ${test_name}
    ...    shell=true
    ...    stderr=STDOUT
    ...    cwd=${CODEFLARE-SDK_DIR}
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=20m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-sdk-e2e-logs
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${test_name} failed
    END
