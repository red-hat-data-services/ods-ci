*** Settings ***
Force Tags       Smoke  Sanity
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Special User Testing Suite Setup
Suite Teardown   End Web Test

*** Variables ***
@{CHARS} =  .  ^  $  *  +  ?  (  )  [  ]  {  }  \\  |  @  ;  <  >

*** Test Cases ***
Test Special Usernames
    [Tags]  Smoke
    ...     PLACEHOLDER  #Category tags
    ...     ODS-257
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for ODH Dashboard to Load
    Launch JupyterHub From ODH Dashboard Dropdown
    FOR  ${char}  IN  @{CHARS}
        Login Verify Logout  htpasswd-special${char}  ${TEST_USER.PASSWORD}  htpasswd-provider-qe
    END

*** Keywords ***
Special User Testing Suite Setup
  Set Library Search Order  SeleniumLibrary

Login Verify Logout
    [Arguments]  ${username}  ${password}  ${auth}
    Login To Jupyterhub  ${username}  ${password}  ${auth}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service Account
    User Is Allowed
    Capture Page Screenshot  special-user-login-{index}.png
    Logout Via Button
    Login Via Button

