*** Settings ***
Library     SeleniumLibrary

*** Keywords ***
Install Operator
    [Arguments]    ${operator}        ${catalog}=operators
    Search Operator    ${operator}
    Select Operator with Catalog Name     ${operator}   ${catalog}
    ${show_operator_warning_visible} =    Show Operator Warning Is Visible
    IF    ${show_operator_warning_visible}   Confirm Show Operator
    Click Install
    Click Install
    Wait Until Installation Completes

Search Operator
   [Arguments]    ${operator}
   Wait Until Element Is Visible    //input[contains(@aria-label,"Filter by keyword")]   timeout=150
   Clear Element Text    //input[contains(@aria-label,"Filter by keyword")]
   Sleep    0.5s
   Input Text    //input[contains(@aria-label,"Filter by keyword")]   ${operator}
   Press Keys   //input[contains(@aria-label,"Filter by keyword")]   RETURN

Select Operator with Catalog Name
    [Arguments]    ${operator}     ${catalog}
    Wait Until Element is Visible   //a[contains(@data-test, "${operator}") and (contains(@data-test,"${catalog}"))]  timeout=50
    Click Element    //a[contains(@data-test, "${operator}") and (contains(@data-test,"${catalog}"))]

Click Install
    Wait Until Element is Visible    //*[text()="Install"]  timeout=20
    Click Element    //*[text()="Install"]

Show Operator Warning Is Visible
   ${is_warning_visible} =    Run Keyword and Return Status
   ...                        Get WebElement    //*[contains(text(), "Show community Operator")]
   RETURN    ${is_warning_visible}

Confirm Show Operator
   Click Element    //*[@id="confirm-action"]

Wait Until Installation Completes
    Wait Until Page Contains    Installed operator   timeout=300

Operator Should Be Installed
    [Arguments]    ${operator}
    Page Should Contain    ${operator}
    Page Should Contain    ready for use

Get The Number of Operator Available
   [Arguments]    ${operator}
   Search Operator      ${operator}
   ${no_of_items}        Get Webelements    //a[contains(@data-test, "${operator}")]
   ${lenghth}   Get Length   ${no_of_items}
   RETURN   ${lenghth}
