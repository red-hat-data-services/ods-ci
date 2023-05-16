*** Settings ***
Documentation      Suite to test additional scenarios for Data Science Projects (a.k.a DSG) feature
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Permissions.resource
Suite Setup        Project Permissions Mgmt Suite Setup
Suite Teardown     Project Permissions Mgmt Suite Teardown


*** Variables ***
${PRJ_BASE_TITLE}=   ODS-CI DS Project
${PRJ_A_TITLE}=   ${PRJ_BASE_TITLE}-${TEST_USER_3.USERNAME}
${PRJ_DESCRIPTION}=   ${PRJ_BASE_TITLE} is a test project for validating DS Project Sharing feature
${WORKBENCH_DESCRIPTION}=   a test workbench to check project sharing
${NB_IMAGE}=        Minimal Python
${PV_NAME}=         ods-ci-project-sharing
${PV_DESCRIPTION}=         it is a PV created to test DS Projects Sharing feature
${PV_SIZE}=         1


*** Test Cases ***
Verify User Can Access Permission Tab In Their Owned DS Project
    [Documentation]    Verify user has access to "Permissions" tab in their DS Projects
    [Tags]    Tier1    Smoke
    ...       ODS-2194
    Pass Execution    The Test is executed as part of Suite Setup

Verify User Can Make Their Owned DS Project Accessible To Other Users
    [Documentation]    Verify user can give access permissions for their DS Projects to other users
    [Tags]    Tier1    Smoke
    ...       ODS-2201
    Switch To User    ${TEST_USER_3.USERNAME}
    Move To Tab    Permissions
    Assign Edit Permissions To ${TEST_USER_4.USERNAME}
    Assign Admin Permissions To ${TEST_USER_2.USERNAME}
    Switch To User    ${TEST_USER_4.USERNAME}
    Open Data Science Project Details Page    ${PRJ_A_TITLE}
    Permissions Tab Should Not Be Accessible
    Capture Page Screenshot
    Switch To User    ${TEST_USER_2.USERNAME}
    Open Data Science Project Details Page    ${PRJ_A_TITLE}
    Permissions Tab Should Be Accessible
    Capture Page Screenshot

Verify User Can Modify And Revoke Access To DS Projects From Other Users    # robocop: disable
    [Documentation]    Verify user can modify/remove access permissions for their DS Projects to other users
    [Tags]    Tier1    Sanity
    ...       ODS-2202
    Switch To User    ${TEST_USER_3.USERNAME}
    Move To Tab    Permissions
    Change ${TEST_USER_4.USERNAME} Permissions To Admin
    Change ${TEST_USER_2.USERNAME} Permissions To Edit
    Switch To User    ${TEST_USER_4.USERNAME}
    Open Data Science Project Details Page    ${PRJ_A_TITLE}
    Permissions Tab Should Be Accessible
    Components Tab Should Be Accessible
    RoleBinding Should Exist    project_title=${PRJ_A_TITLE}
    ...    subject_name=${TEST_USER_4.USERNAME}
    Switch To User    ${TEST_USER_2.USERNAME}
    Open Data Science Project Details Page    ${PRJ_A_TITLE}
    Permissions Tab Should Not Be Accessible
    RoleBinding Should Exist    project_title=${PRJ_A_TITLE}
    ...    subject_name=${TEST_USER_2.USERNAME}
    Switch To User    ${TEST_USER_3.USERNAME}
    Remove ${TEST_USER_4.USERNAME} Permissions
    Switch To User    ${TEST_USER_4.USERNAME}
    Reload RHODS Dashboard Page    expected_page=Data science projects
    ...    wait_for_cards=${FALSE}
    Open Data Science Projects Home Page
    Project Should Not Be Listed    project_title=${PRJ_A_TITLE}
    RoleBinding Should Not Exist    project_title=${PRJ_A_TITLE}
    ...    subject_name=${TEST_USER_4.USERNAME}


*** Keywords ***
Project Permissions Mgmt Suite Setup    # robocop: disable
    [Documentation]    Suite setup steps for testing DS Projects.
    ...                It creates some test variables and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_A_TITLE}
    ...    ${PRJ_BASE_TITLE}-${TEST_USER_4.USERNAME}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup
    Remove User From Group    username=${TEST_USER_2.USERNAME}
    ...    group_name=dedicated-admins
    Remove User From Group    username=${TEST_USER_2.USERNAME}
    ...    group_name=rhods-admins
    Add User To Group    username=${TEST_USER_2.USERNAME}
    ...    group_name=rhods-users
    Launch Dashboard    ocp_user_name=${TEST_USER_2.USERNAME}  ocp_user_pw=${TEST_USER_2.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_2.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    ...    browser_alias=${TEST_USER_2.USERNAME}-session
    Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}
    ...    browser_alias=${TEST_USER_3.USERNAME}-session
    Create Data Science Project    title=${PRJ_A_TITLE}
    ...    description=${PRJ_DESCRIPTION}
    Permissions Tab Should Be Accessible
    Components Tab Should Be Accessible
    Launch Data Science Project Main Page    username=${TEST_USER_4.USERNAME}
    ...    password=${TEST_USER_4.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_4.AUTH_TYPE}
    ...    browser_alias=${TEST_USER_4.USERNAME}-session
    Create Data Science Project    title=${PRJ_BASE_TITLE}-${TEST_USER_4.USERNAME}
    ...    description=${PRJ_DESCRIPTION}
    Permissions Tab Should Be Accessible
    Components Tab Should Be Accessible

Project Permissions Mgmt Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown
    Remove User From Group    username=${TEST_USER_2.USERNAME}
    ...    group_name=rhods-users
    Add User To Group    username=${TEST_USER_2.USERNAME}
    ...    group_name=dedicated-admins
    Add User To Group    username=${TEST_USER_2.USERNAME}
    ...    group_name=rhods-admins

Switch To User
    [Documentation]    Move from one browser window to another. Every browser window
    ...    is a user login session in RHODS Dashboard
    [Arguments]    ${username}
    Switch Browser    ${username}-session
