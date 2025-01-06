*** Settings ***
Documentation     Smoke tests for Workloads Training
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Suite Setup       Prepare Codeflare E2E Test Suite
Suite Teardown    Teardown Codeflare E2E Test Suite


*** Test Cases ***
Ray smoke test
    [Documentation]    Check that Kuberay deployment and service are up and running
    [Tags]    Smoke
    ...       DistributedWorkloads
    ...       Training
    ...       ODS-2648
    Log To Console    Waiting for kuberay-operator to be available
    ${result} =    Run Process    oc wait --for\=condition\=Available --timeout\=60s -n ${APPLICATIONS_NAMESPACE} deployment/kuberay-operator
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Timeout waiting for deployment/kuberay-operator to be available in ${APPLICATIONS_NAMESPACE}
    END
    Log To Console    kuberay-operator deployment is available
    ${result} =    Run Process    oc get service -n ${APPLICATIONS_NAMESPACE} kuberay-operator
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Can not find kuberay-operator service in ${APPLICATIONS_NAMESPACE}
    END
    Log To Console    kuberay-operator service exists
    Verify container images    kuberay-operator    kuberay-operator    odh-kuberay-operator-controller

Codeflare smoke test
    [Documentation]    Check that Codeflare deployment and its monitoring service are up and running
    [Tags]    Smoke
    ...       DistributedWorkloads
    ...       Training
    ...       ODS-2675
    Log To Console    Waiting for codeflare-operator-manager to be available
    ${result} =    Run Process    oc wait --for\=condition\=Available --timeout\=60s -n ${APPLICATIONS_NAMESPACE} deployment/codeflare-operator-manager
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Timeout waiting for deployment/codeflare-operator-manager to be available in ${APPLICATIONS_NAMESPACE}
    END
    ${result} =    Run Process    oc get service -n ${APPLICATIONS_NAMESPACE} codeflare-operator-manager-metrics
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Can not find codeflare-operator-manager-metrics service in ${APPLICATIONS_NAMESPACE}
    END
    Log To Console    codeflare-operator-manager-metrics service exists
    Verify container images    codeflare-operator-manager    manager    odh-codeflare-operator

Training operator smoke test
    [Documentation]    Check that Training operator deployment is up and running
    [Tags]    Smoke
    ...       DistributedWorkloads
    ...       Training
    Log To Console    Waiting for kubeflow-training-operator to be available
    ${result} =    Run Process    oc wait --for\=condition\=Available --timeout\=300s -n ${APPLICATIONS_NAMESPACE} deployment/kubeflow-training-operator
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Timeout waiting for deployment/kubeflow-training-operator to be available in ${APPLICATIONS_NAMESPACE}
    END
    Verify container images    kubeflow-training-operator    training-operator    odh-training-operator


*** Keywords ***
Prepare Codeflare E2E Test Suite
    Enable Component    trainingoperator
    Wait Component Ready    trainingoperator
    RHOSi Setup

Teardown Codeflare E2E Test Suite
    Disable Component    trainingoperator
    RHOSi Teardown
