*** Settings ***
Resource      ../../../Page/Components/Components.resource
Resource       ../../../Common.robot

*** Variables ***
${DS_PROJECT_XP}=   //h1[text()="Data science projects"]
*** Keywords ***
Verify Data Science Projects Page Is Available
    [Documentation]    Verifies submenu Settings > Cluster settings" is visible
    Page Should Contain    Settings
    Menu.Navigate To Page    Settings    Data Science Projects
    Wait Until Page Contains    View your existing projects or create new projects.    timeout=30
    Wait Until Page Contains Element    ${DS_PROJECT_XP}    timeout=30
