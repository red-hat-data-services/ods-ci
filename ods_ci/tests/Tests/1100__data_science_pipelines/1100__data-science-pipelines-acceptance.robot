*** Settings ***
Documentation       Basic acceptance test suite for Data Science Pipelines
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../Resources/CLI/DataSciencePipelines/DataSciencePipelinesBackend.resource
Test Tags           DataSciencePipelines-Backend
Suite Setup         Dsp Acceptance Suite Setup
Suite Teardown      Dsp Acceptance Suite Teardown


*** Variables ***
${PROJECT}=    dsp-acceptance
${PIPELINE_HELLOWORLD_FILEPATH}=    tests/Resources/Files/pipeline-samples/v2/pip_index_url/hello_world_pip_index_url_compiled.yaml  # robocop: disable:line-too-long


*** Test Cases ***
Verify Pipeline Server Creation With S3 Object Storage
    [Documentation]    Creates a pipeline server using S3 object storage and verifies that all components are running
    [Tags]    Smoke
    Pass Execution    Passing test, as suite setup creates pipeline server

Verify Hello World Pipeline Runs Successfully    # robocop: disable:too-long-test-case
    [Documentation]    Runs a quick hello-world pipeline and verifies that it finishes successfully
    [Tags]    Smoke

    ${pipeline_run_params}=    Create Dictionary    message=Hello world!

    ${pipeline_id}    ${pipeline_version_id}    ${pipeline_run_id}    ${experiment_id}=
    ...    DataSciencePipelinesBackend.Import Pipeline And Create Run
    ...    namespace=${PROJECT}    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    pipeline_name=hello-world
    ...    pipeline_description=A hello world pipeline
    ...    pipeline_package_path=${PIPELINE_HELLOWORLD_FILEPATH}
    ...    pipeline_run_name=hello-wold-run
    ...    pipeline_run_params=${pipeline_run_params}

    DataSciencePipelinesBackend.Wait For Run Completion And Verify Status
    ...    namespace=${PROJECT}    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    pipeline_run_id=${pipeline_run_id}    pipeline_run_timeout=180
    ...    pipeline_run_expected_status=SUCCEEDED

    [Teardown]       DataSciencePipelinesBackend.Delete Pipeline And Related Resources
    ...    namespace=${PROJECT}    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    pipeline_id=${pipeline_id}


*** Keywords ***
Dsp Acceptance Suite Setup
    [Documentation]    Dsp Acceptance Suite Setup
    RHOSi Setup
    Projects.Create Data Science Project From CLI    ${PROJECT}
    DataSciencePipelinesBackend.Create Pipeline Server    namespace=${PROJECT}
    ...    object_storage_access_key=${S3.AWS_ACCESS_KEY_ID}
    ...    object_storage_secret_key=${S3.AWS_SECRET_ACCESS_KEY}
    ...    object_storage_endpoint=${S3.BUCKET_2.ENDPOINT}
    ...    object_storage_region=${S3.BUCKET_2.REGION}
    ...    object_storage_bucket_name=${S3.BUCKET_2.NAME}
    ...    dsp_version=v2
    DataSciencePipelinesBackend.Wait Until Pipeline Server Is Deployed    namespace=${PROJECT}

Dsp Acceptance Suite Teardown
    [Documentation]    Dsp Acceptance Suite Teardown
    Projects.Delete Project Via CLI By Display Name    ${PROJECT}
