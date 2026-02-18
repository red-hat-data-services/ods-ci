*** Settings ***
Documentation    Test Cases to verify Trusted CA Bundle support
Library    Collections
Resource       ../../../../../Resources/OCP.resource
Resource       ../../../../../Resources/ODS.robot
Resource       ../../../../../Resources/RHOSi.resource
Suite Setup    Suite Setup
Suite Teardown    Suite Teardown


*** Variables ***
${OPERATOR_NS}    ${OPERATOR_NAMESPACE}
${TEST_NS}    test-trustedcabundle
${DSCI_NAME}    default-dsci
${TRUSTED_CA_BUNDLE_CONFIGMAP}    odh-trusted-ca-bundle
${CUSTOM_CA_BUNDLE}    test-example-custom-ca-bundle
${IS_PRESENT}    0
${IS_NOT_PRESENT}    1
${SAVED_CUSTOM_CA_BUNDLE}    ${EMPTY}


*** Test Cases ***
Validate Trusted CA Bundles State Managed
    [Documentation]  The purpose of this test case is to validate Trusted CA Bundles when in state Managed
    ...    With Trusted CA Bundles Managed, ConfigMap odh-trusted-ca-bundle is expected to be created in
    ...    each non-reserved namespace.
    [Tags]    Operator    Smoke    ODS-2638    TrustedCABundle-Managed

    Wait Until Keyword Succeeds    10 min    0 sec
    ...    Is Resource Present    project    ${TEST_NS}    ${TEST_NS}    ${IS_PRESENT}

    Wait Until Keyword Succeeds    10 min    0 sec
    ...    Is Resource Present     ConfigMap    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${TEST_NS}    ${IS_PRESENT}

    # Check that ConfigMap contains key "ca-bundle.crt"
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    Check ConfigMap Contains CA Bundle Key    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ca-bundle.crt    ${TEST_NS}

    Set Custom CA Bundle Value In DSCI    ${DSCI_NAME}   ${CUSTOM_CA_BUNDLE}    ${OPERATOR_NS}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get project test-trustedcabundle -o yaml
    Log To Console          ${output}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get configmap ${TRUSTED_CA_BUNDLE_CONFIGMAP} -n ${TEST_NS} -o yaml | grep ${CUSTOM_CA_BUNDLE}
    Log To Console          ${output}
    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is CA Bundle Value Present    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${CUSTOM_CA_BUNDLE}    ${TEST_NS}    ${IS_PRESENT}

    [Teardown]     Restore DSCI Trusted CA Bundle Settings    ${SAVED_CUSTOM_CA_BUNDLE}

Validate Trusted CA Bundles State Unmanaged
    [Documentation]  The purpose of this test case is to validate Trusted CA Bundles when in state Unmanaged
    ...    With Trusted CA Bundles Unmanaged, ConfigMap odh-trusted-ca-bundle will not be managed by the operator.
    [Tags]    Operator    Smoke    ODS-2638    TrustedCABundle-Unmanaged

    Set Trusted CA Bundle Management State    ${DSCI_NAME}    Unmanaged    ${OPERATOR_NS}

    # Trusted CA Bundle managementStatus 'Unmanaged' should NOT result in bundle being overwirtten by operator
    Set Custom CA Bundle Value On ConfigMap
    ...    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    random-ca-bundle-value    ${TEST_NS}    5s
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get project test-trustedcabundle -o yaml
    Log To Console          ${output}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get configmap ${TRUSTED_CA_BUNDLE_CONFIGMAP} -n ${TEST_NS} -o yaml | grep ${CUSTOM_CA_BUNDLE}
    Log To Console          ${output}
    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is CA Bundle Value Present    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    random-ca-bundle-value    ${TEST_NS}    ${IS_PRESENT}

    [Teardown]     Restore DSCI Trusted CA Bundle Settings    ${SAVED_CUSTOM_CA_BUNDLE}

Validate Trusted CA Bundles State Removed
    [Documentation]  The purpose of this test case is to validate Trusted CA Bundles when in state Removed
    ...    With Trusted CA Bundles Removed, all odh-trusted-ca-bundle ConfigMaps will be removed.
    [Tags]    Operator    Sanity    ODS-2638    TrustedCABundle-Removed

    Set Trusted CA Bundle Management State    ${DSCI_NAME}    Removed    ${OPERATOR_NS}

    # Check that odh-trusted-ca-bundle has been 'Removed'
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    Is Resource Present     ConfigMap    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${TEST_NS}    ${IS_NOT_PRESENT}

    [Teardown]     Restore DSCI Trusted CA Bundle Settings    ${SAVED_CUSTOM_CA_BUNDLE}

Validate Trusted CA Bundles Exclude Namespace
    [Documentation]  The purpose of this test case is to validate Trusted CA Bundles can be excluded from a namespace.
    [Tags]    Operator    ODS-2638    TrustedCABundle-Exclude-Namespace   Sanity

    Set Trusted CA Bundle Management State    ${DSCI_NAME}    Managed    ${OPERATOR_NS}

    # Check that namespace does contain Trusted CA Bundle ConfigMap prior to excluding.
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    Is Resource Present     ConfigMap    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${TEST_NS}    ${IS_PRESENT}

    # Exclude the namespace
    Trusted CA Bundle Include Namespace    ${TEST_NS}    False

    # Trusted CA Bundle ConfigMap should not exist in namespace
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    Is Resource Present     ConfigMap    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${TEST_NS}    ${IS_NOT_PRESENT}

    # Enable Trusted CA Bundles on namespace, ConfigMap is expected to be created.
    Trusted CA Bundle Include Namespace    ${TEST_NS}    True
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    Is Resource Present     ConfigMap    ${TRUSTED_CA_BUNDLE_CONFIGMAP}    ${TEST_NS}    ${IS_PRESENT}

    [Teardown]     Restore DSCI Trusted CA Bundle Settings    ${SAVED_CUSTOM_CA_BUNDLE}


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Wait Until Operator Ready    ${OPERATOR_DEPLOYMENT_NAME}    ${OPERATOR_NS}
    Wait For DSCI Ready State    ${DSCI_NAME}    ${OPERATOR_NS}
    Create Namespace In Openshift    ${TEST_NS}
    ${SAVED_CUSTOM_CA_BUNDLE}=    Get Custom CA Bundle Value In DSCI    ${DSCI_NAME}    ${OPERATOR_NAMESPACE}
    Set Suite Variable    ${SAVED_CUSTOM_CA_BUNDLE}

Suite Teardown
    [Documentation]    Suite Teardown
    Delete Namespace From Openshift    ${TEST_NS}
    RHOSi Teardown

Restore DSCI Trusted CA Bundle Settings
    [Documentation]    Restore DSCI Trusted CA Bundle settings to original tate
    [Arguments]    ${custom_ca_value}

    Set Trusted CA Bundle Management State    ${DSCI_NAME}    Managed    ${OPERATOR_NS}
    Set Custom CA Bundle Value In DSCI    ${DSCI_NAME}    ${custom_ca_value}    ${OPERATOR_NS}

Is CA Bundle Value Present
    [Documentation]    Check if the ConfigtMap contains Custom CA Bundle value
    [Arguments]    ${config_map}    ${custom_ca_bundle_value}    ${namespace}        ${expected_result}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get configmap ${config_map} -n ${namespace} -o yaml | grep ${custom_ca_bundle_value}
    Should Be Equal    "${rc}"    "${expected_result}"    msg=${output}

Check ConfigMap Contains CA Bundle Key
    [Documentation]    Checks that ConfigMap contains CA Bundle
    [Arguments]    ${config_map}    ${ca_bundle_name}    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get configmap ${config_map} -n ${namespace} -o yaml | grep ${ca_bundle_name}
    Should Be Equal    "${rc}"    "0"     msg=${output}

Set Custom CA Bundle Value In DSCI
    [Documentation]    Set Custom CA Bundle value in DSCI
    [Arguments]    ${DSCI}    ${custom_ca_bundle_value}    ${namespace}
    ${custom_ca_bundle_value}=    Multiline To Oneline String    ${custom_ca_bundle_value}    \\n
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc patch DSCInitialization/${DSCI} -n ${namespace} -p '{"spec":{"trustedCABundle":{"customCABundle":"${custom_ca_bundle_value}"}}}' --type merge
    Should Be Equal    "${rc}"    "0"   msg=${output}

Set Custom CA Bundle Value On ConfigMap
    [Documentation]    Set Custom CA Bundle value in ConfigMap
    [Arguments]    ${config_map}    ${custom_ca_bundle_value}    ${namespace}    ${reconsile_wait_time}

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

Get Custom CA Bundle Value In DSCI
    [Documentation]    Get DSCI Custdom CA Bundle Value
    [Arguments]    ${dsci}    ${namespace}
    ${rc}   ${value}=    Run And Return Rc And Output
    ...    oc get DSCInitialization/${dsci} -n ${namespace} -o 'jsonpath={.spec.trustedCABundle.customCABundle}'
    Should Be Equal    "${rc}"    "0"   msg=${value}

    RETURN    ${value}

Trusted CA Bundle Include Namespace
    [Documentation]    Include/Exclude specific namespace from containing the Trusted CA Bundle ConfigMap
    [Arguments]    ${namespace}    ${include}

    ${rc}   ${value}=    Run And Return Rc And Output
    ...    oc annotate ns ${namespace} security.opendatahub.io/inject-trusted-ca-bundle=${include} --overwrite
    Should Be Equal    "${rc}"    "0"   msg=${value}
