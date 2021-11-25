*** Settings ***
Library         SeleniumLibrary

*** Keywords ***
Is SSO Login Page Visible
  ${login_prompt_visible} =  Run Keyword and Return Status  Page Should Contain  Log in to your Red Hat account
  [Return]  ${login_prompt_visible}

Login to HCC
  [Arguments]  ${username}  ${password}
  ${login-required} =  Is SSO Login Page Visible
  IF    ${login-required} == True
    Wait Until Element is Visible  xpath://input[@id="username-verification"]  timeout=5
    Input Text  id=username-verification  ${username}
    Click Button    Next
    Wait Until Element is Visible  xpath://input[@id="password"]  timeout=5
    Input Text  id=password  ${password}
    Click Button    Log in
  END

Maybe Skip RHOSAK Tour
   ${tour_modal} =  Run Keyword And Return Status  Page Should Contain Element  xpath=//button[text()='Take tour']
   Run Keyword If  ${tour_modal}  Click Button    Not now

Wait For HCC Splash Page
   Wait Until Page Contains Element    xpath://span[contains(@class, 'pf-c-spinner')]   timeout=15
   Wait Until Page Does Not Contain Element    xpath://span[contains(@class, 'pf-c-spinner')]   timeout=15
   Sleep    3