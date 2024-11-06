*** Settings ***
Documentation     Codeflare operator E2E tests - https://github.com/opendatahub-io/codeflare-operator/tree/main/test/odh
Suite Setup       Prepare Codeflare E2E Test Suite
Suite Teardown    Teardown Codeflare E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Variables ***
${CODEFLARE_DIR}                codeflare-operator
${CODEFLARE_RELEASE_ASSETS}     %{CODEFLARE_RELEASE_ASSETS=https://github.com/opendatahub-io/codeflare-operator/releases/download/v1.2.0}
${ODH_NAMESPACE}                %{ODH_NAMESPACE=redhat-ods-applications}
${NOTEBOOK_IMAGE_STREAM_NAME}   %{NOTEBOOK_IMAGE_STREAM_NAME=s2i-generic-data-science-notebook}


*** Test Cases ***
Run TestMNISTPyTorchMCAD E2E test
    [Documentation]    Run Go E2E test: TestMNISTPyTorchMCAD
    [Tags]  ODS-2543
    ...     Sanity
    ...     Tier1
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare E2E Test    TestMNISTPyTorchMCAD

Run TestMNISTRayJobMCADRayCluster E2E test
    [Documentation]    Run Go E2E test: TestMNISTRayJobMCADRayCluster
    [Tags]  ODS-2545
    ...     Tier1
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare E2E Test    TestMNISTRayJobMCADRayCluster

Run TestMCADRay ODH test
    [Documentation]    Run Go ODH test: TestMCADRay
    [Tags]  ODS-2514
    ...     Tier1
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Skip    "Skip because of https://issues.redhat.com/browse/RHOAIENG-3981"
    Run Codeflare ODH Test    TestMCADRay

Run TestMnistPyTorchMCAD ODH test
    [Documentation]    Run Go ODH test: TestMnistPyTorchMCAD
    [Tags]  ODS-2515
    ...     Tier1
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistPyTorchMCAD


*** Keywords ***
Prepare Codeflare E2E Test Suite
    Enable Component    ray
    Enable Component    codeflare
    Wait Component Ready    ray
    Wait Component Ready    codeflare
    Create Directory    %{WORKSPACE}/codeflare-e2e-logs
    Create Directory    %{WORKSPACE}/codeflare-odh-logs
    RHOSi Setup

Teardown Codeflare E2E Test Suite
    Log To Console    "Removing test binaries"
    ${result} =    Run Process    rm -f e2e odh
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to remove compiled binaries
    END
    Disable Component    codeflare
    Disable Component    ray
    RHOSi Teardown

Run Codeflare E2E Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Downloading compiled test binary e2e"
    ${result} =    Run Process    curl --location --silent --output e2e ${CODEFLARE_RELEASE_ASSETS}/e2e && chmod +x e2e
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve e2e compiled binary
    END
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    ./e2e -test.run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:CODEFLARE_TEST_TIMEOUT_SHORT=5m
    ...    env:CODEFLARE_TEST_TIMEOUT_MEDIUM=10m
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=20m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-e2e-logs
    ...    env:MNIST_DATASET_URL=https://ossci-datasets.s3.amazonaws.com/mnist/
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END

Run Codeflare ODH Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Downloading compiled test binary odh"
    ${result} =    Run Process    curl --location --silent --output odh ${CODEFLARE_RELEASE_ASSETS}/odh && chmod +x odh
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve odh compiled binary
    END
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    ./odh -test.run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
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
