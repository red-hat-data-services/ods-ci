*** Settings ***
Documentation       Tests features in ODS Dashboard "Settings" section

Library             SeleniumLibrary
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/ODS.robot

Suite Setup         Dashboard Settings Suite Setup
Suite Teardown      RHOSi Teardown


*** Test Cases ***
Verify That Administrators Can Access "Cluster Settings"
    [Documentation]    Verifies users in the admin_groups (group "dedicated-admins" since RHODS 1.8.0)
    ...    can access to "Cluster Settings"
    [Tags]    Smoke
    ...       ODS-1216

    Open ODS Dashboard With Admin User
    Verify Cluster Settings Is Available
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
    Verify Cluster Settings Is Available
    Enable "Usage Data Collection"
    Capture Page Screenshot
    ODS.Usage Data Collection Should Be Enabled
    Disable "Usage Data Collection"
    Capture Page Screenshot
    ODS.Usage Data Collection Should Not Be Enabled
    [Teardown]    Restore Default Configuration For "Usage Data Collection" And TearDown


*** Keywords ***
Open ODS Dashboard With Admin User
    [Documentation]    Opens a browser and logs into ODS Dashboard with a user belonging to the rhods-admins group
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}

Open ODS Dashboard With Non Admin User
    [Documentation]    Opens a browser and logs into ODS Dashboard with a user belonging to the rhods-users group
    Launch Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}

Restore Default Configuration For "Usage Data Collection" And TearDown
    [Documentation]    Restores "Usage Data Collection" default configuration and runs test teardown
    Verify Cluster Settings Is Available
    Enable "Usage Data Collection"
    Capture Page Screenshot
    Dashboard Settings Test Teardown

Dashboard Settings Suite Setup
    [Documentation]    Suite setup
    Set Library Search Order    SeleniumWireLibrary    SeleniumLibrary
    RHOSi Setup

Dashboard Settings Test Teardown
    [Documentation]    Test teardown
    Close All Browsers
