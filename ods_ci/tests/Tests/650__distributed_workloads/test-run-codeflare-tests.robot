*** Settings ***
Documentation     Codeflare operator E2E tests - https://github.com/opendatahub-io/codeflare-operator/tree/main/test/odh
Suite Setup       Prepare Codeflare E2E Test Suite
Suite Teardown    Teardown Codeflare E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Variables ***
${CODEFLARE_DIR}                codeflare-operator
${CODEFLARE_REPO_URL}           %{CODEFLARE_REPO_URL=https://github.com/opendatahub-io/codeflare-operator.git}
${CODEFLARE_REPO_BRANCH}        %{CODEFLARE_REPO_BRANCH=main}
${ODH_NAMESPACE}                %{ODH_NAMESPACE=redhat-ods-applications}
${NOTEBOOK_IMAGE_STREAM_NAME}   %{NOTEBOOK_IMAGE_STREAM_NAME=s2i-generic-data-science-notebook}


*** Test Cases ***
Run TestMNISTPyTorchMCAD E2E test
    [Documentation]    Run Go E2E test: TestMNISTPyTorchMCAD
    [Tags]  ODS-2543
    ...     Tier2
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare E2E Test    TestMNISTPyTorchMCAD

Run TestMNISTRayJobMCADRayCluster E2E test
    [Documentation]    Run Go E2E test: TestMNISTRayJobMCADRayCluster
    [Tags]  ODS-2545
    ...     Tier2
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare E2E Test    TestMNISTRayJobMCADRayCluster

Run TestMCADRay ODH test
    [Documentation]    Run Go ODH test: TestMCADRay
    [Tags]  ODS-2514
    ...     Tier2
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Skip    "Skip because of test failures. Currently being investigated"
    Run Codeflare ODH Test    TestMCADRay

Run TestMnistPyTorchMCAD ODH test
    [Documentation]    Run Go ODH test: TestMnistPyTorchMCAD
    [Tags]  ODS-2515
    ...     Tier2
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistPyTorchMCAD


*** Keywords ***
Prepare Codeflare E2E Test Suite
    ${result} =    Run Process    git clone -b ${CODEFLARE_REPO_BRANCH} ${CODEFLARE_REPO_URL} ${CODEFLARE_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone Codeflare repo ${CODEFLARE_REPO_URL}:${CODEFLARE_REPO_BRANCH}
    END
    
    Enable Component    ray
    Enable Component    codeflare
    Create Directory    %{WORKSPACE}/codeflare-e2e-logs
    Create Directory    %{WORKSPACE}/codeflare-odh-logs
    RHOSi Setup

Teardown Codeflare E2E Test Suite
    Disable Component    codeflare
    Disable Component    ray
    RHOSi Teardown

Run Codeflare E2E Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    go test -timeout 30m -v ./test/e2e -run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    cwd=${CODEFLARE_DIR}
    ...    env:CODEFLARE_TEST_TIMEOUT_SHORT=5m
    ...    env:CODEFLARE_TEST_TIMEOUT_MEDIUM=10m
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=20m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-e2e-logs
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END

Run Codeflare ODH Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    go test -timeout 30m -v ./test/odh -run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    cwd=${CODEFLARE_DIR}
    ...    env:CODEFLARE_TEST_TIMEOUT_SHORT=5m
    ...    env:CODEFLARE_TEST_TIMEOUT_MEDIUM=10m
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=20m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-odh-logs
    ...    env:ODH_NAMESPACE=${ODH_NAMESPACE}
    ...    env:NOTEBOOK_IMAGE_STREAM_NAME=${NOTEBOOK_IMAGE_STREAM_NAME}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END
