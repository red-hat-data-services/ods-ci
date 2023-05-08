*** Settings ***
Documentation      Suite to test additional scenarios for Data Science Projects (a.k.a DSG) feature
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Suite Setup        Project Permissions Mgmt Suite Setup
Suite Teardown     Project Permissions Mgmt Suite Teardown
Test Teardown      Close All Browsers


*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project
${PRJ_TITLE_GPU}=   ODS-CI DS Project
${PRJ_RESOURCE_NAME}=   ods-ci-ds-project-test-permissions
${PRJ_DESCRIPTION}=   ${PRJ_TITLE} is a test project for validating DS Project Sharing feature
${WORKBENCH_DESCRIPTION}=   a test workbench to check project sharing
${NB_IMAGE}=        Minimal Python
${PV_NAME}=         ods-ci-project-sharing
${PV_DESCRIPTION}=         it is a PV created to test DS Projects Sharing feature
${PV_SIZE}=         1


*** Test Cases ***
Verify User Can Access Permission Tab In Their Owned DS Project
    # TO DO

Verify User Make Their Owned DS Project Accessible To Other Users
    # TO DO

Verify User Can Revoke Access To DS Projects From Other Users
    # TO DO

Verify Cluster Admins Automatically Get Admin Access To DS Projects
    # TO DO

*** Keywords ***
Project Permissions Mgmt Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects. 
    ...                It creates some test variables and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup

Project Permissions Mgmt Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown