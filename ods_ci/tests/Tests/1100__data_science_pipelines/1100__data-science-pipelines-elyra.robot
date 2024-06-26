*** Settings ***
Documentation    Test Suite for Elyra pipelines in workbenches
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/Elyra.resource
Resource         ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workbenches.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Storages.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Pipelines.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Library          Screenshot
Library          String
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
${PRJ_TITLE} =    elyra-test
${PRJ_DESCRIPTION} =    testing Elyra pipeline functionality
${PV_NAME} =    ods-ci-pv-elyra
${PV_DESCRIPTION} =    ods-ci-pv-elyra is a PV created to test Elyra in workbenches
${PV_SIZE} =    2
${ENVS_LIST} =    ${NONE}
${DC_NAME} =    elyra-s3


*** Test Cases ***
Verify Pipelines Integration With Elyra When Using Standard Data Science Image
    [Documentation]    Verifies that a workbench using the Standard Data Science Image can be used to
    ...    create and run a Data Science Pipeline
    [Tags]    Sanity    Tier1
    ...       ODS-2197
    [Timeout]    10m
    Verify Pipelines Integration With Elyra Running Hello World Pipeline Test
    ...    img=Standard Data Science
    ...    runtime_image=Datascience with Python 3.9 (UBI9)

Verify Pipelines Integration With Elyra When Using Standard Data Science Based Images
    [Documentation]    Verifies that a workbench using an image based on the Standard Data Science Image
    ...    can be used to create and run a Data Science Pipeline
    ...    Note: this a templated test case
    ...    (more info at https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#test-templates)
    [Template]    Verify Pipelines Integration With Elyra Running Hello World Pipeline Test
    [Tags]        Tier1    ODS-2271
    [Timeout]     30m
    PyTorch       Datascience with Python 3.9 (UBI9)
    TensorFlow    Datascience with Python 3.9 (UBI9)
    TrustyAI      Datascience with Python 3.9 (UBI9)
    HabanaAI      Datascience with Python 3.8 (UBI8)


*** Keywords ***
Elyra Pipelines Suite Setup    # robocop: off=too-many-calls-in-keyword
    [Documentation]    Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Data Science Project Main Page
    ${project_suffix} =    Generate Random String    3   [NUMBERS]
    Set Suite Variable    \${PRJ_TITLE}    ${PRJ_TITLE}-${project_suffix}
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ${to_delete} =    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-ds-pipelines
    Create Pipeline Server    dc_name=${DC_NAME}
    ...    project_title=${PRJ_TITLE}
    Wait Until Pipeline Server Is Deployed    project_title=${PRJ_TITLE}
    Sleep    15s    reason=Wait until pipeline server is detected by dashboard

Elyra Pipelines Suite Teardown
    [Documentation]    Closes the browser and performs RHOSi Teardown
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    Close All Browsers
    RHOSi Teardown

Verify Pipelines Integration With Elyra Running Hello World Pipeline Test     # robocop: off=too-many-calls-in-keyword
    [Documentation]    Creates and starts a workbench using ${img} and verifies that the Hello World sample pipeline
    ...    runs successfully
    [Arguments]    ${img}    ${runtime_image}
    Create Workbench    workbench_title=elyra_${img}    workbench_description=Elyra test
    ...                 prj_title=${PRJ_TITLE}    image_name=${img}  deployment_size=Small
    ...                 storage=Persistent  pv_existent=${FALSE}
    ...                 pv_name=${PV_NAME}_${img}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    ...                 envs=${ENVS_LIST}
    Start Workbench     workbench_title=elyra_${img}    timeout=300s
    Launch And Access Workbench    workbench_title=elyra_${img}
    Clone Git Repository And Open    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main
    ...    ods-ci-notebooks-main/notebooks/500__jupyterhub/pipelines/v2/elyra/run-pipelines-on-data-science-pipelines/hello-generic-world.pipeline  # robocop: disable
    Verify Hello World Pipeline Elements
    Set Runtime Image In All Nodes    runtime_image=${runtime_image}
    Run Pipeline    pipeline_name=${img} Pipeline
    Wait Until Page Contains Element    xpath=//a[.="Run Details."]    timeout=30s
    ${pipeline_run_name} =    Get Pipeline Run Name
    Switch To Pipeline Execution Page
    # We need to navigate to the page because the project name hold a state
    # In a fresh cluster, if not state found, it will select the first one
    # In this case, the first could not be the project created
    Menu.Navigate To Page    Data Science Pipelines    Runs
    Select Pipeline Project By Name    ${PRJ_TITLE}
    Log    ${pipeline_run_name}
    Verify Pipeline Run Is Completed    ${pipeline_run_name}    timeout=5m
    [Teardown]    Verify Pipelines Integration With Elyra Teardown    ${img}

Verify Pipelines Integration With Elyra Teardown
    [Documentation]    Closes all browsers and stops the running workbench
    [Arguments]    ${img}
    Close All Browsers
    Launch Data Science Project Main Page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}    tab_id=workbenches
    Stop Workbench    workbench_title=elyra_${img}

Verify Hello World Pipeline Elements
    [Documentation]    Verifies that the example pipeline is displayed correctly by Elyra
    Wait Until Page Contains Element    xpath=${SVG_CANVAS}     timeout=10s
    Maybe Migrate Pipeline
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Load weather data"]  # robocop: disable
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 1 - Data Cleaning.ipynb"]  # robocop: disable
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 2 - Data Analysis.ipynb"]  # robocop: disable
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 3 - Time Series Forecasting.ipynb"]  # robocop: disable

Select Pipeline Project By Name
    [Documentation]    Select the project by project name
    [Arguments]    ${project_name}
    ${project_menu}=    Set Variable    xpath://div[@data-testid="project-selector-dropdown"]
    Wait until Element is Visible    ${project_menu}   timeout=20
    Click Element    ${project_menu}
    Click Element    xpath://a[@role="menuitem" and text()="${project_name}"]
