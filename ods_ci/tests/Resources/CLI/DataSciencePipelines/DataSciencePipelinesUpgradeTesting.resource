*** Settings ***
Documentation    Upgrade Testing Keywords
Resource         DataSciencePipelinesBackend.resource
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource


*** Variables ***
${PROJECT}=    upg-dsp
${PIPELINE_LONGRUNNING_FILEPATH}=    tests/Resources/Files/pipeline-samples/v2/cache-disabled/pip_index_url/take_nap_compiled.yaml  # robocop: disable:line-too-long


*** Keywords ***
Setup Environment For Upgrade Testing
    [Documentation]    Creates project dsp-test-upgrade and sets up the resources to test during upgrade:
    ...    - Creates a pipeline server
    ...    - Starts a pipeline that will run for 1h

    Create Project And Configure Pipeline Server    ${PROJECT}
    Start Long Running Pipeline    ${PROJECT}

Verify Resources After Upgrade
    [Documentation]    Verifies the status of the resources created in ${PROJECT} after the upgrade
    ...    Deletes ${PROJECT} if all verifications are correct (leaving for debugging purposes if not)

    Skip If Namespace Does Not Exist    ${PROJECT}

    DataSciencePipelinesBackend.Wait Until Pipeline Server Is Deployed    namespace=${PROJECT}

    ${take_nap_run_id}=    DataSciencePipelinesBackend.Get Last Run By Pipeline Name
    ...    namespace=${PROJECT}    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    pipeline_name=take-nap

    ${pipeline_run_status}=    DataSciencePipelinesBackend.Get Run Status
    ...    namespace=${PROJECT}    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    pipeline_run_id=${take_nap_run_id}

    IF   "${pipeline_run_status}" != "RUNNING" and "${pipeline_run_status}" != "SUCCEEDED"
        Fail    take-nap has status ${pipeline_run_status} after upgrade
    END

    Projects.Delete Project Via CLI By Display Name    ${PROJECT}

Create Project And Configure Pipeline Server
    [Documentation]    Creates a data science pipelines project ${namespace}  (deleting existing one if needed),
    ...    configures a pipeline server using the default configuration and waits until the server is running
    [Arguments]    ${namespace}
    Projects.Delete Project Via CLI By Display Name    ${namespace}
    Projects.Create Data Science Project From CLI    ${namespace}
    DataSciencePipelinesBackend.Create Pipeline Server    namespace=${namespace}
    ...    object_storage_access_key=${S3.AWS_ACCESS_KEY_ID}
    ...    object_storage_secret_key=${S3.AWS_SECRET_ACCESS_KEY}
    ...    object_storage_endpoint=${S3.BUCKET_2.ENDPOINT}
    ...    object_storage_region=${S3.BUCKET_2.REGION}
    ...    object_storage_bucket_name=${S3.BUCKET_2.NAME}
    ...    dsp_version=v2
    DataSciencePipelinesBackend.Wait Until Pipeline Server Is Deployed    namespace=${namespace}

Start Long Running Pipeline
    [Documentation]    Imports and creates a run of a long running pipeline
    [Arguments]    ${namespace}

    ${pipeline_run_params}=    Create Dictionary    naptime_secs=${3600}

    # robocop:off=unused-variable
    ${pipeline_id}    ${pipeline_version_id}    ${pipeline_run_id}    ${experiment_id}=
    ...    DataSciencePipelinesBackend.Import Pipeline And Create Run
    ...    namespace=${namespace}    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    pipeline_name=take-nap
    ...    pipeline_description=A pipeline that runs for 1h and prints a message
    ...    pipeline_package_path=${PIPELINE_LONGRUNNING_FILEPATH}
    ...    pipeline_run_name=take-nap-run
    ...    pipeline_run_params=${pipeline_run_params}
