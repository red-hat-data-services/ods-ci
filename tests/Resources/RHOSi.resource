*** Settings ***
Documentation       Applies RHOSi settings to run the test suites

Library             RPA.RobotLogListener
Resource            Page/ODH/Monitoring/Monitoring.resource
Resource            Page/OCPDashboard/InstalledOperators/InstalledOperators.robot

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


*** Keywords ***
RHOSi Setup
    [Documentation]    Applies RHOSi Settings and stores availability metrics
    ...                The suggested usage of this keyword is to call it inside all the Suite Setup keywords.
    ...                Do Not extend this keyword for high-level setup, e.g., don't open browser
    Protect Sensitive Variables In Keywords
    Suite Availability Setup    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}
    Initialize Global Variables
    # TO DO: oc login

RHOSi Teardown
    [Documentation]    Gets current availability metrics and compares them with the ones
    ...                stored at RHOSi setup
    ...                The suggested usage of this keyword is to call it inside all the Suite Teardown keywords.
    ...                Do Not extend this keyword for high-level setup, e.g., don't close browser
    Suite Availability Teardown    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}

Protect Sensitive Variables In Keywords
    [Documentation]    Register keywords which use sensitive data as "Protected"
    ...                to turn their log level to NONE using RobotLogListener by Robocorp
    Register Protected Keywords    names=@{PROTECTED_KEYWORDS}

Initialize Global Variables
    [Documentation]   Set varibled globally
    ${RHODS_VERSION}    Get RHODS Version
    Set Global Variable   ${RHODS_VERSION}
