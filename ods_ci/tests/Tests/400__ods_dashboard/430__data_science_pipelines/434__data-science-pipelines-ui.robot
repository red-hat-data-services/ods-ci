# robocop: off=line-too-long
*** Settings ***
Documentation      Suite to test Data Science Pipeline feature using RHODS UI
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Pipelines.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Test Tags          DataSciencePipelines
Suite Setup        Pipelines Suite Setup
Suite Teardown     Pipelines Suite Teardown


*** Variables ***
# lower case because it will be the OpenShift project
${PRJ_BASE_TITLE}=   dsp
${PRJ_DESCRIPTION}=   ${PRJ_BASE_TITLE} is a test project for validating DS Pipelines feature
${PRJ_TITLE}=    ${PRJ_BASE_TITLE}-${TEST_USER_3.USERNAME}
${PIPELINE_TEST_NAME}=    ${PIPELINE_TEST_BASENAME}-${TEST_USER_3.USERNAME}
${DC_NAME}=    ds-pipeline-conn
${PIPELINE_TEST_BASENAME}=    iris
${PIPELINE_TEST_DESC}=    test pipeline definition
${PIPELINE_TEST_FILEPATH}=    ods_ci/tests/Resources/Files/pipeline-samples/v2/pip_index_url/iris_pipeline_pip_index_url_compiled.yaml
${PIPELINE_TEST_RUN_BASENAME}=    ${PIPELINE_TEST_BASENAME}-run


*** Test Cases ***
# robocop: off=too-long-test-case,too-many-calls-in-test-case
Verify User Can Create, Run and Delete A DS Pipeline From DS Project Details Page Using Custom Pip Mirror
    [Documentation]    Verifies users are able to create and execute Data Science Pipelines using the UI.
    ...    The pipeline to run will be using the values for pip_index_url and pip_trusted_host
    ...    availables in a ConfigMap created in the SuiteSetup.
    [Tags]    Smoke
    ...       ODS-2206    ODS-2226    ODS-2633

    Open Data Science Project Details Page    ${PRJ_TITLE}

    Create Pipeline Server    dc_name=${DC_NAME}    project_title=${PRJ_TITLE}
    Verify There Is No "Error Displaying Pipelines" After Creating Pipeline Server
    Verify That There Are No Sample Pipelines After Creating Pipeline Server
    Wait Until Pipeline Server Is Deployed    project_title=${PRJ_TITLE}

    Import Pipeline    name=${PIPELINE_TEST_NAME}
    ...    description=${PIPELINE_TEST_DESC}
    ...    project_title=${PRJ_TITLE}
    ...    filepath=${PIPELINE_TEST_FILEPATH}
    ...    press_cancel=${FALSE}

    # TODO: Fix these verifications
    # Pipeline Context Menu Should Be Working    pipeline_name=${PIPELINE_TEST_NAME}
    # Pipeline Yaml Should Be Readonly    pipeline_name=${PIPELINE_TEST_NAME}

    Pipeline Should Be Listed    pipeline_name=${PIPELINE_TEST_NAME}
    ...    pipeline_description=${PIPELINE_TEST_DESC}

    # Create run
    Open Data Science Project Details Page    ${PRJ_TITLE}    tab_id=pipelines-projects
    Create Pipeline Run    name=${PIPELINE_TEST_RUN_BASENAME}
    ...    pipeline_name=${PIPELINE_TEST_NAME}     run_type=Immediate
    Verify Pipeline Run Is Completed    ${PIPELINE_TEST_RUN_BASENAME}

    # TODO: fix pipeline logs checking
    # ${data_prep_log}=    Get Pipeline Run Step Log    data-prep
    # # deterministic: "Initial Dataset:" came from a print inside the python code.
    # Should Contain    ${data_prep_log}    Initial Dataset:

    # TODO: fix duplicated runs and archival testing
    # Verify Data Science Parameter From A Duplicated Run Are The Same From The Compiled File
    # ODHDataSciencePipelines.Archive Pipeline Run       ${PIPELINE_TEST_RUN_BASENAME}    ${PIPELINE_TEST_NAME}

    ODHDataSciencePipelines.Delete Pipeline           ${PIPELINE_TEST_NAME}
    ODHDataSciencePipelines.Delete Pipeline Server    ${PRJ_TITLE}
    [Teardown]    Delete Data Science Project         ${PRJ_TITLE}


*** Keywords ***
Pipelines Suite Setup
    [Documentation]    Sets global test variables, create a DS project and a data connection
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}

    Create Data Science Project    title=${PRJ_TITLE}
    ...    description=${PRJ_DESCRIPTION}
    Projects.Move To Tab    Data connections
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-ds-pipelines

    Create Pipelines ConfigMap With Custom Pip Index Url And Trusted Host    ${PRJ_TITLE}

Pipelines Suite Teardown
    [Documentation]    Deletes the test project which automatically triggers the
    ...                deletion of any pipeline resource contained in it
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown

# robocop: disable:too-many-calls-in-keyword
Verify DSPv1 Pipeline Run Deployment Is Successful
    [Documentation]    Verifies the correct deployment of the test pipeline run in the rhods namespace.
    ...                It checks all the expected pods for the "iris" test pipeline run used in the TC.
    [Arguments]    ${project_title}    ${workflow_name}
    ${namespace}=    Get Openshift Namespace From Data Science Project
    ...    project_title=${project_title}
    @{data_prep}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=tekton.dev/taskRun=${workflow_name}-data-prep
    ${containerNames}=  Create List    step-main    step-output-taskrun-name
    ...    step-copy-results-artifacts    step-move-all-results-to-tekton-home    step-copy-artifacts
    ${podStatuses}=    Create List    Succeeded
    ${containerStatuses}=  Create List        terminated    terminated
    ...    terminated    terminated    terminated
    Verify Deployment    ${data_prep}  1  5  ${containerNames}    ${podStatuses}    ${containerStatuses}
    @{train_model}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=tekton.dev/taskRun=${workflow_name}-train-model
    ${containerNames}=  Create List    step-main    step-output-taskrun-name
    ...    step-copy-results-artifacts    step-move-all-results-to-tekton-home    step-copy-artifacts
    ${podStatuses}=    Create List    Succeeded
    ${containerStatuses}=  Create List        terminated    terminated
    ...    terminated    terminated    terminated
    Verify Deployment    ${train_model}  1  5  ${containerNames}    ${podStatuses}    ${containerStatuses}
    @{eval_model}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=tekton.dev/taskRun=${workflow_name}-evaluate-model
    ${containerNames}=  Create List    step-main    step-copy-artifacts
    ${podStatuses}=    Create List    Succeeded
    ${containerStatuses}=  Create List        terminated    terminated
    ...    terminated    terminated    terminated
    Verify Deployment    ${eval_model}  1  2  ${containerNames}    ${podStatuses}    ${containerStatuses}
    @{valid_model}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=tekton.dev/taskRun=${workflow_name}-validate-model
    ${containerNames}=  Create List    step-main
    ${podStatuses}=    Create List    Succeeded
    ${containerStatuses}=  Create List        terminated    terminated
    ...    terminated    terminated    terminated
    Verify Deployment    ${valid_model}  1  1  ${containerNames}    ${podStatuses}    ${containerStatuses}

Verify Data Science Parameter From A Duplicated Run Are The Same From The Compiled File
    [Documentation]    Verify Data Science Parameter From A Duplicated Run Are The Same From The Compiled File
    ${input_parameters}=    Get Pipeline Run Duplicate Parameters    ${PIPELINE_TEST_RUN_BASENAME}
    # look for spec.params inside ${PIPELINE_TEST_FILEPATH} source code
    Should Contain    ${input_parameters}    model_obc
    Should Contain    ${input_parameters}    iris-model

