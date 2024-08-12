*** Settings ***
Documentation    Test Cases to verify Serverless installation
Library         Collections
Library         OpenShiftLibrary
Resource        ../../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../../../Resources/OCP.resource
Resource        ../../../../../Resources/RHOSi.resource
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown


*** Variables ***
${KNATIVESERVING_NS}    knative-serving
${ISTIO_NS}     istio-system
${regex_pattern}       ERROR


*** Test Cases ***
Validate DSC creates all Serverless CRs
    [Documentation]  The purpose of this Test Case is to validate the creation
    ...    of Serverless Custom Resources
    [Tags]  Operator    ODS-2600    Tier2
    Resource Should Exist     KnativeServing    knative-serving     ${KNATIVESERVING_NS}
    Wait Until Keyword Succeeds    5 min    0 sec
    ...        Resource Status Should Be     oc get KnativeServing knative-serving -n ${KNATIVESERVING_NS} -o json | jq '.status.conditions[] | select(.type=="Ready") | .status'     KnativeServing    "True"    # robocop: disable
    Resource Should Exist     Gateway    knative-ingress-gateway     ${KNATIVESERVING_NS}
    Resource Should Exist     Gateway    knative-local-gateway     ${KNATIVESERVING_NS}
    Resource Should Exist     Gateway    kserve-local-gateway     ${ISTIO_NS}
    Resource Should Exist     Service    kserve-local-gateway     ${ISTIO_NS}
    Resource Should Exist     Service    knative-local-gateway     ${ISTIO_NS}
    Resource Should Exist     deployment    controller     ${KNATIVESERVING_NS}
    Wait For Pods Numbers  2    namespace=${KNATIVESERVING_NS}
    ...    label_selector=app.kubernetes.io/component=controller    timeout=120
    ${pod_names}=    Get Pod Names    ${KNATIVESERVING_NS}    app.kubernetes.io/component=controller
    Verify Containers Have Zero Restarts    ${pod_names}    ${KNATIVESERVING_NS}
    #${podname}=    Get Pod Name   ${OPERATOR_NAMESPACE}    ${OPERATOR_LABEL_SELECTOR}
    #Verify Pod Logs Do Not Contain    ${podname}    ${OPERATOR_NAMESPACE}    ${regex_pattern}    rhods-operator
    Wait For DSC Conditions Reconciled    ${KNATIVESERVING_NS}    default-dsc


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Wait For DSC Conditions Reconciled    ${OPERATOR_NAMESPACE}    default-dsc

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown
