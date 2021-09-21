*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Library          DebugLibrary
Library          JupyterLibrary
Library          OpenShiftCLI
Library          OperatingSystem
Suite Setup      Special User Testing Suite Setup
Suite Teardown   End Web Test

*** Variables ***
${AUTH_TYPE}     ldap-provider-qe

*** Test Cases ***
Test User Not In JH Access Groups
    [Tags]  Sanity
    ...     PLACEHOLDER  #Category tags
    ...     ODS-503
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ldap-noaccess1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Launch JupyterHub From RHODS Dashboard Dropdown
    Login Verify Access Level  ldap-noaccess1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}  none

Test User In JH Admin Group
    [Tags]  Sanity
    ...     PLACEHOLDER  #Category tags
    ...     ODS-503
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ldap-admin1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Launch JupyterHub From RHODS Dashboard Dropdown
    Login Verify Access Level  ldap-admin1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}  admin

Test User In JH Users Group
    [Tags]  Sanity
    ...     PLACEHOLDER  #Category tags
    ...     ODS-503
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ldap-user1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Launch JupyterHub From RHODS Dashboard Dropdown
    Login Verify Access Level  ldap-user1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}  user
