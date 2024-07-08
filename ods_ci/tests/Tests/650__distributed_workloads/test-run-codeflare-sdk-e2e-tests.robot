*** Settings ***
Documentation     Codeflare-sdk E2E tests - https://github.com/project-codeflare/codeflare-sdk/tree/main/tests/e2e
Suite Setup       Prepare Codeflare-sdk E2E Test Suite
Suite Teardown    Teardown Codeflare-sdk E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/RHOSi.resource
Resource          ../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Variables ***
${CODEFLARE-SDK_DIR}                codeflare-sdk
${CODEFLARE-SDK_REPO_URL}           %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}
${CODEFLARE-SDK-API_URL}            %{CODEFLARE-SDK-API_URL=https://api.github.com/repos/project-codeflare/codeflare-sdk/releases/latest}
${VIRTUAL_ENV_NAME}                 venv3.9


*** Test Cases ***
Run TestRayClusterSDKOauth test
    [Documentation]    Run Python E2E test: TestRayClusterSDKOauth
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     Codeflare-sdk
    Run Codeflare-sdk E2E Test    mnist_raycluster_sdk_oauth_test.py

Run TestRayLocalInteractiveOauth test
    [Documentation]    Run Python E2E test: TestRayLocalInteractiveOauth
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     Codeflare-sdk
    Run Codeflare-sdk E2E Test    local_interactive_sdk_oauth_test.py

*** Keywords ***
Prepare Codeflare-sdk E2E Test Suite
    [Documentation]    Prepare codeflare-sdk E2E Test Suite
    Log To Console    "Restarting kueue"
    Restart Kueue

    ${latest_tag} =    Run Process   curl -s "${CODEFLARE-SDK-API_URL}" | grep '"tag_name":' | cut -d '"' -f 4
    ...    shell=True    stderr=STDOUT
    Log To Console  codeflare-sdk latest tag is : ${latest_tag.stdout}
    IF    ${latest_tag.rc} != 0
        FAIL    Unable to fetch codeflare-sdk latest tag
    END
    ${result} =    Run Process    git clone -b ${latest_tag.stdout} ${CODEFLARE-SDK_REPO_URL} ${CODEFLARE-SDK_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone ${CODEFLARE-SDK_DIR} repo ${CODEFLARE-SDK_REPO_URL}:${latest_tag.stdout}
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

    ${result} =    Run Process  rm -rf ${CODEFLARE-SDK_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL   Unable to cleanup directory ${CODEFLARE-SDK_DIR}
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
