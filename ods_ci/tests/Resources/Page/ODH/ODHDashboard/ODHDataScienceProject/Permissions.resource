*** Settings ***
Documentation    Collection of keywords to interact with Storages
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource
Library    RPA.Desktop

*** Variables ***


*** Keywords ***
Assign ${permission_type} Permission To ${username}
    Log     ${username} - ${permission_type}
    Click Element    css:button span[text="Add user"]
    Input Text    aria-label:project-sharing-name-input    ${username}
    Select Permission Type    permission_type=${permission_type}

Select Permission Type
    [Arguments]    ${permission_type}
    Click Element    css:td[data-label="Permission"] button[aria-label="Options menu"] 
    Click Element    css:ul li[text="${permission_type}"]