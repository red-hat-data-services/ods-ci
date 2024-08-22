*** Settings ***
Documentation    Test Cases to verify Serverless installation
Library         Collections
Library         OpenShiftLibrary
Resource        ../../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../../../Resources/OCP.resource
Resource        ../../../../../Resources/RHOSi.resource
Resource        ../../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown


*** Variables ***
${KNATIVESERVING_NS}    knative-serving
${ISTIO_NS}     istio-system
#${regex_pattern}       ERROR
${KNATIVE_SERVING_CONTROLLER_LABEL_SELECTOR}    app.kubernetes.io/component=controller
${KSERVE_SERVING_STATE}    ${EMPTY}
${IS_NOT_PRESENT}    1


*** Test Cases ***
Validate DSC creates all Serverless CRs
    [Documentation]  The purpose of this Test Case is to validate the creation
    ...    of Serverless Custom Resources when KServe.Serving is in Managed state
    [Tags]  Operator    ODS-2600    Tier2    kserve-serving-managed

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    kserve/serving    ${OPERATOR_NAMESPACE}
    IF    "${management_state}" != "Managed"
            Set Component State    kserve/serving    Managed
    END

    Wait For DSC Conditions Reconciled    ${OPERATOR_NAMESPACE}    default-dsc

    # Resource Should Exist     KnativeServing    knative-serving     ${KNATIVESERVING_NS}
    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     KnativeServing    knative-serving     ${KNATIVESERVING_NS}

    Wait Knative Serving CR To Be In Ready State

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     Gateway    knative-ingress-gateway     ${KNATIVESERVING_NS}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     Gateway    knative-local-gateway     ${KNATIVESERVING_NS}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     Gateway    kserve-local-gateway     ${ISTIO_NS}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     Service    kserve-local-gateway     ${ISTIO_NS}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     Service    knative-local-gateway     ${ISTIO_NS}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     deployment    controller     ${KNATIVESERVING_NS}

    Wait For Pods Numbers  2    namespace=${KNATIVESERVING_NS}
    ...    label_selector=${KNATIVE_SERVING_CONTROLLER_LABEL_SELECTOR}    timeout=300

    ${pod_names}=    Get Pod Names    ${KNATIVESERVING_NS}    ${KNATIVE_SERVING_CONTROLLER_LABEL_SELECTOR}
    Verify Containers Have Zero Restarts    ${pod_names}    ${KNATIVESERVING_NS}
    #${podname}=    Get Pod Name   ${OPERATOR_NAMESPACE}    ${OPERATOR_LABEL_SELECTOR}
    #Verify Pod Logs Do Not Contain    ${podname}    ${OPERATOR_NAMESPACE}    ${regex_pattern}    rhods-operator

Validate DSC Kserve Serving Removed State
    [Documentation]    Validate that KServe Serving state Removed does remove relevant resources.
    [Tags]  Operator    RHOAIENG-7217    Tier2    kserve-serving-removed

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    kserve/serving    ${OPERATOR_NAMESPACE}
    IF    "${management_state}" != "Removed"
            Set Component State    kserve/serving    Removed
    END

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     KnativeServing    knative-serving    ${KNATIVESERVING_NS}   ${IS_NOT_PRESENT}

    Wait For DSC Conditions Reconciled    ${OPERATOR_NAMESPACE}    default-dsc

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Gateway    knative-ingress-gateway     ${KNATIVESERVING_NS}   ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Gateway    knative-ingress-gateway     ${KNATIVESERVING_NS}   ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present      Gateway    kserve-local-gateway     ${ISTIO_NS}    ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Service    kserve-local-gateway     ${ISTIO_NS}    ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Service    knative-local-gateway     ${ISTIO_NS}    ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     deployment    controller     ${KNATIVESERVING_NS}    ${IS_NOT_PRESENT}

    Wait For Pods Numbers  0    namespace=${KNATIVESERVING_NS}
    ...    label_selector=${KNATIVE_SERVING_CONTROLLER_LABEL_SELECTOR}    timeout=300


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Wait For DSC Conditions Reconciled    ${OPERATOR_NAMESPACE}    default-dsc
    ${KSERVE_SERVING_STATE}=    Get DSC Component State    ${DSC_NAME}    kserve.serving    ${OPERATOR_NAMESPACE}
    Log To Console    "KServe.serving State: ${KSERVE_SERVING_STATE}"
    Should Not Be Empty  ${KSERVE_SERVING_STATE}
    Set Suite Variable    ${KSERVE_SERVING_STATE}

Suite Teardown
    [Documentation]    Suite Teardown
    Restore Kserve Serving State
    RHOSi Teardown

Restore Kserve Serving State
    [Documentation]    Restore Kserve Serving state to original value (Managed or Removed)

    Log To Console    "Restore saved Kserve.serving state: ${KSERVE_SERVING_STATE}"
    Set Component State    kserve/serving     ${KSERVE_SERVING_STATE}

    IF    "${KSERVE_SERVING_STATE}" == "Managed"
        Wait Knative Serving CR To Be In Ready State

        # Note: May not need the following, as it is just a sanity-check
        Wait Until Keyword Succeeds    5 min    0 sec
        ...    Resource Should Exist     Gateway    knative-ingress-gateway     ${KNATIVESERVING_NS}

    ELSE
        Wait Until Keyword Succeeds    5 min    0 sec
        ...    Is Resource Present     KnativeServing    knative-serving    ${KNATIVESERVING_NS}   ${IS_NOT_PRESENT}
    END

    Wait For DSC Conditions Reconciled    ${KNATIVESERVING_NS}    default-dsc

Wait Knative Serving CR To Be In Ready State
    [Documentation]    Wait for Knative Serving CR to be in Ready state.

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Status Should Be     oc get KnativeServing knative-serving -n ${KNATIVESERVING_NS} -o json | jq '.status.conditions[] | select(.type=="Ready") | .status'     KnativeServing    "True"    # robocop: disable
