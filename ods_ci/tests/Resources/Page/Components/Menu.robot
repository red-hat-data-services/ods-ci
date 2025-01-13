*** Settings ***
Resource    ../ODH/ODHDashboard/ODHDashboard.robot
Library     String
Library     JupyterLibrary


*** Variables ***
${SIDEBAR_XP}    //div[@id="page-sidebar"]


*** Keywords ***
Navigate To Page
   [Arguments]
   ...    ${menu}
   ...    ${submenu}=${NONE}
   ...    ${timeout}=10s
   Wait Until Element Is Visible    ${SIDEBAR_XP}    timeout=${timeout}
   Wait Until Page Contains    ${menu}
   ${menu}=     Set Variable If     "${menu}" == "Deployed models"      Model Serving    ${menu}
   IF  "${submenu}" == "${NONE}"    Run Keyword And Return
   ...     Click Button    ${SIDEBAR_XP}//button[text()="${menu}"]
   ${is_menu_expanded}=    Menu.Is Menu Expanded  ${menu}
   IF    "${is_menu_expanded}" == "false"    Menu.Click Menu   ${menu}
   Wait Until Page Contains    ${submenu}
   Menu.Click Submenu    ${submenu}
   Run Keyword And Ignore Error    Wait For Dashboard Page Title    ${submenu}

Click Menu
   [Arguments]
   ...   ${menu}
   Click Element    ${SIDEBAR_XP}//button[text()="${menu}"]

Click Submenu
   [Arguments]
   ...   ${submenu}
   Click Element   ${SIDEBAR_XP}//a[text()="${submenu}"]

Is Menu Expanded
   [Arguments]
   ...   ${menu}
   ${is_menu_expanded}=    Get Element Attribute   ${SIDEBAR_XP}//button[text()="${menu}"]   attribute=aria-expanded
   RETURN    ${is_menu_expanded}

Page Should Contain Menu
   [Arguments]  ${menu}
   Page Should Contain Element    ${SIDEBAR_XP}//button[text()="${menu}"]

