*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Variables ***
${CODEFLARE-SDK-RELEASE-TAG}             v0.29.0-post-cve-test-fix
${CODEFLARE-SDK_DIR}                     codeflare-sdk
${CODEFLARE-SDK_REPO_URL}                %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}
${DISTRIBUTED_WORKLOADS_RELEASE_ASSETS}  https://github.com/opendatahub-io/distributed-workloads/releases/download/v2.22.0-04-07-2025
# Corresponds to quay.io/modh/ray:2.44.1-py311-cu121
${RAY_CUDA_IMAGE_3.11}                   quay.io/modh/ray@sha256:a5b7c04a14f180d7ca6d06a5697f6bb684e40a26b95a0c872cac23b552741707
# Corresponds to quay.io/rhoai/ray:2.35.0-py311-cu121-torch24-fa26
${RAY_TORCH_CUDA_IMAGE_3.11}             quay.io/rhoai/ray@sha256:5077f9bb230dfa88f34089fecdfcdaa8abc6964716a8a8325c7f9dcdf11bbbb3
# Corresponds to quay.io/modh/ray:2.44.1-py311-rocm62
${RAY_ROCM_IMAGE_3.11}                   quay.io/modh/ray@sha256:48c7864989c8f22ef07772c698b761f5c1b58c6781e7a99518204d521bf56a4c
# Corresponds to quay.io/rhoai/ray:2.35.0-py311-rocm61-torch24-fa26
${RAY_TORCH_ROCM_IMAGE_3.11}             quay.io/rhoai/ray@sha256:b0e129cd2f4cdea7ad7a7859031357ffd9915410551f94fbcb942af2198cdf78
# Corresponds to quay.io/modh/training:py311-cuda121-torch241
${CUDA_TRAINING_IMAGE_TORCH241}          quay.io/modh/training@sha256:f64f7bba3f1020d39491ac84d40d362a52e4822bdc11a33cfff021178b7c4097
# Corresponds to quay.io/modh/training:py311-rocm62-torch241
${ROCM_TRAINING_IMAGE_TORCH241}          quay.io/modh/training@sha256:883739b576b485d79966d8c894fdd9ebebd226605a2abe8b33593ca67c87a394
# Corresponds to quay.io/modh/training:py311-cuda124-torch251
${CUDA_TRAINING_IMAGE_TORCH251}          quay.io/modh/training@sha256:1d0caea3e5d56ff7d672954b1ad511e661df9bdb364d56879961169a4ca8dae0
# Corresponds to quay.io/modh/training:py311-rocm62-torch251
${ROCM_TRAINING_IMAGE_TORCH251}          quay.io/modh/training@sha256:6cdae840fa029da33cccab620367e82404d24ddf67762eb4537a9bffe1af306d
# Corresponds to quay.io/repository/modh/odh-workbench-jupyter-datascience-cpu-py311-ubi9:rhoai-2.22
${NOTEBOOK_IMAGE_3.11}                   quay.io/modh/odh-workbench-jupyter-datascience-cpu-py311-ubi9@sha256:48c2be818e8d2a5005a69e2c76f9a2d40ddeb1d03376e04516ca6da13418c887
${NOTEBOOK_USER_NAME}                    ${TEST_USER_3.USERNAME}
${NOTEBOOK_USER_PASSWORD}                ${TEST_USER_3.PASSWORD}
${KFTO_BINARY_NAME}                      kfto
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

    # Perform oc login with Test User
    Login To OCP Using API    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}

Prepare Codeflare-SDK Upgrade Test Setup
    [Documentation]   Prepare codeflare-sdk upgrade tests with RBAC setup and namespace creation
    Clone Git Repository    ${CODEFLARE-SDK_REPO_URL}    ${CODEFLARE-SDK-RELEASE-TAG}    ${CODEFLARE-SDK_DIR}

    # Setup Kueue RBAC permissions as admin before switching to test user
    Setup Kueue Batch User RoleBinding

    # Create the test namespace as admin
    Create Test Namespace For Codeflare Test

    # Perform oc login with Test User
    Login To OCP Using API    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}

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

    Log To Console    "Log back as cluster admin"
    Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}

    # Cleanup Kueue RBAC resources
    Teardown Kueue Batch User RoleBinding

Create Test Namespace For Codeflare Test
    [Documentation]    Create the test namespace as admin for codeflare tests
    Log To Console    "Creating test namespace test-ns-rayupgrade as admin"
    ${rc}=    Run And Return Rc    oc create namespace test-ns-rayupgrade

    IF    ${rc} != 0
        Log To Console    "Warning: Unable to create namespace test-ns-rayupgrade (may already exist)"
    END

Prepare Training Operator KFTO E2E Test Suite
    [Documentation]    Prepare Training Operator KFTO E2E Test Suite
    Prepare Training Operator E2E Test Suite    ${KFTO_BINARY_NAME}

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

Teardown Training Operator KFTO E2E Test Suite
    [Documentation]    Teardown Training Operator KFTO E2E Test Suite
    Teardown Training Operator E2E Test Suite    ${KFTO_BINARY_NAME}

Teardown Training Operator E2E Test Suite
    [Documentation]    Teardown Training Operator E2E Test Suite
    [Arguments]        ${test_binary}
    Log To Console     "Removing test binaries"
    Remove File        ${test_binary}

Run Training Operator KFTO Test
    [Documentation]    Run Training Operator KFTO Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    ./${KFTO_BINARY_NAME} -test.run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:TEST_TIMEOUT_SHORT=5m
    ...    env:TEST_TIMEOUT_MEDIUM=10m
    ...    env:TEST_TIMEOUT_LONG=20m
    ...    env:TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-${KFTO_BINARY_NAME}-logs
    ...    env:TEST_TRAINING_CUDA_PYTORCH_241_IMAGE=${CUDA_TRAINING_IMAGE_TORCH241}
    ...    env:TEST_TRAINING_CUDA_PYTORCH_251_IMAGE=${CUDA_TRAINING_IMAGE_TORCH251}
    ...    env:TEST_TRAINING_ROCM_PYTORCH_241_IMAGE=${ROCM_TRAINING_IMAGE_TORCH241}
    ...    env:TEST_TRAINING_ROCM_PYTORCH_251_IMAGE=${ROCM_TRAINING_IMAGE_TORCH251}
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

Run Training Operator KFTO SDK Test
    [Documentation]    Run Training Operator KFTO SDK Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    ./${KFTO_BINARY_NAME} -test.run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:TEST_TIMEOUT_SHORT=10m
    ...    env:TEST_TIMEOUT_MEDIUM=15m
    ...    env:TEST_TIMEOUT_LONG=20m
    ...    env:ODH_NAMESPACE=${APPLICATIONS_NAMESPACE}
    ...    env:TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-${KFTO_BINARY_NAME}-logs
    ...    env:TEST_TRAINING_CUDA_PYTORCH_241_IMAGE=${CUDA_TRAINING_IMAGE_TORCH241}
    ...    env:TEST_TRAINING_CUDA_PYTORCH_251_IMAGE=${CUDA_TRAINING_IMAGE_TORCH251}
    ...    env:TEST_TRAINING_ROCM_PYTORCH_241_IMAGE=${ROCM_TRAINING_IMAGE_TORCH241}
    ...    env:TEST_TRAINING_ROCM_PYTORCH_251_IMAGE=${ROCM_TRAINING_IMAGE_TORCH251}
    ...    env:AWS_DEFAULT_ENDPOINT=${AWS_DEFAULT_ENDPOINT}
    ...    env:AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
    ...    env:AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    ...    env:AWS_STORAGE_BUCKET=${AWS_STORAGE_BUCKET}
    ...    env:AWS_STORAGE_BUCKET_MNIST_DIR=${AWS_STORAGE_BUCKET_MNIST_DIR}
    ...    env:PIP_INDEX_URL=${PIP_INDEX_URL}
    ...    env:PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}
    ...    env:NOTEBOOK_USER_NAME=${NOTEBOOK_USER_NAME}
    ...    env:NOTEBOOK_USER_PASSWORD=${NOTEBOOK_USER_PASSWORD}
    ...    env:NOTEBOOK_IMAGE=${NOTEBOOK_IMAGE_3.11}
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
    Setup Kueue Batch User RoleBinding

Teardown DistributedWorkloads Integration Test Suite
    [Documentation]    Teardown DistributedWorkloads Integration Test Suite
    Log To Console    "Log back as cluster admin"
    Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}
    Log To Console    "Removing test binaries"
    Remove File        ${ODH_BINARY_NAME}
    RHOSi Teardown
    Teardown Kueue Batch User RoleBinding

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
    ...    env:TEST_TIMEOUT_SHORT=5m
    ...    env:TEST_TIMEOUT_MEDIUM=10m
    ...    env:TEST_TIMEOUT_LONG=20m
    ...    env:TEST_OUTPUT_DIR=%{WORKSPACE}/distributed-workloads-odh-logs
    ...    env:TEST_RAY_IMAGE=${DW_RAY_IMAGE}
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

Enable appwrapper in Codeflare operator
    [Documentation]    Enable appwrapper in Codeflare operator
    ${result} =    Run Process    config_yaml\=\$(oc -n ${APPLICATIONS_NAMESPACE} get configmap codeflare-operator-config -o json | jq -r '.data."config.yaml"' | yq ".appwrapper.enabled\=true" | sed 's/"/\\\\"/g') && oc -n ${APPLICATIONS_NAMESPACE} get configmap codeflare-operator-config -o json | jq ".data.\\"config.yaml\\"\=\\"\$config_yaml\\"" | oc apply -n ${APPLICATIONS_NAMESPACE} -f -
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to edit codeflare-operator-config configmap
    END
    ${result} =    Run Process    oc -n ${APPLICATIONS_NAMESPACE} delete pod -l app.kubernetes.io/name\=codeflare-operator
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to reset codeflare-operator pod
    END
    ${result} =    Run Process    oc -n ${APPLICATIONS_NAMESPACE} wait --for\=condition\=Available deployment/codeflare-operator-manager
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}

Disable appwrapper in Codeflare operator
    [Documentation]    Enable appwrapper in Codeflare operator
    ${result} =    Run Process    config_yaml\=\$(oc -n ${APPLICATIONS_NAMESPACE} get configmap codeflare-operator-config -o json | jq -r '.data."config.yaml"' | yq ".appwrapper.enabled\=false" | sed 's/"/\\\\"/g') && oc -n ${APPLICATIONS_NAMESPACE} get configmap codeflare-operator-config -o json | jq ".data.\\"config.yaml\\"\=\\"\$config_yaml\\"" | oc apply -n ${APPLICATIONS_NAMESPACE} -f -
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to edit codeflare-operator-config configmap
    END
    ${result} =    Run Process    oc -n ${APPLICATIONS_NAMESPACE} delete pod -l app.kubernetes.io/name\=codeflare-operator
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to reset codeflare-operator pod
    END
    ${result} =    Run Process    oc -n ${APPLICATIONS_NAMESPACE} wait --for\=condition\=Available deployment/codeflare-operator-manager
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}

Setup Kueue Batch User RoleBinding
    [Documentation]    Apply the kueue-batch-user-role ClusterRole and kueue-batch-user-rolebinding ClusterRoleBinding as admin
    Log To Console    "Logging in as cluster admin to setup RBAC permissions"
    Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}
    Log To Console    "Applying kueue-batch-user-role ClusterRole"
    ${result} =    Run Process    oc apply -f tests/Resources/Files/kueue-batch-user-role.yaml
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to apply kueue-batch-user-role ClusterRole
    END
    Log To Console    "Applying kueue-batch-user-rolebinding ClusterRoleBinding"
    ${result} =    Run Process    oc apply -f tests/Resources/Files/kueue-batch-user-rolebinding.yaml
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to apply kueue-batch-user-rolebinding ClusterRoleBinding
    END
    Log To Console    "Applying kueue-batch-user-specific-rolebinding ClusterRoleBinding"
    ${result} =    Run Process    oc apply -f tests/Resources/Files/kueue-batch-user-specific-rolebinding.yaml
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to apply kueue-batch-user-specific-rolebinding ClusterRoleBinding
    END

Teardown Kueue Batch User RoleBinding
    [Documentation]    Remove the kueue-batch-user-role ClusterRole and kueue-batch-user-rolebinding ClusterRoleBinding as admin
    Log To Console    "Logging in as cluster admin to cleanup RBAC permissions"
    Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}
    Log To Console    "Removing kueue-batch-user-rolebinding ClusterRoleBinding"
    ${result} =    Run Process    oc delete -f tests/Resources/Files/kueue-batch-user-rolebinding.yaml
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        Log To Console    "Warning: Unable to delete kueue-batch-user-rolebinding ClusterRoleBinding (may not exist)"
    END
    Log To Console    "Removing kueue-batch-user-specific-rolebinding ClusterRoleBinding"
    ${result} =    Run Process    oc delete -f tests/Resources/Files/kueue-batch-user-specific-rolebinding.yaml
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        Log To Console    "Warning: Unable to delete kueue-batch-user-specific-rolebinding ClusterRoleBinding (may not exist)"
    END
    Log To Console    "Removing kueue-batch-user-role ClusterRole"
    ${result} =    Run Process    oc delete -f tests/Resources/Files/kueue-batch-user-role.yaml
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        Log To Console    "Warning: Unable to delete kueue-batch-user-role ClusterRole (may not exist)"
    END
