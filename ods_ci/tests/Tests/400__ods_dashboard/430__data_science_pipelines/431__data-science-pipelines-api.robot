*** Settings ***
Documentation       Test suite for OpenShift Pipeline API
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
${URL_TEST_PIPELINE_RUN_YAML}=                 https://raw.githubusercontent.com/opendatahub-io/data-science-pipelines-operator/main/tests/resources/test-pipeline-run.yaml


*** Test Cases ***
Verify Ods Users Can Create And Run a Data Science Pipeline Using The Api
    [Documentation]    Creates, runs pipelines with admin and regular user. Double check the pipeline result and clean
    ...    the pipeline resources.
    [Tags]      Sanity    Tier1    ODS-2083
    End To End Pipeline Workflow Via Api    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    pipelinesapi1
    End To End Pipeline Workflow Via Api    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    pipelinesapi2

Verify Ods Users Can Do Http Request That Must Be Redirected to Https
    [Documentation]    Verify Ods Users Can Do Http Request That Must Be Redirected to Https
    [Tags]      Sanity    Tier1    ODS-2234
    New Project    project-redirect-http
    Install DataSciencePipelinesApplication CR    project-redirect-http
    ${status}    Login And Wait Dsp Route    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}
    ...         project-redirect-http
    Should Be True    ${status} == 200    Could not login to the Data Science Pipelines Rest API OR DSP routing is not working    # robocop: disable:line-too-long
    ${url}    Do Http Request    apis/v2beta1/runs
    Should Start With    ${url}    https
    [Teardown]    Remove Pipeline Project    project-redirect-http

Verify DSPO Operator Reconciliation Retry
    [Documentation]    Verify DSPO Operator is able to recover from missing components during the initialization
    [Tags]      Sanity    Tier1    ODS-2477
    ${local_project_name} =    Set Variable    recon-test
    New Project    ${local_project_name}
    Install DataSciencePipelinesApplication CR    ${local_project_name}    data-science-pipelines-reconciliation.yaml    False
    Wait Until Keyword Succeeds    15 times    1s
    ...    Double Check If DSPA Was Created    ${local_project_name}
    DSPA Should Reconcile
    ${rc}  ${out} =    Run And Return Rc And Output   oc apply -f ods_ci/tests/Resources/Files/dummy-storage-creds.yaml -n ${local_project_name}
    IF    ${rc}!=0    Fail
    # one pod is good when reconciliation finished
    Wait For Pods Number  1    namespace=${local_project_name}    timeout=60
    [Teardown]    Remove Pipeline Project    ${local_project_name}


*** Keywords ***
End To End Pipeline Workflow Via Api
    [Documentation]    Create, run and double check the pipeline result using API.
    ...    In the end, clean the pipeline resources.
    [Arguments]     ${username}    ${password}    ${project}
    Remove Pipeline Project    ${project}
    New Project    ${project}
    Install DataSciencePipelinesApplication CR    ${project}
    ${status}    Login And Wait Dsp Route    ${username}    ${password}    ${project}
    Should Be True    ${status} == 200    Could not login to the Data Science Pipelines Rest API OR DSP routing is not working    # robocop: disable:line-too-long
    Setup Client    ${username}    ${password}    ${project}
    ${pipeline_param}=    Create Dictionary    recipient=integration_test
    ${run_id}    Import Run Pipeline    pipeline_url=${URL_TEST_PIPELINE_RUN_YAML}    pipeline_params=${pipeline_param}
    ${run_status}    Check Run Status    ${run_id}
    Should Be Equal As Strings    ${run_status}    SUCCEEDED    Pipeline run doesn't have a status that means success. Check the logs
    DataSciencePipelinesKfp.Delete Run    ${run_id}
    [Teardown]    Remove Pipeline Project    ${project}

Double Check If DSPA Was Created
    [Documentation]    Double check if DSPA was created
    [Arguments]     ${local_project_name}
    ${rc}  ${out} =    Run And Return Rc And Output   oc get datasciencepipelinesapplications -n ${local_project_name}
    IF    ${rc}!=0    Fail

DSPA Should Reconcile
    [Documentation]    DSPA must find an error because not all components were deployed
    ${stopped} =    Set Variable    ${False}
    # limit is 180 because the reconciliation run every 2 minutes
    ${timeout} =    Set Variable    180
    ${pod_name} =    Run    oc get pods -n ${APPLICATIONS_NAMESPACE} | grep data-science-pipelines-operator | awk '{print $1}'
    Log    ${pod_name}
    TRY
        WHILE    not ${stopped}    limit=${timeout}
            Sleep    1s
            ${logs}=    Oc Get Pod Logs
            ...    name=${pod_name}
            ...    namespace=${APPLICATIONS_NAMESPACE}
            ${stopped} =    Set Variable If    "Encountered error when parsing CR" in """${logs}"""    True    False
        END
    EXCEPT    WHILE loop was aborted    type=start
        Fail    msg=Reconciliation wasn't triggered
    END

Data Science Pipelines Suite Setup
    [Documentation]    Data Science Pipelines Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
