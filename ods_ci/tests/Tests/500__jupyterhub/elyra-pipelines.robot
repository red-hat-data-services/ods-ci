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
${PROPERTIES_PANEL_BTN} =    //div[@class="toolbar-right-bar"]//button[@class="bx--btn bx--btn--ghost"]
${PIPELINE_FAILED_RUN} =    //*[local-name() = 'svg'][@style="color: rgb(213, 0, 0); height: 18px; width: 18px;"]
${PIPELINE_SUCCESSFUL_RUN} =     //*[local-name() = 'svg'][@style="color: rgb(52, 168, 83); height: 18px; width: 18px;"]


*** Test Cases ***
Verify Pipeline Is Displayed Correctly
    [Documentation]    
    [Tags]    Sanity    Tier1
    ...       ODS-XXXX
    [Setup]    Elyra Pipelines SDS Setup
    # Until https://github.com/elyra-ai/examples/pull/120 is merged
    Clone Git Repository And Open    https://github.com/lugi0/examples    examples/pipelines/run-generic-pipelines-on-kubeflow-pipelines/hello-generic-world.pipeline
    #Clone Git Repository And Open    https://github.com/elyra-ai/examples    examples/pipelines/run-generic-pipelines-on-kubeflow-pipelines/hello-generic-world.pipeline
    Verify Hello World Pipeline Elements

Verify Pipeline Can Be Submitted And Runs Correctly
    [Documentation]
    [Tags]
    # Assumes there's already a runtime config with correct values called `test`
    ${runtime_config_name} =    Set Variable    test

    # Open Properties menu and set runtime image
    Click Element    xpath=${PROPERTIES_PANEL_BTN}
    Wait Until Page Contains Element    xpath=//div[.="Pipeline Properties"]
    Click Element    xpath=//div[.="Pipeline Properties"]
    Wait Until Page Contains Element    xpath=//div[@id="root_pipeline_defaults_runtime_image"]
    Click Element    xpath=//select[@id="root_pipeline_defaults_runtime_image"]
    Click Element    xpath=//option[.="Datascience with Python 3.8 (UBI8)"]
    Click Element    xpath=${PROPERTIES_PANEL_BTN}
    Click Element    xpath=//div[contains(@class, 'save-action')]/button
    Wait Until Page Contains    Saving started
    Wait Until Page Contains    Saving completed

    #Click on Run
    Click Element    xpath=//button[@aria-label="Run Pipeline"]
    Wait Until Page Contains Element    xpath=//form[@class="elyra-dialog-form"]

    #Select Platform: Kubeflow Pipelines
    Click Element    xpath=//form[@class="elyra-dialog-form"]//select[@id="runtime_platform"]
    Click Element    xpath=//form[@class="elyra-dialog-form"]//select[@id="runtime_platform"]/option[@value="KUBEFLOW_PIPELINES"]

    #Select Runtime Config: Custom one called `test
    Wait Until Page Contains Element   xpath=//form[@class="elyra-dialog-form"]//select[@id="runtime_config"]
    Click Element    xpath=//form[@class="elyra-dialog-form"]//select[@id="runtime_config"]
    Click Element    xpath=//form[@class="elyra-dialog-form"]//select[@id="runtime_config"]/option[@value="${runtime_config_name}"]

    #Click Ok
    Click Element    xpath=//button[.="OK"]

    #Wait for the Pipeline to be submitted, switch to kfp page
    Wait Until Page Contains Element    xpath=//a[.="Run Details."]
    ${job_id} =    Get Text    xpath=//a[.="Run Details."]/../p
    Log To Console    ${job_id}
    # split string L: /bucketname/ R: working directory
    ${job_id} =    Fetch From Right    ${job_id}    /
    Log To Console    ${job_id}
    ${job_id} =    Fetch From Left    ${job_id}    working directory
    ${job_id} =    Strip String    ${job_id}
    Log To Console    ${job_id}
    Click Element    xpath=//a[.="Run Details."]
    ${handle} =    Switch Window    NEW
    ${oauth_prompt_visible} =  Is OpenShift OAuth Login Prompt Visible
    IF  ${oauth_prompt_visible}  Click Button  Log in with OpenShift
    ${login-required} =  Is OpenShift Login Visible
    IF  ${login-required}  Login To Openshift  ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize jupyterhub service account
    WHILE    True    limit=30
        Wait Until Page Contains Element    xpath=//span[@title="${job_id}"]    timeout=30s
        ${failed} =    Run Keyword And Return Status    Page Should Contain Element    //span[@title="${job_id}"]${PIPELINE_FAILED_RUN}
        ${passed} =    Run Keyword And Return Status    Page Should Contain Element    //span[@title="${job_id}"]${PIPELINE_SUCCESSFUL_RUN}
        IF  ${failed}==False and ${passed}==True
            BREAK
        ELSE IF  ${failed}==True and ${passed}==False
            Fail
        END
        Sleep    10s
        Reload Page
    END
    # Need to refresh page to see updated status
    # Wait Until Page Contains Element    xpath=//span[@title="${job_id}"]${PIPELINE_SUCCESSFUL_RUN}    timeout=300s

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
    Spawn Notebook With Arguments    image=s2i-generic-data-science-notebook    version=ElyraPR64

Verify Hello World Pipeline Elements
    [Documentation]
    Wait Until Page Contains Element    xpath=${SVG_CANVAS}
    Maybe Migrate Pipeline
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Load weather data"]
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 1 - Data Cleaning.ipynb"]
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 2 - Data Analysis.ipynb"]
    Page Should Contain Element    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}//span[.="Part 3 - Time Series Forecasting.ipynb"]

Maybe Migrate Pipeline
    [Documentation]
    ${popup} =    Run Keyword And Return Status    Page Should Contain Element    //div[.="Migrate pipeline?"]
    IF    ${popup}==True
        Click Element    //button[.="OK"]
        Click Element    xpath=//div[contains(@class, 'save-action')]/button
        Wait Until Page Contains    Saving started
        Wait Until Page Contains    Saving completed
    END