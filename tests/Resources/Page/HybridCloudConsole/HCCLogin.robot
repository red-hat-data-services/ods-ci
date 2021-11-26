*** Settings ***
Library         SeleniumLibrary

*** Keywords ***
Is SSO Login Page Visible
  ${login_prompt_visible} =  Run Keyword and Return Status  Page Should Contain  Log in to your Red Hat account
  [Return]  ${login_prompt_visible}

Wait For HCC Splash Page
   Wait Until Page Contains Element    xpath://span[contains(@class, 'pf-c-spinner')]   timeout=15
   Wait Until Page Does Not Contain Element    xpath://span[contains(@class, 'pf-c-spinner')]   timeout=15
   Sleep    3

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
  Run Keyword And Continue On Failure    Wait For HCC Splash Page

Maybe Skip RHOSAK Tour
   ${tour_modal} =  Run Keyword And Return Status  Page Should Contain Element  xpath=//button[text()='Take tour']
   Run Keyword If  ${tour_modal}  Click Button    Not now

Maybe Agree RH Terms and Conditions
  ${agree_required}=  Run Keyword And Return Status  Page Should Contain  Red Hat Terms and Conditions
  IF    ${agree_required} == True
    Wait Until Page Contains Element    xpath=//div[@class='checkbox terms-decision']
    Select Checkbox    xpath=//input[contains(@id, 'checkbox-term')]
    Checkbox Should Be Selected  xpath=//input[contains(@id, 'checkbox-term')]
    Click Button  Submit
  END

Maybe Accept Cookie Policy
  ${cookie_required}=  Run Keyword And Return Status  Page Should Contain  We use cookies on this site
  IF    ${cookie_required} == True
    Select Frame    xpath=//iframe[@title='TrustArc Cookie Consent Manager']
    Wait Until Page Contains Element    xpath=//a[contains(@class, 'required')]  timeout=10
    Click Link    xpath=//a[contains(@class, 'required')]
    Wait Until Page Contains Element    xpath=//a[contains(@class, 'close')]  timeout=10
    Click Link    xpath=//a[contains(@class, 'close')]
    Wait Until Page Does Not Contain    xpath=//iframe[@title='TrustArc Cookie Consent Manager']
    Unselect Frame
    Capture Page Screenshot  cookieaccepted.png
  END
