*** Settings ***
Documentation       Basic acceptance test suite for Data Science Pipelines
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../Resources/CLI/DataSciencePipelines/DataSciencePipelinesBackend.resource
Test Tags           DataSciencePipelines-Backend
Suite Setup         Dsp Nvidia Gpu Suite Setup
Suite Teardown      Dsp Nvidia Gpu Suite Teardown


*** Variables ***
${PROJECT}=    dsp-gpu-nvidia
${PIPELINE_GPU_AVAILABILITY_FILEPATH}=    tests/Resources/Files/pipeline-samples/v2/gpu/pytorch/pytorch_verify_gpu_availability_compiled.yaml    # robocop: off=line-too-long


*** Test Cases ***
Verify Pipeline Tasks Run On GPU Nodes Only When Tolerations Are Added   # robocop: off=too-long-test-case
    [Documentation]    Runs a pipeline that tests GPU availability according to GPU tolerations in pipeline tasks:
    ...    - One task should not have GPUs available, as we don't add the GPU tolerations
    ...    - Another task should have GPUs available, as we add the GPU tolerations
    [Tags]    Tier1    Resources-GPU    NVIDIA-GPUs

    # robocop: off=unused-variable
    ${pipeline_id}    ${pipeline_version_id}    ${pipeline_run_id}    ${experiment_id}=
    ...    DataSciencePipelinesBackend.Import Pipeline And Create Run
    ...    namespace=${PROJECT}    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    pipeline_name=pytorch-verify-gpu-availability
    ...    pipeline_description=Verifies GPU availability in tasks when using tolerations
    ...    pipeline_package_path=${PIPELINE_GPU_AVAILABILITY_FILEPATH}
    ...    pipeline_run_name=pytorch-verify-gpu-availability-run

    DataSciencePipelinesBackend.Wait For Run Completion And Verify Status
    ...    namespace=${PROJECT}    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    pipeline_run_id=${pipeline_run_id}    pipeline_run_timeout=240
    ...    pipeline_run_expected_status=SUCCEEDED

    [Teardown]       DataSciencePipelinesBackend.Delete Pipeline And Related Resources
    ...    namespace=${PROJECT}    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    pipeline_id=${pipeline_id}


*** Keywords ***
Dsp Nvidia Gpu Suite Setup
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

Dsp Nvidia Gpu Suite Teardown
    [Documentation]    Dsp Acceptance Suite Teardown
    Projects.Delete Project Via CLI By Display Name    ${PROJECT}
    RHOSi Teardown
