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
${VIRTUAL_ENV_NAME}                 venv3.9


*** Test Cases ***
Run TestMNISTRayClusterSDK test
    [Documentation]    Run Python E2E test: TestMNISTRayClusterSDK
    ...    ProductBug: https://issues.redhat.com/browse/RHOAIENG-3981 https://issues.redhat.com/browse/RHOAIENG-4240
    [Tags]  ODS-2544
    ...     Tier1
    ...     DistributedWorkloads
    ...     Codeflare-sdk
    ...   	ProductBug
    Skip    "Skipping because of RHOAIENG-3981 and RHOAIENG-4240."
    Run Codeflare-sdk E2E Test    mnist_raycluster_sdk_test.py

Run TestRayClusterSDKOauth test
    [Documentation]    Run Python E2E test: TestRayClusterSDKOauth
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     Codeflare-sdk
    Run Codeflare-sdk E2E Test    mnist_raycluster_sdk_oauth_test.py

*** Keywords ***
Prepare Codeflare-sdk E2E Test Suite
    [Documentation]    Prepare codeflare-sdk E2E Test Suite
    ${result} =    Run Process    git clone ${CODEFLARE-SDK_REPO_URL} ${CODEFLARE-SDK_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone codeflare-sdk repo ${CODEFLARE-SDK_REPO_URL}
    END

    ${result} =    Run Process  virtualenv -p python3.9 ${VIRTUAL_ENV_NAME}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to setup Python virtual environment
    END

    RHOSi Setup

Teardown Codeflare-sdk E2E Test Suite
    [Documentation]    Teardown codeflare-sdk E2E Test Suite

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

    RHOSi Teardown

Run Codeflare-sdk E2E Test
    [Documentation]    Run codeflare-sdk E2E Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Running codeflare-sdk test: ${TEST_NAME}"
    ${result} =    Run Process  source ${VIRTUAL_ENV_NAME}/bin/activate && cd codeflare-sdk && poetry env use 3.9 && poetry install --with test,docs && poetry run pytest -v -s ./tests/e2e/${TEST_NAME} --timeout\=600 && deactivate
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END
