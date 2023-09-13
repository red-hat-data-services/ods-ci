*** Settings ***
Resource        ../../Common.robot
Library         SeleniumLibrary

*** Keywords ***
Is SSO Login Page Visible
  ${login_prompt_visible} =  Run Keyword and Return Status  Page Should Contain Element    xpath://body[@id='rh-login']
  # ${login_prompt_visible} =  Run Keyword and Return Status  Page Should Contain  Log in to your Red Hat account
  RETURN  ${login_prompt_visible}

Wait For HCC Splash Page
   Wait Until Page Contains Element    xpath://span[contains(@class, 'pf-c-spinner')]   timeout=15
   Wait Until Page Does Not Contain Element    xpath://span[contains(@class, 'pf-c-spinner')]   timeout=20
   Sleep    3

Login To HCC
  [Documentation]    Performs log in to Hybrid Cloud Console web page
  [Arguments]  ${username}  ${password}
  Sleep  5
  ${login-required} =  Is SSO Login Page Visible
  IF    ${login-required} == True
    Wait Until Element is Visible  xpath://input[@id="username-verification"]  timeout=5
    Maybe Accept Cookie Policy
    Input Text  id=username-verification  ${username}
    Click Button    Next
    Wait Until Element is Visible  xpath://input[@id="password"]  timeout=5
    Input Text  id=password  ${password}
    Click Button    Log in
  END
  Run Keyword And Ignore Error     Wait For HCC Splash Page
  Maybe Handle Something Went Wrong Page

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

Maybe Handle Something Went Wrong Page
  ${sww_required}=  Run Keyword And Return Status  Page Should Contain  Something went wrong
  IF    ${sww_required} == True
    Capture Page Screenshot  somethingwentwrong_kafka.png
    Reload Page
  END

Wait Until Page Contains HCC Generic Modal
  Wait Until Page Contains Element    xpath=//div[contains(@id, 'pf-modal-part')]

Wait Until Page Does Not Contains HCC Generic Modal
  Wait Until Page Does Not Contain Element    xpath=//div[contains(@id, 'pf-modal-part')]

Open Cluster By Name
  [Documentation]     Opens the cluster by name from the list of clusters.
  ${cluster_id} =     Get Cluster ID
  ${cluster_name}=    Get Cluster Name By Cluster ID    ${cluster_id}
  Wait Until Page Contains Element  //input[@class="pf-c-form-control cluster-list-filter"]
  Input Text    //input[@class="pf-c-form-control cluster-list-filter"]     ${cluster_name}
  Sleep    1s
  Wait Until Page Contains Element  //table[@class="pf-c-table pf-m-grid-md"]//a    10
  Click Link    //table[@class="pf-c-table pf-m-grid-md"]//a

Maybe Skip OCM Tour
  ${tour_modal} =  Run Keyword And Return Status  Page Should Contain Element  xpath=//div[@id="pendo-guide-container"]
  IF  ${tour_modal}  Click Element  xpath=//button[@class="_pendo-close-guide"]
