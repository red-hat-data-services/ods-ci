*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Variables ***
${CODEFLARE-SDK-RELEASE-TAG}             v0.23.1
${CODEFLARE-SDK-RELEASE-TAG-3.9}         adjustments-release-0.21.1
${CODEFLARE-SDK_DIR}                     codeflare-sdk
${CODEFLARE-SDK_REPO_URL}                %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}
${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS}  https://github.com/opendatahub-io/distributed-workloads/releases/latest/download
# Corresponds to quay.io/modh/ray:2.35.0-py311-cu121
${RAY_CUDA_IMAGE_3.11}                   quay.io/modh/ray@sha256:db667df1bc437a7b0965e8031e905d3ab04b86390d764d120e05ea5a5c18d1b4
# Corresponds to quay.io/rhoai/ray:2.35.0-py311-cu121-torch24-fa26
${RAY_TORCH_CUDA_IMAGE_3.11}             quay.io/rhoai/ray@sha256:5077f9bb230dfa88f34089fecdfcdaa8abc6964716a8a8325c7f9dcdf11bbbb3
# Corresponds to quay.io/modh/ray:2.35.0-py311-rocm61
${RAY_ROCM_IMAGE_3.11}                   quay.io/modh/ray@sha256:f8b4f2b1c954187753c1f5254f7bb6a4286cec5a4f1b43def7ef4e009f2d28cb
# Corresponds to quay.io/rhoai/ray:2.35.0-py311-rocm61-torch24-fa26
${RAY_TORCH_ROCM_IMAGE_3.11}             quay.io/rhoai/ray@sha256:b0e129cd2f4cdea7ad7a7859031357ffd9915410551f94fbcb942af2198cdf78
# Corresponds to quay.io/modh/ray:2.35.0-py39-cu121
${RAY_CUDA_IMAGE_3.9}                    quay.io/modh/ray@sha256:0d715f92570a2997381b7cafc0e224cfa25323f18b9545acfd23bc2b71576d06
# Corresponds to quay.io/rhoai/ray:2.35.0-py39-cu121-torch24-fa26
${RAY_TORCH_CUDA_IMAGE_3.9}              quay.io/rhoai/ray@sha256:158b481b8e9110008d60ac9fb8d156eadd71cb057ac30382e62e3a231ceb39c0
# Corresponds to quay.io/modh/fms-hf-tuning:v2.1.2
${FMS_HF_TUNING_IMAGE}                   quay.io/modh/fms-hf-tuning@sha256:6f98907f9095db72932caa54094438eae742145f4b66c28d15887d5303ff1186
# Corresponds to quay.io/modh/training:py311-cuda121-torch241
${CUDA_TRAINING_IMAGE}                   quay.io/modh/training@sha256:b98e373a972ff6f896a9dc054d56920e915675339c02ea7fa123e0f4bbef4d74
# Corresponds to quay.io/modh/training:py311-rocm61-torch241
${ROCM_TRAINING_IMAGE}                   quay.io/modh/training@sha256:2efb6efba4ec08e63847d701e3062a5f6ddf51c91af5fbcef6378b9e6520a3bb
# Corresponds to quay.io/modh/odh-generic-data-science-notebook:v3-2024b-20241111
${NOTEBOOK_IMAGE_3.11}                   quay.io/modh/odh-generic-data-science-notebook@sha256:7c1a4ca213b71d342a2d1366171304e469da06d5f15710fab5dd3ce013aa1b73
# Corresponds to quay.io/modh/odh-generic-data-science-notebook:v2-2024a-20241108
${NOTEBOOK_IMAGE_3.9}                    quay.io/modh/odh-generic-data-science-notebook@sha256:b1066204611b4bcfa6172c3115650a8e8393089d5606458fa0d8c53633d2ce17
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

Verify container images
    [Documentation]    Verify container images
    [Arguments]    ${pod_name}    ${container}    ${expected_image}
    ${test_env}=  Is Test Enviroment ROSA-HCP
    # We use Kyverno custom policies to pull unreleased images from quay registry for hypershift clusters
    ${registry_name} =   Set Variable If    ${test_env}==True
    ...    quay.io
    ...    registry.redhat.io
    Log To Console    Verifying ${pod_name}'s container image is referred from ${registry_name}
    ${pod} =    Find First Pod By Name  namespace=${APPLICATIONS_NAMESPACE}   pod_regex=${pod_name}
    Container Image Url Should Contain      ${APPLICATIONS_NAMESPACE}     ${pod}      ${container}
    ...     ${registry_name}/rhoai/${expected_image}
    Log To Console    ${pod_name}'s container image is verified
