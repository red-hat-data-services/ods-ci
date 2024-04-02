*** Settings ***
Documentation    Test Suite for Elyra pipelines in workbenches
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/Elyra.resource
Resource         ../../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workbenches.resource
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Storages.resource
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Pipelines.resource
Library          Screenshot
Library          DebugLibrary
Library          JupyterLibrary
Test Tags        DataSciencePipelines
Suite Setup      Elyra Pipelines Suite Setup
Suite Teardown   Elyra Pipelines Suite Teardown


*** Variables ***
${SVG_CANVAS} =    //*[name()="svg" and @class="svg-area"]
${SVG_INTERACTABLE} =    /*[name()="g" and @class="d3-canvas-group"]
${SVG_PIPELINE_NODES} =    /*[name()="g" and @class="d3-nodes-links-group"]
${SVG_SINGLE_NODE} =    /*[name()="g" and contains(@class, "d3-draggable")]
${PRJ_TITLE} =    elyra-test-project
${PRJ_DESCRIPTION} =    testing Elyra pipeline functionality
${PV_NAME} =    ods-ci-pv-elyra
${PV_DESCRIPTION} =    ods-ci-pv-elyra is a PV created to test Elyra in workbenches
${PV_SIZE} =    2
${ENVS_LIST} =    ${NONE}
${DC_NAME} =    elyra-s3
@{IMAGE_LIST}    PyTorch    TensorFlow    TrustyAI


*** Test Cases ***
Verify Pipeline Is Displayed Correctly In Standard Data Science Workbench
    [Documentation]    Loads an example Elyra pipeline and confirms the Elyra web UI displays it correctly
    [Tags]    Sanity    Tier1
    ...       ODS-2197      RunThisTest
    [Setup]    Elyra Pipelines SDS Setup
    Create Workbench    workbench_title=elyra-sds    workbench_description=Elyra test
    ...                 prj_title=${PRJ_TITLE}    image_name=Standard Data Science  deployment_size=Small
    ...                 storage=Persistent  pv_existent=${FALSE}
    ...                 pv_name=${PV_NAME}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    ...                 envs=${ENVS_LIST}
    Start Workbench     workbench_title=elyra-sds    timeout=400s
    Launch And Access Workbench    workbench_title=elyra-sds
    Clone Git Repository And Open    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main
    ...    ods-ci-notebooks-main/notebooks/500__jupyterhub/elyra/run-pipelines-on-data-science-pipelines/hello-generic-world.pipeline  # robocop: disable
    Verify Hello World Pipeline Elements

Verify Pipeline Can Be Submitted And Runs Correctly From Standard Data Science Workbench
    [Documentation]    Submits an example Elyra pipeline to be run by Data Science Pipelines and
    ...    Confirms that it runs correctly
    [Tags]    Sanity    Tier1
    ...       ODS-2199      RunThisTest
    Set Runtime Image In All Nodes    runtime_image=Datascience with Python 3.9 (UBI9)
    Run Pipeline
    Wait Until Page Contains Element    xpath=//a[.="Run Details."]    timeout=30s
    ${pipeline_run_name} =    Get Pipeline Run Name
    ${handle} =    Switch To Pipeline Execution Page

## TODO: modify it to use Pipeles > Runs
#    Verify Successful Pipeline Run Via Project UI   pipeline_run_name=${pipeline_run_name}
#    ...    pipeline_name=hello-generic-world    project_name=${PRJ_TITLE}

    Switch Window    ${handle}
    Click Element    //button[.="OK"]
    [Teardown]    Elyra Pipelines SDS Teardown

Verify Elyra Pipelines In SDS-Based Images
    [Documentation]    Runs the same Elyra test of the first two test cases in the other images based on SDS
    ...    (Tensorflow, Pytorch and TrustyAI)
    [Tags]    Sanity    Tier1
    ...       ODS-2271
    [Setup]    Elyra Pipelines SDS Setup
    FOR    ${img}    IN    @{IMAGE_LIST}
        Run Elyra Hello World Pipeline Test    ${img}
    END
    [Teardown]    Elyra Pipelines SDS Teardown


*** Keywords ***
Elyra Pipelines Suite Setup
    [Documentation]    Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Elyra Pipelines SDS Setup
    [Documentation]    Suite Setup, creates DS Project and opens it
    Launch Data Science Project Main Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ${to_delete} =    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-ds-pipelines
    Create Pipeline Server    dc_name=${DC_NAME}
    ...    project_title=${PRJ_TITLE}
    Wait Until Pipeline Server Is Deployed    project_title=${PRJ_TITLE}
    Create Env Var List If RHODS Is Self-Managed

Elyra Pipelines SDS Teardown
    [Documentation]    Closes the browser and deletes the DS Project created
    Close All Browsers
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}

Elyra Pipelines Suite Teardown
    [Documentation]    Closes the browser and performs RHOSi Teardown
    Close All Browsers
    RHOSi Teardown

Verify Hello World Pipeline Elements
    [Documentation]    Verifies that the example pipeline is displayed correctly by Elyra
    Wait Until Page Contains Element    xpath=${SVG_CANVAS}
    Maybe Migrate Pipeline
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Load weather data"]  # robocop: disable
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 1 - Data Cleaning.ipynb"]  # robocop: disable
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 2 - Data Analysis.ipynb"]  # robocop: disable
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 3 - Time Series Forecasting.ipynb"]  # robocop: disable

Create Env Var List If RHODS Is Self-Managed
    [Documentation]    If RHODS is running a self-managed environment, this keyword will create a dictionary containing
    ...    The required environment variables for Elyra to trust the endpoint SSL connection.
    ${self_managed} =    Is RHODS Self-Managed
    IF  ${self_managed}==${TRUE}
        ${env_vars_ssl} =    Create Dictionary
        ...    PIPELINES_SSL_SA_CERTS=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        ...    k8s_type=Config Map  input_type=Key / value
        ${list} =    Create List    ${env_vars_ssl}
        Set Suite Variable    ${ENVS_LIST}    ${list}
    END

Run Elyra Hello World Pipeline Test  # robocop: disable
    [Documentation]    Runs the same steps of the first two tests of this Suite, but on different images
    [Arguments]    ${img}
    Create Workbench    workbench_title=elyra_${img}    workbench_description=Elyra test
    ...                 prj_title=${PRJ_TITLE}    image_name=${img}  deployment_size=Small
    ...                 storage=Persistent  pv_existent=${FALSE}
    ...                 pv_name=${PV_NAME}_${img}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    ...                 envs=${ENVS_LIST}
    Start Workbench     workbench_title=elyra_${img}    timeout=300s
    Launch And Access Workbench    workbench_title=elyra_${img}
    Clone Git Repository And Open    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main
    ...    ods-ci-notebooks-main/notebooks/500__jupyterhub/elyra/run-pipelines-on-data-science-pipelines/hello-generic-world.pipeline  # robocop: disable
    Verify Hello World Pipeline Elements
    Set Runtime Image In All Nodes    runtime_image=Datascience with Python 3.9 (UBI9)
    Run Pipeline    pipeline_name=${img} Pipeline
    Wait Until Page Contains Element    xpath=//a[.="Run Details."]    timeout=30s
    ${pipeline_run_name} =    Get Pipeline Run Name
    Switch To Pipeline Execution Page
    Verify Successful Pipeline Run Via Pipelines Runs UI   pipeline_name=${img} Pipeline
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Stop Workbench    workbench_title=elyra_${img}
