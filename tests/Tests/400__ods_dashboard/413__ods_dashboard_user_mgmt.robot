*** Settings ***
Resource        ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHAdminUI.robot
Resource        ../../Resources/ODS.robot
Suite Setup     Setup Admin UI
Suite Teardown  Teardown Admin UI


*** Test Cases ***
Verify The CRD Gets Updated After Applying Changes In Admin UI
    [Documentation]  Verify The CRD Gets Updated After Applying Changes In Admin UI
    [Tags]  ODS-1661
    ...     Tier1
    ...     Sanity
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Clear User Management Settings
    Add OpenShift Groups To Data Science Administrators   rhods-admins  rhods-users
    Add OpenShift Groups To Data Science User Groups    system:authenticated
    Save Changes In User Management Setting
    AdminGroups In OdhDashboardConfig CRD Should Be     rhods-admins  rhods-users
    AllowedGroups In OdhDashboardConfig CRD Should Be   system:authenticated

Verify If Unauthorized User Can Not Change The Permission
    [Documentation]  Verify If Unauthorized User Can Not Change the Permission even if the UI is visible in browser cache,
     ...    if the unauthorized user has saved, the changes should not reflect In CRD file
    [Tags]  ODS-1660
    ...     ODS-1555
    ...     Tier1
    ...     Sanity
    ...     AutomationBug
    Launch Dashboard And Check User Management Option Is Available For The User     ${TEST_USER_3.USERNAME}   ${TEST_USER_3.PASSWORD}  ${TEST_USER_3.AUTH_TYPE}
    Remove OpenShift Groups From Data Science Administrator Groups     rhods-admins
    Save Changes In User Management Setting
    Switch Browser  1
    Add OpenShift Groups To Data Science Administrators    rhods-noaccess
    Add OpenShift Groups To Data Science User Groups       rhods-noaccess
    AdminGroups In OdhDashboardConfig CRD Should Be        rhods-users
    AllowedGroups In OdhDashboardConfig CRD Should Be      system:authenticated
    Save Changes In User Management Setting
    Page Should Contain  Unable to load User and group settings
    Switch Browser  2
    [Teardown]  Teardown Admin UI

Verify Unauthorized User Is Not Able To Spawn Jupyter Notebook
    [Documentation]    Verify unauthorized User Is Not Able To Spawn Jupyter
    ...     Notebook , user should not see a spawner if the user is not in allowed Groups
    [Tags]  ODS-1680
    ...     Tier1
    ...     Sanity
    ...     AutomationBug
    Skip If RHODS Is Self-Managed    msg=Test skiped on Self-Managed due to disruptive automation error to be fixed
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Clear User Management Settings
    Add OpenShift Groups To Data Science Administrators    rhods-users
    Add OpenShift Groups To Data Science User Groups       rhods-users
    Save Changes In User Management Setting
    AdminGroups In OdhDashboardConfig CRD Should Be        rhods-users
    AllowedGroups In OdhDashboardConfig CRD Should Be      rhods-users
    Reload Page
    Menu.Navigate To Page    Applications    Enabled
    Run Keyword And Expect Error  *  Launch Jupyter From RHODS Dashboard Link
    Wait Until Page Contains    Page Not Found   timeout=15s
    [Teardown]  Teardown Admin UI

Verify Automatically Detects a Group Selected Is Removed and Notify the User
    [Documentation]  Verify if the group is deleted the user should get the
    ...    message / notification
    [Tags]  ODS-1686
    ...     Tier1
    ...     Sanity
    ...     AutomationBug
    Create Group  new-group-test
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Add OpenShift Groups To Data Science Administrators     new-group-test
    Save Changes In User Management Setting
    Delete Group  new-group-test
    Reload Page
    Wait Until Page Contains    Group no longer exist   timeout=20s


*** Keywords ***
Teardown Admin UI
    [Documentation]  Setup Default Values In User Management Settings
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings

Setup Admin UI
    [Documentation]  Customized Steup for admin UI
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings
