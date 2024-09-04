*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process


*** Variables ***
${VIRTUAL_ENV_NAME}                      venv3.9
${CODEFLARE-SDK-API_URL}                 %{CODEFLARE-SDK-API_URL=https://api.github.com/repos/project-codeflare/codeflare-sdk/releases/latest}
${CODEFLARE-SDK_DIR}                     codeflare-sdk
${CODEFLARE-SDK_REPO_URL}                %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}
${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS}  https://github.com/opendatahub-io/distributed-workloads/releases/latest/download
${FMS_HF_TUNING_IMAGE}                   quay.io/modh/fms-hf-tuning@sha256:8edea6f0f9c4c631cdca1e1c10abf0d4b994738fde78c40d48eda216fdd382f5
${KFTO_CORE_BINARY_NAME}                 kfto
${KFTO_UPGRADE_BINARY_NAME}              kfto-upgrade


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

Prepare Codeflare-SDK Test Setup
    [Documentation]   Prepare codeflare-sdk tests by cloning codeflare-sdk repo and python virtual environmnet

    Log To Console    "Restarting kueue"
    Restart Kueue

    ${latest_tag} =    Run Process   curl -s "${CODEFLARE-SDK-API_URL}" | grep '"tag_name":' | cut -d '"' -f 4
    ...    shell=True    stderr=STDOUT
    Log To Console  codeflare-sdk latest tag is : ${latest_tag.stdout}
    IF    ${latest_tag.rc} != 0
        FAIL    Unable to fetch codeflare-sdk latest tag
    END

    Clone Git Repository    ${CODEFLARE-SDK_REPO_URL}    ${latest_tag.stdout}    ${CODEFLARE-SDK_DIR}

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

Restart Kueue
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

Prepare Training Operator E2E Core Test Suite
    [Documentation]    Prepare Training Operator E2E Core Test Suite
    Prepare Training Operator E2E Test Suite    ${KFTO_CORE_BINARY_NAME}

Prepare Training Operator E2E Upgrade Test Suite
    [Documentation]    Prepare Training Operator E2E Upgrade Test Suite
    Prepare Training Operator E2E Test Suite    ${KFTO_UPGRADE_BINARY_NAME}

Prepare Training Operator E2E Test Suite
    [Documentation]    Prepare Training Operator E2E Test Suite
    [Arguments]        ${test_binary}
    Log To Console    "Downloading compiled test binary ${test_binary}"
    ${result} =    Run Process    curl --location --silent --output ${test_binary} ${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS}/${test_binary} && chmod +x ${test_binary}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve ${test_binary} compiled binary
    END
    Create Directory    %{WORKSPACE}/codeflare-${test_binary}-logs
    Enable Component    trainingoperator
    Wait Component Ready    trainingoperator
    Log To Console    "Restarting kueue"
    Restart Kueue

Teardown Training Operator E2E Core Test Suite
    [Documentation]    Prepare Training Operator E2E Core Test Suite
    Teardown Training Operator E2E Test Suite    ${KFTO_CORE_BINARY_NAME}

Teardown Training Operator E2E Upgrade Test Suite
    [Documentation]    Prepare Training Operator E2E Upgrade Test Suite
    Teardown Training Operator E2E Test Suite    ${KFTO_UPGRADE_BINARY_NAME}

Teardown Training Operator E2E Test Suite
    [Documentation]    Teardown Training Operator E2E Test Suite
    [Arguments]        ${test_binary}
    Log To Console     "Removing test binaries"
    Remove File        ${test_binary}
    Disable Component    trainingoperator

Run Training Operator ODH Core Test
    [Documentation]    Run Training Operator ODH Core Test
    [Arguments]    ${TEST_NAME}
    Run Training Operator ODH Test   ${TEST_NAME}   ${KFTO_CORE_BINARY_NAME}

Run Training Operator ODH Upgrade Test
    [Documentation]    Run Training Operator ODH Upgrade Test
    [Arguments]    ${TEST_NAME}
    Run Training Operator ODH Test   ${TEST_NAME}   ${KFTO_UPGRADE_BINARY_NAME}

Run Training Operator ODH Test
    [Documentation]    Run Training Operator ODH Test
    [Arguments]    ${TEST_NAME}    ${test_binary}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    ./${test_binary} -test.run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:CODEFLARE_TEST_TIMEOUT_SHORT=5m
    ...    env:CODEFLARE_TEST_TIMEOUT_MEDIUM=10m
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=20m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-${test_binary}-logs
    ...    env:FMS_HF_TUNING_IMAGE=${FMS_HF_TUNING_IMAGE}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END
