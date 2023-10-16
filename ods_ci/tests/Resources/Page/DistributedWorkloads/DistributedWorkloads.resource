*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process


*** Variables ***
${CODEFLARE_TEST_TIMEOUT_LONG}    20m
${GO_TEST_TIMEOUT}    1h
${JOB_GO_BIN}    %{WORKSPACE=.}/go-bin
${GO_JUNIT_REPORT_TOOL}    github.com/jstemmer/go-junit-report/v2@latest


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
