*** Settings ***
Library            SeleniumLibrary
Library            OpenShiftLibrary
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workspaces.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown
Test Setup         Launch Data Science Project Main Page


*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project
${PRJ_DESCRIPTION}=   ODS-CI DS Project is a test for validating DSG feature
${WRKSP_TITLE}=   ODS-CI Workspace 1
${WRKSP_DESCRIPTION}=   ODS-CI Workspace 1 is a test workspace using Minimal Python image to test DS Projects feature


*** Keywords ***
Project Suite Setup
    Set Library Search Order    SeleniumLibrary
    # RHOSi Setup

Project Suite Teardown
    Close All Browsers
    Delete All Data Science Projects From CLI

Launch Data Science Project Main Page
    [Arguments]     ${username}=${TEST_USER_3.USERNAME}     ${password}=${TEST_USER_3.PASSWORD}
    Launch Dashboard    ocp_user_name=${username}  ocp_user_pw=${TEST_USER_3.PASSWORD}  browser_options=${BROWSER.OPTIONS}
    Open Data Science Projects Home Page

Create DS Project Template
    [Arguments]     ${title}   ${description}   ${username}
    Open Data Science Projects Home Page
    IF    "${title}" == "${EMPTY}"
        ${error_rgx}=   Set Variable    Element[ a-zA-Z=\(\)\[\]"'\/\s]+was not enabled[ a-zA-Z=\(\)\[\]"'\/\s0-9.]+
        Run Keyword And Expect Error    Element*was not enabled*   Create Data Science Project    title=${title}  description=${title}
        Click Button    ${GENERIC_CREATE_BTN_XP}
        Return From Keyword
    ELSE
        Create Data Science Project    title=${title}    description=${description}
    END

    Wait Until Project Is Open    project_title=${title}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${title}
    Project's Owner Should Be   expected_username=${username}   project_title=${title}


*** Test Cases ***
Verify User Can Create A Data Science Project
    [Template]      Create DS Project Template
    [Tags]      template
    ${EMPTY}    ${EMPTY}    ${OCP_ADMIN_USER.USERNAME}
    ${PRJ_TITLE}    ${PRJ_DESCRIPTION}    ${OCP_ADMIN_USER.USERNAME}
