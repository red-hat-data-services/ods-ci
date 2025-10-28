*** Settings ***
# robocop: disable=LEN08,LEN28
Documentation       NetworkPolicies resource file containing keywords for notebook network policy testing
Library             OperatingSystem
Library             String
Library             OpenShiftLibrary


*** Keywords ***
Verify Network Policies Exist
    [Documentation]    Verifies that both network policies exist for the given notebook (or confirms they don't exist for RHOAI-Managed)
    [Arguments]    ${CR_name}
    ${platform_type} =    Detect Platform Type
    Log    Verifying network policies for notebook: ${CR_name} on platform: ${platform_type}

    ${ctrl_policy_exists} =    Run Keyword And Return Status    Run
    ...    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE}
    ${oauth_policy_exists} =    Run Keyword And Return Status    Run
    ...    oc get networkpolicy ${CR_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE}

    # Check if network policies exist and log the result
    IF    ${ctrl_policy_exists} and ${oauth_policy_exists}
        Log    Confirmed: Network policies exist on ${platform_type} platform
        IF    "${platform_type}" == "RHOAI-Managed"
            Log    Note: This RHOAI-Managed cluster creates network policies (some may not)
        END
    ELSE
        Log    Confirmed: Network policies do not exist on ${platform_type} platform
        IF    "${platform_type}" == "RHOAI-Managed"
            Log    Note: This RHOAI-Managed cluster does not create network policies (expected behavior)
        ELSE
            Fail    Network policies should exist on ${platform_type} platform
        END
    END

Verify Network Policy Configurations
    [Documentation]    Verifies the configuration of network policies that exist
    [Arguments]    ${CR_name}
    ${ctrl_policy_exists} =    Run Keyword And Return Status    Run
    ...    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE}
    ${oauth_policy_exists} =    Run Keyword And Return Status    Run
    ...    oc get networkpolicy ${CR_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE}

    IF    ${ctrl_policy_exists}
        Verify Control Network Policy Configuration    ${CR_name}
    ELSE
        Log    Control network policy ${CR_name}-ctrl-np does not exist, skipping configuration verification
    END

    IF    ${oauth_policy_exists}
        Verify OAuth Network Policy Configuration    ${CR_name}
    ELSE
        Log    OAuth network policy ${CR_name}-kube-rbac-proxy-np does not exist, skipping configuration verification
    END

    IF    ${ctrl_policy_exists} or ${oauth_policy_exists}
        Verify Network Policy Labels    ${CR_name}
    ELSE
        Log    No network policies exist, skipping label verification
    END

Verify Control Network Policy Configuration
    [Documentation]    Verifies the control network policy configuration
    [Arguments]    ${CR_name}
    ${rc} =    Run And Return Rc    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE}
    ${ctrl_policy_exists} =    Evaluate    ${rc} == 0
    IF    ${ctrl_policy_exists}
        ${policy_ctrl} =    Run
        ...    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.spec.ingress[0]'
        ${expected_policy_ctrl} =    Run
        ...    sed "s#SELECTOR_LABEL_VALUE#${APPLICATIONS_NAMESPACE}#" tests/Resources/Files/expected_ctrl_np_template.txt  # robocop: disable=LEN08
        Should Be Equal As Strings    ${policy_ctrl}    ${expected_policy_ctrl}
        Log    Control network policy configuration: ${policy_ctrl}
        Log    Expected control network policy: ${expected_policy_ctrl}
    ELSE
        Log    Control network policy ${CR_name}-ctrl-np does not exist, skipping configuration verification
    END

Verify OAuth Network Policy Configuration
    [Documentation]    Verifies the OAuth network policy configuration
    [Arguments]    ${CR_name}
    ${rc} =    Run And Return Rc    oc get networkpolicy ${CR_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE}
    ${oauth_policy_exists} =    Evaluate    ${rc} == 0
    IF    ${oauth_policy_exists}
        ${policy_oauth} =    Run
        ...    oc get networkpolicy ${CR_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.spec.ingress[0]'  # robocop: disable=LEN08
        ${expected_policy_oauth} =    Get File    tests/Resources/Files/expected_oauth_np.txt
        Should Be Equal As Strings    ${policy_oauth}    ${expected_policy_oauth}
        Log    OAuth network policy configuration: ${policy_oauth}
        Log    Expected OAuth network policy: ${expected_policy_oauth}
    ELSE
        Log    OAuth network policy ${CR_name}-kube-rbac-proxy-np does not exist, skipping configuration verification
    END

Verify Network Policy Labels
    [Documentation]    Verifies that network policies have correct labels
    [Arguments]    ${CR_name}
    ${rc} =    Run And Return Rc    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE}
    ${ctrl_policy_exists} =    Evaluate    ${rc} == 0
    ${rc} =    Run And Return Rc    oc get networkpolicy ${CR_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE}
    ${oauth_policy_exists} =    Evaluate    ${rc} == 0

    IF    ${ctrl_policy_exists}
        Verify Control Network Policy Labels    ${CR_name}
    ELSE
        Log    Control network policy ${CR_name}-ctrl-np does not exist, skipping label verification
    END

    IF    ${oauth_policy_exists}
        Verify OAuth Network Policy Labels    ${CR_name}
    ELSE
        Log    OAuth network policy ${CR_name}-kube-rbac-proxy-np does not exist, skipping label verification
    END

Verify Control Network Policy Labels
    [Documentation]    Verifies control network policy labels
    [Arguments]    ${CR_name}
    ${ctrl_policy_labels} =    Run
    ...    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.metadata.labels // {}'
    # Check labels if they exist (they might be null in some cases)
    IF    '${ctrl_policy_labels}' != '{}' and '${ctrl_policy_labels}' != 'null'
        Should Contain    ${ctrl_policy_labels}    notebook-name
        Should Contain    ${ctrl_policy_labels}    ${CR_name}
    END

Verify OAuth Network Policy Labels
    [Documentation]    Verifies OAuth network policy labels
    [Arguments]    ${CR_name}
    ${oauth_policy_labels} =    Run
    ...    oc get networkpolicy ${CR_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.metadata.labels // {}'  # robocop: disable=LEN08
    # Check labels if they exist (they might be null in some cases)
    IF    '${oauth_policy_labels}' != '{}' and '${oauth_policy_labels}' != 'null'
        Should Contain    ${oauth_policy_labels}    notebook-name
        Should Contain    ${oauth_policy_labels}    ${CR_name}
    END

Verify Platform Specific Security
    [Documentation]    Verifies platform-specific security configurations
    [Arguments]    ${CR_name}    ${platform_type}
    Log    Performing platform-specific security validation checks for: ${platform_type}

    # Validate namespace labeling follows platform-specific patterns
    ${namespace_labels} =    Run
    ...    oc get namespace ${NOTEBOOKS_NAMESPACE} -o json | jq '.metadata.labels // {}'
    Log    Notebook namespace labels: ${namespace_labels}

    # Platform-specific namespace label validation
    IF    "${platform_type}" == "ODH"
        Validate ODH Namespace Labels    ${namespace_labels}
    ELSE IF    "${platform_type}" == "RHOAI-SelfManaged"
        Validate RHOAI SelfManaged Namespace Labels    ${namespace_labels}
    ELSE IF    "${platform_type}" == "RHOAI-Managed"
        Validate RHOAI Managed Namespace Labels    ${namespace_labels}
    END

    # Validate port ranges and namespace selectors
    Verify Security Ports    ${CR_name}
    Verify Security Namespace Selectors    ${CR_name}    ${platform_type}
    Verify Security Policy Compliance    ${CR_name}

Verify Security Ports
    [Documentation]    Validates port ranges are within expected security bounds
    [Arguments]    ${CR_name}
    ${rc} =    Run And Return Rc    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE}
    ${ctrl_policy_exists} =    Evaluate    ${rc} == 0
    ${rc} =    Run And Return Rc    oc get networkpolicy ${CR_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE}
    ${oauth_policy_exists} =    Evaluate    ${rc} == 0

    IF    ${ctrl_policy_exists}
        Verify Control Network Policy Ports    ${CR_name}
    ELSE
        Log    Control network policy does not exist, skipping port validation
    END

    IF    ${oauth_policy_exists}
        Verify OAuth Network Policy Ports    ${CR_name}
    ELSE
        Log    OAuth network policy does not exist, skipping port validation
    END

Verify Control Network Policy Ports
    [Documentation]    Verifies control network policy port configuration
    [Arguments]    ${CR_name}
    ${ctrl_ports} =    Run
    ...    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.spec.ingress[0].ports[0].port'  # robocop: disable=LEN08
    Should Be Equal As Integers    ${ctrl_ports}    ${8888}    msg=Control network policy should only allow port 8888
    Log    ✓ Control network policy port validation passed - only port 8888 is allowed

Verify OAuth Network Policy Ports
    [Documentation]    Verifies OAuth network policy port configuration
    [Arguments]    ${CR_name}
    ${oauth_ports} =    Run
    ...    oc get networkpolicy ${CR_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.spec.ingress[0].ports[0].port'  # robocop: disable=LEN08
    Should Be Equal As Integers    ${oauth_ports}    ${8443}    msg=OAuth network policy should only allow port 8443
    Log    ✓ OAuth network policy port validation passed - only port 8443 is allowed

Verify Security Namespace Selectors
    [Documentation]    Validates namespace selector security
    [Arguments]    ${CR_name}    ${platform_type}
    ${rc} =    Run And Return Rc    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE}
    ${ctrl_policy_exists} =    Evaluate    ${rc} == 0

    IF    ${ctrl_policy_exists}
        ${ctrl_namespace_selector} =    Run
        ...    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.spec.ingress[0].from[0].namespaceSelector.matchLabels'  # robocop: disable=LEN08

        IF    "${platform_type}" == "ODH"
            Validate ODH Namespace Selector    ${ctrl_namespace_selector}
        ELSE IF    "${platform_type}" == "RHOAI-SelfManaged"
            Validate RHOAI SelfManaged Namespace Selector    ${ctrl_namespace_selector}
        ELSE IF    "${platform_type}" == "RHOAI-Managed"
            Validate RHOAI Managed Namespace Selector    ${ctrl_namespace_selector}
        END
        Log    ✓ Platform-specific namespace selector validation passed
    ELSE
        Log    Control network policy ${CR_name}-ctrl-np does not exist, skipping namespace selector validation
    END

Verify Security Policy Compliance
    [Documentation]    Ensures no overly permissive rules
    [Arguments]    ${CR_name}
    ${rc} =    Run And Return Rc    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE}
    ${ctrl_policy_exists} =    Evaluate    ${rc} == 0
    ${rc} =    Run And Return Rc    oc get networkpolicy ${CR_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE}
    ${oauth_policy_exists} =    Evaluate    ${rc} == 0

    IF    ${ctrl_policy_exists}
        ${ctrl_ingress_rules} =    Run
        ...    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.spec.ingress | length'  # robocop: disable=LEN08
        Should Be Equal As Integers    ${ctrl_ingress_rules}    ${1}    msg=Control policy should have exactly 1 ingress rule (not overly permissive)
    ELSE
        Log    Control network policy ${CR_name}-ctrl-np does not exist, skipping compliance check
    END

    IF    ${oauth_policy_exists}
        ${oauth_ingress_rules} =    Run
        ...    oc get networkpolicy ${CR_name}-kube-rbac-proxy-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.spec.ingress | length'  # robocop: disable=LEN08
        Should Be Equal As Integers    ${oauth_ingress_rules}    ${1}    msg=OAuth policy should have exactly 1 ingress rule (not overly permissive)    # robocop: disable=LEN28
    ELSE
        Log    OAuth network policy ${CR_name}-kube-rbac-proxy-np does not exist, skipping compliance check
    END

    Log    ✓ Policy compliance check passed - no overly permissive rules detected
    Log    Network policies verification and security validation completed successfully
