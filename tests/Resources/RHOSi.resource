*** Settings ***
Documentation       Applies RHOSi settings to run the test suites

Library             RPA.RobotLogListener
Resource            Page/ODH/Monitoring/Monitoring.resource
Resource            Page/OCPDashboard/InstalledOperators/InstalledOperators.robot
Resource    Common.robot


*** Variables ***
@{PROTECTED_KEYWORDS}=      Login To RHODS Dashboard
...                         Launch Dashboard
...                         Login to HCC
...                         Login to OCP
...                         Login to Openshift
...                         Login to Jupyterhub
...                         Verify Username Displayed On RHODS Dashboard
...                         Create Pachyderm AWS-Secret
...                         Push Changes To Remote
...                         Commit Changes
...                         Push Some Changes To Repo
...                         Decide OCM URL And Open Link
...                         Get Bearer Token
...                         Log In As RHODS Admin
...                         Log In As RHODS Basic User
...                         Perform Dashboard API Endpoint GET Call
...                         Perform Dashboard API Endpoint PUT Call
...                         Perform Dashboard API Endpoint PATCH Call
...                         Perform Dashboard API Endpoint POST Call
...                         Perform Dashboard API Endpoint DELETE Call
...                         Check Managed Starburst Addon Is Not Installed
...                         Delete Managed Starburst CRs
...                         Create RedHat Marketplace Secret
...                         Get Observatorium Token
...                         Get Original License Secret
...                         Apply Fake Starburst License
...                         Restore Starburst Original License And Verify Deployment


*** Keywords ***
RHOSi Setup
    [Documentation]    Applies RHOSi Settings and stores availability metrics
    ...                The suggested usage of this keyword is to call it inside all the Suite Setup keywords.
    ...                Do Not extend this keyword for high-level setup, e.g., don't open browser
    Protect Sensitive Variables In Keywords
    Initialize Global Variables
    Run Keyword If RHODS Is Managed
    ...    Suite Availability Setup    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}
    # TO DO: oc login

RHOSi Teardown
    [Documentation]    Gets current availability metrics and compares them with the ones
    ...                stored at RHOSi setup
    ...                The suggested usage of this keyword is to call it inside all the Suite Teardown keywords.
    ...                Do Not extend this keyword for high-level setup, e.g., don't close browser
    Run Keyword If RHODS Is Managed
    ...    Suite Availability Teardown    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}

Protect Sensitive Variables In Keywords
    [Documentation]    Register keywords which use sensitive data as "Protected"
    ...                to turn their log level to NONE using RobotLogListener by Robocorp
    Register Protected Keywords    names=@{PROTECTED_KEYWORDS}

Initialize Global Variables
    [Documentation]   Sets global variables
    [Arguments]    ${force_fetch}=False
    Log    Variable initialization temporally disabled
#    ${RHODS_VERSION}=    Get RHODS Version    ${force_fetch}
#    Set Global Variable   ${RHODS_VERSION}
