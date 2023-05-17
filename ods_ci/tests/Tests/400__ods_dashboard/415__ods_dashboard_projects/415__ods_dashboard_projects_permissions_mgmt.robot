*** Settings ***
Documentation      Suite to test additional scenarios for Data Science Projects (a.k.a DSG) feature
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Permissions.resource
Suite Setup        Project Permissions Mgmt Suite Setup
Suite Teardown     Project Permissions Mgmt Suite Teardown


*** Variables ***
${PRJ_BASE_TITLE}=   ODS-CI DS Project
${PRJ_DESCRIPTION}=   ${PRJ_BASE_TITLE} is a test project for validating DS Project Sharing feature
${WORKBENCH_DESCRIPTION}=   a test workbench to check project sharing
${NB_IMAGE}=        Minimal Python
${PV_NAME}=         ods-ci-project-sharing
${PV_DESCRIPTION}=         it is a PV created to test DS Projects Sharing feature
${PV_SIZE}=         1
${USER_GROUP_1}=    ds-group-1
${USER_GROUP_2}=    ds-group-2

*** Test Cases ***
Verify User Can Access Permission Tab In Their Owned DS Project
    [Documentation]    Verify user has access to "Permissions" tab in their DS Projects
    [Tags]    Tier1    Smoke
    ...       ODS-2194
    Pass Execution    The Test is executed as part of Suite Setup

Verify User Can Make Their Owned DS Project Accessible To Other Users    # robocop: disable
    [Documentation]    Verify user can give access permissions for their DS Projects to other users
    [Tags]    Tier1    Smoke
    ...       ODS-2201
    Switch To User    ${USER_B}
    Move To Tab    Permissions
    Assign Edit Permissions To ${USER_C}
    Assign Admin Permissions To ${USER_A}
    Switch To User    ${USER_C}
    Open Data Science Project Details Page    ${PRJ_USER_B_TITLE}
    Permissions Tab Should Not Be Accessible
    Capture Page Screenshot
    Switch To User    ${USER_A}
    Open Data Science Project Details Page    ${PRJ_USER_B_TITLE}
    Permissions Tab Should Be Accessible
    Capture Page Screenshot

Verify User Can Modify And Revoke Access To DS Projects From Other Users    # robocop: disable
    [Documentation]    Verify user can modify/remove access permissions for their DS Projects to other users
    [Tags]    Tier1    Sanity
    ...       ODS-2202
    Switch To User    ${USER_B}
    Move To Tab    Permissions
    Change ${USER_C} Permissions To Admin
    Change ${USER_A} Permissions To Edit
    Switch To User    ${USER_C}
    Open Data Science Project Details Page    ${PRJ_USER_B_TITLE}
    Permissions Tab Should Be Accessible
    Components Tab Should Be Accessible
    RoleBinding Should Exist    project_title=${PRJ_USER_B_TITLE}
    ...    subject_name=${USER_C}
    Switch To User    ${USER_A}
    Open Data Science Project Details Page    ${PRJ_USER_B_TITLE}
    Permissions Tab Should Not Be Accessible
    RoleBinding Should Exist    project_title=${PRJ_USER_B_TITLE}
    ...    subject_name=${USER_A}
    Switch To User    ${USER_B}
    Remove ${USER_C} Permissions
    Switch To User    ${USER_C}
    Open Data Science Projects Home Page
    Reload RHODS Dashboard Page    expected_page=Data science projects
    ...    wait_for_cards=${FALSE}
    Project Should Not Be Listed    project_title=${PRJ_USER_B_TITLE}
    RoleBinding Should Not Exist    project_title=${PRJ_USER_B_TITLE}
    ...    subject_name=${USER_C}


*** Keywords ***
Project Permissions Mgmt Suite Setup    # robocop: disable
    [Documentation]    Suite setup steps for testing DS Projects.
    ...                It creates some test variables and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch RHODS Dashboard Session With User A
    Launch RHODS Dashboard Session And Create A DS Project With User B
    Launch RHODS Dashboard Session With User C
    ${to_delete}=    Create List    ${PRJ_USER_B_TITLE}
    ...    ${PRJ_USER_C_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}

Project Permissions Mgmt Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown
    Remove User From Group    username=${USER_A}
    ...    group_name=rhods-users
    Add User To Group    username=${USER_A}
    ...    group_name=dedicated-admins
    Add User To Group    username=${USER_A}
    ...    group_name=rhods-admins

Switch To User
    [Documentation]    Move from one browser window to another. Every browser window
    ...    is a user login session in RHODS Dashboard
    [Arguments]    ${username}
    Switch Browser    ${username}-session

Launch RHODS Dashboard Session With User A
    Launch Dashboard    ocp_user_name=${TEST_USER_2.USERNAME}  ocp_user_pw=${TEST_USER_2.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_2.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    ...    browser_alias=${TEST_USER_2.USERNAME}-session
    Set Suite Variable    ${USER_A}    ${TEST_USER_2.USERNAME}

Launch RHODS Dashboard Session And Create A DS Project With User B
    ${PRJ_USER_B_TITLE}=    Set Variable   ${PRJ_BASE_TITLE}-${TEST_USER_3.USERNAME}
    Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}
    ...    browser_alias=${TEST_USER_3.USERNAME}-session
    Create Data Science Project    title=${PRJ_USER_B_TITLE}
    ...    description=${PRJ_DESCRIPTION}
    Permissions Tab Should Be Accessible
    Components Tab Should Be Accessible
    Set Suite Variable    ${USER_B}    ${TEST_USER_3.USERNAME}
    Set Suite Variable    ${PRJ_USER_B_TITLE}    ${PRJ_USER_B_TITLE}

Launch RHODS Dashboard Session With User C
    ${PRJ_USER_C_TITLE}=    Set Variable   ${PRJ_BASE_TITLE}-${TEST_USER_4.USERNAME}
    Launch Data Science Project Main Page    username=${TEST_USER_4.USERNAME}
    ...    password=${TEST_USER_4.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_4.AUTH_TYPE}
    ...    browser_alias=${TEST_USER_4.USERNAME}-session
    Create Data Science Project    title=${PRJ_USER_C_TITLE}
    ...    description=${PRJ_DESCRIPTION}
    Permissions Tab Should Be Accessible
    Components Tab Should Be Accessible
    Set Suite Variable    ${USER_C}    ${TEST_USER_4.USERNAME}
    Set Suite Variable    ${PRJ_USER_C_TITLE}    ${PRJ_USER_C_TITLE}

Restore Permissions Of The Project
    Switch To User    ${USER_B}
    Move To Tab    Permissions
    Remove ${USER_A} Permissions
    Remove ${USER_C} Permissions
    Switch To User    ${USER_A}
    Open Data Science Projects Home Page
    Reload RHODS Dashboard Page    expected_page=Data science projects
    ...    wait_for_cards=${FALSE}
    Project Should Not Be Listed    project_title=${PRJ_USER_B_TITLE}
    RoleBinding Should Not Exist    project_title=${PRJ_USER_B_TITLE}
    ...    subject_name=${USER_A}
    Switch To User    ${USER_C}
    Open Data Science Projects Home Page
    Reload RHODS Dashboard Page    expected_page=Data science projects
    ...    wait_for_cards=${FALSE}
    Project Should Not Be Listed    project_title=${PRJ_USER_B_TITLE}
    RoleBinding Should Not Exist    project_title=${PRJ_USER_B_TITLE}
    ...    subject_name=${USER_C}