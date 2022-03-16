*** Settings ***
Force Tags       Smoke  Sanity    JupyterHub
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Special User Testing Suite Setup
Suite Teardown   End Web Test

*** Variables ***
@{CHARS} =  .  ^  $  *  ?  [  ]  {  }  @

# (  ) |  <  > not working in OSD
# + and ; disabled for now

*** Test Cases ***
Test Special Usernames
    [Tags]  Smoke
    ...     PLACEHOLDER  #Category tags
    ...     ODS-257
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
    IF  ${version-check}==True
      Launch JupyterHub From RHODS Dashboard Link
    ELSE
      Launch JupyterHub From RHODS Dashboard Dropdown
    END
    FOR  ${char}  IN  @{CHARS}
        Login Verify Logout  ldap-special${char}  ${TEST_USER.PASSWORD}  ldap-provider-qe
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

