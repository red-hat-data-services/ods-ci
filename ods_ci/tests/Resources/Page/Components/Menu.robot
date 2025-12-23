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
   ...    ${subsubmenu}=${NONE}
   ...    ${timeout}=10s
   Wait Until Element Is Visible    ${SIDEBAR_XP}    timeout=${timeout}
   Wait Until Page Contains    ${menu}
   ${menu}=     Set Variable If     "${menu}" == "Deployed models"      Model Serving    ${menu}
   IF  "${submenu}" == "${NONE}"    Run Keyword And Return
   ...     Click Menu    ${menu}

   ${is_menu_expanded}=    Menu.Is Menu Expanded  ${menu}
   IF    "${is_menu_expanded}" == "false"    Menu.Click Menu   ${menu}
   Wait Until Page Contains    ${submenu}

   ${is_menu_expanded}=    Menu.Is Menu Expanded  ${submenu}
   IF    "${is_menu_expanded}" == "false"    Menu.Click Menu   ${submenu}

   IF    "${subsubmenu}" != "${NONE}"
       # 3-level navigation: navigate to subsubmenu
       Wait Until Page Contains    ${subsubmenu}
       Click Menu    ${subsubmenu}
       Run Keyword And Ignore Error    Wait For Dashboard Page Title    ${subsubmenu}
   ELSE
       # 2-level navigation: we're done at submenu level
       Run Keyword And Ignore Error    Wait For Dashboard Page Title    ${submenu}
   END

Click Menu
   [Arguments]
   ...   ${menu}
   Click Element   ${SIDEBAR_XP}//a[normalize-space(.)="${menu}"]|${SIDEBAR_XP}//button[normalize-space(.)="${menu}"]

Is Menu Expanded
   [Arguments]
   ...   ${menu}
   # Only buttons have aria-expanded attribute, links are not expandable
   ${is_button}=    Run Keyword And Return Status    Page Should Contain Element    ${SIDEBAR_XP}//button[normalize-space(.)="${menu}"]
   IF    ${is_button}
       ${is_menu_expanded}=    Get Element Attribute   ${SIDEBAR_XP}//button[normalize-space(.)="${menu}"]   attribute=aria-expanded
       RETURN    ${is_menu_expanded}
   ELSE
       # Links are not expandable, return "false"
       RETURN    false
   END

Page Should Contain Menu
   [Arguments]  ${menu}
   Page Should Contain Element    ${SIDEBAR_XP}//button[normalize-space(.)="${menu}"]

