*** Settings ***
Documentation     Feast Operator E2E tests - https://github.com/opendatahub-io/feast/tree/master/infra/feast-operator/test/e2e
Suite Setup       Prepare Feast E2E Test Suite
Suite Teardown    Teardown Feast E2E Test Suite
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Common.robot
Resource          ../../Resources/Page/FeatureStore/FeatureStore.resource


*** Variables ***
${FEATURE-STORE-RELEASE-TAG}             adjustment-release-v0.48.1
${FEATURE-STORE_DIR}                     feature-store
${FEATURE-STORE_REPO_URL}                %{FEATURE-STORE_REPO_URL=https://github.com/opendatahub-io/feast.git}


*** Test Cases ***
Run runTestDeploySimpleCRFunc test
    [Documentation]    Run Go E2E test: runTestDeploySimpleCRFunc
    [Tags]  Sanity
    ...     FeatureStore
    ...     RHOAIENG-14799
    Run Feast Operator E2E Test    TesDefaultFeastCR

Run runTestWithRemoteRegistryFunction test
    [Documentation]    Run Go E2E test: runTestWithRemoteRegistryFunction
    [Tags]  Sanity
    ...     FeatureStore
    ...     RHOAIENG-14799
    Run Feast Operator E2E Test    TestRemoteRegistryFeastCR


*** Keywords ***
Prepare Feast E2E Test Suite
    [Documentation]    Prepare Feast E2E Test Suite
    Log To Console    Preparing Feast E2E Test Suite
    Log To Console    "Cloning Git reposiotory ${FEATURE-STORE_REPO_URL}"
    Common.Clone Git Repository    ${FEATURE-STORE_REPO_URL}    ${FEATURE-STORE-RELEASE-TAG}    ${FEATURE-STORE_DIR}
    Prepare Feature Store Test Suite
    Skip If Component Is Not Enabled     feastoperator

Teardown Feast E2E Test Suite
    [Documentation]   Cleanup directory and Feast E2E Test Suite
    Log To Console     "Removing directory ${FEATURE-STORE_DIR}"
    Remove Directory        ${FEATURE-STORE_DIR}    recursive=True
    Cleanup Feature Store Setup
