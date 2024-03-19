*** Settings ***
Documentation    Test Cases to verify Serverless installation
Library    Collections
Resource    ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Suite Setup    Suite Setup
Suite Teardown    Suite Teardown


*** Variables ***
${RHOAI_OPERATOR_NS}    redhat-ods-operator
${RHOAI_OPERATOR_DEPLOYMENT_NAME}    rhods-operator
${SERVICE_MESH_OPERATOR_NS}    openshift-operators
${SERVICE_MESH_CR_NS}    istio-system
${SERVICE_MESH_OPERATOR_DEPLOYMENT_NAME}    istio-operator
${DSCI_NAME}    default-dsci
${TRUSTED_CA_BUNDLE_CONFIGMAP}    odh-trusted-ca-bundle
${CUSTOM_CA_BUNDLE}    test-example-custom-ca-bundle

${IS_PRESENT}    0
${IS_NOT_PRESENT}    1


*** Test Cases ***
Validate Trusted CA Bundles ConfigMaps
    [Documentation]  The purpose of this Test Case is to validate the creation of
    ...    odh-trusted-ca-bundle ConfigMaps
    [Tags]    Operator
    ...       ODS-2638

    Log    message=Check that operators are available    level=INFO

    Is Operator Available    ${RHOAI_OPERATOR_DEPLOYMENT_NAME}    ${RHOAI_OPERATOR_NS}
    Is Operator Available    ${SERVICE_MESH_OPERATOR_DEPLOYMENT_NAME}    ${SERVICE_MESH_OPERATOR_NS}

    Log    message=Validate Trusted CA Bundle Management state Managed    level=INFO

    Is DSCI In Ready State    ${DSCI_NAME}    ${SERVICE_MESH_OPERATOR_NS}
    Is Resource Present     ConfigMap    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${SERVICE_MESH_CR_NS}    ${IS_PRESENT}

    # Check that ConfigMap contains "ca-bundle.crt"
    Check ConfigMap Contains CA Bundle   ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ca-bundle.crt    ${SERVICE_MESH_CR_NS}

    Set Custom CA Bundle Value In DSCI   ${CUSTOM_CA_BUNDLE}    ${RHOAI_OPERATOR_NS}
    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Is CA Bundle Value Present    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${CUSTOM_CA_BUNDLE}    ${SERVICE_MESH_CR_NS}    ${IS_PRESENT}

    Log    message=Validate Trusted CA Bundle Management State Unmanaged    level=INFO

    Set Trusted CA Bundle Management State    Unmanaged    ${RHOAI_OPERATOR_NS}

    # Trusted CA BUndle managementStatus 'Unmanaged' should NOT result in bundle being overwirtten by operator
    Set Custom CA Bundle Value On ConfigMap
    ...    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    random-ca-bundle-value    ${SERVICE_MESH_CR_NS}
    # Allow operator time to reconsile
    Sleep    5
    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Is CA Bundle Value Present    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    random-ca-bundle-value    ${SERVICE_MESH_CR_NS}    ${IS_PRESENT}

    Log    message=Validate Trusted CA Bundle Management State Removed    level=INFO

    Set Trusted CA Bundle Management State    Removed    ${RHOAI_OPERATOR_NS}

    # Check that odh-trusted-ca-bundle has been 'Removed'
    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Is Resource Present     ConfigMap    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${SERVICE_MESH_CR_NS}    ${IS_NOT_PRESENT}

    Log    message=Restore DSCI to original state    level=INFO
    Set Custom CA Bundle Value In DSCI   ''    ${RHOAI_OPERATOR_NS}
    Set Trusted CA Bundle Management State    Managed    ${RHOAI_OPERATOR_NS}


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    Log    message=Suite Setup.    level=INFO
    RHOSi Setup

Suite Teardown
    [Documentation]    Suite Teardown
    Log    message=Suite Teardown.    level=INFO
    RHOSi Teardown

Is Operator Available
    [Documentation]    Checks if operator is available
    [Arguments]    ${operator_name}    ${namespace}
    ${rc}=    Run And Return Rc
    ...    oc wait --timeout=2m --for condition=available -n ${namespace} deploy/${operator_name}
    Should Be Equal As Integers    ${rc}     ${0}    msg=${operator_name} Not Available

Is Resource Present
    [Documentation]    Check If Resource Is Present In Namespace
    [Arguments]       ${resource}     ${resource_name}    ${namespace}    ${expected_result}
    ${rc}=     Run And Return Rc
    ...  oc get ${resource} ${resource_name} -n ${namespace}
    Should Be Equal    "${rc}"    "${expected_result}"    msg=${resource} does not exist in ${namespace}

Is DSCI In Ready State
    [Documentation]    Checks that DSCI Reconciled Succesfully
    [Arguments]    ${dsci}    ${namespace}
    ${rc}=    Run And Return Rc
    ...    oc wait --timeout=3m --for jsonpath='{.status.conditions[].reason}'=ReconcileCompleted -n ${namespace} dsci ${dsci}
    Should Be Equal As Integers    ${rc}     ${0}    msg=${dsci} not in Ready state

Check ConfigMap Contains CA Bundle
    [Documentation]    Checks that ConfigMap contains CA Bundle
    [Arguments]    ${config_map}    ${ca_bundle_name}    ${namespace}
    ${rc}=     Run And Return Rc
    ...    oc get configmap ${config_map} -n ${namespace} -o yaml | grep ${ca_bundle_name}
    Should Be Equal    "${rc}"    "0"    msg=${TRUSTED_CA_BUNDLE_CONFIGMAP} does not contain CA bundle ${ca_bundle_name}

Is CA Bundle Value Present
    [Documentation]    Check if the ConfigtMap contains Custom CA Bundle value
    [Arguments]    ${config_map}    ${custom_ca_bundle_value}    ${namespace}        ${expected_result}
    ${rc}=     Run And Return Rc
    ...    oc get configmap ${config_map} -n ${namespace} -o yaml | grep ${custom_ca_bundle_value}
    Should Be Equal As Integers    ${rc}    ${expected_result}

Set Custom CA Bundle Value In DSCI
    [Documentation]    Set Custom CA Bundle Value in DSCI
    [Arguments]    ${custom_ca_bundle_value}    ${namespace}
    ${rc}=     Run And Return Rc
    ...    oc patch DSCInitialization/default-dsci -n ${namespace} -p '{"spec":{"trustedCABundle":{"customCABundle":"${custom_ca_bundle_value}"}}}' --type merge
    Should Be Equal    "${rc}"    "0"    msg=Failed to set DSCI Custom CA Bundle value to ${custom_ca_bundle_value}

Set Custom CA Bundle Value On ConfigMap
    [Documentation]    Set Custom CA Bundle Value in ConfigMap
    [Arguments]    ${config_map}    ${custom_ca_bundle_value}    ${namespace}
    ${rc}=     Run And Return Rc
    ...    oc patch ConfigMap/${config_map} -n ${namespace} -p '{"data":{"odh-ca-bundle.crt":"${custom_ca_bundle_value}"}}' --type merge
    Should Be Equal    "${rc}"    "0"    msg=Failed to set ${config_map} value ${custom_ca_bundle_value} ${namespace}

Set Trusted CA Bundle Management State
    [Documentation]    Change DSCI Management State to one of Managed/Unmanaged/Removed
    [Arguments]    ${management_state}    ${namespace}
    ${rc}=     Run And Return Rc
    ...    oc patch DSCInitialization/default-dsci -n ${namespace} -p '{"spec":{"trustedCABundle":{"managementState":"${management_state}"}}}' --type merge
    Should Be Equal    "${rc}"    "0"    msg=Failed update DSCI trustedCABundle managementState to ${management_state}
