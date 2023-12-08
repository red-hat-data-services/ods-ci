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
${CLUSTER_ID}

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

Run TestInstascaleMachinePool test
    [Documentation]    Run Go E2E test TestInstascaleMachinePool
    ...                This particular test runs on OSD cluster
    [Tags]  Instascale
    ...     Tier3
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Skip If RHODS Is Self-Managed

    # Generate ocm token and create a secret
    Log To Console    "Generating token ....."
    ${token} =    Run Process    ocm token --generate
    ...    shell=true    stderr=STDOUT
    IF    ${token.rc} != 0
        FAIL    Can not generate token
    END
    Create Instascale Secret    ${token.stdout}

    # Set instascale to true in the codeflare operator config map
    Log To Console    "Setting instascale to true in config map ....."
    ${result} =    Run Process    oc get cm codeflare-operator-config -n redhat-ods-applications -o yaml | sed -e 's|enabled: false|enabled: true|' | oc apply -f -
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL    Can not enable instascale to true
    END

    #Fetch cluster ID
    Log To Console    "Fetching cluster ID ....."
    ${cluster_id} =    Run Process    ocm list clusters | grep %{TEST_CLUSTER} | awk '{print $1}'
        ...    shell=true    stderr=STDOUT
    IF    ${cluster_id.rc} != 0
        FAIL    Can not fetch cluster details
    END
    Set Suite Variable    ${CLUSTER_ID}    ${cluster_id.stdout}

    # Run TestInstascaleMachinePool test
    Run Codeflare E2E Test    TestInstascaleMachinePool

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
    ${result} =    Run Process    oc patch datascienceclusters.datasciencecluster.opendatahub.io rhods --type 'json' -p '[{"op" : "replace" ,"path" : "/spec/components/codeflare/managementState" ,"value" : "Removed"}]'
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL    Can not disable codeflare
    END
    ${result} =    Run Process    oc patch datascienceclusters.datasciencecluster.opendatahub.io rhods --type 'json' -p '[{"op" : "replace" ,"path" : "/spec/components/ray/managementState" ,"value" : "Removed"}]'
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
    ...    env:CLUSTER_TYPE=OSD
    ...    env:CLUSTERID=${CLUSTER_ID}
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

Create Instascale Secret
    [Arguments]    ${TOKEN}
    Log To Console    "Creating Instascale secret ....."
    Run    oc create secret generic instascale-ocm-secret -n default --from-literal=token=${TOKEN}