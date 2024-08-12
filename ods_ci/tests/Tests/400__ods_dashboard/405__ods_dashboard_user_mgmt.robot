*** Settings ***
Resource        ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource        ../../Resources/ODS.robot
Suite Setup     Setup Admin UI
Suite Teardown  Teardown Admin UI
Test Setup      Revert Changes To Access Configuration
Test Teardown   Close All Browsers
Test Tags       Dashboard


*** Test Cases ***
Verify RHODS Accept Multiple Admin Groups And CRD Gets Updates
    [Documentation]    Verify that users can set multiple admin groups and
    ...                check OdhDashboardConfig CRD gets updated according to Admin UI
    [Tags]  ODS-1661    ODS-1555
    ...     Tier1
    # Login with RHOAI regular user (Settings should not be avaiable)
    Launch Dashboard And Check User Management Option Is Available For The User   
    ...  ${TEST_USER_3.USERNAME}  ${TEST_USER_3.PASSWORD}  ${TEST_USER_3.AUTH_TYPE}  settings_should_be=${FALSE}
    # Login with RHOAI Admin user (Settings should be avaiable)
    Launch Dashboard And Check User Management Option Is Available For The User
    ...  ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Clear User Management Settings
    Add OpenShift Groups To Data Science Administrators   rhods-admins  rhods-users
    Add OpenShift Groups To Data Science User Groups    system:authenticated
    Save Changes In User Management Setting
    AdminGroups In OdhDashboardConfig CRD Should Be     rhods-admins  rhods-users
    AllowedGroups In OdhDashboardConfig CRD Should Be   system:authenticated
    Launch Dashboard And Check User Management Option Is Available For The User
    ...  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}

Verify If Unauthorized User Can Not Change The Permission
    [Documentation]  Verify If Unauthorized User Can Not Change the Permission even if the UI is visible in browser cache,
    ...    if the unauthorized user has saved, the changes should not reflect In CRD file.
    ...    ProductBug: RHOAIENG-11116
    [Tags]  ODS-1660
    ...     Tier1
    ...     Sanity
    # Login with an RHOAI Admin user and add RHOAI permissions to non-admin user (TEST_USER_3)
    Launch Dashboard And Check User Management Option Is Available For The User
    ...  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Add OpenShift Groups To Data Science Administrators    rhods-users
    Add OpenShift Groups To Data Science User Groups       rhods-noaccess
    Save Changes In User Management Setting
    AdminGroups In OdhDashboardConfig CRD Should Be    rhods-admins    rhods-users
    AllowedGroups In OdhDashboardConfig CRD Should Be      system:authenticated    rhods-noaccess
    @{admin_session} =  Get Browser Ids
    # Login with TEST_USER_3 and verify new permissions
    Launch Dashboard And Check User Management Option Is Available For The User
    ...  ${TEST_USER_3.USERNAME}  ${TEST_USER_3.PASSWORD}  ${TEST_USER_3.AUTH_TYPE}
    @{non_admin_session} =  Get Browser Ids
    # Switch back to RHOAI Admin session, and remove TEST_USER_3 permissions
    Switch Browser  ${admin_session}[0]
    Menu.Navigate To Page    Settings    User management
    Remove OpenShift Groups From Data Science Administrator Groups     rhods-users
    Save Changes In User Management Setting
    AdminGroups In OdhDashboardConfig CRD Should Be    rhods-admins
    Close Browser
    # Switch to TEST_USER_3 session and verify permissions removed (Settings page not accessible)
    Switch Browser  ${non_admin_session}[1]
    Settings Page Should Be Unavailable    2m    # 2 minutes duration is a workaround for bug RHOAIENG-11116
    [Teardown]    Capture Page Screenshot

Verify Unauthorized User Is Not Able To Spawn Jupyter Notebook
    [Documentation]    Verify unauthorized User Is Not Able To Spawn Jupyter
    ...     Notebook , user should not see a spawner if the user is not in allowed Groups
    ...     Note: this test configures user access via ODH Dashboard UI in setting appropriate
    ...     groups in `Settings -> User management` section. There is an another test that changes
    ...     users/groups via `oc adm groups` command,see: `Verify User Can Set Custom RHODS Groups`
    ...     in tests/Tests/500__jupyterhub/jupyterhub-user-access.robot
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
    Run Keyword And Ignore Error
    ...    Login To RHODS Dashboard    ${TEST_USER_4.USERNAME}    ${TEST_USER_4.PASSWORD}    ${TEST_USER_4.AUTH_TYPE}
    Wait For RHODS Dashboard To Load    expected_page=${NONE}    wait_for_cards=${FALSE}
    Run Keyword And Continue On Failure    Page Should Contain    Access permissions needed
    Run Keyword And Continue On Failure    Page Should Contain    ask your administrator to adjust your permissions.
    # Let's check that we're not allowed to also access the spawner page directly navigating the browser there
    Go To    ${ODH_DASHBOARD_URL}/notebookController/spawner
    Wait For RHODS Dashboard To Load    expected_page=${NONE}    wait_for_cards=${FALSE}
    Run Keyword And Continue On Failure    Page Should Contain    Access permissions needed
    Run Keyword And Continue On Failure    Page Should Contain    ask your administrator to adjust your permissions.

Verify Automatically Detects a Group Selected Is Removed and Notify the User
    [Documentation]  Verify if the group is deleted the user should get the
    ...    message / notification
    [Tags]  ODS-1686
    ...     Tier1
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
Teardown Admin UI
    [Documentation]    Sets the default values In User Management Settings
    ...                and runs the RHOSi Teardown
    Revert Changes To Access Configuration
    RHOSi Teardown

Revert Changes To Access Configuration
    [Documentation]  Sets the default values In User Management Settings
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings

Setup Admin UI
    [Documentation]  Customized Steup for admin UI
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings
