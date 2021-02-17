*** Settings ***
Library  SeleniumLibrary

*** Keywords ***
Login To Openshift
    Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER}  options=add_argument("--ignore-certificate-errors")
    Wait Until Page Contains  Log in with  timeout=15
    Log  ${USER_AUTH_TYPE}
    Click Element  link:${USER_AUTH_TYPE}
    Wait Until Page Contains  Log in to your account
    Input Text  id=inputUsername  ${TEST_USER_NAME}
    Input Text  id=inputPassword  ${TEST_USER_PW}
    Click Element  xpath=/html/body/div/div/main/div/form/div[4]/button
