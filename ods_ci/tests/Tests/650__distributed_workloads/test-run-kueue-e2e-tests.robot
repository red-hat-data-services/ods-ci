*** Settings ***
Documentation     Kueue E2E tests - https://github.com/opendatahub-io/kueue.git
Suite Setup       Prepare Kueue E2E Test Suite
Suite Teardown    Teardown Kueue E2E Test Suite
Library           OperatingSystem
Library           Process
Library           OpenShiftLibrary
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Variables ***
${KUEUE_DIR}            kueue
${KUEUE_REPO_URL}       %{KUEUE_REPO_URL=https://github.com/opendatahub-io/kueue.git}
${KUEUE_REPO_BRANCH}    %{KUEUE_REPO_BRANCH=dev}
${JOB_GO_BIN}           %{WORKSPACE=.}/go-bin
${KUBECONFIG}           %{WORKSPACE=.}/kconfig
${WORKER_NODE}          ${EMPTY}


*** Test Cases ***
Run E2E test
    [Documentation]    Run ginkgo E2E single cluster test
    [Tags]  Kueue
    ...     DistributedWorkloads
    Run Kueue E2E Test    e2e_test.go


*** Keywords ***
Prepare Kueue E2E Test Suite
    [Documentation]    Prepare Kueue E2E Test Suite
    ${result} =    Run Process    git clone -b ${KUEUE_REPO_BRANCH} ${KUEUE_REPO_URL} ${KUEUE_DIR}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to clone kueue repo ${KUEUE_REPO_URL}:${KUEUE_REPO_BRANCH}:${KUEUE_DIR}
    END

    Enable Component    kueue
    Wait Component Ready    kueue

    # Add label instance-type=on-demand on worker node
    Log To Console    Add label on worker node ...
    ${return_code}    ${output}    Run And Return Rc And Output    oc get nodes -o name --selector=node-role.kubernetes.io/worker | tail -n1
    Set Suite Variable    ${WORKER_NODE}    ${output}
    ${return_code} =    Run And Return Rc    oc label ${WORKER_NODE} instance-type=on-demand
    Should Be Equal As Integers  ${return_code}   0   msg=Fail to label worker node with instance-type=on-demand

    # Use Go install command to install ginkgo
    Log To Console    Install ginkgo ...
    ${result} =    Run Process    go install github.com/onsi/ginkgo/v2/ginkgo
    ...    shell=true    stderr=STDOUT
    ...    env:GOBIN=${JOB_GO_BIN}
    ...    cwd=${KUEUE_DIR}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Fail to install ginkgo
    END


Teardown Kueue E2E Test Suite
    [Documentation]    Teardown Kueue E2E Test Suite
    Disable Component    kueue

    # Remove label instance-type=on-demand from worker node
    Log To Console    Remove label from worker node ...
    ${return_code} =    Run And Return Rc    oc label ${WORKER_NODE} instance-type-
    Should Be Equal As Integers  ${return_code}   0   msg=Fail to unlabel instance-type=on-demand from worker node

Run Kueue E2E Test
    [Documentation]    Run Kueue E2E Test
    [Arguments]    ${test_name}
    Log To Console    Running Kueue E2E test: ${test_name}
    ${result} =    Run Process    ginkgo --focus-file\=${test_name} ${KUEUE_DIR}/test/e2e/singlecluster
    ...    shell=true    stderr=STDOUT
    ...    env:PATH=%{PATH}:${JOB_GO_BIN}
    ...    env:KUBECONFIG=${KUBECONFIG}
    ...    env:NAMESPACE=${APPLICATIONS_NAMESPACE}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    failed
    END
