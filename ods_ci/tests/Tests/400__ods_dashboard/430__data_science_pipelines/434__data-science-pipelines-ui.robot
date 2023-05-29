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
${PIPELINE_TEST_BASENAME}=    iris
${PIPELINE_TEST_DESC}=    test pipeline definition
${PIPELINE_TEST_FILEPATH}=    ods_ci/tests/Resources/Files/pipeline-samples/iris-pipeline-compiled.yaml
${PIPELINE_TEST_RUN_BASENAME}=    ${PIPELINE_TEST_BASENAME}-run

*** Test Cases ***
Verify User Can Create And Run A DS Pipeline From DS Project Details Page
    [Tags]    Sanity    Tier1
    ...       ODS-2206
    Create Pipeline server    dc_name=${DC_NAME}
    Wait Until Pipeline Server Is Deployed
    Import Pipeline    name=${PIPELINE_TEST_NAME}
    ...    description=${PIPELINE_TEST_DESC}
    ...    project_title=${PRJ_TITLE}
    ...    filepath=${PIPELINE_TEST_FILEPATH}
    ...    press_cancel=${TRUE}
    Pipeline Should Not Be Listed    pipeline_name=${PIPELINE_TEST_NAME}
    ...    pipeline_description=${PIPELINE_TEST_DESC}
    Import Pipeline    name=${PIPELINE_TEST_NAME}
    ...    description=${PIPELINE_TEST_DESC}
    ...    project_title=${PRJ_TITLE}
    ...    filepath=${PIPELINE_TEST_FILEPATH}
    ...    press_cancel=${FALSE}
    Pipeline Should Be Listed    pipeline_name=${PIPELINE_TEST_NAME}
    ...    pipeline_description=${PIPELINE_TEST_DESC}
    Capture Page Screenshot
    Create Pipeline Run    name=${PIPELINE_TEST_RUN_BASENAME}    pipeline_name=${PIPELINE_TEST_NAME}
    ...    from_actions_menu=${FALSE}    run_type=Immediate
    ...    press_cancel=${TRUE}
    Open Data Science Project Details Page    ${PRJ_TITLE}
    Create Pipeline Run    name=${PIPELINE_TEST_RUN_BASENAME}    pipeline_name=${PIPELINE_TEST_NAME}
    ...    from_actions_menu=${FALSE}    run_type=Immediate
    # check pipeline details section - for future PR
    # check pipeline representation exists  - for future PR
    # check run output section  - for future PR
    Open Data Science Project Details Page    ${PRJ_TITLE}
    Wait Until Pipeline Last Run Is Finished    pipeline_name=${PIPELINE_TEST_NAME}
    ...    timeout=180s
    Pipeline Last Run Should Be    pipeline_name=${PIPELINE_TEST_NAME}
    ...    run_name=${PIPELINE_TEST_RUN_BASENAME}
    Pipeline Last Run Status Should Be    pipeline_name=${PIPELINE_TEST_NAME}
    ...    status=Completed
    Pipeline Run Should be Listed    name=${PIPELINE_TEST_RUN_BASENAME}
    ...    pipeline_name=${PIPELINE_TEST_NAME}


*** Keywords ***
Pipelines Suite Setup
    Set Library Search Order    SeleniumLibrary
    ${prj_title}=    Set Variable    ${PRJ_BASE_TITLE}-${TEST_USER_3.USERNAME}
    ${iris_pipeline_name}=    Set Variable    ${PIPELINE_TEST_BASENAME}-${TEST_USER_3.USERNAME}
    Set Suite Variable    ${PRJ_TITLE}    ${prj_title}
    Set Suite Variable    ${PIPELINE_TEST_NAME}    ${iris_pipeline_name}
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}    
    Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}
    # Open Data Science Project Details Page    ${PRJ_TITLE}
    Create Data Science Project    title=${PRJ_TITLE}
    ...    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-ds-pipelines
    Reload RHODS Dashboard Page    expected_page=${PRJ_TITLE}
    ...    wait_for_cards=${FALSE}
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    # TO DELETE # Maybe Wait For Dashboard Loading Spinner Page
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

