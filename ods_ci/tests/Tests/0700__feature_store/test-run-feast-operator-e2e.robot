*** Settings ***
Documentation     Feast Operator E2E tests - https://github.com/feast-dev/feast/tree/master/infra/feast-operator/test/e2e
Suite Setup       Prepare Feast E2E Test Suite
Suite Teardown    Teardown Feast E2E Test Suite
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Common.robot

*** Variables ***
${FEAST_RELEASE_ASSETS}          %{FEAST_RELEASE_ASSETS=https://raw.githubusercontent.com/feast-dev/feast/master/infra/feast-operator/dist/}
${E2E_TESTS_BINARY_NAME}         %{E2E_TESTS_BINARY_NAME=operator-e2e-tests}

*** Test Cases ***
Run runTestDeploySimpleCRFunc test
    [Documentation]    Run Go E2E test: runTestDeploySimpleCRFunc
    [Tags]  smoke
    ...     FeatureStore
    Run Feast E2E Test    "Should be able to deploy and run a default feature store CR successfully"

Run runTestWithRemoteRegistryFunction test
    [Documentation]    Run Go E2E test: runTestWithRemoteRegistryFunction
    [Tags]  smoke
    ...     FeatureStore
    Run Feast E2E Test    "Should be able to deploy and run a feature store with remote registry CR successfully"

*** Keywords ***
Prepare Feast E2E Test Suite
    [Documentation]    Prepare Feast E2E Test Suite
    Skip If Component Is Not Enabled     feastoperator
    Log To Console    Preparing Feast E2E Test Suite
    Log To Console    "Downloading compiled test binary ${E2E_TESTS_BINARY_NAME}"
    ${result} =    Run Process    curl --location --silent --output ${E2E_TESTS_BINARY_NAME} ${FEAST_RELEASE_ASSETS}/${E2E_TESTS_BINARY_NAME} && chmod +x ${E2E_TESTS_BINARY_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve ${E2E_TESTS_BINARY_NAME} compiled binary
    END

Teardown Feast E2E Test Suite
    [Documentation]   cleanup binaries downloaded
    Log To Console     "Removing test binaries"
    Remove File        ${E2E_TESTS_BINARY_NAME}

Run Feast E2E Test
    [Documentation]    Run Feast Operator E2E Test
    [Arguments]    ${test_name}
    Log To Console    Running Feast E2E test: ${test_name}
    ${result} =    Run Process    ./${E2E_TESTS_BINARY_NAME} -test.run ${test_name}
    ...    env=RUN_ON_OPENSHIFT_CI:true
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${test_name} failed
    END
