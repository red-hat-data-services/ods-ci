*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource         ../../Resources/Page/ODH/JupyterHub/AccessGroups.robot
Resource         ../../Resources/Page/OCPLogin/OCPLogin.robot
Library          DebugLibrary
Library          JupyterLibrary
Library          OpenShiftCLI
Library          OperatingSystem
Suite Setup      Special User Testing Suite Setup
Suite Teardown   End Web Test
Force Tags       JupyterHub


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
    ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
    IF  ${version-check}==True
      Launch JupyterHub From RHODS Dashboard Link
    ELSE
      Launch JupyterHub From RHODS Dashboard Dropdown
    END
    Login Verify Access Level  ldap-noaccess1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}  none

Test User In JH Admin Group
    [Tags]  Sanity
    ...     PLACEHOLDER  #Category tags
    ...     ODS-503
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ldap-admin1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
    IF  ${version-check}==True
      Launch JupyterHub From RHODS Dashboard Link
    ELSE
      Launch JupyterHub From RHODS Dashboard Dropdown
    END
    Login Verify Access Level  ldap-admin1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}  admin

Test User In JH Users Group
    [Tags]  Sanity
    ...     PLACEHOLDER  #Category tags
    ...     ODS-503
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ldap-user1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
    IF  ${version-check}==True
      Launch JupyterHub From RHODS Dashboard Link
    ELSE
      Launch JupyterHub From RHODS Dashboard Dropdown
    END
    Login Verify Access Level  ldap-user1  ${TEST_USER.PASSWORD}  ${AUTH_TYPE}  user

Verify User Can Set Custom RHODS Groups
    [Tags]  Sanity
    ...     ODS-293
    # Open OCP Console
    Go To    ${OCP_CONSOLE_URL}
    Login To OCP
    Create Custom Groups
    Add Test Users To Custom Groups
    Remove Test Users From RHODS Standard Groups
    Apply New Groups Config Map
    Rollout JupyterHub
    Check New Access Configuration Works As Expected
    Restore RHODS Standard Groups Config Map
    Rollout JupyterHub
    Go To    ${OCP_CONSOLE_URL}
    Add Test Users Back To RHODS Standard Groups
    Remove Test Users From Custom Groups
    Delete Custom Groups
    Check Standard Access Configuration Works As Expected