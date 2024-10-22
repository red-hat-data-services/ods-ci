*** Settings ***
Documentation     Codeflare operator E2E tests - https://github.com/project-codeflare/integration-tests/tree/main/test/odh
Suite Setup       Prepare Codeflare E2E Test Suite
Suite Teardown    Teardown Codeflare E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Variables ***
${CODEFLARE_DIR}                codeflare-operator
${CODEFLARE_RELEASE_ASSETS}     %{CODEFLARE_RELEASE_ASSETS=https://github.com/opendatahub-io/distributed-workloads/releases/latest/download}
${NOTEBOOK_IMAGE_STREAM_NAME}   %{NOTEBOOK_IMAGE_STREAM_NAME=s2i-generic-data-science-notebook}
${NOTEBOOK_ADMIN_NAME}          ${TEST_USER_2.USERNAME}
${NOTEBOOK_ADMIN_PASSWORD}      ${TEST_USER_2.PASSWORD}
${NOTEBOOK_USER_NAME}           ${TEST_USER_3.USERNAME}
${NOTEBOOK_USER_PASSWORD}       ${TEST_USER_3.PASSWORD}


*** Test Cases ***
Run TestKueueRayCpu ODH test
    [Documentation]    Run Go ODH test: TestKueueRayCpu
    [Tags]  ODS-2514
    ...     Tier1
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistRayCpu

Run TestKueueRayGpu ODH test
    [Documentation]    Run Go ODH test: TestKueueRayGpu
    [Tags]  Resources-GPU    NVIDIA-GPUs
    ...     Tier1
    ...     DistributedWorkloads
    ...     CodeflareOperator
    Run Codeflare ODH Test    TestMnistRayGpu


*** Keywords ***
Prepare Codeflare E2E Test Suite
    Log To Console    "Restarting kueue"
    Restart Kueue

    Log To Console    "Downloading compiled test binary odh"
    ${result} =    Run Process    curl --location --silent --output odh ${CODEFLARE_RELEASE_ASSETS}/odh && chmod +x odh
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve odh compiled binary
    END
    Create Directory    %{WORKSPACE}/codeflare-odh-logs
    Log To Console    "Retrieving user tokens"
    ${user_admin_token} =    Generate User Token    ${NOTEBOOK_ADMIN_NAME}    ${NOTEBOOK_ADMIN_PASSWORD}
    Set Suite Variable    ${NOTEBOOK_ADMIN_TOKEN}    ${user_admin_token}
    ${common_user_token} =    Generate User Token    ${NOTEBOOK_USER_NAME}    ${NOTEBOOK_USER_PASSWORD}
    Set Suite Variable    ${NOTEBOOK_USER_TOKEN}   ${common_user_token}
    Log To Console    "Log back as cluster admin"
    Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}
    RHOSi Setup

Teardown Codeflare E2E Test Suite
    Log To Console    "Log back as cluster admin"
    Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}
    Log To Console    "Removing test binaries"
    ${result} =    Run Process    rm -f odh
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to remove compiled binaries
    END
    RHOSi Teardown

Generate User Token
    [Documentation]    Authenticate as a user and return user token.
    [Arguments]    ${username}    ${password}
    Login To OCP Using API    ${username}    ${password}
    ${rc}    ${out} =    Run And Return Rc And Output    oc whoami -t
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${out}

Run Codeflare ODH Test
    [Arguments]    ${TEST_NAME}
    Log To Console    "Running test: ${TEST_NAME}"
    ${result} =    Run Process    ./odh -test.run ${TEST_NAME}
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:CODEFLARE_TEST_TIMEOUT_SHORT=5m
    ...    env:CODEFLARE_TEST_TIMEOUT_MEDIUM=10m
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=20m
    ...    env:CODEFLARE_TEST_OUTPUT_DIR=%{WORKSPACE}/codeflare-odh-logs
    ...    env:ODH_NAMESPACE=${APPLICATIONS_NAMESPACE}
    ...    env:NOTEBOOK_IMAGE_STREAM_NAME=${NOTEBOOK_IMAGE_STREAM_NAME}
    ...    env:NOTEBOOK_ADMIN_NAME=${NOTEBOOK_ADMIN_NAME}
    ...    env:NOTEBOOK_ADMIN_TOKEN=${NOTEBOOK_ADMIN_TOKEN}
    ...    env:NOTEBOOK_USER_NAME=${NOTEBOOK_USER_NAME}
    ...    env:NOTEBOOK_USER_TOKEN=${NOTEBOOK_USER_TOKEN}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${TEST_NAME} failed
    END
