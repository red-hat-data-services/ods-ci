*** Settings ***
Documentation    Test Cases to verify Serverless installation
Library         Collections
Library         SeleniumLibrary
Library         OpenShiftLibrary
Resource        ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown


*** Variables ***
${RHOAI_APPNAME}  Red Hat OpenShift AI
${RHOAI_OPERATOR_NAME}    Red Hat OpenShift AI
${KSERVE_APPNAME}  Red Hat OpenShift Serverless
${KSERVE_OPERATOR_NAME}    Red Hat OpenShift Serverless
${KNATIVESERVING_NS}    knative-serving
${RHOAI_OPERATOR_NS}    redhat-ods-operator


*** Test Cases ***
Validate DSC creates all Serverless CRs
    [Documentation]  The purpose of this Test Case is to validate the creation
    ...    of KServe Custom Resources
    [Tags]  Operator    ODS-2600
    Check And Install Operator In Openshift    ${RHOAI_APPNAME}    ${RHOAI_OPERATOR_NAME}
    Check And Install Operator In Openshift    ${KSERVE_APPNAME}    ${KSERVE_OPERATOR_NAME}
    Is Resource Present     KnativeServing    knative-serving     ${KNATIVESERVING_NS}
    Check Status     oc get KnativeServing knative-serving -n ${KNATIVESERVING_NS} -o json | jq '.status.conditions[] | select(.type=="Ready") | .status'     KnativeServing    "True"    # robocop: disable
    Is Resource Present     Gateway    knative-ingress-gateway     ${KNATIVESERVING_NS}
    Is Resource Present     Gateway    knative-local-gateway     ${KNATIVESERVING_NS}
    Is Resource Present     Service    knative-local-gateway     istio-system
    Is Resource Present     deployment    controller     ${KNATIVESERVING_NS}
    Check Pods Number    ${KNATIVESERVING_NS}    app.kubernetes.io/component=controller
    ${pod_names}=    Get Pod Names    ${KNATIVESERVING_NS}    app.kubernetes.io/component=controller
    Verify Containers Have Zero Restarts    ${pod_names}    ${KNATIVESERVING_NS}
    ${podname}=    Get Pod Name   ${RHOAI_OPERATOR_NS}    label_selector=name=rhods-operator
    Check For Errors On Operator Logs    ${podname}    ${RHOAI_OPERATOR_NS}
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

Check Pods Number
    [Documentation]    Checks number of Pods
    [Arguments]    ${namespace}    ${label_selector}
    ${return_code}    ${output}    Run And Return Rc And Output    oc get pod -n ${namespace} -l app.kubernetes.io/component=controller | tail -n +2 | wc -l    # robocop: disable
    Should Be Equal As Integers    ${return_code}     ${0}
    Should Not Be Empty    ${output}
    Log To Console  pods ${label_selector} created

Check DSC Conditions
    [Documentation]    Checks that all conditions Reconciled Succesfully
    [Arguments]    ${namespace}    ${dsc_name}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc wait --timeout=3m --for jsonpath='{.status.conditions[].reason}'=ReconcileCompleted -n ${namespace} dsc ${dsc_name}    # robocop: disable
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

Extract Errors From Logs
    [Documentation]    Given Pod Logs it retrieves only the ERROR level ones.
    [Arguments]    ${logs}
    ${log_splits}=    Split String    string=${logs}    separator=.
    ${value}=    Set Variable    ${logs}
    FOR    ${idx}    ${split}    IN ENUMERATE    @{log_splits}  start=1
        Log    ${idx} - ${split}
        ${present}=    Run Keyword And Return Status
        ...    Should Contain    ${split}    ERROR
        IF    ${present}
            ${value}=    Set Variable    ${value["${split}"]}
            Log    message=No ERROR logs found on Pod.    level=WARN
        ELSE
            ${value}=    Set Variable    ${EMPTY}
            Log    message=No ERROR logs found on Pod.    level=INFO
            BREAK
        END
    END
