*** Settings ***
Resource        ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettingsAcceleratorProfiles.resource
Resource        ../../Resources/CLI/AcceleratorProfiles/AcceleratorProfiles.resource
Resource        ../../Resources/ODS.robot
Suite Setup     Setup Settings Accelerator Profiles
Suite Teardown  Teardown Settings Accelerator Profiles
Test Tags         Dashboard


*** Variables ***
${ACC2_DISPLAY_NAME}=    Test: Modify Accelerator Profile 2
${ACC3_DISPLAY_NAME}=    Test: Delete Tolerations from AP 3
${ACC4_DISPLAY_NAME}=    Test: Disable AP 4 from Edit Detail View
${ACC5_DISPLAY_NAME}=    Test: Enable AP 5 from Edit Detail View
${ACC6_DISPLAY_NAME}=    Test: Disable AP 6 from Administration View
${ACC7_DISPLAY_NAME}=    Test: Enable AP 7 from Administration View
${ACC8_DISPLAY_NAME}=    Test: Delete AP 8 from grid
${ACC_NAME}=    accelerator-profile-3349-
${ACC_IDENTIFIER}=    nvidia.com/gpu
${ACC_DESCRIPTION}=    Create Accelerator Profile
${ACC_DESCRIPTION2}=    Modify Accelerator Profile
${ACC_ENABLED}=    True
${ACC_TOLERATION_OPERATOR}=    Exists
${ACC_TOLERATION_EFFECT}=    PreferNoSchedule
${ACC_TOLERATION_KEY}=    my_key
${ACC_TOLERATION_VALUE}=    my_value
${ACC_TOLERATION_SECONDS}=    15


*** Test Cases ***
Create An Accelerator Profile From Accelerator Profiles Administration UI
    [Documentation]    Create an Accelerator Profile instance from the Administration UI and verify it's content
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Open Dashboard And Navigate To Accelerator Profiles From Settings
    Create An Accelerator Profile Via UI   ${ACC_NAME}1   ${ACC_IDENTIFIER}
    ...                                    ${ACC_DESCRIPTION}   ${ACC_ENABLED}    tolerations=yes
    ...                                    tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                                    tol_effect=${ACC_TOLERATION_EFFECT}
    ...                                    tol_key=${ACC_TOLERATION_KEY}
    ...                                    tol_value=${ACC_TOLERATION_VALUE}
    ...                                    tol_seconds=${ACC_TOLERATION_SECONDS}
    Accelerator Profile Should Be Displayed In The Grid   ${ACC_NAME}1
    Verify Accelerator Profile Values Via CLI   ${ACC_NAME}1   ${ACC_IDENTIFIER}
    ...                                         ${ACC_DESCRIPTION}   ${ACC_ENABLED}    tolerations=yes
    ...                                         tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                                         tol_effect=${ACC_TOLERATION_EFFECT}
    ...                                         tol_key=${ACC_TOLERATION_KEY}
    ...                                         tol_value=${ACC_TOLERATION_VALUE}
    ...                                         tol_seconds=${ACC_TOLERATION_SECONDS}

Modify An Accelerator Profile Using Accelerator Profiles Administration UI
    [Documentation]    Modify an Accelerator Profile instance from the Administration UI and verify it's content
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_NAME}2
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles From Settings
    Edit Accelerator Profile    original_display_name=${ACC2_DISPLAY_NAME}
    ...                         display_name=${ACC2_DISPLAY_NAME}_modified
    ...                         identifier=${ACC_IDENTIFIER}_modified
    ...                         description=${ACC_DESCRIPTION2}_modified    tolerations=yes
    ...                         tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                         tol_effect=${ACC_TOLERATION_EFFECT}
    ...                         tol_key=${ACC_TOLERATION_KEY}
    ...                         tol_value=${ACC_TOLERATION_VALUE}
    ...                         tol_seconds=${ACC_TOLERATION_SECONDS}
    Accelerator Profile Should Be Displayed In The Grid   ${ACC2_DISPLAY_NAME}_modified
    Verify Accelerator Profile Values Via CLI   ${ACC2_DISPLAY_NAME}_modified   ${ACC_IDENTIFIER}_modified
    ...                                         ${ACC_DESCRIPTION2}_modified   tolerations=yes
    ...                                         tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                                         tol_effect=${ACC_TOLERATION_EFFECT}
    ...                                         tol_key=${ACC_TOLERATION_KEY}
    ...                                         tol_value=${ACC_TOLERATION_VALUE}
    ...                                         tol_seconds=${ACC_TOLERATION_SECONDS}

Delete Tolerations from an Accelerator Profile Using Accelerator Profiles Administration UI
    [Documentation]    Delete Tolerations from  an Accelerator Profile instance from the Administration UI and
    ...                verify it's content
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_NAME}3
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles From Settings
    Delete Accelerator Profile Tolerations    ${ACC3_DISPLAY_NAME}
    Accelerator Profile Should Be Displayed In The Grid   ${ACC3_DISPLAY_NAME}
    Verify Accelerator Profile Has No Tolerations Via CLI   ${ACC3_DISPLAY_NAME}

Disable an Accelerator Profile From The Accelerator Profile Edit View
    [Documentation]    Disable an An accelerator profile from the Edit Accelerator Profile view
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_NAME}4
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles From Settings
    Edit Accelerator Profile    original_display_name=${ACC4DISPLAY_NAME}    enabled=False
    Accelerator Profile Should Be Displayed In The Grid   ${ACC4_DISPLAY_NAME}
    Verify Accelerator Profile Values Via CLI   ${ACC4_DISPLAY_NAME}    enabled=False

Enable an Accelerator Profile From The Accelerator Profile Edit View
    [Documentation]    Enable an An accelerator profile from the Edit Accelerator Profile view
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_NAME}5
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles From Settings
    Edit Accelerator Profile    original_display_name=${ACC5_DISPLAY_NAME}    enabled=True
    Accelerator Profile Should Be Displayed In The Grid   ${ACC5_DISPLAY_NAME}
    Verify Accelerator Profile Values Via CLI   ${ACC5_DISPLAY_NAME}    enabled=True

Disable an Accelerator Profile From The Grid of the Accelerator Profile View
    [Documentation]    Disable an An accelerator profile from the Edit Accelerator Profile view
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_NAME}6
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles From Settings
    Search for accelerator profile in grid    ${ACC6_DISPLAY_NAME}
    Disable Accelerator Profile    ${ACC_NAME}6
    Verify Accelerator Profile Values Via CLI   ${ACC6_DISPLAY_NAME}    enabled=False

Enable an Accelerator Profile From The Grid of the Accelerator Profile View
    [Documentation]    Enable an An accelerator profile from the Accelerator Profile view
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_NAME}7
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles From Settings
    Search for accelerator profile in grid    ${ACC7_DISPLAY_NAME}
    Click On The Enable Switch From Accelerator Profile    ${ACC_NAME}7
    Verify Accelerator Profile Values Via CLI   ${ACC7_DISPLAY_NAME}    enabled=True

Delete an Accelerator Profile From The Grid of the Accelerator Profile View
    [Documentation]    Delete an An accelerator profile from the Accelerator Profile view
    [Tags]  RHOAIENG-3349
    ...     Sanity
    [Setup]  Run Keywords    Create An Accelerator Profile Via CLI    ${ACC_NAME}8
    ...    AND
    ...    Open Dashboard And Navigate to Accelerator Profiles From Settings
    Delete Accelerator Profile    ${ACC8_DISPLAY_NAME}
    Accelerator Profile Should Not Exist   ${ACC_NAME}8


*** Keywords ***
Teardown Settings Accelerator Profiles
    [Documentation]    Sets the default values In User Management Settings
    ...                and runs the RHOSi Teardown
    Run Keyword And Ignore Error    Delete All Accelerator Profiles Which Starts With   ${ACC_NAME}
    RHOSi Teardown

Open Dashboard And Navigate to Accelerator Profiles From Settings
    [Documentation]    Navigate as an Admin User to the Accelerator Profiles administration view
    ...                Used as a Test Setup
    Open ODS Dashboard With Admin User
    Navigate To Page    Settings    Accelerator profiles

Setup Settings Accelerator Profiles
    [Documentation]  Customized Steup for admin UI
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup

