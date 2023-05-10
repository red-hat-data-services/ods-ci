*** Settings ***
Documentation    Test Suite for Elyra pipelines in the SDS image
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/Elyra.resource
Resource         ../../Resources/Page/ODH/Pipelines/Pipelines.resource
Resource         ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Library          Screenshot
Library          DebugLibrary
Library          JupyterLibrary
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Variables ***
${SVG_CANVAS} =    //*[name()="svg" and @class="svg-area"]
${SVG_INTERACTABLE} =    /*[name()="g" and @class="d3-canvas-group"]
${SVG_PIPELINE_NODES} =    /*[name()="g" and @class="d3-nodes-links-group"]
${SVG_SINGLE_NODE} =    /*[name()="g" and contains(@class, "d3-draggable")]



*** Test Cases ***
Verify Pipeline Is Displayed Correctly
    [Documentation]    Loads an example Elyra pipeline and confirms the Web UI displays it correctly
    [Tags]    Sanity    Tier1
    ...       ODS-XXXX
    [Setup]    Elyra Pipelines SDS Setup
    # Until https://github.com/elyra-ai/examples/pull/120 is merged
    Clone Git Repository And Open    https://github.com/lugi0/examples    examples/pipelines/run-generic-pipelines-on-kubeflow-pipelines/hello-generic-world.pipeline
    #Clone Git Repository And Open    https://github.com/elyra-ai/examples    examples/pipelines/run-generic-pipelines-on-kubeflow-pipelines/hello-generic-world.pipeline
    Verify Hello World Pipeline Elements

Verify Pipeline Can Be Submitted And Runs Correctly
    [Documentation]    Submits an example Elyra pipeline to be run by Kubeflow and
    ...    Confirms that it runs correctly
    [Tags]    Sanity    Tier1
    ...       ODS-XXXX
    # Assumes there's already a runtime config with correct values called `test`
    # Set Runtime Image In Pipeline Properties <- Currently bugged
    Set Runtime Image In All Nodes    runtime_image=Datascience with Python 3.8 (UBI8)
    Run Pipeline    runtime_platform=KUBEFLOW_PIPELINES    runtime_config=test
    Wait Until Page Contains Element    xpath=//a[.="Run Details."]
    ${job_id} =    Get Pipeline Job ID
    ${handle} =    Switch To Pipeline Execution Page
    Verify Successful Pipeline Run    ${job_id}
    Switch Window    ${handle}
    Click Element    //button[.="OK"]


*** Keywords ***
Elyra Pipelines SDS Setup
    [Documentation]    Suite Setup, launches spawner page and image.
    ...                This assumes Pipelines have already been set up and the updated
    ...                image tag for SDS is present in the spawner.
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-generic-data-science-notebook    version=ElyraPR64

Verify Hello World Pipeline Elements
    [Documentation]
    Wait Until Page Contains Element    xpath=${SVG_CANVAS}
    Maybe Migrate Pipeline
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Load weather data"]
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 1 - Data Cleaning.ipynb"]
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 2 - Data Analysis.ipynb"]
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 3 - Time Series Forecasting.ipynb"]
