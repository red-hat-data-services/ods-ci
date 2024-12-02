*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process


*** Variables ***
${CODEFLARE-SDK-RELEASE-TAG}             v0.23.1
${CODEFLARE-SDK-RELEASE-TAG-3.9}         adjustments-release-0.21.1
${CODEFLARE-SDK_DIR}                     codeflare-sdk
${CODEFLARE-SDK_REPO_URL}                %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}
${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS}  https://github.com/opendatahub-io/distributed-workloads/releases/latest/download
${RAY_IMAGE_3.11}                        quay.io/modh/ray@sha256:db667df1bc437a7b0965e8031e905d3ab04b86390d764d120e05ea5a5c18d1b4
${RAY_IMAGE_3.9}                         quay.io/modh/ray@sha256:0d715f92570a2997381b7cafc0e224cfa25323f18b9545acfd23bc2b71576d06
${FMS_HF_TUNING_IMAGE}                   quay.io/modh/fms-hf-tuning@sha256:6f98907f9095db72932caa54094438eae742145f4b66c28d15887d5303ff1186
${CUDA_TRAINING_IMAGE}                   quay.io/modh/training@sha256:b98e373a972ff6f896a9dc054d56920e915675339c02ea7fa123e0f4bbef4d74
${ROCM_TRAINING_IMAGE}                   quay.io/modh/training@sha256:2efb6efba4ec08e63847d701e3062a5f6ddf51c91af5fbcef6378b9e6520a3bb
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
${KUBECONFIGPATH}                        %{HOME}/.kube/config


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

    # Perform oc login with default kubeconfig
    Login To OCP Using API And Kubeconfig    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    ${KUBECONFIGPATH}

Run Codeflare-SDK Test
    [Documentation]   Run codeflare-sdk Test
    [Arguments]    ${TEST_TYPE}    ${TEST_NAME}    ${PYTHON_VERSION}    ${RAY_IMAGE}    ${RELEASE_BRANCH}
    Log To Console    "Running codeflare-sdk test: ${TEST_NAME}"
    ${result} =    Run Process  cd ${CODEFLARE-SDK_DIR} && git fetch origin && git checkout ${RELEASE_BRANCH} && git branch && poetry env use ${PYTHON_VERSION} && poetry install --with test,docs && poetry run pytest -v -s ./tests/${TEST_TYPE}/${TEST_NAME} --timeout\=540
    ...    env:RAY_IMAGE=${RAY_IMAGE}
    ...    env:AWS_DEFAULT_ENDPOINT=${AWS_DEFAULT_ENDPOINT}
    ...    env:AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
    ...    env:AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    ...    env:AWS_STORAGE_BUCKET=${AWS_STORAGE_BUCKET}
    ...    env:AWS_STORAGE_BUCKET_MNIST_DIR=${AWS_STORAGE_BUCKET_MNIST_DIR}
    ...    env:PIP_INDEX_URL=${PIP_INDEX_URL}
    ...    env:PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}
    ...    env:CONTROL_LABEL=node-role.kubernetes.io/control-plane=
    ...    env:WORKER_LABEL=node-role.kubernetes.io/worker=
    ...    env:TOLERATION_KEY=node-role.kubernetes.io/master
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
    Check missing Go test    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END

Run Training Operator KFTO Test
    [Documentation]    Run Training Operator KFTO Test
    [Arguments]    ${TEST_NAME}    ${TRAINING_IMAGE}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    ./${KFTO_CORE_BINARY_NAME} -test.run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:CODEFLARE_TEST_TIMEOUT_SHORT=5m
    ...    env:CODEFLARE_TEST_TIMEOUT_MEDIUM=10m
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=20m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-${KFTO_CORE_BINARY_NAME}-logs
    ...    env:CODEFLARE_TEST_TRAINING_IMAGE=${TRAINING_IMAGE}
    Log To Console    ${result.stdout}
    Check missing Go test    ${result.stdout}
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
    [Arguments]    ${TEST_NAME}    ${DW_RAY_IMAGE}    ${NOTEBOOK_IMAGE}
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
    Check missing Go test    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END

Check missing Go test
    [Documentation]    Check that upstream Go test is not missing
    [Arguments]    ${test_run_output}
    Should Not Contain    ${test_run_output}    testing: warning: no tests to run    No Go tests were run
