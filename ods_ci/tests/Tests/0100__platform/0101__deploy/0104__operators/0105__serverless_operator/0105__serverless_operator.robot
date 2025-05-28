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
${INITIAL_KSERVE_MODE}    ${EMPTY}


*** Test Cases ***
Validate DSC creates all Serverless CRs
    [Documentation]  The purpose of this Test Case is to validate the creation
    ...    of Serverless Custom Resources when KServe.Serving is in Managed state
    [Tags]  Operator    ODS-2600    Tier2    kserve-serving-managed

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    kserve/serving    ${OPERATOR_NAMESPACE}
    IF    "${management_state}" != "Managed"
            Set Component State    kserve/serving    Managed
    END

    Wait For DSC Ready State    ${OPERATOR_NAMESPACE}    default-dsc

    # Resource Should Exist     KnativeServing    knative-serving     ${KNATIVESERVING_NS}
    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     KnativeServing    knative-serving     ${KNATIVESERVING_NS}

    Wait Knative Serving CR To Be In Ready State

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     gateway.networking.istio.io    knative-ingress-gateway     ${KNATIVESERVING_NS}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     gateway.networking.istio.io    knative-local-gateway     ${KNATIVESERVING_NS}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Should Exist     gateway.networking.istio.io    kserve-local-gateway     ${ISTIO_NS}

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

Validate DSC Kserve Serving Removed When Mode Is Serverless
    [Documentation]    Validate that KServe Serving state Removed does trigger an error in the DSC conditions,
    ...                showing this mode is not supported if kserve/serving mode is Serverless.
    [Tags]  Operator    RHOAIENG-7217    Tier2    kserve-serving-removed-serverless

    Set Resource Attribute       ${OPERATOR_NAMESPACE}       DataScienceCluster      ${DSC_NAME}
    ...                          /spec/components/kserve/defaultDeploymentMode       Serverless

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    kserve/serving    ${OPERATOR_NAMESPACE}
    IF    "${management_state}" != "Removed"
            Set Component State    kserve/serving    Removed
    END

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    DataScienceCluster Should Fail Because Kserve Serving Is Removed And Mode Is Serverless

Validate DSC Kserve Serving Removed State When Mode Is RawDeployment
    [Documentation]    Validate that KServe Serving state Removed does remove relevant resources if kserve/serving
    ...                mode is RawDeployment
    [Tags]  Operator    RHOAIENG-7217    Tier2    kserve-serving-removed-rawdeployment

    Set Resource Attribute       ${OPERATOR_NAMESPACE}       DataScienceCluster      ${DSC_NAME}
    ...                          /spec/components/kserve/defaultDeploymentMode       RawDeployment

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    kserve/serving    ${OPERATOR_NAMESPACE}
    IF    "${management_state}" != "Removed"
            Set Component State    kserve/serving    Removed
    END

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     KnativeServing    knative-serving    ${KNATIVESERVING_NS}   ${IS_NOT_PRESENT}

    Wait For DSC Ready State    ${OPERATOR_NAMESPACE}    default-dsc

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     gateway.networking.istio.io    knative-ingress-gateway     ${KNATIVESERVING_NS}   ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     gateway.networking.istio.io    knative-ingress-gateway     ${KNATIVESERVING_NS}   ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     gateway.networking.istio.io    kserve-local-gateway     ${ISTIO_NS}    ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Service    kserve-local-gateway     ${ISTIO_NS}    ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Service    knative-local-gateway     ${ISTIO_NS}    ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     deployment    controller     ${KNATIVESERVING_NS}    ${IS_NOT_PRESENT}

    Wait For Pods Numbers  0    namespace=${KNATIVESERVING_NS}
    ...    label_selector=${KNATIVE_SERVING_CONTROLLER_LABEL_SELECTOR}    timeout=300

Check value for serverless cert on CSV
    [Documentation]     Check value for serverless cert on CSV
    [Tags]      Operator    RHOAIENG-14530      Smoke       ExcludeOnODH
    ${rc}    ${json_derulo}=    Run And Return Rc And Output
    ...    oc get ClusterServiceVersion -l ${OPERATOR_SUBSCRIPTION_LABEL} -n ${OPERATOR_NAMESPACE} -o jsonpath='{.items[].metadata.annotations.operatorframework\\.io/initialization-resource}'
    Log To Console      ${json_derulo}
    &{my_dict}=        Create Dictionary
    ${my_dict}=     Load Json String        ${json_derulo}
    ${spec}=            Get From Dictionary 	${my_dict} 	spec
    ${components}=      Get From Dictionary 	${spec} 	components
    ${kserve}=          Get From Dictionary 	${components} 	kserve
    ${serving}=         Get From Dictionary 	${kserve} 	serving
    ${ingressGateway}=  Get From Dictionary 	${serving} 	ingressGateway
    ${certificate}=     Get From Dictionary 	${ingressGateway} 	certificate
    ${type}=            Get From Dictionary 	${certificate} 	type
    Should Be Equal 	${type} 	OpenshiftDefaultIngress


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Wait For DSC Ready State    ${OPERATOR_NAMESPACE}    default-dsc
    ${KSERVE_SERVING_STATE}=    Get DSC Component State    ${DSC_NAME}    kserve.serving    ${OPERATOR_NAMESPACE}
    ${INITIAL_KSERVE_MODE}=    Get Resource Attribute      ${OPERATOR_NAMESPACE}
    ...                 DataScienceCluster      ${DSC_NAME}        .spec.components.kserve.defaultDeploymentMode
    Set Suite Variable    ${KSERVE_SERVING_STATE}
    Set Suite Variable    ${INITIAL_KSERVE_MODE}
    Log To Console    "Suite Setup: KServe.serving state: ${KSERVE_SERVING_STATE}"
    Log To Console    "Suite Setup: KServe.defaultDeploymentMode: ${INITIAL_KSERVE_MODE}"
    ${STATE_LENGTH}=    Get Length    "${KSERVE_SERVING_STATE}"
    Should Be True     ${STATE_LENGTH} > 0
    ${STATE_LENGTH}=    Get Length    "${INITIAL_KSERVE_MODE}"
    Should Be True     ${STATE_LENGTH} > 0

Suite Teardown
    [Documentation]    Suite Teardown
    Restore Kserve Mode And Serving State
    RHOSi Teardown

DataScienceCluster Should Fail Because Kserve Serving Is Removed And Mode Is Serverless
    [Documentation]   Keyword to check the DSC conditions when serverless operator is not installed.
    ...           One condition should appear saying this operator is needed to enable kserve component.
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster ${DSC_NAME} -n ${OPERATOR_NAMESPACE} -o json | jq -r '.status.conditions | map(.message) | join(",")'    #robocop:disable
    Should Be Equal As Integers  ${return_code}   0   msg=Error retrieved DSC conditions
    Should Contain    ${output}    setting defaultdeployment mode as Serverless is incompatible with having Serving 'Removed'    #robocop:disable

Restore Kserve Mode And Serving State
    [Documentation]    Restore Kserve mode to original value (Serverless or RawDeployment) and
    ...                Serving state to original value (Managed or Removed)

    Set Component State    kserve/serving     ${KSERVE_SERVING_STATE}
    Log To Console    "Restored Saved State: ${KSERVE_SERVING_STATE}"
    Set Resource Attribute       ${OPERATOR_NAMESPACE}       DataScienceCluster      ${DSC_NAME}
    ...                          /spec/components/kserve/defaultDeploymentMode       ${INITIAL_KSERVE_MODE}
    Log To Console    "Restored Save Mode: ${INITIAL_KSERVE_MODE}

    IF    "${KSERVE_SERVING_STATE}" == "Managed"
        Wait Knative Serving CR To Be In Ready State

        # Note: May not need the following, as it is just a sanity-check
        Wait Until Keyword Succeeds    5 min    0 sec
        ...    Resource Should Exist     gateway.networking.istio.io    knative-ingress-gateway     ${KNATIVESERVING_NS}

    ELSE
        Wait Until Keyword Succeeds    5 min    0 sec
        ...    Is Resource Present     KnativeServing    knative-serving    ${KNATIVESERVING_NS}   ${IS_NOT_PRESENT}
    END

    Wait For DSC Ready State    ${KNATIVESERVING_NS}    default-dsc

Wait Knative Serving CR To Be In Ready State
    [Documentation]    Wait for Knative Serving CR to be in Ready state.

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Resource Status Should Be     oc get KnativeServing knative-serving -n ${KNATIVESERVING_NS} -o json | jq '.status.conditions[] | select(.type=="Ready") | .status'     KnativeServing    "True"    # robocop: disable
