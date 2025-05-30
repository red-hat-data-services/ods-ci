*** Settings ***
Documentation     Feast Operator E2E tests - https://github.com/opendatahub-io/feast/tree/master/infra/feast-operator/test/e2e
Suite Setup       Prepare Feast E2E Test Suite
Suite Teardown    Teardown Feast E2E Test Suite
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Common.robot
Resource          ../../Resources/Page/FeatureStore/FeatureStore.resource


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

Run runTestApplyAndMaterializeFeastDefinitions test
    [Documentation]    Run Go E2E test: TestApplyAndMaterializeFeastDefinitions
    [Tags]  Tier1
    ...     FeatureStore
    ...     RHOAIENG-26460
    Run Feast Operator E2E Test    TestApplyAndMaterializeFeastDefinitions
