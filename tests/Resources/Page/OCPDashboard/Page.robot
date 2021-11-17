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
  Location Should Contain  ${url}

Select Project By Name
  [Arguments]  ${project_name}
  Wait Until Page Contains Element    xpath://div/button[contains(@class, 'co-namespace-dropdown__menu-toggle')]
  Click Element    xpath://div/button[contains(@class, 'co-namespace-dropdown__menu-toggle')]
  Wait Until Page Contains Element  xpath://li[contains(@class, 'pf-c-menu__list-item')]
  Click Element    xpath://li[contains(@class, 'pf-c-menu__list-item')]/*/span[.='${project_name}']

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