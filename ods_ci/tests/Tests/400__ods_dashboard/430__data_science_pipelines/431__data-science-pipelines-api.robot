*** Settings ***
Documentation       Test suite for OpenShift Pipeline
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Library             DateTime
Library             ../../../../libs/DataSciencePipelinesAPI.py
Suite Setup         Data Science Pipelines Suite Setup
Suite Teardown      RHOSi Teardown


*** Variables ***
${REDHAT_OPENSHIFT_PIPELINES_YAML}=            ods_ci/tests/Resources/Files/redhat-openshift-pipelines.yaml
${DATA_SCIENCE_PIPELINES_APPLICATION_YAML}=    ods_ci/tests/Resources/Files/data-science-pipelines-sample.yaml
${URL_TEST_PIPELINE_RUN_YAML}=                 https://raw.githubusercontent.com/opendatahub-io/data-science-pipelines-operator/main/tests/resources/dsp-operator/test-pipeline-run.yaml


*** Test Cases ***
Verify ODS users can create and run a data science pipeline using the API
    [Documentation]    Creates, runs pipelines with admin and regular user. Double check the pipeline result and clean
    ...    the pipeline resources.
    [Tags]      Sanity
    ...         Tier1
    ...         ODS-2083
    End To End Pipeline Workflow Via Api    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    myproject1
    End To End Pipeline Workflow Via Api    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    myproject2


*** Keywords ***
End To End Pipeline Workflow Via Api
    [Documentation]    Create, run and double check the pipeline result. In the end, clean the pipeline resources.
    [Arguments]     ${username}    ${password}    ${project}
    Remove Pipeline Project    ${project}
    Create Pipeline Project    ${project}
    Install DataSciencePipelinesApplication CR    ${project}
    ${status}    Login Using User And Password    ${username}    ${password}    ${project}
    Should Be True    ${status} == 200    DSP routing is working
    ${pipeline_id}    Create Pipeline    ${URL_TEST_PIPELINE_RUN_YAML}
    ${run_id}    Create Run    ${pipeline_id}
    ${run_status}    Check Run Status    ${run_id}
    Should Be True    '${run_status}' == 'Completed'    Run ends
    [Teardown]    Clear Data Science Pipelines Resources    ${run_id}    ${pipeline_id}    ${project}

Clear Data Science Pipelines Resources
    [Documentation]    Cleans the pipeline resources.
    [Arguments]     ${run_id}    ${pipeline_id}    ${project}
    Delete Runs    ${run_id}
    Delete Pipeline    ${pipeline_id}
    Remove Pipeline Project    ${project}

Data Science Pipelines Suite Setup
    [Documentation]    Data Science Pipelines Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Install Red Hat OpenShfit Pipelines

Install Red Hat OpenShfit Pipelines
    [Documentation]    Install Red Hat OpenShfit Pipelines
    Oc Apply    kind=Subscription    src=${REDHAT_OPENSHIFT_PIPELINES_YAML}     namespace=openshift-operators
    ${pod_count}    Get Redhat Openshift Pipelines
    Should Be True    ${pod_count} == 1    All the pods were created

Install DataSciencePipelinesApplication CR
    [Documentation]    Install and verifies that DataSciencePipelinesApplication CRD is installed and working
    [Arguments]     ${project}
    Log    ${project}
    Oc Apply    kind=DataSciencePipelinesApplication    src=${DATA_SCIENCE_PIPELINES_APPLICATION_YAML}     namespace=${project}    # robocop: disable:line-too-long
    ${generation_value}    Run    oc get datasciencepipelinesapplications -n ${project} -o json | jq '.items[0].metadata.generation'    # robocop: disable:line-too-long
    Should Be True    ${generation_value} == 1    DataSciencePipelinesApplication created
