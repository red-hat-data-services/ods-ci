*** Settings ***
Documentation     Smoke tests for Feature Store
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/Page/FeatureStore/FeatureStore.resource
Suite Setup       Prepare Feature Store Test Suite
Suite Teardown    Cleanup Feature Store Setup


*** Test Cases ***
Feature Store Smoke Test
    [Documentation]    Check that Feature Store deployment and its service are up and running
    [Tags]    Smoke
    ...       FeatureStore
    ...       RHOAIENG-23588

    # Verify feature store operator deployment available
    Log To Console    Waiting for Feature store operator deployment to be available
    ${result} =    Run Process    oc wait --for\=condition\=Available --timeout\=300s -n ${APPLICATIONS_NAMESPACE} deployment/feast-operator-controller-manager
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Timeout waiting for deployment/feast-operator-controller-manager to be available in ${APPLICATIONS_NAMESPACE}
    END
    Log To Console    feast-operator-controller-manager deployment is available

    # Verify feature store oeprator metrics service exists
    ${result} =    Run Process    oc get service -n ${APPLICATIONS_NAMESPACE} feast-operator-controller-manager-metrics-service
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Can not find feast-operator-controller-manager-metrics-service in ${APPLICATIONS_NAMESPACE}
    END
    Log To Console    feast-operator-controller-manager-metrics-service exists

    #  Verify feature store operator container image referrence
    Log To Console    Verifying feast-operator-controller-manager container image is referred from registry.redhat.io
    ${pod} =    Find First Pod By Name  namespace=${APPLICATIONS_NAMESPACE}   pod_regex=feast-operator-controller-manager
    Container Image Url Should Contain      ${APPLICATIONS_NAMESPACE}     ${pod}      manager
    ...     registry.redhat.io/rhoai/odh-feast-operator
    Log To Console    feast-operator-controller-manager's container image is verified
