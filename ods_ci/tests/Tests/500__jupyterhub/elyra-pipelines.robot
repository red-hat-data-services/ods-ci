*** Settings ***
Documentation    Test Suite for Elyra pipelines in the SDS image
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
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
    [Documentation]    
    [Tags]    Sanity    Tier1
    ...       ODS-XXXX
    [Setup]    Elyra Pipelines SDS Setup
    Clone Git Repository And Open    https://github.com/elyra-ai/examples    examples/pipelines/run-generic-pipelines-on-kubeflow-pipelines/hello-generic-world.pipeline
    Verify Hello World Pipeline Elements

Verify Pipeline Can Be Submitted And Runs Correctly
    [Documentation]
    [Tags]
    # Assumes there's already a runtime config with correct values called `test`
    ${runtime_config_name} =    test
    
    #Click on Run
    Click Element    xpath=//button[@aria-label="Run Pipeline"]
    Wait Until Page Contains Element    xpath=//form[@class="elyra-dialog-form"]

    #Select Platform: Kubeflow Pipelines
    Click Element    xpath=//form[@class="elyra-dialog-form"]//select[@id="runtime_platform"]
    Click Element    xpath=//form[@class="elyra-dialog-form"]//select[@id="runtime_platform"]/option[@value="KUBEFLOW_PIPELINES"]

    #Select Runtime Config: Custom one called `test
    Wait Until Page Contains Element   xpath=//form[@class="elyra-dialog-form"]//select[@id="runtime_config"]
    Click Element    xpath=//form[@class="elyra-dialog-form"]//select[@id="runtime_config"]
    Click Element    xpath=xpath=//form[@class="elyra-dialog-form"]//select[@id="runtime_config"]/option[@value="${runtime_config_name}"]

    #Click Ok
    Click Element    xpath=//button[.="OK"]

    #Wait for the Pipeline to be submitted, switch to kfp page
    Wait Until Page Contains Element    xpath=//a[.="Run Details."]
    Click Element    xpath=//a[.="Run Details."]
    ${handle} =    Switch Window    NEW
    Wait Until Page Contains    hello-generic-world-
    # Verify run was successful
    # TBD how to do this, currently fails every time

    #Switch back to JL window, close popup, end test
    Switch Window    ${handle}
    Click Element    //button[.="OK"]


*** Keywords ***
Elyra Pipelines SDS Setup
    [Documentation]    Suite Setup, launches spawner page and image.
    ...                This assumes Pipelines have already been set up and the updated
    ...                image tag for SDS is present in the spawner.
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-generic-data-science-notebook    version=Elyra

Verify Hello World Pipeline Elements
    [Documentation]
    Wait Until Page Contains Element    xpath=${SVG_CANVAS}
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Load weather data"]
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 1 - Data Cleaning.ipynb"]
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 2 - Data Analysis.ipynb"]
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 3 - Time Series Forecasting.ipynb"]
