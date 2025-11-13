*** Settings ***
# robocop: disable=LEN08,LEN28
Documentation       Platforms resource file containing keywords for platform-specific validation
Library             OperatingSystem
Library             String
Library             OpenShiftLibrary


*** Keywords ***
Validate ODH Namespace Labels
    [Documentation]    Validates namespace labels for ODH platform
    [Arguments]    ${namespace_labels}
    Log    Validating ODH namespace labels...

    # ODH should have opendatahub.io/generated-namespace label
    ${has_generated_label} =    Run Keyword And Return Status
    ...    Should Contain    ${namespace_labels}    opendatahub.io/generated-namespace
    IF    ${has_generated_label}
        Log    ✓ ODH namespace has opendatahub.io/generated-namespace label
    ELSE
        Log    ⚠ ODH namespace missing opendatahub.io/generated-namespace label
    END

    # ODH should have platform.opendatahub.io/part-of label
    ${has_part_of_label} =    Run Keyword And Return Status
    ...    Should Contain    ${namespace_labels}    platform.opendatahub.io/part-of
    IF    ${has_part_of_label}
        Log    ✓ ODH namespace has platform.opendatahub.io/part-of label
    ELSE
        Log    ⚠ ODH namespace missing platform.opendatahub.io/part-of label
    END

Validate RHOAI SelfManaged Namespace Labels
    [Documentation]    Validates namespace labels for RHOAI Self-Managed platform
    [Arguments]    ${namespace_labels}
    Log    Validating RHOAI Self-Managed namespace labels...

    # RHOAI Self-Managed should have opendatahub.io/generated-namespace label
    ${has_generated_label} =    Run Keyword And Return Status
    ...    Should Contain    ${namespace_labels}    opendatahub.io/generated-namespace
    IF    ${has_generated_label}
        Log    ✓ RHOAI Self-Managed namespace has opendatahub.io/generated-namespace label
    ELSE
        Log    ⚠ RHOAI Self-Managed namespace missing opendatahub.io/generated-namespace label
    END

    # RHOAI Self-Managed should have platform.opendatahub.io/part-of label
    ${has_part_of_label} =    Run Keyword And Return Status
    ...    Should Contain    ${namespace_labels}    platform.opendatahub.io/part-of
    IF    ${has_part_of_label}
        Log    ✓ RHOAI Self-Managed namespace has platform.opendatahub.io/part-of label
    ELSE
        Log    ⚠ RHOAI Self-Managed namespace missing platform.opendatahub.io/part-of label
    END

Validate RHOAI Managed Namespace Labels
    [Documentation]    Validates namespace labels for RHOAI Managed platform
    [Arguments]    ${namespace_labels}
    Log    Validating RHOAI Managed namespace labels...

    # RHOAI Managed should have opendatahub.io/generated-namespace label
    ${has_generated_label} =    Run Keyword And Return Status
    ...    Should Contain    ${namespace_labels}    opendatahub.io/generated-namespace
    IF    ${has_generated_label}
        Log    ✓ RHOAI Managed namespace has opendatahub.io/generated-namespace label
    ELSE
        Log    ⚠ RHOAI Managed namespace missing opendatahub.io/generated-namespace label
    END

    # RHOAI Managed should have platform.opendatahub.io/part-of label
    ${has_part_of_label} =    Run Keyword And Return Status
    ...    Should Contain    ${namespace_labels}    platform.opendatahub.io/part-of
    IF    ${has_part_of_label}
        Log    ✓ RHOAI Managed namespace has platform.opendatahub.io/part-of label
    ELSE
        Log    ⚠ RHOAI Managed namespace missing platform.opendatahub.io/part-of label
    END

Validate ODH Namespace Selector
    [Documentation]    Validates namespace selector for ODH platform
    [Arguments]    ${namespace_selector}
    Log    Validating ODH namespace selector...

    # ODH should allow traffic from namespaces with specific labels
    Should Contain    ${namespace_selector}    kubernetes.io/metadata.name
    Should Contain    ${namespace_selector}    ${APPLICATIONS_NAMESPACE}

    Log    ✓ ODH namespace selector validation passed

Validate RHOAI SelfManaged Namespace Selector
    [Documentation]    Validates namespace selector for RHOAI Self-Managed platform
    [Arguments]    ${namespace_selector}
    Log    Validating RHOAI Self-Managed namespace selector...

    # RHOAI Self-Managed should allow traffic from applications namespace
    Should Contain    ${namespace_selector}    kubernetes.io/metadata.name
    Should Contain    ${namespace_selector}    ${APPLICATIONS_NAMESPACE}

    Log    ✓ RHOAI Self-Managed namespace selector validation passed

Validate RHOAI Managed Namespace Selector
    [Documentation]    Validates namespace selector for RHOAI Managed platform
    [Arguments]    ${namespace_selector}
    Log    Validating RHOAI Managed namespace selector...

    # RHOAI Managed should allow traffic from applications namespace
    Should Contain    ${namespace_selector}    kubernetes.io/metadata.name
    Should Contain    ${namespace_selector}    ${APPLICATIONS_NAMESPACE}

    Log    ✓ RHOAI Managed namespace selector validation passed

Detect Platform Type
    [Documentation]    Detects the platform type for platform-specific validation
    ${is_self_managed} =    Is RHODS Self-Managed
    ${platform_type} =    Set Variable    ${EMPTY}
    IF    ${is_self_managed}
        IF    "${PRODUCT}" == "ODH"
            ${platform_type} =    Set Variable    ODH
        ELSE
            ${platform_type} =    Set Variable    RHOAI-SelfManaged
        END
    ELSE
        ${platform_type} =    Set Variable    RHOAI-Managed
    END
    Log    Detected platform type: ${platform_type}
    Log    PRODUCT: ${PRODUCT}, CLUSTER_TYPE: ${CLUSTER_TYPE}
    RETURN    ${platform_type}
