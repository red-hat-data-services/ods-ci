*** Settings ***
Documentation     Smoke tests for Feature Store
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/Page/FeatureStore/FeatureStore.resource
Resource          ../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Suite Setup       Prepare Feature Store Test Suite
Test Tags         ExcludeOnODH

*** Test Cases ***
Feature Store Smoke Test
    [Documentation]    Check that Feature Store deployment and its service are up and running
    [Tags]    Smoke
    ...       FeatureStore
    ...       RHOAIENG-23588

    # Verify feature store operator deployment available
    Log To Console    Waiting for Feature store operator deployment to be available
    ${result} =    Run Process    oc wait --for\=condition\=Available --timeout\=300s -n ${APPLICATIONS_NAMESPACE} deployment/opendatahub-feast-operator
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Timeout waiting for deployment/opendatahub-feast-operator to be available in ${APPLICATIONS_NAMESPACE}
    END
    Log To Console    opendatahub-feast-operator deployment is available

    # Verify feature store oeprator metrics service exists
    ${result} =    Run Process    oc get service -n ${APPLICATIONS_NAMESPACE} opendatahub-feast-operator-metrics-service
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Can not find opendatahub-feast-operator-metrics-service in ${APPLICATIONS_NAMESPACE}
    END
    Log To Console    opendatahub-feast-operator-metrics-service exists

    #  Verify feature store operator container image referrence
    Verify container images    opendatahub-feast-operator    manager    odh-feast-operator
