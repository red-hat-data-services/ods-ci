*** Settings ***
Documentation     Smoke tests for DistributedWorkloads
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Variables ***
${ODH_NAMESPACE}                %{ODH_NAMESPACE=redhat-ods-applications}


*** Test Cases ***
Ray smoke test
    [Documentation]    Check that Kuberay deployment and service are up and running
    [Tags]    Smoke
    ...       DistributedWorkloads
    [Setup]    Enable Component    ray
    [Teardown]    Disable Component    ray
    Wait Component Ready    ray
    Log To Console    Waiting for kuberay-operator to be available
    ${result} =    Run Process    oc wait --for\=condition\=Available --timeout\=60s -n ${ODH_NAMESPACE} deployment/kuberay-operator
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Timeout waiting for deployment/kuberay-operator to be available in ${ODH_NAMESPACE}
    END
    Log To Console    kuberay-operator deployment is available
    ${result} =    Run Process    oc get service -n ${ODH_NAMESPACE} kuberay-operator
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Can not find kuberay-operator service in ${ODH_NAMESPACE}
    END
    Log To Console    kuberay-operator service exists

Codeflare smoke test
    [Documentation]    Check that Codeflare deployment and its monitoring service are up and running
    [Tags]    Smoke
    ...       DistributedWorkloads
    [Setup]    Enable Component    codeflare
    [Teardown]    Disable Component    codeflare
    Wait Component Ready    codeflare
    Log To Console    Waiting for codeflare-operator-manager to be available
    ${result} =    Run Process    oc wait --for\=condition\=Available --timeout\=60s -n ${ODH_NAMESPACE} deployment/codeflare-operator-manager
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Timeout waiting for deployment/codeflare-operator-manager to be available in ${ODH_NAMESPACE}
    END
    ${result} =    Run Process    oc get service -n ${ODH_NAMESPACE} codeflare-operator-manager-metrics
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Can not find codeflare-operator-manager-metrics service in ${ODH_NAMESPACE}
    END
    Log To Console    codeflare-operator-manager-metrics service exists

Kueue smoke test
    [Documentation]    Check that Kueue deployment and its service are up and running
    [Tags]    Smoke
    ...       DistributedWorkloads
    [Setup]    Enable Component    kueue
    [Teardown]    Disable Component    kueue
    Wait Component Ready    kueue
    Log To Console    Waiting for kueue-controller-manager to be available
    ${result} =    Run Process    oc wait --for\=condition\=Available --timeout\=300s -n ${ODH_NAMESPACE} deployment/kueue-controller-manager
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Timeout waiting for deployment/kueue-controller-manager to be available in ${ODH_NAMESPACE}
    END
    ${result} =    Run Process    oc get service -n ${ODH_NAMESPACE} kueue-webhook-service
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Can not find kueue-webhook-service service in ${ODH_NAMESPACE}
    END
    Log To Console    kueue-webhook-service service exists
