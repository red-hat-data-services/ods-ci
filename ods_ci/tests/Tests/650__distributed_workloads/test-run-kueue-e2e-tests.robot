*** Settings ***
Documentation     Kueue E2E tests - https://github.com/opendatahub-io/kueue.git
Suite Setup       Prepare Kueue E2E Test Suite
Suite Teardown    Teardown Kueue E2E Test Suite
Library           OperatingSystem
Library           Process
Library           OpenShiftLibrary
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Page/OCPLogin/OCPLogin.robot


*** Variables ***
${KUEUE_KUBECONFIG}         %{WORKSPACE=.}/kueue-kubeconfig
${WORKER_NODE}              ${EMPTY}
${KUEUE_RELEASE_ASSETS}     %{KUEUE_RELEASE_ASSETS=https://github.com/opendatahub-io/kueue/releases/latest/download}

*** Test Cases ***
Run E2E test
    [Documentation]    Run ginkgo E2E single cluster test
    [Tags]  Tier1
    ...     Kueue
    ...     DistributedWorkloads
    Run Kueue E2E Test    e2e_test.go

Run Sanity test
    [Documentation]    Run ginkgo Sanity test
    [Tags]  Sanity
    ...     Kueue
    ...     DistributedWorkloads
    Run Kueue sanity Test    Should run with prebuilt workload


*** Keywords ***
Prepare Kueue E2E Test Suite
    [Documentation]    Prepare Kueue E2E Test Suite
    Log To Console    "Downloading compiled test binary e2e-singlecluster"
    ${result} =    Run Process    curl --location --silent --output e2e-singlecluster ${KUEUE_RELEASE_ASSETS}/e2e-singlecluster && chmod +x e2e-singlecluster
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to retrieve e2e-singlecluster compiled binary
    END

    # Store login information into dedicated config
    Login To OCP Using API And Kubeconfig    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    ${KUEUE_KUBECONFIG}

    Enable Component    kueue
    Wait Component Ready    kueue

    # Add label instance-type=on-demand on worker node
    Log To Console    Add label on worker node ...
    ${return_code}    ${output}    Run And Return Rc And Output    oc get nodes -o name --selector='node-role.kubernetes.io/worker,node-role.kubernetes.io notin (infra)' | tail -n1
    Set Suite Variable    ${WORKER_NODE}    ${output}
    ${return_code} =    Run And Return Rc    oc label ${WORKER_NODE} instance-type=on-demand
    Should Be Equal As Integers  ${return_code}   0   msg=Fail to label worker node with instance-type=on-demand

Teardown Kueue E2E Test Suite
    [Documentation]    Teardown Kueue E2E Test Suite
    Log To Console    "Removing test binaries"
    ${result} =    Run Process    rm -f e2e-singlecluster
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Unable to remove files
    END
    Disable Component    kueue

    # Remove label instance-type=on-demand from worker node
    Log To Console    Remove label from worker node ...
    ${return_code} =    Run And Return Rc    oc label ${WORKER_NODE} instance-type-
    Should Be Equal As Integers  ${return_code}   0   msg=Fail to unlabel instance-type=on-demand from worker node

Run Kueue E2E Test
    [Documentation]    Run Kueue E2E Test
    [Arguments]    ${test_name}
    Log To Console    Running Kueue E2E test: ${test_name}
    ${result} =    Run Process    ./e2e-singlecluster -ginkgo.focus-file\=${test_name}
    ...    shell=true    stderr=STDOUT
    ...    env:KUBECONFIG=${KUEUE_KUBECONFIG}
    ...    env:NAMESPACE=${APPLICATIONS_NAMESPACE}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    failed
    END

Run Kueue Sanity Test
    [Documentation]    Run Kueue Sanity Test
    [Arguments]    ${test_name}
    Log To Console    Running Kueue Sanity test: ${test_name}
    ${result} =    Run Process    ./e2e-singlecluster -ginkgo.focus "${test_name}"
    ...    shell=true    stderr=STDOUT
    ...    env:KUBECONFIG=${KUEUE_KUBECONFIG}
    ...    env:NAMESPACE=${APPLICATIONS_NAMESPACE}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    failed
    END
