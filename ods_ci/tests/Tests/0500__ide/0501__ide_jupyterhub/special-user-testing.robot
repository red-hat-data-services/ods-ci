*** Settings ***
Test Tags        JupyterHub
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/RHOSi.resource
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
    ...     Tier1
    ...     OpenDataHub
    ...     ODS-257  ODS-532
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch Jupyter From RHODS Dashboard Link
    FOR  ${char}  IN  @{CHARS}
        Login Verify Logout  ldap-special${char}  ${TEST_USER.PASSWORD}  ldap-provider-qe
    END

*** Keywords ***
Special User Testing Suite Setup
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup

Login Verify Logout
    [Arguments]  ${username}  ${password}  ${auth}
    Logout From RHODS Dashboard
    Login To RHODS Dashboard  ${username}  ${password}  ${auth}
    # We need to Launch Jupyter app again, because there is a redirect to the `enabled` page in the
    # Login To RHODS Dashboard keyword now as a workaround.
    Launch Jupyter From RHODS Dashboard Link
    User Is Allowed
    Page Should Contain  ${username}
    Capture Page Screenshot  special-user-login-{index}.png

