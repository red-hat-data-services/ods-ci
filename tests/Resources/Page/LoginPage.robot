*** Settings ***
Resource  OCPDashboard/OCPDashboard.resource
Resource  ../Common.robot
Library   DebugLibrary
Library   JupyterLibrary

*** Keywords ***
Is ${service_account_name} Service Account Authorization Required
   ${title} =  Get Title
   ${result} =  Run Keyword And Return Status  Should Start With  ${title}  Authorize service account ${service_account_name}
   [Return]  ${result}

Does Login Require Authentication Type
   ${authentication_required} =  Run Keyword and Return Status  Page Should Contain  Log in with
   [Return]  ${authentication_required}

Is OpenShift OAuth Login Prompt Visible
   ${login_prompt_visible} =  Run Keyword and Return Status  Page Should Contain  Log in with
   ${oauth_login} =  Run Keyword and Return Status  Page Should Contain  oauth
   ${result} =  Evaluate  ${login_prompt_visible} and ${oauth_login}
   [Return]  ${result}

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
    # Check if we are in the Openshift auth page
    ${should_login} =    Is Current Domain Equal To    https://oauth-openshift
    IF  ${should_login}==False
        Return From Keyword
    END
    # If here we need to login
    Wait Until Element is Visible  xpath://div[@class="pf-c-login"]  timeout=10s
    ${select_auth_type} =  Does Login Require Authentication Type
    Run Keyword If  ${select_auth_type}  Select Login Authentication Type  ${ocp_user_auth_type}
    Wait Until Page Contains  Log in to your account
    Input Text  id=inputUsername  ${ocp_user_name}
    Input Text  id=inputPassword  ${ocp_user_pw}
    Click Element  xpath=/html/body/div/div/main/div/form/div[4]/button
    Maybe Skip Tour
