*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process


*** Variables ***
${CODEFLARE_TEST_TIMEOUT_LONG}    20m
${GO_TEST_TIMEOUT}    1h
${JOB_GO_BIN}    %{WORKSPACE=.}/go-bin
${GO_JUNIT_REPORT_TOOL}    github.com/jstemmer/go-junit-report/v2@latest
${VIRTUAL_ENV_NAME}    venv3.9
${CODEFLARE-SDK-API_URL}            %{CODEFLARE-SDK-API_URL=https://api.github.com/repos/project-codeflare/codeflare-sdk/releases/latest}
${CODEFLARE-SDK_DIR}    codeflare-sdk-upgrade
${CODEFLARE-SDK_REPO_URL}    %{CODEFLARE-SDK_REPO_URL=https://github.com/project-codeflare/codeflare-sdk.git}


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

Run Distributed Workloads Tests
    [Documentation]   Run distributed workloads E2E tests from integration directory
    [Arguments]    ${DW_DIR}    ${DW_TEST_RESULT_FILE}    ${TEST_PARAMETERS}
    ${result} =    Run Process
    ...    go test -v -timeout ${GO_TEST_TIMEOUT} ./integration ${TEST_PARAMETERS} 2>&1 > ${DW_TEST_RESULT_FILE}
    ...    shell=true    cwd=${DW_DIR}/tests    env:ODH_NAMESPACE=redhat-ods-applications
    ...    env:CODEFLARE_TEST_TIMEOUT_LONG=${CODEFLARE_TEST_TIMEOUT_LONG}
    ...    env:CODEFLARE_TEST_RAY_IMAGE=quay.io/project-codeflare/ray:2.5.0-py38-cu116
    Log To Console    ${result.stdout}
    ${test_output}=    Get File    ${DW_TEST_RESULT_FILE}
    Log To Console    ${test_output}
    RETURN    ${result.rc}

Install Go Junit Report Tool
    [Documentation]   Use Go install command to install Go Junit report tool
    ${result} =    Run Process    go install ${GO_JUNIT_REPORT_TOOL}
    ...    shell=true    env:GOBIN=${JOB_GO_BIN}    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to install Go junit report tool
    END

Convert Go Test Results To Junit
    [Documentation]   Use Go Junit report tool to convert Go test results to Junit
    [Arguments]    ${DW_TEST_RESULT_FILE}    ${DW_JUNIT_FILE}
    ${result} =    Run Process    ${JOB_GO_BIN}/go-junit-report -in ${DW_TEST_RESULT_FILE} -iocopy -out ${DW_JUNIT_FILE}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to convert Go test results to Junit
    END

Run Codeflare Upgrade Tests
    [Documentation]   Run codeflare upgrade tests by cloning codeflare-sdk repo
    [Arguments]    ${TEST_NAME}
    ${latest_tag} =    Run Process   curl -s "${CODEFLARE-SDK-API_URL}" | grep '"tag_name":' | cut -d '"' -f 4
    ...    shell=True    stderr=STDOUT
    Log To Console  codeflare-sdk latest tag is : ${latest_tag.stdout}
    IF    ${latest_tag.rc} != 0
        FAIL    Unable to fetch codeflare-sdk latest tag
    END

    Clone Git Repository    ${CODEFLARE-SDK_REPO_URL}    ${latest_tag.stdout}    ${CODEFLARE-SDK_DIR}

    ${result} =    Run Process  virtualenv -p python3.9 ${VIRTUAL_ENV_NAME}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to setup Python virtual environment
    END

    ${result} =    Run Process  source ${VIRTUAL_ENV_NAME}/bin/activate && cd ${CODEFLARE-SDK_DIR} && poetry env use 3.9 && poetry install --with test,docs && poetry run pytest -v -s ./tests/upgrade/raycluster_sdk_upgrade_test.py::${TEST_NAME} --timeout\=300 && deactivate
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running test ${TEST_NAME} failed
    END

Codeflare Upgrade Tests Teardown
    [Documentation]   Run codeflare upgrade tests by cloning codeflare-sdk repo
    [Arguments]    ${project_name}    ${project_created}
    ${result} =    Run Process  rm -rf ${VIRTUAL_ENV_NAME}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL   Unable to cleanup Python virtual environment
    END

    ${result} =    Run Process  rm -rf ${CODEFLARE-SDK_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL   Unable to cleanup directory ${CODEFLARE-SDK_DIR}
    END

    IF    ${project_created} == True    Run Keywords
    ...    Run   oc delete project ${project_name}    AND
    ...    Run Process    oc delete LocalQueue local-queue-mnist -n ${project_name} &
    ...    oc delete ClusterQueue cluster-queue-mnist &
    ...    oc delete ResourceFlavor default-flavor-mnist    shell=True
