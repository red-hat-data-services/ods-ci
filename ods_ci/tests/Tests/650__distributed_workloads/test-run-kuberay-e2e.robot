*** Settings ***
Documentation     Kuberay E2E tests - https://github.com/ray-project/kuberay.git
Suite Setup       Prepare Kuberay E2E Test Suite
Suite Teardown    Teardown Kuberay E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot

*** Variables ***
${KUBERAY_DIR}            kuberay
${KUBERAY_REPO_URL}       %{KUBERAY_REPO_URL=https://github.com/ray-project/kuberay.git}
${KUBERAY_REPO_BRANCH}    %{KUBERAY_REPO_BRANCH=master}

*** Test Cases ***
Run TestRayJob test
    [Documentation]    Run Go E2E test: TestRayJob
    [Tags]  Sanity
    ...     Tier1
    ...     DistributedWorkloads
    ...     Kuberay
    Skip    "Requires Kuberay 1.0"
    Run Kuberay E2E Test    "^TestRayJob$"

Run TestRayJobWithClusterSelector test
    [Documentation]    Run Go E2E test: TestRayJobWithClusterSelector
    [Tags]  Sanity
    ...     Tier1
    ...     DistributedWorkloads
    ...     Kuberay
    Skip    "Requires Kuberay 1.0"
    Run Kuberay E2E Test    TestRayJobWithClusterSelector

Run TestRayJobSuspend test
    [Documentation]    Run Go E2E test: TestRayJobSuspend
    [Tags]  Sanity
    ...     Tier1
    ...     DistributedWorkloads
    ...     Kuberay
    Run Kuberay E2E Test    TestRayJobSuspend
    

*** Keywords ***
Prepare Kuberay E2E Test Suite
    [Documentation]    Prepare Kuberay E2E Test Suite
    ${result} =    Run Process    git clone -b %{KUBERAY_REPO_BRANCH=master} ${KUBERAY_REPO_URL} ${KUBERAY_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone Kuberay repo ${DW_REPO_URL}:${DW_REPO_BRANCH}:${DW_DIR}
    END
    Enable Component    ray

Teardown Kuberay E2E Test Suite
    Disable Component    ray

Run Kuberay E2E Test
    [Documentation]    Run Kuberay E2E Test
    [Arguments]    ${test_name}
    Log To Console    Running Kuberay E2E test: ${test_name}
    ${result} =    Run Process    go test -timeout 30m -parallel 1 -v ./test/e2e -run ${test_name}
    ...    shell=true    stderr=STDOUT    cwd=${KUBERAY_DIR}/ray-operator    timeout=20m    stdout=${TEMPDIR}/output.txt
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    ${test_name} failed
    END
