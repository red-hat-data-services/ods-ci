*** Settings ***
Documentation     Smoke tests for Workloads Orchestration
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


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
    Log To Console    Verifying kueue-controller-manager's container image is referred from registry.redhat.io
    ${pod} =    Find First Pod By Name  namespace=${APPLICATIONS_NAMESPACE}   pod_regex=kueue-controller-manager-
    Container Image Url Should Contain      ${APPLICATIONS_NAMESPACE}     ${pod}      manager
    ...     registry.redhat.io/rhoai/odh-kueue-controller
    Log To Console    kueue-controller-manager's container image is verified
