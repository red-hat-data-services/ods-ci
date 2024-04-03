*** Settings ***
Documentation    Test Cases to verify Serverless installation
Library         Collections
Library         SeleniumLibrary
Library         OpenShiftLibrary
Resource        ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../../Resources/OCP.resource
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown


*** Variables ***
${KNATIVESERVING_NS}    knative-serving
${ISTIO_NS}     istio-system
${regex_pattern}       ERROR
${LABEL_SELECTOR}    name=rhods-operator

*** Test Cases ***
Validate DSC creates all Serverless CRs
    [Documentation]  The purpose of this Test Case is to validate the creation
    ...    of Serverless Custom Resources
    ...    ProductBug: RHOAIENG-4358
    [Tags]  Operator    ODS-2600    ProductBug
    Assign Vars According To Product    ${PRODUCT}
    Resource Should Exist     KnativeServing    knative-serving     ${KNATIVESERVING_NS}
    Resource Status Should Be     oc get KnativeServing knative-serving -n ${KNATIVESERVING_NS} -o json | jq '.status.conditions[] | select(.type=="Ready") | .status'     KnativeServing    "True"    # robocop: disable
    Resource Should Exist     Gateway    knative-ingress-gateway     ${KNATIVESERVING_NS}
    Resource Should Exist     Gateway    knative-local-gateway     ${KNATIVESERVING_NS}
    Resource Should Exist     Service    knative-local-gateway     ${ISTIO_NS}
    Resource Should Exist     deployment    controller     ${KNATIVESERVING_NS}
    Wait For Pods Numbers  2    namespace=${KNATIVESERVING_NS}
    ...    label_selector=app.kubernetes.io/component=controller    timeout=120
    ${pod_names}=    Get Pod Names    ${KNATIVESERVING_NS}    app.kubernetes.io/component=controller
    Verify Containers Have Zero Restarts    ${pod_names}    ${KNATIVESERVING_NS}
    ${podname}=    Get Pod Name   ${OPERATOR_NAMESPACE}    ${LABEL_SELECTOR}
    Verify Pod Logs Do Not Contain    ${podname}    ${OPERATOR_NAMESPACE}    ${regex_pattern}    rhods-operator
    Read DSC Conditions    ${KNATIVESERVING_NS}    default-dsc


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Suite Teardown
    [Documentation]    Suite Teardown
    Close All Browsers
    RHOSi Teardown

Assign Vars According To Product
    [Documentation]    Assign vars related to product
    [Arguments]    ${PRODUCT}
    IF    "${PRODUCT}" == "RHODS"
        Set Suite Variable    ${OPERATOR_APPNAME}     Red Hat OpenShift AI
        Set Suite Variable    ${OPERATOR_NAME}    Red Hat OpenShift AI
    ELSE IF    "${PRODUCT}" == "ODH"
        Set Suite Variable    ${OPERATOR_APPNAME}  Open Data Hub Operator
        Set Suite Variable    ${OPERATOR_NAME}    Open Data Hub Operator
    END

Read DSC Conditions
    [Documentation]    Reads all DSC conditions
    [Arguments]    ${namespace}    ${dsc_name}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster ${dsc_name} -n ${namespace} -o jsonpath='{.status.conditions[].reason}'
    Should Be Equal As Integers    ${rc}     ${0}
    Log    ${out}    console=${out}
