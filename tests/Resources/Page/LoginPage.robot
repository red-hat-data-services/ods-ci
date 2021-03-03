*** Settings ***
Library  SeleniumLibrary

*** Keywords ***
Does Login Require Authentication Type
   ${authentication_required} =  Run Keyword and Return Status  Page Should Contain  Log in with...
   [Return]  ${authentication_required}

Select Login Authentication Type
   [Arguments]  ${auth_type}
   Wait Until Page Contains  Log in with  timeout=15
   Log  ${auth_type}
   Click Element  link:${auth_type}

Login To Openshift
    #TODO: Move browser creation into its own keyword
    Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    ${select_auth_type} =  Does Login Require Authentication Type
    Run Keyword If  ${select_auth_type}  Select Login Authentication Type  ${USER_AUTH_TYPE}
    Wait Until Page Contains  Log in to your account
    Input Text  id=inputUsername  ${TEST_USER_NAME}
    Input Text  id=inputPassword  ${TEST_USER_PW}
    Click Element  xpath=/html/body/div/div/main/div/form/div[4]/button
