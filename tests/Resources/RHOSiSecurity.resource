*** Settings ***
Library     RPA.RobotLogListener


*** Variables ***
@{PROTECTED_KEYWORDS}=      Login To RHODS Dashboard


*** Keywords ***
Protect Keywords
    Register Protected Keywords     names=@{PROTECTED_KEYWORDS}
