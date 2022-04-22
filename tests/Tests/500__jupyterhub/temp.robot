*** Comments ***
# this is temporary file to test 'Clone Git Repository' keyword
# Once it get verified then will remove it


*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
#Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             OpenShiftCLI
Library             DebugLibrary

Suite Setup         Server Setup
Suite Teardown      End Web Test


*** Variables ***
${link}=    https://github.com/Pranav-Code-007/Python.git


*** Test Cases ***
Test1
    [Documentation]    When repo is already cloned
    [Tags]    XXXX
    Clone Git Repository    ${link}
    Clone Git Repository    ${link}
    Clean Up Server

Test2
    [Documentation]    When repo is not cloned
    [Tags]    XXXX
    Clone Git Repository    ${link}
    Clean Up Server


*** Keywords ***
Server Setup
    [Documentation]    Suite Setup
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Default
