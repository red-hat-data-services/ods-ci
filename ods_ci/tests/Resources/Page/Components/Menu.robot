*** Settings ***
Library  JupyterLibrary
Library  String

*** Keywords ***
Navigate To Page
   [Arguments]
   ...    ${menu}
   ...    ${submenu}=${NONE}
   ...    ${timeout}=10s
   Wait Until Element Is Visible    //div[@id="page-sidebar"]    timeout=${timeout}
   Wait Until Page Contains    ${menu}
   ${menu}=    Set Variable If    "${menu}" == "Deployed models"    Model Serving    ${menu}
   IF  "${submenu}" == "${NONE}"    Run Keyword And Return
   ...    Click Link    ${menu}
   ${is_menu_expanded}=    Menu.Is Menu Expanded  ${menu}
   IF    "${is_menu_expanded}" == "false"    Menu.Click Menu   ${menu}
   Wait Until Page Contains    ${submenu}
   Menu.Click Submenu    ${submenu}

Click Menu
   [Arguments]
   ...   ${menu}
   Click Element    //button[text()="${menu}"]

Click Submenu
   [Arguments]
   ...   ${submenu}
   Click Element   //a[text()="${submenu}"]

Is Menu Expanded
   [Arguments]
   ...   ${menu}
   ${is_menu_expanded}=    Get Element Attribute   //button[text()="${menu}"]   attribute=aria-expanded
   RETURN    ${is_menu_expanded}

Page Should Contain Menu
   [Arguments]  ${menu}
   Page Should Contain Element    //button[text()="${menu}"]

