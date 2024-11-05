*** Settings ***
Documentation     Codeflare-sdk E2E tests - https://github.com/project-codeflare/codeflare-sdk/tree/main/tests/e2e
Suite Setup       Prepare Codeflare-sdk E2E Test Suite
Suite Teardown    Teardown Codeflare-sdk E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../Resources/RHOSi.resource
Resource          ../../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource

*** Variables ***
${CODEFLARE-SDK_HTC_REPO_URL}                https://github.com/Ygnas/codeflare-sdk.git
${CODEFLARE-SDK-HTC-RELEASE-TAG}             heterogeneous-clusters
${CODEFLARE-SDK_HTC_DIR}                     codeflare-sdk-htc

*** Test Cases ***
Run TestRayClusterSDKOauth test with Python 3.9
    [Documentation]    Run Python E2E test: TestRayClusterSDKOauth
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     WorkloadsOrchestration
    ...     Codeflare-sdk
    Run Codeflare-SDK Test    e2e    mnist_raycluster_sdk_oauth_test.py    3.9    ${RAY_IMAGE_3.9}

Run TestRayClusterSDKOauth test with Python 3.11
    [Documentation]    Run Python E2E test: TestRayClusterSDKOauth
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     WorkloadsOrchestration
    ...     Codeflare-sdk
    Run Codeflare-SDK Test    e2e    mnist_raycluster_sdk_oauth_test.py    3.11    ${RAY_IMAGE_3.11}

Run TestRayLocalInteractiveOauth test with Python 3.9
    [Documentation]    Run Python E2E test: TestRayLocalInteractiveOauth
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     WorkloadsOrchestration
    ...     Codeflare-sdk
    Run Codeflare-SDK Test    e2e    local_interactive_sdk_oauth_test.py    3.9    ${RAY_IMAGE_3.9}

Run TestRayLocalInteractiveOauth test with Python 3.11
    [Documentation]    Run Python E2E test: TestRayLocalInteractiveOauth
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     WorkloadsOrchestration
    ...     Codeflare-sdk
    Run Codeflare-SDK Test    e2e    local_interactive_sdk_oauth_test.py    3.11    ${RAY_IMAGE_3.11}

Run TestHeterogenousClustersOauth
    [Documentation]    Run Python E2E test: TestHeterogenousClustersOauth (workaround for 2.15)
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     WorkloadsOrchestration
    ...     HeterogeneousCluster
    ...     Codeflare-sdk
    DistributedWorkloads.Clone Git Repository    ${CODEFLARE-SDK_HTC_REPO_URL}    ${CODEFLARE-SDK-HTC-RELEASE-TAG}    ${CODEFLARE-SDK_HTC_DIR}
    Log To Console    "Running codeflare-sdk test: ${TEST_NAME}"
    ${result} =    Run Process  source ${VIRTUAL_ENV_NAME}/bin/activate && cd ${CODEFLARE-SDK_HTC_DIR} && poetry env use 3.11 && poetry install --with test,docs && poetry run pytest -v -s ./tests/e2e/heterogeneous_clusters_oauth_test.py --timeout\=600 && deactivate
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

*** Keywords ***
Prepare Codeflare-sdk E2E Test Suite
    [Documentation]    Prepare codeflare-sdk E2E Test Suite
    Prepare Codeflare-SDK Test Setup
    RHOSi Setup

Teardown Codeflare-sdk E2E Test Suite
    [Documentation]    Teardown codeflare-sdk E2E Test Suite
    Cleanup Codeflare-SDK Setup
    RHOSi Teardown
