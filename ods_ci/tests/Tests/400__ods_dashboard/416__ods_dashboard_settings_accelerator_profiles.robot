*** Settings ***
Resource        ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettingsAcceleratorProfiles.resource
Resource        ../../Resources/CLI/AcceleratorProfiles/AcceleratorProfiles.resource
Resource        ../../Resources/ODS.robot
Suite Setup     Setup Settings Accelerator Profiles
Suite Teardown  Teardown Settings Accelerator Profiles


*** Variables ***
${ACC_DISPLAY_NAME}=    qe_accelerator_profile_
${ACC_NAME}=    qeacceleratorprofile
${ACC_IDENTIFIER}=    nvidia.com/gpu
${ACC_DESCRIPTION}=    Accelerator Profile Description
${ACC_ENABLED}=    True
${ACC_TOLERATION_OPERATOR}=    Exists
${ACC_TOLERATION_EFFECT}=    PreferNoSchedule
${ACC_TOLERATION_KEY}=    my_key
${ACC_TOLERATION_VALUE}=    my_value
${ACC_TOLERATION_SECONDS}=    15


*** Test Cases ***
Create An Accelerator Profile From "Accelerator Profiles" Administration UI
    [Documentation]    Create an Accelerator Profile instance from the Administration UI and verify it's content
    [Tags]  RHOAIENG-3349
    ...     Smoke
    [Setup]  Open Dashboard And Navigate to Accelerator Profiles from Settings
    Create An Accelerator Profile Via UI   ${ACC_DISPLAY_NAME}1   ${ACC_IDENTIFIER}
    ...                                    ${ACC_DESCRIPTION}   ${ACC_ENABLED}    tolerations=yes
    ...                                    tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                                    tol_effect=${ACC_TOLERATION_EFFECT}
    ...                                    tol_key=${ACC_TOLERATION_KEY}
    ...                                    tol_value=${ACC_TOLERATION_VALUE}
    ...                                    tol_seconds=${ACC_TOLERATION_SECONDS}
    Accelerator Profile Should Be Displayed In The Grid   ${ACC_DISPLAY_NAME}1
    Verify Accelerator Profile Values Via CLI   ${ACC_DISPLAY_NAME}1   ${ACC_IDENTIFIER}
    ...                                         ${ACC_DESCRIPTION}   ${ACC_ENABLED}    tolerations=yes
    ...                                         tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                                         tol_effect=${ACC_TOLERATION_EFFECT}
    ...                                         tol_key=${ACC_TOLERATION_KEY}
    ...                                         tol_value=${ACC_TOLERATION_VALUE}
    ...                                         tol_seconds=${ACC_TOLERATION_SECONDS}

Modify An Accelerator Profile Using "Accelerator Profiles" Administration UI
    [Documentation]    Modify an Accelerator Profile instance from the Administration UI and verify it's content
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_DISPLAY_NAME}2
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles from Settings
    Edit Accelerator Profile    original_display_name=${ACC_DISPLAY_NAME}2
    ...                         display_name=${ACC_DISPLAY_NAME}2_modified
    ...                         identifier=${ACC_IDENTIFIER}_modified
    ...                         description=${ACC_DESCRIPTION}_modified    tolerations=yes
    ...                         tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                         tol_effect=${ACC_TOLERATION_EFFECT}
    ...                         tol_key=${ACC_TOLERATION_KEY}
    ...                         tol_value=${ACC_TOLERATION_VALUE}
    ...                         tol_seconds=${ACC_TOLERATION_SECONDS}
    Accelerator Profile Should Be Displayed In The Grid   ${ACC_DISPLAY_NAME}2_modified
    Verify Accelerator Profile Values Via CLI   ${ACC_DISPLAY_NAME}2_modified   ${ACC_IDENTIFIER}_modified
    ...                                         ${ACC_DESCRIPTION}_modified   tolerations=yes
    ...                                         tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                                         tol_effect=${ACC_TOLERATION_EFFECT}
    ...                                         tol_key=${ACC_TOLERATION_KEY}
    ...                                         tol_value=${ACC_TOLERATION_VALUE}
    ...                                         tol_seconds=${ACC_TOLERATION_SECONDS}

Delete Tolerations from an Accelerator Profile Using "Accelerator Profiles" Administration UI
    [Documentation]    Delete Tolerations from  an Accelerator Profile instance from the Administration UI and
    ...                verify it's content
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_DISPLAY_NAME}3
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles from Settings
    Delete Accelerator Profile Tolerations    ${ACC_DISPLAY_NAME}3
    Accelerator Profile Should Be Displayed In The Grid   ${ACC_DISPLAY_NAME}3
    Verify Accelerator Profile Has No Tolerations Via CLI   ${ACC_DISPLAY_NAME}3

Disable an Accelerator Profile From The Accelerator Profile Edit View
    [Documentation]    Disable an An accelerator profile from the Edit Accelerator Profile view
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_DISPLAY_NAME}4
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles from Settings
    Edit Accelerator Profile    original_display_name=${ACC_DISPLAY_NAME}4    enabled=False
    Accelerator Profile Should Be Displayed In The Grid   ${ACC_DISPLAY_NAME}4
    Verify Accelerator Profile Values Via CLI   ${ACC_DISPLAY_NAME}4    enabled=False

Enable an Accelerator Profile From The Accelerator Profile Edit View
    [Documentation]    Enable an An accelerator profile from the Edit Accelerator Profile view
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_DISPLAY_NAME}5
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles from Settings
    Edit Accelerator Profile    original_display_name=${ACC_DISPLAY_NAME}5    enabled=True
    Accelerator Profile Should Be Displayed In The Grid   ${ACC_DISPLAY_NAME}5
    Verify Accelerator Profile Values Via CLI   ${ACC_DISPLAY_NAME}5    enabled=True

Disable an Accelerator Profile From The Grid of the Accelerator Profile View
    [Documentation]    Disable an An accelerator profile from the Edit Accelerator Profile view
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_DISPLAY_NAME}6
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles from Settings
    Search for accelerator profile in grid    ${ACC_DISPLAY_NAME}6
    Disable Accelerator Profile    ${ACC_NAME}6
    Verify Accelerator Profile Values Via CLI   ${ACC_DISPLAY_NAME}6    enabled=False

Enable an Accelerator Profile From The Grid of the Accelerator Profile View
    [Documentation]    Enable an An accelerator profile from the Accelerator Profile view
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_DISPLAY_NAME}7
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles from Settings
    Search for accelerator profile in grid    ${ACC_DISPLAY_NAME}7
    Click On Enable Accelerator Profile    ${ACC_NAME}7
    Verify Accelerator Profile Values Via CLI   ${ACC_DISPLAY_NAME}7    enabled=True

Delete an Accelerator Profile From The Grid of the Accelerator Profile View
    [Documentation]    Delete an An accelerator profile from the Accelerator Profile view
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_DISPLAY_NAME}8
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles from Settings
    Delete Accelerator Profile    ${ACC_DISPLAY_NAME}8
    Accelerator Profile Should Not Exist   ${ACC_NAME}8


*** Keywords ***
Teardown Settings Accelerator Profiles
    [Documentation]    Sets the default values In User Management Settings
    ...                and runs the RHOSi Teardown
    Dashboard Settings Accelerator Profiles Test Teardown
    RHOSi Teardown

Open Dashboard And Navigate to Accelerator Profiles from Settings
    [Documentation]    Navigate as an Admin User to the Accelerator Profiles administration view
    ...                Used as a Test Setup
    Open ODS Dashboard With Admin User
    Navigate To Page    Settings    Accelerator profiles

Setup Settings Accelerator Profiles
    [Documentation]  Customized Steup for admin UI
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup

Dashboard Settings Accelerator Profiles Test Teardown
    [Documentation]    Test teardown
    Delete All Accelerator Profiles Which Starts With   ${ACC_NAME}

