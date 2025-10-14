*** Settings ***
Documentation     Feast Operator E2E tests - https://github.com/opendatahub-io/feast/tree/master/infra/feast-operator/test/e2e
Suite Setup       Prepare Feast E2E Test Suite
Suite Teardown    Teardown Feast E2E Test Suite
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Common.robot
Resource          ../../Resources/Page/FeatureStore/FeatureStore.resource
Test Tags         ExcludeOnODH


*** Variables ***
${FEAST_CR_FILE}=       tests/Resources/Page/FeatureStore/feature_store_cr.yaml
${PRJ_TITLE}=           test-ns-feast-images
${FEAST_INSTANCE_NAME}=  test-image-reference


*** Test Cases ***
Run runTestDeploySimpleCRFunc test
    [Documentation]    Run Go E2E test: runTestDeploySimpleCRFunc
    [Tags]  Sanity
    ...     FeatureStore
    ...     RHOAIENG-14799
    Run Feast Operator E2E Test    TesDefaultFeastCR    e2e

Run runTestWithRemoteRegistryFunction test
    [Documentation]    Run Go E2E test: runTestWithRemoteRegistryFunction
    [Tags]  Sanity
    ...     FeatureStore
    ...     RHOAIENG-14799
    Run Feast Operator E2E Test    TestRemoteRegistryFeastCR    e2e

Run runTestApplyAndMaterializeFeastDefinitions test
    [Documentation]    Run Go E2E test: TestApplyAndMaterializeFeastDefinitions
    [Tags]  Tier1
    ...     FeatureStore
    ...     RHOAIENG-26460
    Run Feast Operator E2E Test    TestApplyAndMaterializeFeastDefinitions    e2e

Verify Feast Instances Utilizing Correct Feature Server Images
    [Documentation]   Verify that the Feast instance correctly references the expected Feature Server image
    [Tags]  Sanity
    ...     FeatureStore
    ...     RHOAIENG-23500
    Log To Console    Creating Data Science Project ${PRJ_TITLE}
    Create Data Science Project From CLI    ${PRJ_TITLE}    as_user=${OCP_ADMIN_USER.USERNAME}
    Create Feast Instance    ${PRJ_TITLE}    ${FEAST_INSTANCE_NAME}    ${FEAST_CR_FILE}
    Log To Console    Waiting for Feast Project ${FEAST_INSTANCE_NAME} Pods to be ready
    Wait For Pods To Be Ready    feast.dev/name=${FEAST_INSTANCE_NAME}    ${PRJ_TITLE}
    Check Feast Instance Pod Images Pull Path Is Correct    ${PRJ_TITLE}    feast-${FEAST_INSTANCE_NAME}    registry.redhat.io
    [Teardown]    Delete Feast Instance And Project    ${PRJ_TITLE}    ${FEAST_INSTANCE_NAME}
