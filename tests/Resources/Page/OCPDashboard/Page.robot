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