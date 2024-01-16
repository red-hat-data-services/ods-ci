*** Settings ***
Documentation      Suite to test Settings tab for Data Science Projects (a.k.a DSG) feature
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Permissions.resource
Suite Setup        Project Settings Suite Setup
Suite Teardown     Project Settings Suite Teardown


*** Variables ***
${PRJ_BASE_TITLE}=              ODS-CI DS Settings  Project
${PRJ_DESCRIPTION}=             ${PRJ_BASE_TITLE} is a test project for validating DS Project Settings feature


*** Test Cases ***
Verify User Can Access Settings Tab When TrustyAI Component is Enabled in DSC
    [Documentation]    Verify user can access "Settings" tab in DS Project when TrustyAI component is Enabled
    [Tags]    Tier1    Smoke
    Enable Component     trustyai
    Component Should Be Enabled    trustyai
    Move To Tab    Settings
    Page Should Contain Element     xpath://input[@id="trustyai-service-installation"]

*** Keywords ***
Project Settings Suite Setup    # robocop: disable
    [Documentation]    Suite setup steps for testing DS Projects.
    ...                It creates some test variables and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}
    Create Data Science Project    title=${PRJ_BASE_TITLE}    description=${PRJ_DESCRIPTION}
    RHOSi Setup
    Fetch CA Certificate If RHODS Is Self-Managed

Project Settings Suite Teardown
    [Documentation]    Suite teardown steps after testing Settings DSG. It Deletes
    ...         all the DS projects created by the tests and run RHOSi teardown
    Delete Data Science Project    project_title=${PRJ_BASE_TITLE}
    Close Browser
    RHOSi Teardown
