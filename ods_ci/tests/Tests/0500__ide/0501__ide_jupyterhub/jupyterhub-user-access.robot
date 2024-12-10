*** Settings ***
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource         ../../../Resources/Page/OCPLogin/OCPLogin.robot
Resource         ../../../Resources/ODS.robot
Library          OperatingSystem
Library          DebugLibrary
Library          JupyterLibrary
Library          OpenShiftLibrary
Suite Setup      Special User Testing Suite Setup
Suite Teardown   Close All Browsers
Test Tags       JupyterHub


*** Variables ***
${AUTH_TYPE}=    ldap-provider-qe
${CUSTOM_ADMINS_GROUP}=   custom-admins-group
${CUSTOM_USERS_GROUP}=    custom-users-group
${STANDARD_ADMINS_GROUP}=  dedicated-admins
${STANDARD_USERS_GROUP}=   system:authenticated


*** Test Cases ***
Verify User Can Set Custom RHODS Groups
    [Documentation]    Tests the JH access level when using custom rhods groups
    ...                different from rhods-admins and rhods-users
    ...                Note: this test creates users/groups via `oc adm groups`
    ...                command. There is an another test that changes users/groups
    ...                via ODH Dashboard UI in `Settings -> User management` section, see:
    ...                `Verify Unauthorized User Is Not Able To Spawn Jupyter Notebook` in
    ...                tests/Tests/400__ods_dashboard/413__ods_dashboard_user_mgmt.robot
    [Tags]  Tier1
    ...     ODS-293    ODS-503
    [Setup]      Set Standard RHODS Groups Variables
    Create Custom Groups
    Add Test Users To Custom Groups
    Remove Test Users From RHODS Standard Groups
    Set Custom Access Groups
    Check New Access Configuration Works As Expected
    # add notebook spawning check
    [Teardown]   Restore Standard RHODS Groups Configuration


*** Keywords ***
Create Custom Group
    [Documentation]    Creates a custom group using oc cli command
    [Arguments]    ${group_name}
    ${group_created}=    Run Keyword And Return Status    Create Group    group_name=${group_name}
    IF    ${group_created} == False
          FAIL  Creation of ${group_name} group failed. Check the logs
    END

Create Custom Groups
    [Documentation]    Creates two user groups: custom-admins and customer-users
    Create Custom Group    group_name=${CUSTOM_ADMINS_GROUP}
    Create Custom Group    group_name=${CUSTOM_USERS_GROUP}
    OpenshiftLibrary.Oc Get    kind=Group   name=${CUSTOM_ADMINS_GROUP}
    OpenshiftLibrary.Oc Get    kind=Group   name=${CUSTOM_USERS_GROUP}

Delete Custom Groups
    [Documentation]    Deletes two user groups: custom-admins and customer-users
    Delete Group  group_name=${CUSTOM_ADMINS_GROUP}
    Delete Group  group_name=${CUSTOM_USERS_GROUP}
    Run Keyword And Expect Error    EQUALS:ResourceOperationFailed: Get failed\nReason: Not Found
    ...    OpenshiftLibrary.Oc Get    kind=Group   name=${CUSTOM_ADMINS_GROUP}
    Run Keyword And Expect Error    EQUALS:ResourceOperationFailed: Get failed\nReason: Not Found
    ...    OpenshiftLibrary.Oc Get    kind=Group   name=${CUSTOM_USERS_GROUP}

Add Test Users To Custom Groups
    [Documentation]    Adds two tests users to custom-admins and customer-users groups
    Add User To Group    username=${TEST_USER_2.USERNAME}    group_name=${CUSTOM_ADMINS_GROUP}
    Add User To Group    username=${TEST_USER_3.USERNAME}    group_name=${CUSTOM_USERS_GROUP}
    Check User Is In A Group    username=${TEST_USER_2.USERNAME}   group_name=${CUSTOM_ADMINS_GROUP}
    Check User Is In A Group    username=${TEST_USER_3.USERNAME}   group_name=${CUSTOM_USERS_GROUP}

Remove Test Users From RHODS Standard Groups
    [Documentation]    Removes two tests users from rhods-admins and rhods-users
    IF    ':' not in $STANDARD_ADMINS_GROUP
        Remove User From Group    username=${TEST_USER_2.USERNAME}    group_name=${STANDARD_ADMINS_GROUP}
        Check User Is Not In A Group    username=${TEST_USER_2.USERNAME}   group_name=${STANDARD_ADMINS_GROUP}
    END
    IF    ':' not in $STANDARD_USERS_GROUP
        Remove User From Group    username=${TEST_USER_3.USERNAME}    group_name=${STANDARD_USERS_GROUP}
        Check User Is Not In A Group    username=${TEST_USER_3.USERNAME}   group_name=${STANDARD_USERS_GROUP}
    END

Add Test Users Back To RHODS Standard Groups
    [Documentation]    Adds two tests users back to rhods-admins and rhods-users
    IF    ':' not in $STANDARD_ADMINS_GROUP
        Add User To Group    username=${TEST_USER_2.USERNAME}    group_name=${STANDARD_ADMINS_GROUP}
        Check User Is In A Group    username=${TEST_USER_2.USERNAME}   group_name=${STANDARD_ADMINS_GROUP}
    END
    IF    ':' not in $STANDARD_USERS_GROUP
        Add User To Group    username=${TEST_USER_3.USERNAME}    group_name=${STANDARD_USERS_GROUP}
        Check User Is In A Group    username=${TEST_USER_3.USERNAME}   group_name=${STANDARD_USERS_GROUP}
    END

Remove Test Users From Custom Groups
    [Documentation]    Removes two tests users from custom-admins and customer-users groups
    Remove User From Group    username=${TEST_USER_2.USERNAME}    group_name=${CUSTOM_ADMINS_GROUP}
    Remove User From Group    username=${TEST_USER_3.USERNAME}    group_name=${CUSTOM_USERS_GROUP}
    Check User Is Not In A Group    username=${TEST_USER_2.USERNAME}   group_name=${CUSTOM_ADMINS_GROUP}
    Check User Is Not In A Group    username=${TEST_USER_3.USERNAME}   group_name=${CUSTOM_USERS_GROUP}

Set Custom Access Groups
    [Documentation]    Set custom rhods groups to access JH
    Apply Access Groups Settings    admins_group=${CUSTOM_ADMINS_GROUP}
    ...     users_group=${CUSTOM_USERS_GROUP}

Check New Access Configuration Works As Expected
    [Documentation]    Checks if the new access configuration (using two custom groups)
    ...                works as expected in JH
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}    alias=${NONE}

    # Login with user that isn't part of any RHOAI group (neither admin nor user group)
    Login To RHODS Dashboard    ${TEST_USER_4.USERNAME}    ${TEST_USER_4.PASSWORD}    ${TEST_USER_4.AUTH_TYPE}
    Run Keyword And Continue On Failure
    ...    Wait Until Page Contains    text=Access permissions needed    timeout=30s
    Run Keyword And Continue On Failure
    ...    Wait Until Page Contains    text=ask your administrator to adjust your permissions.    timeout=30s
    Capture Page Screenshot    perm_denied_custom.png
    Logout From RHODS Dashboard

    # Login with user with admin permissions
    Login To RHODS Dashboard    ${TEST_USER_2.USERNAME}    ${TEST_USER_2.PASSWORD}    ${TEST_USER_2.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch Jupyter From RHODS Dashboard Link
    Run Keyword And Continue On Failure    Verify Jupyter Access Level    expected_result=admin
    Capture Page Screenshot    perm_admin_custom.png
    Logout From RHODS Dashboard

    # Login with user with user permissions
    Login To RHODS Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}
    # Note: we expect the Jupyter notebook spawner page because in previous step we logged out from this particular
    # page and since it is preserved in the URL, we will be navigated to that page after the login again.
    Wait For RHODS Dashboard To Load    expected_page=Start a notebook server    wait_for_cards=${FALSE}
    Run Keyword And Continue On Failure    Verify Jupyter Access Level    expected_result=user
    Capture Page Screenshot    perm_user_custom.png
    Logout From RHODS Dashboard

Check Standard Access Configuration Works As Expected
    [Documentation]    Checks if the standard access configuration
    ...                works as expected in JH
    Launch Dashboard   ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ...   ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    Launch Jupyter From RHODS Dashboard Link
    Run Keyword And Continue On Failure   Verify Jupyter Access Level  expected_result=admin
    Capture Page Screenshot    perm_admin_std.png
    Logout From RHODS Dashboard
    Login To RHODS Dashboard  ${TEST_USER_4.USERNAME}  ${TEST_USER_4.PASSWORD}  ${TEST_USER_4.AUTH_TYPE}
    Wait For RHODS Dashboard To Load    expected_page=Start a notebook server
    ...    wait_for_cards=${FALSE}
    Run Keyword And Continue On Failure   Verify Jupyter Access Level   expected_result=user
    Capture Page Screenshot    perm_user_std.png
    Logout From RHODS Dashboard

Restore Standard RHODS Groups Configuration
    [Documentation]    Restores the standard RHODS access configuration
    Set Default Access Groups Settings
    Add Test Users Back To RHODS Standard Groups
    Remove Test Users From Custom Groups
    Delete Custom Groups
    Check Standard Access Configuration Works As Expected
