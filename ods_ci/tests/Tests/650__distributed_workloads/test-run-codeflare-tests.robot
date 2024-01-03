*** Settings ***
Documentation     Codeflare operator E2E tests - https://github.com/opendatahub-io/codeflare-operator/tree/main/test/odh
Suite Setup       Prepare Codeflare E2E Test Suite
Suite Teardown    Teardown Codeflare E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../Resources/Common.robot


*** Variables ***
${CODEFLARE_DIR}                codeflare-operator
${CODEFLARE_REPO_URL}           %{CODEFLARE_REPO_URL=https://github.com/opendatahub-io/codeflare-operator.git}
${CODEFLARE_REPO_BRANCH}        %{CODEFLARE_REPO_BRANCH=main}
${ODH_NAMESPACE}                %{ODH_NAMESPACE=redhat-ods-applications}
${NOTEBOOK_IMAGE_STREAM_NAME}   %{NOTEBOOK_IMAGE_STREAM_NAME=s2i-generic-data-science-notebook}
${CLUSTER_TYPE}                 ${EMPTY}

*** Test Cases ***
Run TestMNISTPyTorchMCAD E2E test
    [Documentation]    Run Go E2E test: TestMNISTPyTorchMCAD
    [Tags]  ODS-2543
    ...     Tier2
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare E2E Test    TestMNISTPyTorchMCAD

Run TestMNISTRayClusterSDK E2E test
    [Documentation]    Run Go E2E test: TestMNISTRayClusterSDK
    [Tags]  ODS-2544
    ...     Tier2
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare E2E Test    TestMNISTRayClusterSDK

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

Run TestInstascaleMachineSet E2E test
    [Documentation]    Run Go E2E test TestInstascaleMachineSet
    # This particular test runs on OCP cluster with AWS
    [Tags]  Instascale
    ...     Tier3
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Skip If RHODS Is Managed

    # Enable instascale to true in the codeflare operator config map
    Enable Instascale

    # Create machine set
    Log To Console    "Create machine set ....."
    ${result} =    Run Process    sh    ods_ci/tests/Resources/Files/machineset-template.sh
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL    Can not create machine set
    END

    # Delete the existing GPU machineset
    # This needs to be done as part of test execution and a corresponding jira is tracked here - https://issues.redhat.com/browse/RHOAIENG-1118
    ${result} =    Run Process    oc get machineset -n openshift-machine-api -o name | head -n1
    ...    shell=true    stderr=STDOUT
    Run Process    oc delete ${result.stdout} -n openshift-machine-api    shell=true

    Set Suite Variable    ${CLUSTER_TYPE}    OCP

    # Run TestInstascaleMachineSet test
    Run Codeflare E2E Test    TestInstascaleMachineSet

*** Keywords ***
Prepare Codeflare E2E Test Suite
    ${result} =    Run Process    git clone -b ${CODEFLARE_REPO_BRANCH} ${CODEFLARE_REPO_URL} ${CODEFLARE_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone Codeflare repo ${CODEFLARE_REPO_URL}:${CODEFLARE_REPO_BRANCH}
    END
    
    ${result} =    Run Process    oc patch datascienceclusters.datasciencecluster.opendatahub.io default-dsc --type 'json' -p '[{"op" : "replace" ,"path" : "/spec/components/ray/managementState" ,"value" : "Managed"}]'
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL    Can not enable ray
    END
    ${result} =    Run Process    oc patch datascienceclusters.datasciencecluster.opendatahub.io default-dsc --type 'json' -p '[{"op" : "replace" ,"path" : "/spec/components/codeflare/managementState" ,"value" : "Managed"}]'
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL    Can not enable codeflare
    END
    Create Directory    %{WORKSPACE}/codeflare-e2e-logs
    Create Directory    %{WORKSPACE}/codeflare-odh-logs

Teardown Codeflare E2E Test Suite
    ${result} =    Run Process    oc patch datascienceclusters.datasciencecluster.opendatahub.io default-dsc --type 'json' -p '[{"op" : "replace" ,"path" : "/spec/components/codeflare/managementState" ,"value" : "Removed"}]'
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL    Can not disable codeflare
    END
    ${result} =    Run Process    oc patch datascienceclusters.datasciencecluster.opendatahub.io default-dsc --type 'json' -p '[{"op" : "replace" ,"path" : "/spec/components/ray/managementState" ,"value" : "Removed"}]'
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL    Can not disable ray
    END

Run Codeflare E2E Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    go test -timeout 30m -v ./test/e2e -run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    cwd=${CODEFLARE_DIR}
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=30m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-e2e-logs
    ...    env:CLUSTER_TYPE=${CLUSTER_TYPE}
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
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=30m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-odh-logs
    ...    env:ODH_NAMESPACE=${ODH_NAMESPACE}
    ...    env:NOTEBOOK_IMAGE_STREAM_NAME=${NOTEBOOK_IMAGE_STREAM_NAME}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END

Enable Instascale
    Log To Console    "Enable instascale to true in config map ....."
    ${result} =    Run Process    oc get cm codeflare-operator-config -n redhat-ods-applications -o yaml | sed -e 's|enabled: false|enabled: true|' | oc apply -f -
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL    Can not enable instascale to true
    END
