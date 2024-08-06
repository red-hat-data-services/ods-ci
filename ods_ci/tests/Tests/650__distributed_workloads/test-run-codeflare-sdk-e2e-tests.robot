*** Settings ***
Documentation     Codeflare-sdk E2E tests - https://github.com/project-codeflare/codeflare-sdk/tree/main/tests/e2e
Suite Setup       Prepare Codeflare-sdk E2E Test Suite
Suite Teardown    Teardown Codeflare-sdk E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/RHOSi.resource


*** Variables ***
${CODEFLARE-SDK_DIR}                codeflare-sdk
${CODEFLARE-SDK_REPO_URL}           %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}
${CODEFLARE-SDK_REPO_BRANCH}        %{CODEFLARE-SDK_REPO_BRANCH=vv0.14.1}
${PYTHON_VERSION}                   3.9
${VIRTUAL_ENV_NAME}                 venv${PYTHON_VERSION}


*** Test Cases ***
Run TestMNISTRayClusterSDK test
    [Documentation]    Run Go E2E test: TestRayClusterSDKOauth
    [Tags]  ODS-2544
    ...     Sanity    Tier1
    ...     DistributedWorkloads
    ...     Codeflare-sdk
    Run Codeflare-sdk E2E Test    mnist_raycluster_sdk_oauth_test.py


*** Keywords ***
Prepare Codeflare-sdk E2E Test Suite
    [Documentation]    Prepare codeflare-sdk E2E Test Suite
    ${result} =    Run Process    git clone -b ${CODEFLARE-SDK_REPO_BRANCH} ${CODEFLARE-SDK_REPO_URL} ${CODEFLARE-SDK_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone codeflare-sdk repo ${CODEFLARE-SDK_REPO_URL}:${CODEFLARE-SDK_REPO_BRANCH}:${CODEFLARE-SDK_DIR}
    END
    Enable Component    codeflare
    Enable Component    ray

     ${result} =    Run Process  virtualenv -p python${PYTHON_VERSION} ${VIRTUAL_ENV_NAME}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to setup Python virtual environment
    END

    RHOSi Setup

Teardown Codeflare-sdk E2E Test Suite
    [Documentation]    Teardown codeflare-sdk E2E Test Suite
    Disable Component    codeflare
    Disable Component    ray

    ${result} =    Run Process  rm -rf ${VIRTUAL_ENV_NAME}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL   Unable to cleanup Python virtual environment
    END

    ${result} =    Run Process    poetry env use 3.11
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL   Unable to switch python environment 3.11
    END

    ${result} =    Run Process  rm -rf ${CODEFLARE-SDK_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL   Unable to cleanup directory ${CODEFLARE-SDK_DIR}
    END
    
    RHOSi Teardown

Run Codeflare-sdk E2E Test
    [Documentation]    Run codeflare-sdk E2E Test
    [Arguments]    ${test_name}
    Log To Console    Running codeflare-sdk test: ${test_name}
    ${result} =    Run Process  source ${VIRTUAL_ENV_NAME}/bin/activate && cd codeflare-sdk && poetry env use ${PYTHON_VERSION} && poetry install --with test,docs && poetry run pytest -v -s ./tests/e2e/${test_name} --timeout\=600 && deactivate
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${test_name} failed
    END
