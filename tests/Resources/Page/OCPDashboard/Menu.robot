*** Settings *** 
Library  JupyterLibrary
Library  String

*** Keywords ***
Navigate To Page
   [Arguments]
   ...    ${menu}    
   ...    ${submenu}
   Wait Until Page Contains    ${menu}   timeout=150
   ${is_menu_expanded} =    Is Menu Expanded  ${menu}
   Run Keyword if    "${is_menu_expanded}" == "false"    Click Menu   ${menu}
   Wait Until Page Contains    ${Submenu}
   Click Submenu    ${submenu}

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

Maybe Skip Tour 
   ${tour_modal} =  Run Keyword And Return Status  Page Should Contain Element  xpath=//div[@id='guided-tour-modal']
   Run Keyword If  ${tour_modal}  Click Element  xpath=//div[@id='guided-tour-modal']/button