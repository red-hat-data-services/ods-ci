*** Settings ***
Documentation       Tests features in ODS Dashboard "Settings" section

Library             SeleniumLibrary
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource            ../../../Resources/ODS.robot

Suite Setup         Dashboard Settings Suite Setup


*** Test Cases ***
Verify That Administrators Can Access "Cluster Settings"
    [Documentation]    Verifies users in the admin_groups (group "dedicated-admins" since RHODS 1.8.0)
    ...    can access to "Cluster Settings"
    [Tags]    Tier1
    ...       Sanity
    ...       ODS-1216

    Open ODS Dashboard With Admin User

    ${version_check} =    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check}==True
        Verify Cluster Settings Is Available
    ELSE
        Skip    msg=Cluster settings was introduced in RHODS 1.8.0
    END
    [Teardown]    Dashboard Settings Test Teardown

Verify That Not Admin Users Can Not Access "Cluster Settings"
    [Documentation]    Verifies users not in the admin_groups (group "dedicated-admins" since RHODS 1.8.0)
    ...    can not access to "Cluster Settings"
    [Tags]    Tier1
    ...       Sanity
    ...       ODS-1217

    Open ODS Dashboard With Non Admin User
    Capture Page Screenshot
    Verify Cluster Settings Is Not Available
    [Teardown]    Dashboard Settings Test Teardown

Verify That "Usage Data Collection" Can Be Set In "Cluster Settings"
    [Documentation]    Verifies that a user can set the "Usage Data Collection" flag in "Cluster Settings"
    [Tags]    Tier1
    ...       Sanity
    ...       ODS-1218
    Open ODS Dashboard With Admin User
    ${version_check} =    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check}==True
        Verify Cluster Settings Is Available
        ODHDashboard.Enable "Usage Data Collection"
        Capture Page Screenshot
        ODS.Usage Data Collection Should Be Enabled
        ODHDashboard.Disable "Usage Data Collection"
        Capture Page Screenshot
        ODS.Usage Data Collection Should Not Be Enabled
    ELSE
        Skip    msg=Cluster settings was introduced in RHODS 1.8.0
    END
    [Teardown]    Restore Default Configuration For "Usage Data Collection" And TearDown


*** Keywords ***
Open ODS Dashboard With Admin User
    [Documentation]    Opens a browser and logs into ODS Dashboard with a user belonging to the rhods-admins group
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load

Open ODS Dashboard With Non Admin User
    [Documentation]    Opens a browser and logs into ODS Dashboard with a user belonging to the rhods-users group
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}
    Wait For RHODS Dashboard To Load

Restore Default Configuration For "Usage Data Collection" And TearDown
    [Documentation]    Restores "Usage Data Collection" default configuration and runs test teardown
    ${version_check} =    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check}==True
        Verify Cluster Settings Is Available
        ODHDashboard.Enable "Usage Data Collection"
        Capture Page Screenshot
    END
    Dashboard Settings Test Teardown

Dashboard Settings Suite Setup
    [Documentation]    Suite setup
    Set Library Search Order    SeleniumWireLibrary    SeleniumLibrary

Dashboard Settings Test Teardown
    [Documentation]    Test teardown
    Close All Browsers
