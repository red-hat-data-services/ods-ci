*** Settings ***
Documentation    Keywords to interact with Elyra in JupyterLab
Resource         ../../LoginPage.robot
Library          SeleniumLibrary


*** Variables ***
${SVG_CANVAS} =    //*[name()="svg" and @class="svg-area"]
${SVG_INTERACTABLE} =    /*[name()="g" and @class="d3-canvas-group"]
${SVG_PIPELINE_NODES} =    /*[name()="g" and @class="d3-nodes-links-group"]
${SVG_SINGLE_NODE} =    /*[name()="g" and contains(@class, "d3-draggable")]
${PROPERTIES_PANEL_BTN} =    //div[@class="toolbar-right-bar"]//button[@class="bx--btn bx--btn--ghost"]
${ELYRA_DIALOG} =    //form[@class="elyra-dialog-form"]
${ELYRA_RUNTIME_PLATFORM} =    //select[@id="runtime_platform"]
${ELYRA_PIPELINE_NAME} =    //input[@id="pipeline_name"]
${ELYRA_RUNTIME_CONFIG} =    //select[@id="runtime_config"]


*** Keywords ***
Maybe Migrate Pipeline
    [Documentation]    Outdated pipelines need to be migrated to the newer Elyra version
    ${popup} =    Run Keyword And Return Status    Page Should Contain Element    //div[.="Migrate pipeline?"]
    IF    ${popup}==True
        Click Element    //button[.="OK"]
        Save Pipeline Changes
    END

# This functionality is currently bugged, disabling the keyword for the time being
# Set Runtime Image In Pipeline Properties
#     [Documentation]    Sets a default runtime image for the pipeline (currently bugged)
#     [Arguments]    ${runtime_image}=Datascience with Python 3.8 (UBI8)
#     Open Properties Panel
#     Click Element    xpath=//div[.="Pipeline Properties"]
#     Wait Until Page Contains Element    xpath=//div[@id="root_pipeline_defaults_runtime_image"]
#     Click Element    xpath=//select[@id="root_pipeline_defaults_runtime_image"]
#     Click Element    xpath=//option[.="${runtime_image}"]
#     Close Properties Panel
#     Save Pipeline Changes

Open Properties Panel
    [Documentation]    Opens the Pipeline/Node properties panel (if closed)
    ${panel_open} =    Run Keyword And Return Status    Page Should Contain Element
    ...    xpath=//div[.="Pipeline Properties"]
    IF    ${panel_open}==False
        Click Element    xpath=${PROPERTIES_PANEL_BTN}
        Wait Until Page Contains Element    xpath=//div[.="Pipeline Properties"]
    END

Close Properties Panel
    [Documentation]    Closes the Pipeline/Node properties panel (if open)
    ${panel_open} =    Run Keyword And Return Status    Page Should Contain Element
    ...    xpath=//div[.="Pipeline Properties"]
    IF    ${panel_open}==True
        Click Element    xpath=${PROPERTIES_PANEL_BTN}
        Wait Until Page Does Not Contain Element    xpath=//div[.="Pipeline Properties"]
    END

Save Pipeline Changes
    [Documentation]    Saves changes to the pipeline
    Click Element    xpath=//div[contains(@class, 'save-action')]/button
    Wait Until Page Contains    Saving started
    Wait Until Page Contains    Saving completed

Run Pipeline
    [Documentation]    Submits the pipeline for a run
    [Arguments]    ${runtime_config}=Data Science Pipeline    ${pipeline_name}=hello-generic-world
    Click Run Button
    Set Pipeline Name    ${pipeline_name}
    Select Runtime Config    ${runtime_config}
    Click Element    xpath=//button[.="OK"]

Click Run Button
    [Documentation]    Click the `Run` button in Elyra
    Click Element    xpath=//button[@aria-label="Run Pipeline"]
    Wait Until Page Contains Element    xpath=${ELYRA_DIALOG}

# This selector has been removed, leaving the keyword here in case it is added back in
# Select Runtime Platform
#     [Documentation]    Selects the runtime platform when submitting a pipeline run
#     [Arguments]    ${runtime_platform}
#     Wait Until Page Contains Element    xpath=${ELYRA_DIALOG}${ELYRA_RUNTIME_PLATFORM}
#     Click Element    xpath=${ELYRA_DIALOG}${ELYRA_RUNTIME_PLATFORM}
#     Click Element
#     ...    xpath=${ELYRA_DIALOG}${ELYRA_RUNTIME_PLATFORM}/option[@value="${runtime_platform}"]

Set Pipeline Name
    [Documentation]    Changes the pipeline name when submitting it to be run, if the name is different from the default
    [Arguments]    ${pipeline_name}
    Wait Until Page Contains Element   xpath=${ELYRA_DIALOG}${ELYRA_PIPELINE_NAME}
    ${current_name} =    Get Element Attribute    xpath=${ELYRA_DIALOG}${ELYRA_PIPELINE_NAME}
    ...    value
    IF    "${pipeline_name}" != "${current_name}"
        Input Text    xpath=${ELYRA_DIALOG}${ELYRA_PIPELINE_NAME}    ${pipeline_name}
    END

Select Runtime Config
    [Documentation]    Selects the runtime config when submitting a pipeline run
    [Arguments]    ${runtime_config}=test
    Wait Until Page Contains Element   xpath=${ELYRA_DIALOG}${ELYRA_RUNTIME_CONFIG}
    Click Element    xpath=${ELYRA_DIALOG}${ELYRA_RUNTIME_CONFIG}
    Click Element
    ...    xpath=${ELYRA_DIALOG}${ELYRA_RUNTIME_CONFIG}/option[.="${runtime_config}"]

Get Pipeline Run Name
    [Documentation]    Gets the run ID after a pipeline is successfully submitted
    ${job_id} =    Get Text    xpath=//a[.="Run Details."]/../p
    ${job_id} =    Fetch From Right    ${job_id}    /
    ${job_id} =    Fetch From Left    ${job_id}    working directory
    ${job_id} =    Strip String    ${job_id}
    RETURN    ${job_id}

Switch To Pipeline Execution Page
    [Documentation]    Moves to the Kubeflow Pipelines page for the details of a pipeline run
    Click Element    xpath=//a[.="Run Details."]
    ${handle} =    Switch Window    NEW
    ${oauth_prompt_visible} =  Is OpenShift OAuth Login Prompt Visible
    IF  ${oauth_prompt_visible}  Click Button  Log in with OpenShift
    ${login-required} =  Is OpenShift Login Visible
    IF  ${login-required}  Login To Openshift  ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize jupyterhub service account
    RETURN    ${handle}

Set Runtime Image In All Nodes
    [Documentation]    Sets the runtime image in the properties of all nodes of a pipeline
    [Arguments]    ${runtime_image}=Datascience with Python 3.8 (UBI8)
    @{tmp} =    Get WebElements    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}
    FOR    ${index}    ${node}    IN ENUMERATE    @{tmp}
        @{nodes} =    Get WebElements    xpath=${SVG_CANVAS}${SVG_INTERACTABLE}${SVG_PIPELINE_NODES}${SVG_SINGLE_NODE}
        Log    ${nodes}[${index}]
        Set Runtime Image In Node Properties   ${nodes}[${index}]    ${runtime_image}
    END

Set Runtime Image In Node Properties
    [Documentation]    Sets the runtime image in the properties of a pipeline node
    [Arguments]    ${node}    ${runtime_image}=Datascience with Python 3.8 (UBI8)
    Click Element    ${node}
    Open Properties Panel
    Click Element    xpath=//div[@title="Edit node properties"]
    Wait Until Page Contains Element    xpath=//div[@id="root_component_parameters_runtime_image"]
    Click Element    xpath=//select[@id="root_component_parameters_runtime_image"]
    Click Element    xpath=//option[.="${runtime_image}"]
    Close Properties Panel
    Save Pipeline Changes
