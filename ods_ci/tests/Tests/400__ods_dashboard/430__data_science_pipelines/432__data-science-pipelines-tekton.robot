*** Settings ***
Documentation       Test suite for OpenShift Pipeline using kfp_tekton python package

Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource            ../../../Resources/Page/Operators/OpenShiftPipelines.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Library             DateTime
Library             ../../../../libs/DataSciencePipelinesAPI.py
Library             ../../../../libs/DataSciencePipelinesKfpTekton.py

Suite Setup         Data Science Pipelines Suite Setup
Suite Teardown      RHOSi Teardown


*** Test Cases ***
Verify Ods users can create and run a data science pipeline using the kfp_tekton python package
    [Documentation]    Creates, runs pipelines with regular user. Double check the pipeline result and clean
    ...    the pipeline resources.
    [Tags]      Sanity
    ...         Tier1
    ...         ODS-2203
    End To End Pipeline Workflow Using Kfp_tekton    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    pipelineskfptekton1    # robocop: disable:line-too-long


*** Keywords ***
End To End Pipeline Workflow Using Kfp Tekton
    [Documentation]    Create, run and double check the pipeline result using Kfp_tekton python package. In the end,
    ...    clean the pipeline resources.
    [Arguments]    ${username}    ${password}    ${project}
    Remove Pipeline Project    ${project}
    New Project    ${project}
    Install DataSciencePipelinesApplication CR    ${project}
    ${status}    Login Using User And Password    ${username}    ${password}    ${project}
    Should Be True    ${status} == 200    DSP routing is working
    ${result}    Kfp Tekton Create Run From Pipeline Func    ${username}    ${password}    ${project}    flipcoin_pipeline    # robocop: disable:line-too-long
    ${run_status}   Kfp Tekton Wait For Run Completion    ${username}    ${password}    ${project}    ${result}
    Should Be True    '${run_status}' == 'Completed'    Run ends
    [Teardown]    Remove Pipeline Project    ${project}

Data Science Pipelines Suite Setup
    [Documentation]    Data Science Pipelines Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Install Red Hat OpenShift Pipelines
