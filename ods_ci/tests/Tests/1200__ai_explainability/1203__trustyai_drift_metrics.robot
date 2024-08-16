*** Settings ***
Documentation     This is a resource file for running Drift Metrics.
Suite Setup       Prepare TrustyAi-tests Test Suite
Suite Teardown    Teardown TrustyAi-tests Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../Resources/Common.robot
Resource          ../../Resources/RHOSi.resource


*** Variables ***
${TRUSTYAI-TESTS_URL}                 %{TRUSTYAI-TESTS-URL=https://github.com/trustyai-explainability/trustyai-tests}
${TRUSTYAI-TESTS_DIR}                 trustyai-tests
${GIT_BRANCH}                         main
${VIRTUAL_ENV_NAME}                   drift_venv
${TESTS_FOLDER}                       drift
${LOG_OUTPUT_FILE}                    drift_test.txt


*** Test Cases ***
Run Drift Metrics Tests
    [Documentation]    Verifies that the Drift metrics are available for a deployed model
    [Tags]    RHOAIENG-8163     Smoke
    Run Drift Pytest Framework


*** Keywords ***
Prepare TrustyAi-tests Test Suite
    [Documentation]    Prepare trustyai-tests E2E Test Suite
    Log To Console    "Prepare Test Suite"
    ${TRUSTY} =    Is Component Enabled    trustyai    ${DSC_NAME}
    IF    "${TRUSTY}" == "false"    Enable Component    trustyai
    Drift Setup
    RHOSi Setup

Teardown TrustyAi-tests Test Suite
    [Documentation]    TrustyAi-tests Test Suite
    Cleanup TrustyAI-Tests Setup
    RHOSi Teardown

Drift Setup
    [Documentation]   Setup for Drift tests
    Log To Console     "Cloning ${TRUSTYAI-TESTS_DIR} repo"
    Common.Clone Git Repository    ${TRUSTYAI-TESTS_URL}    ${GIT_BRANCH}    ${TRUSTYAI-TESTS_DIR}
    ${return_code}    ${output}    Run And Return Rc And Output   cd ${TRUSTYAI-TESTS_DIR}
    Should Be Equal As Integers  ${return_code}   0   msg=Error detected while cloning git repo
    ${result} =    Run Process  virtualenv -p python3 ${VIRTUAL_ENV_NAME}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to setup Python virtual environment
    END

Cleanup TrustyAI-Tests Setup
    [Documentation]   cleanup trustyai-tests repository cloned
    Log To Console     "Removing Python virtual environment ${VIRTUAL_ENV_NAME}"
    ${result} =    Run Process  rm -rf ${VIRTUAL_ENV_NAME}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0     FAIL   Unable to cleanup Python virtual environment
    Log To Console     "Removing directory ${TRUSTYAI-TESTS_DIR}"
    Remove Directory        ${TRUSTYAI-TESTS_DIR}    recursive=True

Run Drift Pytest Framework
    [Documentation]    Run Drift tests using poetry
    Log To Console    Running Drift tests using pytest
    ${result} =    Run Process  source ${VIRTUAL_ENV_NAME}/bin/activate && cd ${TRUSTYAI-TESTS_DIR} && poetry install && poetry run pytest -v -s ./trustyai_tests/tests/${TESTS_FOLDER}/ && deactivate     # robocop: disable:line-too-long
    ...    shell=true     stderr=STDOUT     stdout=${LOG_OUTPUT_FILE}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0    FAIL    Tests failed due to ${result.stdout} failed
