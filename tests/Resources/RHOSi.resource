*** Settings ***
Library     RPA.RobotLogListener


*** Variables ***
@{PROTECTED_KEYWORDS}=      Login To RHODS Dashboard
...                         Launch Dashboard
...                         Login to HCC
...                         Login to OCP
...                         Login to Openshift
...                         Login to Jupyterhub


*** Keywords ***
RHOSi Setup
    [Documentation]    Applies RHOSi Settings. The suggested usage of this keyword
    ...                is to call it inside all the Suite Setup keywords.
    ...                Do Not extend this keyword for high-level setup,
    ...                e.g., don't open browser
    Protect Sensitive Variables In Keywords
    # TO DO: oc login

Protect Sensitive Variables In Keywords
    Register Protected Keywords     names=@{PROTECTED_KEYWORDS}
