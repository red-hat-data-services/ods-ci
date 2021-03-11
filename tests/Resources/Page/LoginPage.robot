*** Settings ***
Library  JupyterLibrary

*** Keywords ***
Does Login Require Authentication Type
   ${authentication_required} =  Run Keyword and Return Status  Page Should Contain  Log in with
   [Return]  ${authentication_required}

Is OpenShift Login Visible
   ${login_prompt_visible} =  Run Keyword and Return Status  Page Should Contain  Log in with
   Return From Keyword If  ${login_prompt_visible}  True
   ${login_prompt_visible} =  Run Keyword and Return Status  Page Should Contain  Log in to your account
   [Return]  ${login_prompt_visible}

Select Login Authentication Type
   [Arguments]  ${auth_type}
   Wait Until Page Contains  Log in with  timeout=15
   Log  ${auth_type}
   Click Element  link:${auth_type}

Login To Openshift
   [Arguments]  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
    # Give the login prompt time to render after browser opens
    Wait Until Element is Visible  xpath://div[@class="pf-c-login"]  timeout=15seconds
    ${select_auth_type} =  Does Login Require Authentication Type
    Run Keyword If  ${select_auth_type}  Select Login Authentication Type  ${ocp_user_auth_type}
    Wait Until Page Contains  Log in to your account
    Input Text  id=inputUsername  ${ocp_user_name}
    Input Text  id=inputPassword  ${ocp_user_pw}
    Click Element  xpath=/html/body/div/div/main/div/form/div[4]/button
