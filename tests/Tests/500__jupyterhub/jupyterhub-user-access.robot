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
Force Tags       JupyterHub


*** Variables ***
${AUTH_TYPE}     ldap-provider-qe


*** Test Cases ***
Verify User Can Set Custom RHODS Groups
    [Documentation]    Tests the JH access level when using custom rhods groups
    ...                different from rhods-admins and rhods-users
    [Tags]  Sanity
    ...     ODS-293    ODS-503
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
