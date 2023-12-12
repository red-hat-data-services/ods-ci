*** Settings ***
Resource        ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource        ../../Resources/ODS.robot
Suite Setup     Setup Admin UI
Suite Teardown  Teardown Admin UI


*** Test Cases ***
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
    [Tags]  ODS-1680
    ...     Tier1
    ...     Sanity
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Clear User Management Settings
    Add OpenShift Groups To Data Science Administrators    rhods-users
    Add OpenShift Groups To Data Science User Groups       rhods-users
    Save Changes In User Management Setting
    AdminGroups In OdhDashboardConfig CRD Should Be        rhods-users
    AllowedGroups In OdhDashboardConfig CRD Should Be      rhods-users
    Reload Page
    ${version_check}=    Is RHODS Version Greater Or Equal Than    1.20.0
    IF    ${version_check} == True
        ${status}=    Run Keyword And Return Status     Launch Jupyter From RHODS Dashboard Link
        Run Keyword And Continue On Failure    Should Be Equal    ${status}    ${FALSE}
        Run Keyword And Continue On Failure    Page Should Contain    Access permissions needed
        Run Keyword And Continue On Failure    Page Should Contain    ask your administrator to adjust your permissions.
    ELSE
        Menu.Navigate To Page    Applications    Enabled
        Launch Jupyter From RHODS Dashboard Link
        Run Keyword And Continue On Failure   Verify Jupyter Access Level   expected_result=none
    END
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
