*** Settings ***
Documentation      Suite to test Settings tab for Data Science Projects (a.k.a DSG) feature
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Settings.resource
Suite Setup        Project Settings Suite Setup
Suite Teardown     Project Settings Suite Teardown


*** Variables ***
${PRJ_BASE_TITLE}=              ODS-CI DS Settings  Project
${PRJ_DESCRIPTION}=             ${PRJ_BASE_TITLE} is a test project for validating DS Project Settings feature
${TRUSTYAI_CHECKBOX_XP}         //input[@id="trustyai-service-installation"]


*** Test Cases ***
Verify User Can Access Settings Tab When TrustyAI Component is Enabled in DSC
    [Documentation]    Verify user can access "Settings" tab in DS Project when TrustyAI component is Enabled
    [Tags]    Tier1    Smoke
    Enable Component     trustyai
    Component Should Be Enabled    trustyai
    Move To Tab    Settings
    Page Should Contain Element     xpath:${TRUSTYAI_CHECKBOX_XP}
    Verify TrustyAI Checkbox is Disabled

*** Keywords ***
Project Settings Suite Setup    # robocop: disable
    [Documentation]    Suite setup steps for testing DS Projects.
    ...                It creates some test variables and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_BASE_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_BASE_TITLE}    description=${PRJ_DESCRIPTION}
    RHOSi Setup

Project Settings Suite Teardown
    [Documentation]    Suite teardown steps after testing Settings DSG. It Deletes
    ...         all the DS projects created by the tests and run RHOSi teardown
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    Close Browser
    RHOSi Teardown
