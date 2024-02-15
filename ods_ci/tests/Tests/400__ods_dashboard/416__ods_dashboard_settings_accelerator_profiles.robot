*** Settings ***
Resource        ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource        ../../Resources/ODS.robot
Suite Setup     Setup Settings Accelerator Profiles
Suite Teardown  Teardown Settings Accelerator Profiles


*** Variables ***
${ACC_DISPLAY_NAME}=    qe_create_ap_
${ACC_NAME}=    qecreateap
${ACC_IDENTIFIER}=    nvidia.com/gpu
${ACC_DESCRIPTION}=    description example
${ACC_ENABLED}=    True
${ACC_TOLERATION_OPERATOR}=    Exists
${ACC_TOLERATION_EFFECT}=    PreferNoSchedule
${ACC_TOLERATION_KEY}=    my_key
${ACC_TOLERATION_VALUE}=    my_value
${ACC_TOLERATION_SECONDS}=    15



*** Test Cases ***

Verify RHODS "Accelerator Profiles" Administration UI is available for Admin users
    [Documentation]    Verify users in the admin_groups (group "dedicated-admins" since RHODS 1.8.0)
    ...                can access to the Accelerator Profiles Administration UI
    [Tags]  ODS-WIP-BORRAR
    ...     Smoke
    Open ODS Dashboard With Admin User
    Verify Cluster Settings Is Available


Create An Accelerator Profile From "Accelerator Profiles" Administration UI
    [Documentation]    Create an Accelerator Profile instance from the Administration UI and verify it's content
    [Tags]  ODS-WIP-BORRAR
    ...     Smoke
    Open ODS Dashboard With Admin User
    Navigate To Page    Settings    Accelerator profiles
    Click On Create Accelerator profile button
    Create An Accelerator Profile Via UI   ${ACC_DISPLAY_NAME}01   ${ACC_IDENTIFIER}
    ...                                    ${ACC_DESCRIPTION}   ${ACC_ENABLED}    tolerations=yes
    ...                                    tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                                    tol_effect=${ACC_TOLERATION_EFFECT}
    ...                                    tol_key=${ACC_TOLERATION_KEY}
    ...                                    tol_value=${ACC_TOLERATION_VALUE}
    ...                                    tol_seconds=${ACC_TOLERATION_SECONDS}
    In The Accelerator Profiles Grid There Is An Accelerator Profile With Name   ${ACC_DISPLAY_NAME}01
    Verify Accelerator Profile Values via CLI   ${ACC_DISPLAY_NAME}01   ${ACC_IDENTIFIER}
    ...                                         ${ACC_DESCRIPTION}   ${ACC_ENABLED}    tolerations=yes
    ...                                         tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                                         tol_effect=${ACC_TOLERATION_EFFECT}
    ...                                         tol_key=${ACC_TOLERATION_KEY}
    ...                                         tol_value=${ACC_TOLERATION_VALUE}
    ...                                         tol_seconds=${ACC_TOLERATION_SECONDS}


Modify A Previously Created Accelerator Profile Using "Accelerator Profiles" Administration UI
    [Documentation]    Create an Accelerator Profile instance from the Administration UI and verify it's content
    [Tags]  ODS-WIP
    ...     Smoke
    [Setup]  Create An Accelerator Profile Via CLI    ${ACC_DISPLAY_NAME}2
    Open ODS Dashboard With Admin User
    Navigate To Page    Settings    Accelerator profiles
    Click On Edit Accelerator profile    ${ACC_DISPLAY_NAME}2
    Modify The Accelerator Profile    original_display_name=${ACC_DISPLAY_NAME}2
    ...                               display_name=${ACC_DISPLAY_NAME}2_modified
    ...                               identifier=${ACC_IDENTIFIER}_modified
    ...                               description=${ACC_DESCRIPTION}_modified    tolerations=yes
    ...                               tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                               tol_effect=${ACC_TOLERATION_EFFECT}
    ...                               tol_key=${ACC_TOLERATION_KEY}
    ...                               tol_value=${ACC_TOLERATION_VALUE}
    ...                               tol_seconds=${ACC_TOLERATION_SECONDS}
    In The Accelerator Profiles Grid There Is An Accelerator Profile With Name   ${ACC_DISPLAY_NAME}2_modified
    Verify Accelerator Profile Values via CLI   ${ACC_DISPLAY_NAME}2_modified   ${ACC_IDENTIFIER}_modified
    ...                                         ${ACC_DESCRIPTION}_modified   tolerations=yes
    ...                                         tol_operator=${ACC_TOLERATION_OPERATOR}
    ...                                         tol_effect=${ACC_TOLERATION_EFFECT}
    ...                                         tol_key=${ACC_TOLERATION_KEY}
    ...                                         tol_value=${ACC_TOLERATION_VALUE}
    ...                                         tol_seconds=${ACC_TOLERATION_SECONDS}

#TODO: Disable tolerations, disable  accelerator, shcedule forever, delete accelerator
*** Keywords ***
Teardown Settings Accelerator Profiles
    [Documentation]    Sets the default values In User Management Settings
    ...                and runs the RHOSi Teardown
#    Revert Changes To Access Configuration
    Dashboard Settings Accelerator Profiles Test Teardown
    RHOSi Teardown

#Revert Changes To Access Configuration
#    [Documentation]  Sets the default values In User Management Settings
#    Set Standard RHODS Groups Variables
#    Set Default Access Groups Settings

Setup Settings Accelerator Profiles
    [Documentation]  Customized Steup for admin UI
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup
#    Set Standard RHODS Groups Variables
#    Set Default Access Groups Settings

Dashboard Settings Accelerator Profiles Test Teardown
    [Documentation]    Test teardown
    Delete All Accelerator Profiles Which Starts With   ${ACC_NAME}
