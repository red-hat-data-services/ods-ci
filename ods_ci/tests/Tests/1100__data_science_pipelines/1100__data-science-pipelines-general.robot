*** Settings ***
Documentation       Test suite for OpenShift Pipeline API

Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Pipelines.resource
Resource            ../../Resources/CLI/DataSciencePipelines/DataSciencePipelinesBackend.resource
Library             DateTime
Library             ../../../libs/DataSciencePipelinesAPI.py
Test Tags           DataSciencePipelines-Backend
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
    RHOSi Setup

General Suite Teardown
    [Documentation]    General Suite Teardown
    Delete Data Science Project From CLI By Name    name=${PROJECT_USER3}
    Delete Data Science Project From CLI By Name    name=${PROJECT_USER4}
    RHOSi Teardown

Create A Pipeline Server And Wait For Dsp Route
    [Documentation]    Create A Pipeline Server And Wait For Dsp Route
    [Arguments]     ${user}    ${password}    ${auth_type}    ${project}

    Create Data Science Project From CLI    name=${project}   as_user=${user}

    DataSciencePipelinesBackend.Create Pipeline Server    namespace=${project}
    ...    object_storage_access_key=${S3.AWS_ACCESS_KEY_ID}
    ...    object_storage_secret_key=${S3.AWS_SECRET_ACCESS_KEY}

    DataSciencePipelinesBackend.Wait Until Pipeline Server Is Deployed    namespace=${project}

    ${status}    Login And Wait Dsp Route    ${user}    ${password}    ${project}
    Should Be True    ${status} == 200    Could not login to the Data Science Pipelines Rest API OR DSP routing is not working    # robocop: disable:line-too-long
