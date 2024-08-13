*** Settings ***
Resource  OCPDashboard/OCPDashboard.resource
Resource  ../Common.robot
Library   DebugLibrary
Library   JupyterLibrary

*** Keywords ***
Is ${service_account_name} Service Account Authorization Required
   ${title} =  Get Title
   ${result} =  Run Keyword And Return Status  Should Start With  ${title}  Authorize service account ${service_account_name}
   RETURN  ${result}

Does Login Require Authentication Type
   ${authentication_required} =  Run Keyword And Return Status  Page Should Contain  Log in with
   RETURN  ${authentication_required}

Is OpenShift OAuth Login Prompt Visible
   ${login_prompt_visible} =  Run Keyword And Return Status  Page Should Contain  Log in with
   ${oauth_login} =  Run Keyword And Return Status  Page Should Contain  oauth
   ${result} =  Evaluate  ${login_prompt_visible} and ${oauth_login}
   RETURN  ${result}

Is OpenShift Login Visible
   [Arguments]  ${timeout}=15s
   ${login_prompt_visible} =  Run Keyword And Return Status
   ...    Wait Until Page Contains    Log in with    timeout=${timeout}
   IF  ${login_prompt_visible}    RETURN    ${TRUE}
   ${login_prompt_visible} =  Run Keyword And Return Status
   ...    Wait Until Page Contains    Log in to your account    timeout=${timeout}
   RETURN    ${login_prompt_visible}

Select Login Authentication Type
   [Arguments]  ${auth_type}
   Wait Until Page Contains  Log in with  timeout=15
   Log  ${auth_type}
   Click Element  link:${auth_type}

Login To Openshift
    [Documentation]   Generic keyword to log in to OpenShift Console or other web applications using oauth-proxy.
    ...    It detects when login is not required because of a previous authentication and the page is
    ...    being automatically redirected to the destination app. Note: ${expected_text_list} should contain a
    ...    expected string in the destination app.
    [Arguments]  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
    # Wait until page is the Login page or the destination app
    ${expected_text_list} =    Create List    Log in with    Administrator    Developer    Data Science Projects
    Wait Until Page Contains A String In List    ${expected_text_list}
    # Return if page is not the Login page (no login required)
    ${should_login} =    Does Current Sub Domain Start With    https://oauth
    IF  not ${should_login}    RETURN
    # If here we need to login
    Wait Until Element is Visible  xpath://div[@class="pf-c-login"]  timeout=10s
    ${select_auth_type} =  Does Login Require Authentication Type
    IF  ${select_auth_type}  Select Login Authentication Type   ${ocp_user_auth_type}
    Wait Until Page Contains  Log in to your account
    Input Text  id=inputUsername  ${ocp_user_name}
    Input Text  id=inputPassword  ${ocp_user_pw}
    Click Button   //*[@type="submit"]
    Maybe Skip Tour
    Wait Until Page Does Not Contain    Log in to your account    timeout=30s

Log In Should Be Requested
    [Documentation]    Passes if the login page appears and fails otherwise
    ${present} =    Is OpenShift Login Visible
    IF    not ${present}
        Capture Page Screenshot
        Fail    msg=Login page did not appear as expected
    END

Log In Should Not Be Requested
    [Documentation]    Fails if the login page appears and passes otherwise
    ${present} =    Is OpenShift Login Visible
    IF    ${present}
        Capture Page Screenshot
        Fail    msg=Login page appeared but it was not expected
    END
