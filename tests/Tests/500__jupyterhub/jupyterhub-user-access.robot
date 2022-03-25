*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource         ../../Resources/Page/ODH/JupyterHub/AccessGroups.resource
Resource         ../../Resources/Page/OCPLogin/OCPLogin.robot
Library          OperatingSystem
Library          DebugLibrary
Library          JupyterLibrary
Library          OpenShiftCLI
Suite Setup      Special User Testing Suite Setup
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Variables ***
${AUTH_TYPE}     ldap-provider-qe

*** Test Cases ***
Test User Not In JH Access Groups
    [Tags]  Sanity
    ...     PLACEHOLDER  # Category tags
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
    ...     PLACEHOLDER  # Category tags
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
    ...     PLACEHOLDER  # Category tags
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
    [Documentation]    Tests the JH access level when using custom rhods groups
    ...                different from rhods-admins and rhods-users
    [Tags]  Sanity
    ...     ODS-293
    [Setup]      Set Standard RHODS Groups Variables
    Open OCP Console
    Login To OCP
    Create Custom Groups
    Add Test Users To Custom Groups
    Remove Test Users From RHODS Standard Groups
    Apply New Groups Config Map
    Rollout JupyterHub
    Check New Access Configuration Works As Expected
    [Teardown]   Restore Standard RHODS Groups Configuration
