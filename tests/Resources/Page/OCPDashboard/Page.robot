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
  # Select From List By Value  xpath://*/section/h1[.="Projects"]/ul  ${project_name}
  Click Element    xpath://div/button[contains(@class, 'co-namespace-dropdown__menu-toggle')]
  Wait Until Page Contains Element  xpath://li[contains(@class, 'pf-c-menu__list-item')]
  Click Element    xpath://li[contains(@class, 'pf-c-menu__list-item')]/*/span[.='${project_name}']
