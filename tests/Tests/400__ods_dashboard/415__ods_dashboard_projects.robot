*** Settings ***
Library            SeleniumLibrary
Library            OpenShiftLibrary
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDashboardProjects.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown


*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project
${PRJ_DESCRIPTION}=   ODS-CI DS Project is a test for validating DSG feature


*** Test Cases ***
Verify User Cannot Create Project Without Title
    [Tags]    ODS-1783
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}  ocp_user_pw=${TEST_USER_3.PASSWORD}  browser_options=${BROWSER.OPTIONS}
    Open Data Science Projects Page
    Create Project With Empty Title And Expect Error

Verify User Can Create A Data Science Project
    [Tags]    ODS-1775  ODS-1784
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}  ocp_user_pw=${TEST_USER_3.PASSWORD}  browser_options=${BROWSER.OPTIONS}
    Open Data Science Projects Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Wait Until Project Is Open    project_displayed_name=${PRJ_TITLE}
    Open Data Science Projects Page
    Project Should Be Listed    project_displayed_name=${PRJ_TITLE}
    Project's Owner Should Be   expected_username=${TEST_USER_3.USERNAME}   project_displayed_name=${PRJ_TITLE}
    Check Corresponding Namespace Exists    project_displayed_name=${PRJ_TITLE}
    [Teardown]    Delete Data Science Project   project_displayed_name=${PRJ_TITLE}


*** Keywords ***
Project Suite Setup
    Set Library Search Order    SeleniumLibrary
    # RHOSi Setup

Project Suite Teardown
    Close All Browsers

Create Project With Empty Title And Expect Error
    ${error_rgx}=   Set Variable    Element[ a-zA-Z=\(\)\[\]"'\/\s]+was not enabled[ a-zA-Z=\(\)\[\]"'\/\s0-9.]+
    Run Keyword And Expect Error    Element*was not enabled*   Create Data Science Project    title=${EMPTY}  description=${EMPTY}

Check Corresponding Namespace Exists
    [Arguments]     ${project_displayed_name}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_displayed_name=${project_displayed_name}
    Oc Get      kind=Project    name=${ns_name}
