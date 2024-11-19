*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process

Resource    ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot

*** Variables ***
${CODEFLARE_TEST_TIMEOUT_LONG}    20m
${GO_TEST_TIMEOUT}    1h
${JOB_GO_BIN}    %{WORKSPACE=.}/go-bin
${GO_JUNIT_REPORT_TOOL}    github.com/jstemmer/go-junit-report/v2@latest
# Using DISTRIBUTED_WORKLOADS_RELEASE_ASSETS from 2.12 as 2.10 version doesn't contain sleep upgrade test.
# Using newer release asset is ok as the binary contains just test resources
${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS}  https://github.com/opendatahub-io/distributed-workloads/releases/download/v2.12.0-RC1
${FMS_HF_TUNING_IMAGE}                   quay.io/modh/fms-hf-tuning@sha256:31489be603af448a6e5d25d558ba9ae1d93038d16c08a8500595e63abd54c216
${KFTO_UPGRADE_BINARY_NAME}              kfto-upgrade
${VIRTUAL_ENV_NAME}                      venv3.9
# Supported codeflare-sdk version for 2.10 release is "v0.16.1"
${CODEFLARE-SDK_DIR}                     codeflare-sdk
${CODEFLARE-SDK_REPO_URL}                %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}
${CODEFLARE-SDK-RELEASE-TAG}             adjustments-release-0.16.1


*** Keywords ***
Clone Git Repository
    [Documentation]   Clone Git repository
    [Arguments]    ${DW_REPO_URL}    ${DW_REPO_BRANCH}    ${DW_DIR}
    ${result} =    Run Process    git clone -b ${DW_REPO_BRANCH} ${DW_REPO_URL} ${DW_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone DW repo ${DW_REPO_URL}:${DW_REPO_BRANCH}:${DW_DIR}
    END

Run Distributed Workloads Tests
    [Documentation]   Run distributed workloads E2E tests from integration directory
    [Arguments]    ${DW_DIR}    ${DW_TEST_RESULT_FILE}    ${TEST_PARAMETERS}
    ${result} =    Run Process
    ...    go test -v -timeout ${GO_TEST_TIMEOUT} ./integration ${TEST_PARAMETERS} 2>&1 > ${DW_TEST_RESULT_FILE}
    ...    shell=true    cwd=${DW_DIR}/tests    env:ODH_NAMESPACE=redhat-ods-applications
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=${CODEFLARE_TEST_TIMEOUT_LONG}
    ...    env:CODEFLARE_TEST_RAY_IMAGE=quay.io/project-codeflare/ray:2.5.0-py38-cu116
    Log To Console    ${result.stdout}
    ${test_output}=    Get File    ${DW_TEST_RESULT_FILE}
    Log To Console    ${test_output}
    RETURN    ${result.rc}

Install Go Junit Report Tool
    [Documentation]   Use Go install command to install Go Junit report tool
    ${result} =    Run Process    go install ${GO_JUNIT_REPORT_TOOL}
    ...    shell=true    env:GOBIN=${JOB_GO_BIN}    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to install Go junit report tool
    END

Convert Go Test Results To Junit
    [Documentation]   Use Go Junit report tool to convert Go test results to Junit
    [Arguments]    ${DW_TEST_RESULT_FILE}    ${DW_JUNIT_FILE}
    ${result} =    Run Process    ${JOB_GO_BIN}/go-junit-report -in ${DW_TEST_RESULT_FILE} -iocopy -out ${DW_JUNIT_FILE}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to convert Go test results to Junit
    END

Restart Kueue
    [Documentation]    Restart Kueue to be able to monitor PyTorchJob CRs
    Log To Console    "Rollout restart kueue-controller-manager"
    ${result} =    Run Process    oc rollout restart deployment/kueue-controller-manager -n ${APPLICATIONS_NAMESPACE}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to restart Kueue
    END

    Log To Console    "Wait for kueue-controller-manager rollout to finish"
    ${result} =    Run Process    oc rollout status deployment/kueue-controller-manager -w -n ${APPLICATIONS_NAMESPACE}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to finish Kueue rollout
    END

Prepare Training Operator E2E Upgrade Test Suite
    [Documentation]    Prepare Training Operator E2E Upgrade Test Suite
    Log To Console    "Downloading compiled test binary ${KFTO_UPGRADE_BINARY_NAME}"
    ${result} =    Run Process    curl --location --silent --output ${KFTO_UPGRADE_BINARY_NAME} ${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS}/${KFTO_UPGRADE_BINARY_NAME} && chmod +x ${KFTO_UPGRADE_BINARY_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve ${KFTO_UPGRADE_BINARY_NAME} compiled binary
    END
    Create Directory    %{WORKSPACE}/codeflare-${KFTO_UPGRADE_BINARY_NAME}-logs
    Enable Component    trainingoperator
    Wait Component Ready    trainingoperator
    Log To Console    "Restarting kueue"
    Restart Kueue

Teardown Training Operator E2E Upgrade Test Suite
    [Documentation]    Prepare Training Operator E2E Upgrade Test Suite
    Log To Console     "Removing test binaries"
    Remove File        ${KFTO_UPGRADE_BINARY_NAME}
    Disable Component    trainingoperator

Run Training Operator ODH Upgrade Test
    [Documentation]    Run Training Operator ODH Upgrade Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    ./${KFTO_UPGRADE_BINARY_NAME} -test.run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:CODEFLARE_TEST_TIMEOUT_SHORT=5m
    ...    env:CODEFLARE_TEST_TIMEOUT_MEDIUM=10m
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=20m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-${KFTO_UPGRADE_BINARY_NAME}-logs
    ...    env:FMS_HF_TUNING_IMAGE=${FMS_HF_TUNING_IMAGE}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END

Prepare Codeflare-SDK Test Setup
    [Documentation]   Prepare codeflare-sdk tests by cloning codeflare-sdk repo and python virtual environmnet

    Log To Console    "Restarting kueue"
    Restart Kueue

    Clone Git Repository    ${CODEFLARE-SDK_REPO_URL}    ${CODEFLARE-SDK-RELEASE-TAG}    ${CODEFLARE-SDK_DIR}

    ${result} =    Run Process  virtualenv -p python3.9 ${VIRTUAL_ENV_NAME}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to setup Python virtual environment
    END

Run Codeflare-SDK Test
    [Documentation]   Run codeflare-sdk Test
    [Arguments]    ${TEST_TYPE}    ${TEST_NAME}
    Log To Console    "Running codeflare-sdk test: ${TEST_NAME}"
    ${result} =    Run Process  source ${VIRTUAL_ENV_NAME}/bin/activate && cd ${CODEFLARE-SDK_DIR} && poetry env use 3.9 && poetry install --with test,docs && poetry run pytest -v -s ./tests/${TEST_TYPE}/${TEST_NAME} --timeout\=300 && deactivate
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running test ${TEST_NAME} failed
    END

Codeflare Upgrade Tests Teardown
    [Documentation]   cleanup codeflare-SDK upgrade tests resources created
    [Arguments]    ${project_name}    ${project_created}
    IF    ${project_created} == True    Run Keywords
    ...    Run   oc delete project ${project_name}    AND
    ...    Run Process    oc delete LocalQueue local-queue-mnist -n ${project_name} &
    ...    oc delete ClusterQueue cluster-queue-mnist &
    ...    oc delete ResourceFlavor default-flavor-mnist    shell=True

Cleanup Codeflare-SDK Setup
    [Documentation]   cleanup codeflare repository cloned and python setup
    Log To Console     "Removing Python virtual environment directory ${VIRTUAL_ENV_NAME}"
    Remove Directory        ${VIRTUAL_ENV_NAME}    recursive=True

    Log To Console     "Removing directory ${CODEFLARE-SDK_DIR}"
    Remove Directory        ${CODEFLARE-SDK_DIR}    recursive=True
