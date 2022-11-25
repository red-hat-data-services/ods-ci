*** Settings ***
Documentation    Collection of keywords to interact with Model Serving
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot

*** Variables ***
${MS_HEADER_XP}=     xpath=//h1[text()="Deployed models"]

*** Keywords ***
Open Model Serving Home Page
    [Documentation]    Verifies submenu Settings > "Model Serving" is visible and navigates to page
    Page Should Contain    Model Serving
    Click Link      Model Serving
    Wait Until Page Contains    Manage and view the health and performance of your deployed models.    timeout=30
    Wait Until Page Contains Element    ${MS_HEADER_XP}    timeout=30
    Maybe Wait For Dashboard Loading Spinner Page

Serve Model
    [Documentation]
    [Arguments]    ${project_name}    ${model_name}    ${framework}    ${existing_data_connection}=${TRUE}
    ...    ${data_connection_name}    ${model_path}
    Click Button    Serve model
    Wait Until Page Contains    xpath://h1[.="Deploy model"]
    Select Project    ${project_name}
    Set Model Name    ${model_name}
    Select Framework    ${framework}
    IF    ${existing_data_connection}==${TRUE} 
        Select Radio Button    group_name=model-location    value=existing-data-connection-radio
        Select Existing Data Connection    ${data_connection_name}
        Set Folder Path    ${model_path}
    ELSE
        Select Radio Button    group_name=model-location    value=new-data-connection-radio
        # Set Up New Data Connection
    END
    Click Button    Configure

Select Project
    [Documentation]
    [Arguments]    ${project_name}
    Click Element    xpath://span[.="Project"]/../../..//button[@aria-label="Options menu"]
    Click Element    xpath://li/button[.="${project_name}"]

Set Model Name
    [Documentation]
    [Arguments]    ${model_name}

Select Framework
    [Documentation]
    [Arguments]    ${framework}
    Click Element    xpath://span[.="Model framework"]/../../..//button[@aria-label="Options menu"]
    Click Element    xpath://li/button[contains(., "${framework}")]


Select Existing Data Connection
    [Documentation]
    [Arguments]    ${data_connection_name}
    Click Element    xpath://span[.="Name"]/../../..//button[@aria-label="Options menu"]
    Click Element    xpath://li/button[.="${data_connection_name}"]

Set Folder Path
    [Documentation]
    [Arguments]    ${model_path}

Set Up New Data Connection
    [Documentation]
    [Arguments]