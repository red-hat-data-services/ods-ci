*** Settings ***
Library     SeleniumLibrary

*** Keywords ***
Install Operator
    [Arguments]    ${operator}      ${redhat_marketplace}=None
    Search Operator    ${operator}
    Run Keyword If   "${redhat_marketplace}" == "None"    Select Non Marketplace Operator   ${operator}
    ...         ELSE    Select Operator    ${operator}
    ${show_operator_warning_visible} =    Show Operator Warning Is Visible
    Run Keyword If    ${show_operator_warning_visible}   Confirm Show Operator
    Click Install
    Click Install
    Wait Until Installation Completes

Search Operator
   [Arguments]    ${operator}
   Wait Until Element is Visible    //input[@data-test="search-operatorhub"]   timeout=150
   Input text    //input[@data-test="search-operatorhub"]   ${operator}
   Press keys    //input[@data-test="search-operatorhub"]   RETURN

Select Non Marketplace Operator
    [Arguments]    ${operator}
    Wait Until Element is Visible    //a[contains(@data-test, "${operator}") and not (contains(@data-test,"rhmp"))]   timeout=50
    Click Element    //a[contains(@data-test, "${operator}") and not (contains(@data-test,"rhmp"))]

Select Operator
    [Arguments]    ${operator}
    Wait Until Element is Visible   //a[contains(@data-test, "${operator}") and (contains(@data-test,"rhmp"))]  timeout=50
    Click Element    //a[contains(@data-test, "${operator}") and (contains(@data-test,"rhmp"))]

Click Install
    Wait Until Element is Visible    //*[text()="Install"]
    Click Element    //*[text()="Install"]

Show Operator Warning Is Visible
   ${is_warning_visible} =    Run Keyword and Return Status    
   ...                        Get WebElement    //*[contains(text(), "Show community Operator")]
   [Return]    ${is_warning_visible}
   
Confirm Show Operator
   Click Element    //*[@id="confirm-action"]

Wait Until Installation Completes
    Wait Until Page Contains    ready for use   timeout=300

Operator Should Be Installed
    [Arguments]    ${operator}
    Page Should Contain    ${operator}
    Page Should Contain    ready for use

Get List Of Operator Available
   [Arguments]    ${operator}
   Search Operator      ${operator}
   ${no_of_items}        Get Webelements    //a[contains(@data-test, "${operator}")]
   ${lenghth}   Get Length   ${no_of_items}
   [Return]   ${lenghth}
