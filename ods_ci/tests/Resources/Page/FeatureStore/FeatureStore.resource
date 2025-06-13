*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process
Resource         ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Variables ***
${FEATURE-STORE-RELEASE-TAG}             adjustment-release-v0.49.0
${FEATURE-STORE_DIR}                     feature-store
${FEATURE-STORE_REPO_URL}                %{FEATURE-STORE_REPO_URL=https://github.com/opendatahub-io/feast.git}


*** Keywords ***
Prepare Feature Store Test Suite
    [Documentation]   Prepare Feature store setup by enabling component
    RHOSi Setup
    Enable Component    feastoperator
    Wait Component Ready    feastoperator

Cleanup Feature Store Setup
    [Documentation]   cleanup Feature store setup by Disabling component
    Disable Component    feastoperator
    RHOSi Teardown

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

Run Feast Operator E2E Test
    [Documentation]   Run feast operator e2e test
    [Arguments]   ${TEST_NAME}
    Log To Console    "Running feature-store operator e2e test: ${TEST_NAME}"
    ${command}=    Set Variable    cd ${FEATURE-STORE_DIR}/infra/feast-operator && git fetch origin && git checkout ${FEATURE-STORE-RELEASE-TAG} && git branch && go test -timeout 5m ./test/e2e/ -v -ginkgo.focus=${TEST_NAME}
    ${result}=    Run Process    ${command}
    ...    shell=true
    ...    env:RUN_ON_OPENSHIFT_CI=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running test ${TEST_NAME} failed
    END

Prepare Feature Store Upgrade Test
    [Documentation]   Prepare feast operator upgrade test suite
    Log To Console    Preparing Feast Upgrade Test Suite
    # Patching with oc add , as replace will fail due to after post upgrade feast component spec missing in DSC (https://issues.redhat.com/browse/RHOAIENG-24221)
    ${result} =    Run Process    oc get datascienceclusters.datasciencecluster.opendatahub.io -o name
    ...    shell=true    stderr=STDOUT
    IF    $result.stdout == ""
        FAIL    Can not find datasciencecluster
    END
    ${cluster_name} =    Set Variable    ${result.stdout}
    ${result} =    Run Process    oc patch ${cluster_name} --type 'json' -p '[{"op": "add", "path": "/spec/components/feastoperator", "value": {"managementState": "Managed"}}]'
    ...    shell=true    stderr=STDOUT
    IF    $result.rc != 0
        FAIL    Can not enable feature store: ${result.stdout}
    END
    Log To Console    Component feature store state was set to Managed
    Prepare Feast E2E Test Suite
