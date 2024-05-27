*** Settings ***
Documentation     Training operator E2E tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/kfto
Suite Setup       Prepare Training Operator E2E Test Suite
Suite Teardown    Teardown Training Operator E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Variables ***
${TRAINING_OPERATOR_RELEASE_ASSETS}     %{TRAINING_OPERATOR_RELEASE_ASSETS=https://github.com/opendatahub-io/distributed-workloads/releases/latest/download}


*** Test Cases ***
Run Training operator ODH test base use case
    [Documentation]    Run Go ODH tests for Training operator base use case
    [Tags]  RHOAIENG-6965
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingOperator
    Run Training Operator ODH Test    TestPytorchjobWithSFTtrainer

Run Training operator ODH test with Kueue quota
    [Documentation]    Run Go ODH tests for Training operator with Kueue quota
    [Tags]  RHOAIENG-6965
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingOperator
    Run Training Operator ODH Test    TestPytorchjobUsingKueueQuota


*** Keywords ***
Prepare Training Operator E2E Test Suite
    [Documentation]    Prepare Training Operator E2E Test Suite
    Log To Console    "Downloading compiled test binary kfto"
    ${result} =    Run Process    curl --location --silent --output kfto ${TRAINING_OPERATOR_RELEASE_ASSETS}/kfto && chmod +x kfto
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve kfto compiled binary
    END
    Create Directory    %{WORKSPACE}/codeflare-kfto-logs
    Enable Component    trainingoperator
    Wait Component Ready    trainingoperator
    RHOSi Setup

Teardown Training Operator E2E Test Suite
    [Documentation]    Teardown Training Operator E2E Test Suite
    Log To Console    "Removing test binaries"
    ${result} =    Run Process    rm -f kfto
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to remove compiled binaries
    END
    Disable Component    trainingoperator
    RHOSi Teardown

Run Training Operator ODH Test
    [Documentation]    Run Training Operator ODH Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    ./kfto -test.run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:CODEFLARE_TEST_TIMEOUT_SHORT=5m
    ...    env:CODEFLARE_TEST_TIMEOUT_MEDIUM=10m
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=20m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-kfto-logs
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END
