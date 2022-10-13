*** Settings ***
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${WORKSPACE_CREATE_BTN_XP}=     xpath=//button[text()="Create data science workspace"]
${WRKSP_NAME_INPUT_XP}=               xpath=//input[@name="workspace-name"]
${WRKSP_DESCR_INPUT_XP}=               xpath=//input[@name="workspace-description"]


*** Keywords ***
Create Workspace
    [Documentation]     Creates a new workspace in a Data Science project. It assumes
    ...                 the DS Project details page is open
    [Arguments]     ${name}   ${description}=${EMPTY}   ${image_name}=Minimal Python
    Click Button    ${WORKSPACE_CREATE_BTN_XP}
    Wait Until Page Contains Element    ${WRKSP_NAME_INPUT_XP}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    Input Text    ${WRKSP_NAME_INPUT_XP}    ${name}
    Input Text    ${WRKSP_DESCR_INPUT_XP}    ${description}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    Select Jupyter Image    image_name=${image_name}
    # Wait Until Element Is Enabled    ${GENERIC_CREATE_BTN_XP}
    # Click Button    ${GENERIC_CREATE_BTN_XP}
    # Wait Until Modal Disappear

Select Jupyter Image
    [Arguments]     ${image_name}
    Click Button    xpath=//button[@aria-label="Options menu"]
    Wait Until Page Contains Element    xpath=//ul[@id="workspace-image-stream-selection"]
    Select From List By Value       xpath=//ul[@id="workspace-image-stream-selection"]      Minimal Python
    # Click Element    xpath=//li/button/span[text()="Minimal Python"]
