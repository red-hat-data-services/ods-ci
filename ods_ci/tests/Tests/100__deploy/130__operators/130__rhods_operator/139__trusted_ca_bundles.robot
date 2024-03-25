*** Settings ***
Documentation    Test Cases to verify Serverless installation
Library    Collections
Resource    ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Suite Setup    Suite Setup
Suite Teardown    Suite Teardown


*** Variables ***
${OPERATOR_NS}    ${OPERATOR_NAMESPACE}
${RHOAI_OPERATOR_DEPLOYMENT_NAME}    rhods-operator
${TEST_NS}    test-trustedcabundle
${DSCI_NAME}    default-dsci
${TRUSTED_CA_BUNDLE_CONFIGMAP}    odh-trusted-ca-bundle
${CUSTOM_CA_BUNDLE}    test-example-custom-ca-bundle
${IS_PRESENT}    0
${IS_NOT_PRESENT}    1


*** Test Cases ***
Validate Trusted CA Bundles State Managed
    [Documentation]  The purpose of this test case is to validate Trusted CA Bundles when in state Managed
    ...    With Trusted CA Bundles Managed, ConfigMap odh-trusted-ca-bundle is expected to be created in
    ...    each non-reserved namespace.
    [Tags]    Operator    Smoke    ODS-2638    TrustedCABundle-Managed

    Wait Until Keyword Succeeds    2 min    0 sec
    ...    Is Resource Present    project    ${TEST_NS}    ${TEST_NS}    ${IS_PRESENT}

    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Is Resource Present     ConfigMap    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${TEST_NS}    ${IS_PRESENT}

    # Check that ConfigMap contains key "ca-bundle.crt"
    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Check ConfigMap Contains CA Bundle Key    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ca-bundle.crt    ${TEST_NS}

    Set Custom CA Bundle Value In DSCI    ${DSCI_NAME}   ${CUSTOM_CA_BUNDLE}    ${OPERATOR_NS}
    Wait Until Keyword Succeeds    2 min    0 sec
    ...    Is CA Bundle Value Present    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${CUSTOM_CA_BUNDLE}    ${TEST_NS}    ${IS_PRESENT}

    [Teardown]     Restore DSCI Trusted CA Bundle Settings

Validate Trusted CA Bundles State Unmanaged
    [Documentation]  The purpose of this test case is to validate Trusted CA Bundles when in state Unmanaged
    ...    With Trusted CA Bundles Unmanaged, ConfigMap odh-trusted-ca-bundle will not be managed by the operator.
    [Tags]    Operator    Smoke    ODS-2638    TrustedCABundle-Unmanaged

    Set Trusted CA Bundle Management State    ${DSCI_NAME}    Unmanaged    ${OPERATOR_NS}

    # Trusted CA Bundle managementStatus 'Unmanaged' should NOT result in bundle being overwirtten by operator
    Set Custom CA Bundle Value On ConfigMap
    ...    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    random-ca-bundle-value    ${TEST_NS}    5s
    Wait Until Keyword Succeeds    1 min    0 sec
    ...    Is CA Bundle Value Present    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    random-ca-bundle-value    ${TEST_NS}    ${IS_PRESENT}

    [Teardown]     Restore DSCI Trusted CA Bundle Settings

Validate Trusted CA Bundles State Removed
    [Documentation]  The purpose of this test case is to validate Trusted CA Bundles when in state Removed
    ...    With Trusted CA Bundles Removed, all odh-trusted-ca-bundle ConfigMaps will be removed.
    [Tags]    Operator    Smoke    ODS-2638    TrustedCABundle-Removed

    Set Trusted CA Bundle Management State    ${DSCI_NAME}    Removed    ${OPERATOR_NS}

    # Check that odh-trusted-ca-bundle has been 'Removed'
    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Is Resource Present     ConfigMap    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${TEST_NS}    ${IS_NOT_PRESENT}

    [Teardown]     Restore DSCI Trusted CA Bundle Settings


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Wait Until Operator Ready    ${RHOAI_OPERATOR_DEPLOYMENT_NAME}    ${OPERATOR_NS}
    Wiat For DSCI Ready State    ${DSCI_NAME}    ${OPERATOR_NS}
    Create Namespace In Openshift    ${TEST_NS}

Suite Teardown
    [Documentation]    Suite Teardown
    Delete Namespace From Openshift    ${TEST_NS}
    RHOSi Teardown

Restore DSCI Trusted CA Bundle Settings
    [Documentation]    Restore DSCI Trusted CA Bundle settings to original tate
    Set Custom CA Bundle Value In DSCI    ${DSCI_NAME}   ''    ${OPERATOR_NS}
    Set Trusted CA Bundle Management State    ${DSCI_NAME}    Managed    ${OPERATOR_NS}

Wait Until Operator Ready
    [Documentation]    Checks if operator is available/ready
    [Arguments]    ${operator_name}    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc wait --timeout=2m --for condition=available -n ${namespace} deploy/${operator_name}
    Should Be Equal    "${rc}"    "0"    msg=${output}

Is Resource Present
    [Documentation]    Check if resource is present in namespace
    [Arguments]       ${resource}     ${resource_name}    ${namespace}    ${expected_result}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...  oc get ${resource} ${resource_name} -n ${namespace}
    Should Be Equal    "${rc}"    "${expected_result}"    msg=${output}

Is CA Bundle Value Present
    [Documentation]    Check if the ConfigtMap contains Custom CA Bundle value
    [Arguments]    ${config_map}    ${custom_ca_bundle_value}    ${namespace}        ${expected_result}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get configmap ${config_map} -n ${namespace} -o yaml | grep ${custom_ca_bundle_value}
    Should Be Equal    "${rc}"    "${expected_result}"    msg=${output}

Wiat For DSCI Ready State
    [Documentation]    Checks that DSCI reconciled succesfully
    [Arguments]    ${dsci}    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc wait --timeout=3m --for jsonpath='{.status.conditions[].reason}'=ReconcileCompleted -n ${namespace} dsci ${dsci}
    Should Be Equal    "${rc}"    "0"     msg=${output}

Check ConfigMap Contains CA Bundle Key
    [Documentation]    Checks that ConfigMap contains CA Bundle
    [Arguments]    ${config_map}    ${ca_bundle_name}    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get configmap ${config_map} -n ${namespace} -o yaml | grep ${ca_bundle_name}
    Should Be Equal    "${rc}"    "0"     msg=${output}

Create Namespace In Openshift
    [Documentation]    Create a new namespace if it does not already exist
    [Arguments]    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output    oc get project ${namespace}
    IF    ${rc} != 0
        ${rc}=     Run And Return Rc    oc new-project ${namespace}
        Should Be Equal    "${rc}"    "0"   msg=${output}
    END

Delete Namespace From Openshift
    [Documentation]    Delete namespace from opneshift
    [Arguments]    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output    oc delete project ${namespace}
    Should Be Equal    "${rc}"    "0"   msg=${output}

Set Custom CA Bundle Value In DSCI
    [Documentation]    Set Custom CA Bundle value in DSCI
    [Arguments]    ${DSCI}    ${custom_ca_bundle_value}    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc patch DSCInitialization/${DSCI} -n ${namespace} -p '{"spec":{"trustedCABundle":{"customCABundle":"${custom_ca_bundle_value}"}}}' --type merge
    Should Be Equal    "${rc}"    "0"   msg=${output}

Set Custom CA Bundle Value On ConfigMap
    [Documentation]    Set Custom CA Bundle value in ConfigMap
    [Arguments]    ${config_map}    ${custom_ca_bundle_value}    ${namespace}    ${reconsile_wait_time}
    Log    message=IN Here:${config_map} ${custom_ca_bundle_value} ${namespace}    level=INFO
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc patch ConfigMap/${config_map} -n ${namespace} -p '{"data":{"odh-ca-bundle.crt":"${custom_ca_bundle_value}"}}' --type merge
    Should Be Equal    "${rc}"    "0"   msg=${output}

    # Allow operator time to reconsile
    Sleep    ${reconsile_wait_time}

Set Trusted CA Bundle Management State
    [Documentation]    Change DSCI Management state to one of Managed/Unmanaged/Removed
    [Arguments]    ${DSCI}    ${management_state}    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc patch DSCInitialization/${DSCI} -n ${namespace} -p '{"spec":{"trustedCABundle":{"managementState":"${management_state}"}}}' --type merge
    Should Be Equal    "${rc}"    "0"   msg=${output}
