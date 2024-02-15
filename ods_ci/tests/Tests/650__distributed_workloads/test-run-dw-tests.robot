*** Settings ***
Documentation   Distributed workloads tests

Resource         ../../../tasks/Resources/RHODS_OLM/install/codeflare_install.resource
Resource         ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource         ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource

Suite Setup       Prepare Distributed Workloads E2E Test Suite
Suite Teardown    Teardown Distributed Workloads E2E Test Suite

*** Variables ***
${DW_DIR}                 distributed-workloads
${DW_TEST_RESULT_FILE}    %{WORKSPACE=.}/dw-test-results.txt
${DW_JUNIT_FILE}          %{WORKSPACE=.}/junit.xml
${DW_GIT_REPO}            %{DW_GIT_REPO=https://github.com/red-hat-data-services/distributed-workloads.git}
${DW_GIT_REPO_BRANCH}     %{DW_GIT_REPO_BRANCH=main}


*** Test Cases ***
Run distributed workloads sanity tests
    [Documentation]   Run tests located in Distributed Workloads repo downstream
    [Tags]  ODS-2511
    ...     Sanity
    ...     Tier1
    ...     DistributedWorkloads

    Skip If Component Is Not Enabled    ray
    Skip If Component Is Not Enabled    codeflare
    DistributedWorkloads.Clone Git Repository    %{DW_GIT_REPO}    %{DW_GIT_REPO_BRANCH}    ${DW_DIR}
    ${test_result}=    Run Distributed Workloads Tests    ${DW_DIR}    ${DW_TEST_RESULT_FILE}    -run '.*Test[RK].*[^r]$' -parallel 1
    Install Go Junit Report Tool
    Convert Go Test Results To Junit    ${DW_TEST_RESULT_FILE}    ${DW_JUNIT_FILE}
    IF    ${test_result} != 0
        FAIL    There were test failures in the Distributed Workloads tests.
    END

*** Keywords ***
Prepare Distributed Workloads E2E Test Suite
    Enable Component    ray
    Enable Component    codeflare
    RHOSi Setup

Teardown Distributed Workloads E2E Test Suite
    Disable Component    codeflare
    Disable Component    ray
    RHOSi Teardown
