*** Settings ***
Documentation       Applies RHOSi settings to run the test suites
Library     RPA.RobotLogListener


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


*** Keywords ***
RHOSi Setup
    [Documentation]    Applies RHOSi Settings. The suggested usage of this keyword
    ...                is to call it inside all the Suite Setup keywords.
    ...                Do Not extend this keyword for high-level setup,
    ...                e.g., don't open browser
    Protect Sensitive Variables In Keywords
    # TO DO: oc login

Protect Sensitive Variables In Keywords
    [Documentation]     Register keywords which use sensitive data as "Protected"
    ...                 to turn their log level to NONE using RobotLogListener by Robocorp
    Register Protected Keywords     names=@{PROTECTED_KEYWORDS}
