*** Settings ***
Documentation   Distributed workloads tests

Resource         ../../../tasks/Resources/RHODS_OLM/install/codeflare_install.resource
Resource         ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Variables ***
${DW_DIR}                 distributed-workloads
${DW_TEST_RESULT_FILE}    %{WORKSPACE=.}/dw-test-results.txt
${DW_JUNIT_FILE}          %{WORKSPACE=.}/junit.xml


*** Test Cases ***
Run distributed workloads sanity tests
    [Documentation]   Run tests located in Distributed Workloads repo downstream
    [Tags]  ODS-2511
    ...     Sanity
    ...     Tier1

    Skip If Component Is Not Enabled    ray
    Skip If Component Is Not Enabled    codeflare
    DistributedWorkloads.Clone Git Repository    %{DW_GIT_REPO}    %{DW_GIT_REPO_BRANCH}    ${DW_DIR}
    ${test_result}=    Run Distributed Workloads Tests    ${DW_DIR}    ${DW_TEST_RESULT_FILE}    -run '.*Test[RK].*[^r]$' -parallel 1 %{DW_GO_TESTS_PARAMS}
    Install Go Junit Report Tool
    Convert Go Test Results To Junit    ${DW_TEST_RESULT_FILE}    ${DW_JUNIT_FILE}
    IF    ${test_result} != 0
        FAIL    There were test failures in the Distributed Workloads tests.
    END
