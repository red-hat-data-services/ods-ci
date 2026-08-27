*** Settings ***
Documentation     Feast Modular Operator tests - https://github.com/opendatahub-io/feast-module-operator/tree/main/test/e2e
Suite Setup       Prepare Feast Modular Operator E2E Test Suite
Suite Teardown    Teardown Feast Modular Operator E2E Test Suite
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Common.robot
Resource          ../../Resources/Page/FeatureStore/FeatureStore.resource
Test Tags         ExcludeOnODH


*** Test Cases ***
Run TestFeastModularOperator foundation test
    [Documentation]    Run Go E2E test: TestFeastModularOperator (test/e2e/e2e_foundation_test.go)
    [Tags]  Smoke
    ...     FeatureStore
    ...     FeatureStoreModular
    ...     RHOAIENG-31299
    Run Feast Module Operator Test    TestFeastOperator    e2e
