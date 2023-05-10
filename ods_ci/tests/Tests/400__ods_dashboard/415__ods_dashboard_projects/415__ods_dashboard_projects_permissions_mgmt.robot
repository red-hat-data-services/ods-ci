*** Settings ***
Documentation      Suite to test additional scenarios for Data Science Projects (a.k.a DSG) feature
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Permissions.resource
# Suite Setup        Set Library Search Order    SeleniumLibrary
Suite Setup        Project Permissions Mgmt Suite Setup
Suite Teardown     Project Permissions Mgmt Suite Teardown
Test Teardown      Close All Browsers


*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project
${PRJ_TITLE_GPU}=   ODS-CI DS Project
${PRJ_DESCRIPTION}=   ${PRJ_TITLE} is a test project for validating DS Project Sharing feature
${WORKBENCH_DESCRIPTION}=   a test workbench to check project sharing
${NB_IMAGE}=        Minimal Python
${PV_NAME}=         ods-ci-project-sharing
${PV_DESCRIPTION}=         it is a PV created to test DS Projects Sharing feature
${PV_SIZE}=         1

*** Test Cases ***
Verify User Can Access Permission Tab In Their Owned DS Project
    [Tags]    Tier1    Smoke
    ...       ODS-2194
    Pass Execution    The Test is executed as part of Suite Setup

Verify User Can Make Their Owned DS Project Accessible To Other Users
    [Tags]    Tier1    Smoke
    ...       ODS-2201
    Switch To User    ${TEST_USER_3.USERNAME}
    Move To Tab    Permissions
    Assign Edit Permissions To ${TEST_USER_4.USERNAME}
    # check rolebinding is created
    # check other user can actually access the project based on their permissions

Verify User Can Modify And Revoke Access To DS Projects From Other Users
    [Tags]    Tier1    Sanity
    ...       ODS-XYZ
    Switch To User    ${TEST_USER_3.USERNAME}
    Move To Tab    Permissions
    Change ldap-user4 Permissions To Admin
    Change ldap-user5 Permissions To Edit
    Remove ldap-user6 Permissions
    # check rolebinding is deleted

Verify Cluster Admins Automatically Get Admin Access To DS Projects
    # TO DO

*** Keywords ***
Project Permissions Mgmt Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects. 
    ...                It creates some test variables and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE}-${TEST_USER_3.USERNAME}
    ...    ${PRJ_TITLE}-${TEST_USER_4.USERNAME}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup
    # Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}
    # ...    password=${TEST_USER_3.PASSWORD}
    # ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}
    # ...    browser_alias=${TEST_USER_3.USERNAME}-session
    # Create Data Science Project    title=${PRJ_TITLE}-${TEST_USER_3.USERNAME}
    # ...    description=${PRJ_DESCRIPTION}
    # Permissions Tab Should Be Accessible
    # Components Tab Should Be Accessible
    # Launch Data Science Project Main Page    username=${TEST_USER_4.USERNAME}
    # ...    password=${TEST_USER_4.PASSWORD}
    # ...    ocp_user_auth_type=${TEST_USER_4.AUTH_TYPE}
    # ...    browser_alias=${TEST_USER_4.USERNAME}-session
    # Create Data Science Project    title=${PRJ_TITLE}-${TEST_USER_4.USERNAME}
    # ...    description=${PRJ_DESCRIPTION}
    # Permissions Tab Should Be Accessible
    # Components Tab Should Be Accessible

Project Permissions Mgmt Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    # RHOSi Teardown

Switch To User
    [Arguments]    ${username}
    Switch Browser    ${username}-session