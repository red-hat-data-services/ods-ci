*** Settings ***
Resource        ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHAdminUI.robot
Resource        ../../Resources/ODS.robot
Suite Setup     Set Library Search Order  SeleniumLibrary
Suite Teardown  Set Default Access Groups Settings

*** Test Cases ***
Verify if the CRD after applying changed In admin UI
    [Documentation]  Verify if the CRD after applying changed In admin UI
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

Verify If Unauthorisez User Can Not Change The Permission
    [Documentation]  Verify If Unauthorisez User Can Not Change The Permission
    ...  if Unauthorisez user has saved the changes should not refect In CRD
    [Tags]  ODS-1660
    ...     ODS-1555
    ...     Tier1
    ...     Sanity
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
    [Teardown]  Teardown For Admin UI   ${TEST_USER_3.USERNAME}   ${TEST_USER_3.PASSWORD}  ${TEST_USER_3.AUTH_TYPE}

Verify Unauthorisez User Is Not Able To Spawn Jupyter Notebook
    [Documentation]    Verify User Is Not Able To Spawn Jupyter Notebook
    [Tags]   ODS-1680
    ...     Tier1
    ...     Sanity
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Clear User Management Settings
    Add OpenShift groups To Data Science Administrators         rhods-admin
    Add OpenShift Groups To Data Science User Groups   rhods-admin
    Save Changes In User Management Setting
    Close Browser
    Launch Dashboard  ocp_user_name=${TEST_USER_3.USERNAME}  ocp_user_pw=${TEST_USER_3.PASSWORD}  ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    Menu.Navigate To Page    Applications    Enabled
    Wait Until Page Contains    Launch application
    Click Element               //*[@class="odh-card__footer__link"]
    Wait Until Page Contains    Page Not Found   timeout=15
    Page Should Contain         Page Not Found
    [Teardown]  Teardown For Admin UI   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}

Verify Automatically detects a group selected is removed and notify the user
    [Documentation]  Verify if the group is deleted the user should get the
     ...    message / notification
    [Tags]  ODS-1686
    ...     Tier1
    ...     Sanity
    Create Group  test
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Add OpenShift Groups To Data Science Administrators     test
    Save Changes In User Management Setting
    Delete Group  test
    Reload Page
    Wait Until Page Contains    Group no longer exist   timeout=20s

*** Keywords ***
Teardown For Admin UI
    [Documentation]  Setup Default Values In User Management Settings
    [Arguments]   ${username}  ${password}  ${auth_type}
    Launch Dashboard And Check User Management Option Is Available For The User  ${username}  ${password}  ${auth_type}
    Clear User Management Settings
    Add OpenShift groups to Data Science administrators         dedicated-admins
    Add OpenShift Groups To Data Science User Groups   system:authenticated
    Save Changes In User Management Setting
    Close All Browsers
