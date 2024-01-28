*** Settings ***
Documentation    Collection of keywords for Settings tab
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${TRUSTYAI_CHECKBOX_XP}=                  xpath=//input[@id="trustyai-service-installation"]
${TRUSTYAI_INSTALL_ALERT_XP}=        xpath=//div[@data-testid="trustyai-service-installed-alert"]


*** Keywords ***
Enable TrustyAI Checkbox
    [Documentation]    Enables TrustyAI Service Checkbox in DS Project Settings page
    Run Keyword And Continue On Failure     Wait Until Page Contains Element    xpath://div[text()='Model bias']
    Sleep  10s  reason=Wait until Settings page load
    Select Checkbox Using Id    id=trustyai-service-installation
    Wait Until Keyword Succeeds    5 min    30s
    ...    SeleniumLibrary.Checkbox Should Be Selected  xpath=//input[@id="trustyai-service-installation"]
    Page Should Contain Element     ${TRUSTYAI_INSTALL_ALERT_XP}//span[contains(text(),'Success alert')]

Verify TrustyAI Checkbox is Disabled
    [Documentation]   Verified Enables TrustyAI Service Checkbox is disabled DS Project Settings page
    Run Keyword And Continue On Failure     Wait Until Page Contains Element    xpath://div[text()='Model bias']
    Page Should Contain Element
    ...    xpath://input[@id="trustyai-service-installation"][@disabled=""]
