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
    [Tags]    Tier1    Smoke    OpenDataHub
    ...       ODS-2194
    Pass Execution    The Test is executed as part of Suite Setup

Verify User Can Make Their Owned DS Project Accessible To Other Users    # robocop: disable
    [Documentation]    Verify user can give access permissions for their DS Projects to other users
    [Tags]    Tier1    Sanity
    ...       ODS-2201
    Switch To User    ${USER_B}
    Move To Tab    Permissions
    Assign Edit Permissions To User ${USER_C}
    Assign Admin Permissions To User ${USER_A}
    ${USER_C} Should Have Edit Access To ${PRJ_USER_B_TITLE}
    ${USER_A} Should Have Admin Access To ${PRJ_USER_B_TITLE}

Verify User Can Modify And Revoke Access To DS Projects From Other Users    # robocop: disable
    [Documentation]    Verify user can modify/remove access permissions for their DS Projects to other users
    [Tags]    Tier1    Sanity
    ...       ODS-2202
    Switch To User    ${USER_B}
    Move To Tab    Permissions
    Change ${USER_C} Permissions To Admin
    Change ${USER_A} Permissions To Edit
    Refresh Pages
    ${USER_C} Should Have Admin Access To ${PRJ_USER_B_TITLE}
    ${USER_A} Should Have Edit Access To ${PRJ_USER_B_TITLE}
    Switch To User    ${USER_B}
    Move To Tab    Permissions
    Remove ${USER_C} Permissions
    ${USER_C} Should Not Have Access To ${PRJ_USER_B_TITLE}

Verify User Can Assign Access Permissions To User Groups
    [Tags]    Tier1    Sanity
    ...       ODS-2208
    [Setup]    Restore Permissions Of The Project
    Switch To User    ${USER_B}
    Assign Edit Permissions To Group ${USER_GROUP_1}
    Assign Admin Permissions To Group ${USER_GROUP_2}
    RoleBinding Should Exist    project_title=${PRJ_USER_B_TITLE}
    ...    subject_name=${USER_GROUP_1}

    RoleBinding Should Exist    project_title=${PRJ_USER_B_TITLE}
    ...    subject_name=${USER_GROUP_2}
    Sleep   5s
    ${USER_A} Should Have Edit Access To ${PRJ_USER_B_TITLE}
    ${USER_C} Should Have Admin Access To ${PRJ_USER_B_TITLE}
    Switch To User    ${USER_B}
    Change ${USER_GROUP_1} Permissions To Admin
    Change ${USER_GROUP_2} Permissions To Edit
    Sleep   5s
    ${USER_A} Should Have Admin Access To ${PRJ_USER_B_TITLE}
    ${USER_C} Should Have Edit Access To ${PRJ_USER_B_TITLE}
    Switch To User    ${USER_B}
    Remove ${USER_GROUP_2} Permissions
    Sleep   5s
    ${USER_C} Should Not Have Access To ${PRJ_USER_B_TITLE}

Verify Project Sharing Does Not Override Dashboard Permissions
    [Tags]    Tier1    Sanity
    ...       ODS-2223
    # [Setup]    Run Keywords  Restore Permissions Of The Project
    # ...         AND           Set RHODS Admins Group Empty Group
    [Setup]    Set RHODS Admins Group Empty Group     
    Launch Data Science Project Main Page    username=${TEST_USER_4.USERNAME}
    Move To Tab    Permissions
    Remove User From Group    username=${USER_B}
    ...    group_name=rhods-users
    Remove User From Group    username=${USER_C}
    ...    group_name=rhods-users
    Assign Admin Permissions To User ${USER_B}
    Assign Edit Permissions To User ${USER_C}
    ${USER_B} Should Not Have Access To ${PRJ_USER_B_TITLE}
    ${USER_C} Should Not Have Access To ${PRJ_USER_B_TITLE}
    [Teardown]    Run Keywords  Set RHODS Admins Group To system:authenticated
    ...         AND           Set User Groups For Testing

*** Keywords ***
Project Permissions Mgmt Suite Setup    # robocop: disable
    [Documentation]    Suite setup steps for testing DS Projects.
    ...                It creates some test variables and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings
    ${to_delete}=    Create List
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    Launch RHODS Dashboard Session With User A
    Launch RHODS Dashboard Session And Create A DS Project With User B
    Launch RHODS Dashboard Session With User C
    Set User Groups For Testing
    Refresh Pages

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
    Add User To Group    username=${USER_C}
    ...    group_name=rhods-users
    Add User To Group    username=${USER_B}
    ...    group_name=rhods-users
    Delete Group    ${USER_GROUP_1}
    Delete Group    ${USER_GROUP_2}

Switch To User
    [Documentation]    Move from one browser window to another. Every browser window
    ...    is a user login session in RHODS Dashboard.
    ...    The variable ${is_cluster_admin} is used to enable UI flows which require
    ...    a user with cluster-admin or dedicated-admin level of privileges.
    [Arguments]    ${username}    ${is_cluster_admin}=${FALSE}
    Switch Browser    ${username}-session
    Set Suite Variable    ${IS_CLUSTER_ADMIN}    ${is_cluster_admin}

Launch RHODS Dashboard Session With User A
    Launch Dashboard    ocp_user_name=${TEST_USER_2.USERNAME}  ocp_user_pw=${TEST_USER_2.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_2.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    ...    browser_alias=${TEST_USER_2.USERNAME}-session
    Set Suite Variable    ${USER_A}    ${TEST_USER_2.USERNAME}

Launch RHODS Dashboard Session And Create A DS Project With User B
    ${PRJ_USER_B_TITLE}=    Set Variable   ${PRJ_BASE_TITLE}-${TEST_USER_3.USERNAME}
    Append To List    ${PROJECTS_TO_DELETE}    ${PRJ_USER_B_TITLE}
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
    Append To List    ${PROJECTS_TO_DELETE}    ${PRJ_USER_C_TITLE}
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

Set User Groups For Testing
    Create Group    ${USER_GROUP_1}
    Create Group    ${USER_GROUP_2}
    Remove User From Group    username=${USER_A}
    ...    group_name=dedicated-admins
    Remove User From Group    username=${USER_A}
    ...    group_name=rhods-admins
    Remove User From Group    username=${USER_C}
    ...    group_name=rhods-users
    Remove User From Group    username=${USER_B}
    ...    group_name=rhods-users
    Add User To Group    username=${USER_A}
    ...    group_name=${USER_GROUP_1}
    Add User To Group    username=${USER_C}
    ...    group_name=${USER_GROUP_2}
    Add User To Group    username=${USER_B}
    ...    group_name=${USER_GROUP_1}

Restore Permissions Of The Project
    Switch To User    ${USER_B}
    Move To Tab    Permissions
    ${present_a}=    Is ${USER_A} In The Permissions Table
    IF    ${present_a} == ${TRUE}
        Remove ${USER_A} Permissions
    END
    ${present_c}=    Is ${USER_C} In The Permissions Table
    IF    ${present_c} == ${TRUE}
        Remove ${USER_C} Permissions
    END
    ${USER_A} Should Not Have Access To ${PRJ_USER_B_TITLE}
    ${USER_C} Should Not Have Access To ${PRJ_USER_B_TITLE}

Refresh Pages
    Switch To User    ${USER_A}
    Open Data Science Projects Home Page
    Reload RHODS Dashboard Page    expected_page=Data Science Projects
    ...    wait_for_cards=${FALSE}
    Switch To User    ${USER_B}
    Open Data Science Projects Home Page
    Reload RHODS Dashboard Page    expected_page=Data Science Projects
    ...    wait_for_cards=${FALSE}
    Wait Until Project Is Listed    project_title=${PRJ_USER_B_TITLE}
    Open Data Science Project Details Page    ${PRJ_USER_B_TITLE}
    Switch To User    ${USER_C}
    Open Data Science Projects Home Page
    Reload RHODS Dashboard Page    expected_page=Data Science Projects
    ...    wait_for_cards=${FALSE}

Reload Page If Project ${project_title} Is Not Listed
    ${is_listed}=    Run Keyword And Return Status
    ...    Project Should Be Listed    project_title=${project_title}
    IF    ${is_listed} == ${FALSE}
        Log    message=Project ${project_title} is not listed as expected: reloading DS Project page to refresh project list!    # robocop:disable
        ...    level=WARN
        Reload RHODS Dashboard Page    expected_page=Data Science Projects
        ...    wait_for_cards=${FALSE}
        ${is_listed}=    Run Keyword And Return Status
        ...    Project Should Be Listed    project_title=${project_title}
        IF    ${is_listed} == ${FALSE}
            Log    message=Project ${project_title} is not listed as expected: reloading DS Project page to refresh project list! (2)    # robocop:disable
            ...    level=WARN
            Reload RHODS Dashboard Page    expected_page=Data Science Projects
            ...    wait_for_cards=${FALSE}
        END
    END

Reload Page If Project ${project_title} Is Listed
    ${is_listed}=    Run Keyword And Return Status
    ...    Project Should Be Listed    project_title=${project_title}
    IF    ${is_listed} == ${TRUE}
        Log    message=Project ${project_title} is still listed as NOT expected: reloading DS Project page to refresh project list!    # robocop:disable
        ...    level=WARN
        Reload RHODS Dashboard Page    expected_page=Data Science Projects
        ...    wait_for_cards=${FALSE}
        ${is_listed}=    Run Keyword And Return Status
        ...    Project Should Be Listed    project_title=${project_title}
        IF    ${is_listed} == ${TRUE}
            Log    message=Project ${project_title} is still listed as NOT expected: reloading DS Project page to refresh project list! (2)    # robocop:disable
            ...    level=WARN
            Reload RHODS Dashboard Page    expected_page=Data Science Projects
            ...    wait_for_cards=${FALSE}
        END
    END

${username} Should Have Edit Access To ${project_title}
    Switch To User    ${username}
    Open Data Science Projects Home Page
    Reload Page If Project ${project_title} Is Not Listed
    Wait Until Project Is Listed    project_title=${project_title}
    Open Data Science Project Details Page    ${project_title}
    Permissions Tab Should Not Be Accessible
    # add checks on subsections

${username} Should Have Admin Access To ${project_title}
    Switch To User    ${username}
    Open Data Science Projects Home Page
    Reload Page If Project ${project_title} Is Not Listed
    Wait Until Project Is Listed    project_title=${project_title}
    Open Data Science Project Details Page    ${project_title}
    Permissions Tab Should Be Accessible
    Components Tab Should Be Accessible

${username} Should Not Have Access To ${project_title}
    Switch To User    ${username}
    Open Data Science Projects Home Page
    Reload Page If Project ${project_title} Is Listed
    Project Should Not Be Listed    project_title=${project_title}
    RoleBinding Should Not Exist    project_title=${project_title}
    ...    subject_name=${username}
