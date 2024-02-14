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
    [Tags]  ODS-WIP
    ...     Smoke
    Open ODS Dashboard With Admin User
    Navigate To Page    Settings    Accelerator profiles
    Click On Create Accelerator profile button
    Create An Accelerator Profile via UI   ${ACC_DISPLAY_NAME}01   ${ACC_IDENTIFIER}
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


Verify RHODS Accept Multiple Admin Groups And CRD Gets Updates
    [Documentation]    Verify that users can set multiple admin groups and
    ...                check OdhDashboardConfig CRD gets updated according to Admin UI
    [Tags]  ODS-1661    ODS-1555
    ...     Tier1
    ...     Sanity
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Clear User Management Settings
    Add OpenShift Groups To Data Science Administrators   rhods-admins  rhods-users
    Add OpenShift Groups To Data Science User Groups    system:authenticated
    Save Changes In User Management Setting
    AdminGroups In OdhDashboardConfig CRD Should Be     rhods-admins  rhods-users
    AllowedGroups In OdhDashboardConfig CRD Should Be   system:authenticated
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER_3.USERNAME}   ${TEST_USER_3.PASSWORD}  ${TEST_USER_3.AUTH_TYPE}


Verify If Unauthorized User Can Not Change The Permission
    [Documentation]  Verify If Unauthorized User Can Not Change the Permission even if the UI is visible in browser cache,
    ...    if the unauthorized user has saved, the changes should not reflect In CRD file
    ...    Product Bug:    RHODS-6282
    [Tags]  ODS-1660
    ...     Tier1
    ...     Sanity
    ...     ProductBug
    Launch Dashboard And Check User Management Option Is Available For The User
    ...    ${TEST_USER_3.USERNAME}   ${TEST_USER_3.PASSWORD}  ${TEST_USER_3.AUTH_TYPE}
    Remove OpenShift Groups From Data Science Administrator Groups     rhods-admins
    Save Changes In User Management Setting
    Switch Browser  1
    Add OpenShift Groups To Data Science Administrators    rhods-noaccess
    Add OpenShift Groups To Data Science User Groups       rhods-noaccess
    AdminGroups In OdhDashboardConfig CRD Should Be        rhods-users
    AllowedGroups In OdhDashboardConfig CRD Should Be      system:authenticated
    Save Changes In User Management Setting
    Page Should Contain  Unable to load user and group settings
    Switch Browser  2
    [Teardown]  Revert Changes To Access Configuration

Verify Unauthorized User Is Not Able To Spawn Jupyter Notebook
    [Documentation]    Verify unauthorized User Is Not Able To Spawn Jupyter
    ...     Notebook , user should not see a spawner if the user is not in allowed Groups
    ...     Note: this test configures user access via ODH Dashboard UI in setting appropriate
    ...     groups in `Settings -> User management` section. There is an another test that changes
    ...     users/groups via `oc adm groups` command,see: `Verify User Can Set Custom RHODS Groups`
    ...     in ods_ci/tests/Tests/500__jupyterhub/jupyterhub-user-access.robot
    [Tags]  ODS-1680
    ...     Tier1
    ...     Sanity
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Clear User Management Settings
    Add OpenShift Groups To Data Science Administrators    rhods-admins
    Add OpenShift Groups To Data Science User Groups       rhods-admins
    Save Changes In User Management Setting
    AdminGroups In OdhDashboardConfig CRD Should Be        rhods-admins
    AllowedGroups In OdhDashboardConfig CRD Should Be      rhods-admins
    Logout From RHODS Dashboard
    Login To RHODS Dashboard    ${TEST_USER_4.USERNAME}    ${TEST_USER_4.PASSWORD}    ${TEST_USER_4.AUTH_TYPE}
    Wait for RHODS Dashboard to Load    expected_page=${NONE}    wait_for_cards=${FALSE}
    Run Keyword And Continue On Failure    Page Should Contain    Access permissions needed
    Run Keyword And Continue On Failure    Page Should Contain    ask your administrator to adjust your permissions.
    # Let's check that we're not allowed to also access the spawner page directly navigating the browser there
    Go To    ${ODH_DASHBOARD_URL}/notebookController/spawner
    Wait for RHODS Dashboard to Load    expected_page=${NONE}    wait_for_cards=${FALSE}
    Run Keyword And Continue On Failure    Page Should Contain    Access permissions needed
    Run Keyword And Continue On Failure    Page Should Contain    ask your administrator to adjust your permissions.
    [Teardown]  Revert Changes To Access Configuration

Verify Automatically Detects a Group Selected Is Removed and Notify the User
    [Documentation]  Verify if the group is deleted the user should get the
    ...    message / notification
    [Tags]  ODS-1686
    ...     Tier1
    ...     Sanity
    ${new_group_name}=    Set Variable    new-group-test
    Create Group  ${new_group_name}
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Add OpenShift Groups To Data Science Administrators     ${new_group_name}
    Save Changes In User Management Setting
    Delete Group    ${new_group_name}
    Reload Page
    Wait Until Page Contains    Group error   timeout=20s
    Wait Until Page Contains    The group ${new_group_name} no longer exists   timeout=20s


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
