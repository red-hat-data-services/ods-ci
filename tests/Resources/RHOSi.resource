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
Protect Sensitive Variables In Keywords
    Register Protected Keywords     names=@{PROTECTED_KEYWORDS}
