*** Settings ***
Library  SeleniumLibrary

*** Keywords ***
Open Page
  [Arguments]  ${url}
  Open Browser  ${url}
  ...           browser=${BROWSER.NAME}    
  ...           options=${BROWSER.OPTIONS}
  Page Should be Open  ${url}

Page Should Be Open
  [Arguments]  ${url}

  ${status}       Run keyword and Return Status      Location Should Contain  ${url}
  ${new_url}       Remove string    ${url}         https://
  Run Keyword If   ${status} == ${False}    Location Should Contain  ${new_url}


Maybe Click Show Default Project Button
  ${switch_button}=  Run Keyword And Return Status    Page Should Contain Element    xpath=//input[@data-test='showSystemSwitch']
  IF    ${switch_button} == True
     ${switch_status}=  Get Element Attribute    xpath=//input[@data-test='showSystemSwitch']    data-checked-state
     IF    '${switch_status}' == 'false'
          Click Element    xpath=//input[@data-test='showSystemSwitch']
     END
  END

Select Project By Name
  [Arguments]  ${project_name}
  Wait Until Page Contains Element    xpath://div[@data-test-id='namespace-bar-dropdown']/div/div/button
  Click Element    xpath://div[@data-test-id='namespace-bar-dropdown']/div/div/button
  Wait Until Page Contains Element  xpath://div[@data-test-id='namespace-bar-dropdown']//li
  Maybe Click Show Default Project Button
  Click Element    xpath://div[@data-test-id='namespace-bar-dropdown']//li//*[text()='${project_name}']

Search Last Item Instance By Title in OpenShift Table
  [Arguments]  ${search_term}  ${namespace}=All Projects
  Select Project By Name    ${namespace}
  Wait Until Page Contains Element    xpath://input[@data-test='name-filter-input']
  Wait Until Page Contains Element    xpath://a[contains(., "${search_term}")]
  Clear Element Text    xpath://input[@data-test='name-filter-input']
  Input Text    xpath://input[@data-test='name-filter-input']    ${search_term}
  Sleep  2
  Click Button    xpath://*/th[@data-label='Created']/button  # asc order
  Click Button    xpath://*/th[@data-label='Created']/button  # desc order

