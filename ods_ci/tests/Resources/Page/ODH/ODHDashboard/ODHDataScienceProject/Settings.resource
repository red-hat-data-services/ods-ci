*** Settings ***
Documentation    Collection of keywords for Settings tab
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${TRUSTYAI_CHECKBOX_XP}=             xpath=//input[@id="trustyai-service-installation"]


*** Keywords ***
Enable TrustyAI Checkbox
    [Documentation]    Enables TrustyAI Service Checkbox in DS Project Settings page
    Run Keyword And Continue On Failure     Wait Until Page Contains Element    xpath://div[text()='Model Bias']
    SeleniumLibrary.Select Checkbox    ${TRUSTYAI_CHECKBOX_XP}
    SeleniumLibrary.Checkbox Should Be Selected  xpath=//input[@id="trustyai-service-installation"]

Verify TrustyAI Checkbox is Disabled
    [Documentation]   Verified Enables TrustyAI Service Checkbox is disabled DS Project Settings page
    Run Keyword And Continue On Failure     Wait Until Page Contains Element    xpath://div[text()='Model bias']
    Page Should Contain Element
    ...    xpath://input[@id="trustyai-service-installation"][@disabled=""]
