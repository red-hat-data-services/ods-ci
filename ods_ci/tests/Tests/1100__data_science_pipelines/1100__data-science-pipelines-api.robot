*** Settings ***
Documentation       Test suite for OpenShift Pipeline API
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../Resources/CLI/DataSciencePipelines/DataSciencePipelinesBackend.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Library             DateTime
Library             ../../../libs/DataSciencePipelinesAPI.py
Library             ../../../libs/DataSciencePipelinesKfp.py
Test Tags           DataSciencePipelines-Backend
Suite Setup         Data Science Pipelines Suite Setup
Suite Teardown      RHOSi Teardown


*** Variables ***
${URL_TEST_PIPELINE_RUN_YAML}=                 https://raw.githubusercontent.com/opendatahub-io/data-science-pipelines-operator/main/tests/resources/test-pipeline-run.yaml


*** Test Cases ***
Verify Pipeline Server Creation With S3 Object Storage
    [Documentation]    Creates a pipeline server using S3 object storage and verifies that all components are running
    [Tags]    Smoke
    Projects.Create Data Science Project From CLI    name=dsp-s3
    DataSciencePipelinesBackend.Create Pipeline Server    namespace=dsp-s3
    ...    object_storage_access_key=${S3.AWS_ACCESS_KEY_ID}
    ...    object_storage_secret_key=${S3.AWS_SECRET_ACCESS_KEY}
    ...    dsp_version=v2
    DataSciencePipelinesBackend.Wait Until Pipeline Server Is Deployed    namespace=dsp-s3
    [Teardown]    Projects.Delete Project Via CLI By Display Name    dsp-s3

Verify Admin Users Can Create And Run a Data Science Pipeline Using The Api
    [Documentation]    Creates, runs pipelines with admin user. Double check the pipeline result and clean
    ...    the pipeline resources.
    [Tags]      Sanity    ODS-2083
    End To End Pipeline Workflow Via Api    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    pipelinesapi1

Verify Regular Users Can Create And Run a Data Science Pipeline Using The Api
    [Documentation]    Creates, runs pipelines with regular user. Double check the pipeline result and clean
    ...    the pipeline resources.
    [Tags]      Tier1    ODS-2677
    End To End Pipeline Workflow Via Api    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    pipelinesapi2

Verify Ods Users Can Do Http Request That Must Be Redirected to Https
    [Documentation]    Verify Ods Users Can Do Http Request That Must Be Redirected to Https
    [Tags]        Tier1    ODS-2234
    Projects.Create Data Science Project From CLI    name=project-redirect-http
    DataSciencePipelinesBackend.Create PipelineServer Using Custom DSPA    project-redirect-http
    ${status}    Login And Wait Dsp Route    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}
    ...         project-redirect-http
    Should Be True    ${status} == 200    Could not login to the Data Science Pipelines Rest API OR DSP routing is not working    # robocop: disable:line-too-long
    ${url}    Do Http Request    apis/v2beta1/runs
    Should Start With    ${url}    https
    [Teardown]    Projects.Delete Project Via CLI By Display Name    project-redirect-http

Verify DSPO Operator Reconciliation Retry
    [Documentation]    Verify DSPO Operator is able to recover from missing components during the initialization
    [Tags]      Sanity    ODS-2477

    ${local_project_name} =    Set Variable    dsp-reconciliation-test
    Projects.Create Data Science Project From CLI    name=${local_project_name}

    # Atempt to create a pipeline server with a custom DSPA. It should fail because there is a missing
    # secret with storage credentials (that's why, after, we don't use "Wait Until Pipeline Server Is Deployed"
    DataSciencePipelinesBackend.Create PipelineServer Using Custom DSPA
    ...    ${local_project_name}    data-science-pipelines-reconciliation.yaml    False
    Wait Until Keyword Succeeds    15 times    1s
    ...    Double Check If DSPA Was Created    ${local_project_name}
    Verify DSPO Logs Show Error Encountered When Parsing DSPA

    # Add the missing secret with storage credentials. The DSPO will reconcile and start the pipeline server pods
    # Note: as the credentials are dummy, the DSPA status won't be ready, but it's ok because in this test
    # we are just testing the DSPO reconciliation
    ${rc}  ${out} =    Run And Return Rc And Output   oc apply -f ${DSPA_PATH}/dummy-storage-creds.yaml -n ${local_project_name}
    IF    ${rc}!=0    Fail

    # After reconciliation, the project should have at least one pod running
    Wait For Pods Number  1    namespace=${local_project_name}    timeout=60

    [Teardown]   Projects.Delete Project Via CLI By Display Name    ${local_project_name}

*** Keywords ***
End To End Pipeline Workflow Via Api
    [Documentation]    Create, run and double check the pipeline result using API.
    ...    In the end, clean the pipeline resources.
    [Arguments]     ${username}    ${password}    ${project}
    Projects.Delete Project Via CLI By Display Name    ${project}
    Projects.Create Data Science Project From CLI    name=${project}
    Create PipelineServer Using Custom DSPA    ${project}
    ${status}    Login And Wait Dsp Route    ${username}    ${password}    ${project}
    Should Be True    ${status} == 200    Could not login to the Data Science Pipelines Rest API OR DSP routing is not working    # robocop: disable:line-too-long
    Setup Client    ${username}    ${password}    ${project}
    ${pipeline_param}=    Create Dictionary    recipient=integration_test
    ${run_id}    Import Run Pipeline    pipeline_url=${URL_TEST_PIPELINE_RUN_YAML}    pipeline_params=${pipeline_param}
    ${run_status}    Check Run Status    ${run_id}
    Should Be Equal As Strings    ${run_status}    SUCCEEDED    Pipeline run doesn't have a status that means success. Check the logs
    DataSciencePipelinesKfp.Delete Run    ${run_id}
    [Teardown]    Projects.Delete Project Via CLI By Display Name    ${project}

Double Check If DSPA Was Created
    [Documentation]    Double check if DSPA was created
    [Arguments]     ${local_project_name}
    ${rc}  ${out} =    Run And Return Rc And Output   oc get datasciencepipelinesapplications -n ${local_project_name}
    IF    ${rc}!=0    Fail

Verify DSPO Logs Show Error Encountered When Parsing DSPA
    [Documentation]    DSPA must find an error because not all components were deployed
    ${stopped} =    Set Variable    ${False}
    # limit is 180 because the reconciliation run every 2 minutes
    ${timeout} =    Set Variable    180
    ${pod_name} =    Run    oc get pods -n ${APPLICATIONS_NAMESPACE} | grep data-science-pipelines-operator | awk '{print $1}'
    Log    ${pod_name}
    TRY
        WHILE    not ${stopped}    limit=${timeout}
            Sleep    1s
            ${logs}        Run   oc logs --tail=1000000 ${pod_name} -n ${APPLICATIONS_NAMESPACE}
            ${stopped} =    Set Variable If    "Encountered error when parsing CR" in """${logs}"""    True    False
        END
    EXCEPT    WHILE loop was aborted    type=start
        Fail    msg=Reconciliation wasn't triggered
    END

Data Science Pipelines Suite Setup
    [Documentation]    Data Science Pipelines Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
