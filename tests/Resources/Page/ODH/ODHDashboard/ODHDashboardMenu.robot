*** Keywords ***
Navigate To Page
   [Arguments]
   ...    ${menu}
   ...    ${submenu}
   Wait Until Page Contains    ${menu}   timeout=150
   ${is_menu_expanded} =    ODHDashboardMenu.Is Menu Expanded  ${menu}
   Run Keyword if    "${is_menu_expanded}" == "false"    ODHDashboardMenu.Click Menu   ${menu}
   Wait Until Page Contains    ${submenu}
   ODHDashboardMenu.Click Submenu    ${submenu}

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
   ${is_menu_expanded} =    Get Element Attribute   //button[text()="${menu}"]   attribute=aria-expanded
   [Return]    ${is_menu_expanded}
