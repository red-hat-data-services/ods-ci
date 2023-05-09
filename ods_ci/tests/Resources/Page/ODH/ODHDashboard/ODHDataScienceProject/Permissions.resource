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
    Click Element    css:button span[text='Add user']