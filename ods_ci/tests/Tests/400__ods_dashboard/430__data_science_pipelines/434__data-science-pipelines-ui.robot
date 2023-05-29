*** Settings ***
Documentation      Suite to test additional scenarios for Data Science Projects (a.k.a DSG) feature
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Pipelines.resource
Suite Setup        Pipelines Suite Setup
Suite Teardown     Pipelines Suite Teardown


*** Variables ***
${PRJ_BASE_TITLE}=   DSP
${PRJ_DESCRIPTION}=   ${PRJ_BASE_TITLE} is a test project for validating DS Pipelines feature
${DC_NAME}=    ds-pipeline-conn


*** Test Cases ***
Verify User Can Create A DS Pipeline From DS Project UI
    [Tags]    Sanity    Tier1
    ...       ODS-XYZ
    Create Pipeline server    dc_name=${DC_NAME}
    Wait Until Pipeline Server Is Deployed

*** Keywords ***
Pipelines Suite Setup
    Set Library Search Order    SeleniumLibrary
    ${prj_title}=    Set Variable    ${PRJ_BASE_TITLE}-${TEST_USER_3.USERNAME}
    Set Suite Variable    ${PRJ_TITLE}    ${prj_title}
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}    
    Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}
    Create Data Science Project    title=${PRJ_TITLE}
    ...    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-ds-pipelines
    Reload RHODS Dashboard Page    expected_page=${PRJ_TITLE}
    ...    wait_for_cards=${FALSE}
    Maybe Wait For Dashboard Loading Spinner Page
    Log    message=reload needed to avoid RHODS-8923
    ...    level=WARN
    RHOSi Setup

Pipelines Suite Teardown
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown

Wait Until Pipeline Server Is Deployed
    [Documentation]    Waits until all the expected pods of the pipeline server
    ...                are running
    Wait Until Keyword Succeeds    5 times    5s
    ...    Verify Pipeline Server Deployments    project_title=${PRJ_TITLE}

