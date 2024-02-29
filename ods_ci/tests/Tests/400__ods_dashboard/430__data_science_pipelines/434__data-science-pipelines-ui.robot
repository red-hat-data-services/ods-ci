*** Settings ***
Documentation      Suite to test Data Science Pipeline feature using RHODS UI
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Pipelines.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Resource           ../../../Resources/Page/Operators/OpenShiftPipelines.resource
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
${PIPELINE_TEST_FILEPATH}=    ods_ci/tests/Resources/Files/pipeline-samples/iris_pipeline_compiled.yaml
${PIPELINE_TEST_RUN_BASENAME}=    ${PIPELINE_TEST_BASENAME}-run


*** Test Cases ***
Verify Pipeline Server Creation When Using Internal Database
    [Documentation]     Verifies multiple users can create pipeline server
    [Tags]    Tier2
    ...       RHOAIENG-2099

    FOR  ${ITERATION}      IN   RANGE   10
        Create Pipeline Server    dc_name=${DC_NAME}
        ...    project_title=${PRJ_TITLE}
        ${status}=      Run Keyword And Return Status       Wait Until Import Pipeline button is enabled
        Log     ${ITERATION}  #Iteration which the creation failed
        Wait Until Page Contains        No pipelines        timeout=7s
        ODHDataSciencePipelines.Delete Pipeline Server    ${PRJ_TITLE}
        Exit For Loop If    '${status}'=='FALSE'
    END


Verify User Can Create, Run and Delete A DS Pipeline From DS Project Details Page    # robocop: disable
    [Documentation]    Verifies user are able to create and execute a DS Pipeline leveraging on
    ...                DS Project UI
    [Tags]    Smoke
    ...       ODS-2206    ODS-2226    ODS-2633

    Create Pipeline Server    dc_name=${DC_NAME}
    ...    project_title=${PRJ_TITLE}
    Wait Until Pipeline Server Is Deployed    project_title=${PRJ_TITLE}
    Verify There Is No "Error Displaying Pipelines" After Creating Pipeline Server

    # Import pipeline but cancel dialog
    Import Pipeline    name=${PIPELINE_TEST_NAME}
    ...    description=${PIPELINE_TEST_DESC}
    ...    project_title=${PRJ_TITLE}
    ...    filepath=${PIPELINE_TEST_FILEPATH}
    ...    press_cancel=${TRUE}

    Pipeline Should Not Be Listed    pipeline_name=${PIPELINE_TEST_NAME}
    ...    pipeline_description=${PIPELINE_TEST_DESC}

    # Import pipeline
    Import Pipeline    name=${PIPELINE_TEST_NAME}
    ...    description=${PIPELINE_TEST_DESC}
    ...    project_title=${PRJ_TITLE}
    ...    filepath=${PIPELINE_TEST_FILEPATH}
    ...    press_cancel=${FALSE}

    ## TODO: Fix these verifications
    ##Pipeline Context Menu Should Be Working    pipeline_name=${PIPELINE_TEST_NAME}
    ##Pipeline Yaml Should Be Readonly    pipeline_name=${PIPELINE_TEST_NAME}

    Open Data Science Project Details Page    ${PRJ_TITLE}
    Pipeline Should Be Listed    pipeline_name=${PIPELINE_TEST_NAME}
    ...    pipeline_description=${PIPELINE_TEST_DESC}

    # Create run but cancel dialog
    ${workflow_name}=    Create Pipeline Run    name=${PIPELINE_TEST_RUN_BASENAME}
    ...    pipeline_name=${PIPELINE_TEST_NAME}    run_type=Immediate
    ...    press_cancel=${TRUE}

    # Create run
    Open Data Science Project Details Page    ${PRJ_TITLE}
    ${workflow_name}=    Create Pipeline Run    name=${PIPELINE_TEST_RUN_BASENAME}
    ...    pipeline_name=${PIPELINE_TEST_NAME}     run_type=Immediate

    Verify Pipeline Run Is Completed    ${PIPELINE_TEST_RUN_BASENAME}
    ${data_prep_log}=    Get Pipeline Run Step Log    data-prep
    # deterministic: "Initial Dataset:" came from a print inside the python code.
    Should Contain    ${data_prep_log}    Initial Dataset:

    Verify Data Science Parameter From A Duplicated Run Are The Same From The Compiled File

    ODHDataSciencePipelines.Delete Pipeline Run       ${PIPELINE_TEST_RUN_BASENAME}    ${PIPELINE_TEST_NAME}
    ODHDataSciencePipelines.Delete Pipeline           ${PIPELINE_TEST_NAME}
    ODHDataSciencePipelines.Delete Pipeline Server    ${PRJ_TITLE}
    [Teardown]    Delete Data Science Project         ${PRJ_TITLE}

Verify Pipeline Metadata Pods Are Not Deployed When Running Pipelines
    [Documentation]    Verifies that metadata pods are not created when running a data science pipeline,
    ...         as this feature is currently disabled.
    [Tags]    Sanity
    ...       Tier1
    Open Data Science Project Details Page    project_title=${PRJ_TITLE}
    Create Pipeline Server    dc_name=${DC_NAME}
    ...    project_title=${PRJ_TITLE}
    Wait Until Pipeline Server Is Deployed    project_title=${PRJ_TITLE}
    Verify There Is No "Error Displaying Pipelines" After Creating Pipeline Server
    Import Pipeline    name=${PIPELINE_TEST_NAME}
    ...    description=${PIPELINE_TEST_DESC}
    ...    project_title=${PRJ_TITLE}
    ...    filepath=${PIPELINE_TEST_FILEPATH}
    Pipeline Should Be Listed    pipeline_name=${PIPELINE_TEST_NAME}
    ...    pipeline_description=${PIPELINE_TEST_DESC}

    ${workflow_name}=    Create Pipeline Run    name=${PIPELINE_TEST_RUN_BASENAME}
    ...    pipeline_name=${PIPELINE_TEST_NAME}    run_type=Immediate

    ## TODO: fix keywords checking job status to use Pipelines > Jobs
    ## instead of the Projec Details Page
    SeleniumLibrary.Wait Until Page Contains       Running     timeout=10s
    SeleniumLibrary.Wait Until Page Contains       Completed   timeout=10m

    @{pods} =    Oc Get    kind=Pod    namespace=${PRJ_TITLE}
    FOR    ${pod}    IN    @{pods}
        Log    ${pod['metadata']['name']}
        Should Not Contain    ${pod['metadata']['name']}    ds-pipeline-metadata
    END
    [Teardown]    Delete Data Science Project    ${PRJ_TITLE}

*** Keywords ***
Pipelines Suite Setup    # robocop: disable
    [Documentation]    Sets global test variables, create a DS project and a data connection
    Set Library Search Order    SeleniumLibrary
    # TODO: Install Pipeline only if it does not already installed
    Install Red Hat OpenShift Pipelines
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}

    Create Data Science Project    title=${PRJ_TITLE}
    ...    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-ds-pipelines
    RHOSi Setup

Pipelines Suite Teardown
    [Documentation]    Deletes the test project which automatically triggers the
    ...                deletion of any pipeline resource contained in it
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown

Verify Pipeline Run Deployment Is Successful    # robocop: disable
    [Documentation]    Verifies the correct deployment of the test pipeline run in the rhods namespace.
    ...                It checks all the expected pods for the "iris" test pipeline run used in the TC.
    [Arguments]    ${project_title}    ${workflow_name}
    ${namespace}=    Get Openshift Namespace From Data Science Project
    ...    project_title=${PRJ_TITLE}
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
