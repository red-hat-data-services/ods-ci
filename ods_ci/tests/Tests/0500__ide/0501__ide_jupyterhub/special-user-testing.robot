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
    ...     OpenDataHub
    ...     ODS-257  ODS-532
    ...     ExcludeOnBYOIDC    # This test requires special usernames that are not created on BYOIDC clusters ATM.
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
    # Clear session cookies while still on the dashboard domain, then navigate
    # to about:blank to kill all active WebSocket/AJAX connections. Without this,
    # stale background requests trigger competing OAuth flows that overwrite the
    # CSRF cookie, causing intermittent login failures (CSRF token mismatch).
    Delete All Cookies
    Go To  about:blank
    Go To  ${ODH_DASHBOARD_URL}
    Login To RHODS Dashboard  ${username}  ${password}  ${auth}
    # Wait for dashboard framework to load (title + logo) before navigating.
    # We only check page-agnostic elements since the post-login redirect target varies.
    Wait For Condition    return document.title == "${ODH_DASHBOARD_PROJECT_NAME}"    timeout=30
    Wait Until Page Contains Element    xpath:${RHODS_LOGO_XPATH}    timeout=30
    # We need to Launch Jupyter app again, because there is a redirect to the `enabled` page in the
    # Login To RHODS Dashboard keyword now as a workaround.
    Launch Jupyter From RHODS Dashboard Link
    User Is Allowed
    Page Should Contain  ${username}
    Capture Page Screenshot  special-user-login-{index}.png

