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


*** Variables ***
${PROJECT_NAME}=    pipelineskfptekton1


*** Test Cases ***
Verify Ods Users Can Create And Run A Data Science Pipeline Using The Kfp_tekton Python Package
    [Documentation]    Creates, runs pipelines with regular user. Double check the pipeline result and clean
    ...    the pipeline resources.
    [Tags]      Sanity
    ...         Tier1
    ...         ODS-2203

    End To End Pipeline Workflow Using Kfp_tekton
    ...    username=${TEST_USER.USERNAME}
    ...    password=${TEST_USER.PASSWORD}
    ...    project=${PROJECT_NAME}
    ...    python_file=flip_coin.py
    ...    method_name=flipcoin_pipeline
    End To End Pipeline Workflow Using Kfp_tekton
    ...    username=${TEST_USER.USERNAME}
    ...    password=${TEST_USER.PASSWORD}
    ...    project=${PROJECT_NAME}
    ...    python_file=upload_download.py
    ...    method_name=wire_up_pipeline
    ...    status_check_timeout=220
    [Teardown]    Remove Pipeline Project    ${PROJECT_NAME}


*** Keywords ***
# robocop: disable:line-too-long
End To End Pipeline Workflow Using Kfp Tekton
    [Documentation]    Create, run and double check the pipeline result using Kfp_tekton python package. In the end,
    ...    clean the pipeline resources.
    [Arguments]    ${username}    ${password}    ${project}    ${python_file}    ${method_name}
    ...    ${status_check_timeout}=160
    Remove Pipeline Project    ${project}
    New Project    ${project}
    Install DataSciencePipelinesApplication CR    ${project}
    ${status}    Login And Wait Dsp Route    ${username}    ${password}    ${project}    ds-pipeline-pipelines-definition
    Should Be True    ${status} == 200    Could not login to the Data Science Pipelines Rest API OR DSP routing is not working
    ${result}    Kfp Tekton Create Run From Pipeline Func    ${username}    ${password}    ${project}
    ...    ds-pipeline-pipelines-definition    ${python_file}    ${method_name}
    ${run_status}   Kfp Tekton Wait For Run Completion    ${username}    ${password}    ${project}
    ...    ds-pipeline-pipelines-definition    ${result}    ${status_check_timeout}
    Should Be True    ${run_status}    Pipeline run doesn't have a status that means success. Check the log
    Remove Pipeline Project    ${project}

Data Science Pipelines Suite Setup
    [Documentation]    Data Science Pipelines Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Install Red Hat OpenShift Pipelines

