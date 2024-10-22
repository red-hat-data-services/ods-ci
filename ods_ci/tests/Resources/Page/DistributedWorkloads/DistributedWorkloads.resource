*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process


*** Variables ***
${VIRTUAL_ENV_NAME}                      venv3.9
${CODEFLARE-SDK-RELEASE-TAG}             v0.22.0
${CODEFLARE-SDK_DIR}                     codeflare-sdk
${CODEFLARE-SDK_REPO_URL}                %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}
${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS}  https://github.com/opendatahub-io/distributed-workloads/releases/latest/download
${RAY_IMAGE}                             quay.io/modh/ray@sha256:0d715f92570a2997381b7cafc0e224cfa25323f18b9545acfd23bc2b71576d06
${FMS_HF_TUNING_IMAGE}                   quay.io/modh/fms-hf-tuning@sha256:73bcd66500b8637a9db1339f64c3217212ef74700a22a790f78e9a1f26b8b71a
${NOTEBOOK_IMAGE}                        quay.io/modh/odh-generic-data-science-notebook@sha256:9d7f80080a453bcf7dee01b986df9ee811ee74f6f433c601a8b67d283c160547
${NOTEBOOK_USER_NAME}                    ${TEST_USER_3.USERNAME}
${NOTEBOOK_USER_PASSWORD}                ${TEST_USER_3.PASSWORD}
${KFTO_CORE_BINARY_NAME}                 kfto
${KFTO_UPGRADE_BINARY_NAME}              kfto-upgrade
${ODH_BINARY_NAME}                       odh
${PIP_INDEX_URL}                         ${PIP_INDEX_URL}
${PIP_TRUSTED_HOST}                      ${PIP_TRUSTED_HOST}
${AWS_DEFAULT_ENDPOINT}                  ${S3.BUCKET_5.ENDPOINT}
${AWS_STORAGE_BUCKET}                    ${S3.BUCKET_5.NAME}
${AWS_ACCESS_KEY_ID}                     ${S3.AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}                 ${S3.AWS_SECRET_ACCESS_KEY}
${AWS_STORAGE_BUCKET_MNIST_DIR}          mnist-datasets


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
    ...    env:RAY_IMAGE=${RAY_IMAGE}
    ...    env:AWS_DEFAULT_ENDPOINT=${AWS_DEFAULT_ENDPOINT}
    ...    env:AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
    ...    env:AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    ...    env:AWS_STORAGE_BUCKET=${AWS_STORAGE_BUCKET}
    ...    env:AWS_STORAGE_BUCKET_MNIST_DIR=${AWS_STORAGE_BUCKET_MNIST_DIR}
    ...    env:PIP_INDEX_URL=${PIP_INDEX_URL}
    ...    env:PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}
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

Prepare DistributedWorkloads Integration Test Suite
    [Documentation]    Prepare DistributedWorkloads Integration Test Suite
    Log To Console    "Downloading compiled test binary ${ODH_BINARY_NAME}"

    ${result} =    Run Process    curl --location --silent --output ${ODH_BINARY_NAME} ${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS}/${ODH_BINARY_NAME} && chmod +x ${ODH_BINARY_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve odh compiled binary
    END
    Create Directory    %{WORKSPACE}/distributed-workloads-odh-logs
    Log To Console    "Retrieving user tokens"
    ${common_user_token} =    Generate User Token    ${NOTEBOOK_USER_NAME}    ${NOTEBOOK_USER_PASSWORD}
    Set Suite Variable    ${NOTEBOOK_USER_TOKEN}   ${common_user_token}
    Log To Console    "Log back as cluster admin"
    Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}
    RHOSi Setup

Teardown DistributedWorkloads Integration Test Suite
    [Documentation]    Teardown DistributedWorkloads Integration Test Suite
    Log To Console    "Log back as cluster admin"
    Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}
    Log To Console    "Removing test binaries"
    Remove File        ${ODH_BINARY_NAME}
    RHOSi Teardown

Generate User Token
    [Documentation]    Authenticate as a user and return user token.
    [Arguments]    ${username}    ${password}
    Login To OCP Using API    ${username}    ${password}
    ${rc}    ${out} =    Run And Return Rc And Output    oc whoami -t
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${out}

Run DistributedWorkloads ODH Test
    [Documentation]    Run DistributedWorkloads ODH Test
    [Arguments]    ${TEST_NAME}    ${DW_RAY_IMAGE}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    ./${ODH_BINARY_NAME} -test.run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:CODEFLARE_TEST_TIMEOUT_SHORT=5m
    ...    env:CODEFLARE_TEST_TIMEOUT_MEDIUM=10m
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=20m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/distributed-workloads-odh-logs
    ...    env:CODEFLARE_TEST_RAY_IMAGE=${DW_RAY_IMAGE}
    ...    env:ODH_NAMESPACE=${APPLICATIONS_NAMESPACE}
    ...    env:NOTEBOOK_USER_NAME=${NOTEBOOK_USER_NAME}
    ...    env:NOTEBOOK_USER_TOKEN=${NOTEBOOK_USER_TOKEN}
    ...    env:NOTEBOOK_IMAGE=${NOTEBOOK_IMAGE}
    ...    env:AWS_DEFAULT_ENDPOINT=${AWS_DEFAULT_ENDPOINT}
    ...    env:AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
    ...    env:AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    ...    env:AWS_STORAGE_BUCKET=${AWS_STORAGE_BUCKET}
    ...    env:AWS_STORAGE_BUCKET_MNIST_DIR=${AWS_STORAGE_BUCKET_MNIST_DIR}
    ...    env:PIP_INDEX_URL=${PIP_INDEX_URL}
    ...    env:PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END
