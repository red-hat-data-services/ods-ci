*** Settings ***
Documentation       Test suite for OpenShift Pipeline API

Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Pipelines.resource
Library             DateTime
Library             ../../../../libs/DataSciencePipelinesAPI.py
Test Tags           DataSciencePipelines    Dashboard
Suite Setup         General Suite Setup
Suite Teardown      General Suite Teardown


*** Variables ***
${PROJECT_USER3}=    dspa-project-user3
${PROJECT_USER4}=    dspa-project-user4
${S3_BUCKET}=    ods-ci-ds-pipelines


*** Test Cases ***
Verify Ods User Can Bind The Route Role
    [Documentation]    Create A Data Science Projects for user3
    ...         Create A Data Science Projects for user4
    ...         Test with user3 can access the dsp route for user4, it should fail because it doesn't have the permission    # robocop: disable:line-too-long
    ...         Add the permission using a role binding
    ...         Test with user3 can access the dsp route for user4, it should work because it has the permission
    [Tags]      Tier1
    ...         ODS-2209
    Create A Pipeline Server And Wait For Dsp Route    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}
    ...         ${TEST_USER_3.AUTH_TYPE}    ${PROJECT_USER3}
    Create A Pipeline Server And Wait For Dsp Route    ${TEST_USER_4.USERNAME}    ${TEST_USER_4.PASSWORD}
    ...         ${TEST_USER_4.AUTH_TYPE}    ${PROJECT_USER4}
    # due that the projects were created, it is expected a failure in the first request
    ${status}    Login And Wait Dsp Route    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${PROJECT_USER4}
    Should Be True    ${status} == 403    The user must not have permission to access
    Add Role To User    ds-pipeline-user-access-dspa    ${TEST_USER_3.USERNAME}    ${PROJECT_USER4}
    # rbac is async and takes some time
    ${status}    Login And Wait Dsp Route    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${PROJECT_USER4}
    Should Be True    ${status} == 200    Rolling Binding Not Working


*** Keywords ***
General Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

General Suite Teardown
    [Documentation]    General Suite Teardown
    Remove Pipeline Project    ${PROJECT_USER3}
    Remove Pipeline Project    ${PROJECT_USER4}
    RHOSi Teardown

Create A Pipeline Server And Wait For Dsp Route
    [Documentation]    Create A Pipeline Server And Wait For Dsp Route
    [Arguments]     ${user}    ${password}    ${auth_type}    ${project}
    Launch Data Science Project Main Page    username=${user}
    ...    password=${password}
    ...    ocp_user_auth_type=${auth_type}
    ...    browser_alias=${user}-session
    Remove Pipeline Project    ${project}
    Create Data Science Project    title=${project}    description=
    Projects.Move To Tab    Data connections
    Create S3 Data Connection    project_title=${project}    dc_name=${project}-dc
    ...                          aws_access_key=${S3.AWS_ACCESS_KEY_ID}
    ...                          aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...                          aws_s3_endpoint=${S3.AWS_DEFAULT_ENDPOINT}    aws_region=${S3.AWS_DEFAULT_REGION}
    ...                          aws_bucket_name=${S3_BUCKET}
    Create Pipeline Server    dc_name=${project}-dc    project_title=${project}
    Wait Until Pipeline Server Is Deployed    project_title=${project}
    ${status}    Login And Wait Dsp Route    ${user}    ${password}    ${project}
    Should Be True    ${status} == 200    Could not login to the Data Science Pipelines Rest API OR DSP routing is not working    # robocop: disable:line-too-long
