*** Settings ***
Documentation       Test suite for OpenShift Pipeline using kfp python package

Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Library             DateTime
Library             ../../../../libs/DataSciencePipelinesAPI.py
Library             ../../../../libs/DataSciencePipelinesKfp.py
Test Tags           DataSciencePipelines
Suite Setup         Data Science Pipelines Suite Setup
Suite Teardown      RHOSi Teardown


*** Variables ***
${PROJECT_NAME}=    pipelineskfp1


*** Test Cases ***
Verify Ods Users Can Create And Run A Data Science Pipeline Using The kfp Python Package
    [Documentation]    Creates, runs pipelines with regular user. Double check the pipeline result and clean
    ...    the pipeline resources.
    [Tags]      Sanity    Tier1    ODS-2203
    ${emtpy_dict}=    Create Dictionary
    End To End Pipeline Workflow Using Kfp
    ...    username=${TEST_USER.USERNAME}
    ...    password=${TEST_USER.PASSWORD}
    ...    project=${PROJECT_NAME}
    ...    python_file=flip_coin.py
    ...    method_name=flipcoin_pipeline
    ...    status_check_timeout=440
    ...    pipeline_params=${emtpy_dict}
    ${upload_download_dict}=    Create Dictionary    mlpipeline_minio_artifact_secret=value    bucket_name=value
    End To End Pipeline Workflow Using Kfp
    ...    username=${TEST_USER.USERNAME}
    ...    password=${TEST_USER.PASSWORD}
    ...    project=${PROJECT_NAME}
    ...    python_file=upload_download.py
    ...    method_name=wire_up_pipeline
    ...    status_check_timeout=440
    ...    pipeline_params=${upload_download_dict}
    [Teardown]    Remove Pipeline Project    ${PROJECT_NAME}


Verify Ods Users Can Create And Run A Data Science Pipeline With Ray Using The kfp Python Package
    [Documentation]    Creates, runs pipelines with regular user. Double check the pipeline result and clean
    ...    the pipeline resources.
    [Tags]      Sanity
    ...         Tier1
    ...         ODS-2541
    Skip If Component Is Not Enabled    ray
    Skip If Component Is Not Enabled    codeflare
    End To End Pipeline Workflow Using Kfp
    ...    username=${TEST_USER.USERNAME}
    ...    password=${TEST_USER.PASSWORD}
    ...    project=${PROJECT_NAME}
    ...    python_file=ray_integration.py
    ...    method_name=ray_integration
    ...    status_check_timeout=440
    ...    pipeline_params={'openshift_server': 'value', 'openshift_token': 'value'}
    [Teardown]    Remove Pipeline Project    ${PROJECT_NAME}


*** Keywords ***
# robocop: disable:line-too-long
End To End Pipeline Workflow Using Kfp
    [Documentation]    Create, run and double check the pipeline result using Kfp python package. In the end,
    ...    clean the pipeline resources.
    [Arguments]    ${username}    ${password}    ${project}    ${python_file}    ${method_name}
    ...    ${pipeline_params}    ${status_check_timeout}=160
    Remove Pipeline Project    ${project}
    New Project    ${project}
    Install DataSciencePipelinesApplication CR    ${project}
    ${status}    Login And Wait Dsp Route    ${username}    ${password}    ${project}
    Should Be True    ${status} == 200    Could not login to the Data Science Pipelines Rest API OR DSP routing is not working
    ${run_id}    Create Run From Pipeline Func    ${username}    ${password}    ${project}
    ...    ${python_file}    ${method_name}    pipeline_params=${pipeline_params}
    ${run_status}    Check Run Status    ${run_id}
    Should Be Equal As Strings    ${run_status}    SUCCEEDED    Pipeline run doesn't have a status that means success. Check the logs
    Remove Pipeline Project    ${project}

Data Science Pipelines Suite Setup
    [Documentation]    Data Science Pipelines Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

