*** Settings ***
Documentation    Test Cases to verify Serverless installation
Library         Collections
Library         SeleniumLibrary
Library         OpenShiftLibrary
Resource        ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown


*** Variables ***
${SERVERLESS_APPNAME}  Red Hat OpenShift Serverless
${SERVERLESS_OPERATOR_NAME}    Red Hat OpenShift Serverless
${KNATIVESERVING_NS}    knative-serving
${ISTIO_NS}     istio-system


*** Test Cases ***
Validate DSC creates all Serverless CRs
    [Documentation]  The purpose of this Test Case is to validate the creation
    ...    of Serverless Custom Resources
    [Tags]  Operator    ODS-2600
    Assign Vars According To Product    ${PRODUCT}
    Check And Install Operator in Openshift    ${SERVERLESS_APPNAME}    ${SERVERLESS_OPERATOR_NAME}
    Check And Install Operator in Openshift    ${OPERATOR_APPNAME}    ${OPERATOR_NAME}
    Is Resource Present     KnativeServing    knative-serving     ${KNATIVESERVING_NS}
    Check Status     oc get KnativeServing knative-serving -n ${KNATIVESERVING_NS} -o json | jq '.status.conditions[] | select(.type=="Ready") | .status'     KnativeServing    "True"    # robocop: disable
    Is Resource Present     Gateway    knative-ingress-gateway     ${KNATIVESERVING_NS}
    Is Resource Present     Gateway    knative-local-gateway     ${KNATIVESERVING_NS}
    Is Resource Present     Service    knative-local-gateway     ${ISTIO_NS}
    Is Resource Present     deployment    controller     ${KNATIVESERVING_NS}
    Wait For Pods Numbers  2    namespace=${KNATIVESERVING_NS}
    ...    label_selector=app.kubernetes.io/component=controller    timeout=120
    ${pod_names}=    Get Pod Names    ${KNATIVESERVING_NS}    app.kubernetes.io/component=controller
    Verify Containers Have Zero Restarts    ${pod_names}    ${KNATIVESERVING_NS}
    ${podname}=    Get Pod Name   ${OPERATOR_NAMESPACE}    label_selector=name=rhods-operator
    Check For Errors On Operator Logs    ${podname}    ${OPERATOR_NAMESPACE}
    Check DSC Conditions    ${KNATIVESERVING_NS}    default-dsc


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
    [Arguments]    ${product}
    IF    "${product}" == "RHODS"
        Set Suite Variable    ${OPERATOR_APPNAME}     Red Hat OpenShift AI
        Set Suite Variable    ${OPERATOR_NAME}    Red Hat OpenShift AI
        Set Suite Variable    ${OPERATOR_NAMESPACE}    redhat-ods-operator
    ELSE IF    "${product}" == "ODH"
        Set Suite Variable    ${OPERATOR_APPNAME}  Open Data Hub Operator
        Set Suite Variable    ${OPERATOR_NAME}    Open Data Hub Operator
        Set Suite Variable    ${OPERATOR_NAMESPACE}    openshift-operators
    END

Is Resource Present
    [Documentation]    Check CR
    [Arguments]       ${resource}     ${resource_name}    ${namespace}
    ${rc}=     Run and Return Rc
    ...  oc get ${resource} ${resource_name} -n ${namespace}
    Should Be Equal    "${rc}"    "0"    msg=${resource} does not exist

Check Status
    [Documentation]    Check Resource Status
    [Arguments]       ${oc_get}     ${resource}    ${expected_status}
    ${status}=     Run
    ...  ${oc_get}
    Log    ${status}    console=True
    Should Be Equal    ${status}    ${expected_status}   msg=${resource} is not in Ready status

Check DSC Conditions
    [Documentation]    Checks that all conditions Reconciled Succesfully
    [Arguments]    ${namespace}    ${dsc_name}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster ${dsc_name} -n ${namespace} -o jsonpath='{.status.conditions[].reason}'
    Should Be Equal As Integers    ${rc}     ${0}
    Log    ${out}    console=${out}

Check For Errors On Operator Logs
    [Documentation]    Checks there are no errors on Operator Logs
    [Arguments]    ${operator_name}    ${operator_namespace}
    ${pod_logs}=    Oc Get Pod Logs  name=${operator_name}  namespace=${operator_namespace}  container=rhods-operator
    ${error_present}=    Run Keyword And Return Status    Should Contain    ${pod_logs}    ERROR
    IF    ${error_present}
        Log    message=Check Pod Logs, ERROR level logs found.    level=WARN
    ELSE
        Log    message=No ERROR logs found on Pod.    level=INFO
    END
