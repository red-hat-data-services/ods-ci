*** Settings ***
Documentation     Smoke tests for Workloads Orchestration
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Test Cases ***
Kueue smoke test
    [Documentation]    Check that Kueue deployment and its service are up and running
    [Tags]    Smoke
    ...       DistributedWorkloads
    ...       WorkloadsOrchestration
    ...       ODS-2676
    Log To Console    Waiting for kueue-controller-manager to be available
    ${result} =    Run Process    oc wait --for\=condition\=Available --timeout\=300s -n ${APPLICATIONS_NAMESPACE} deployment/kueue-controller-manager
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Timeout waiting for deployment/kueue-controller-manager to be available in ${APPLICATIONS_NAMESPACE}
    END
    ${result} =    Run Process    oc get service -n ${APPLICATIONS_NAMESPACE} kueue-webhook-service
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Can not find kueue-webhook-service service in ${APPLICATIONS_NAMESPACE}
    END
    Log To Console    kueue-webhook-service service exists
    Verify container images    kueue-controller-manager    manager    odh-kueue-controller
