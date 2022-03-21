*** Settings ***
Documentation    TC to verify Pip changes are not permenemt
...    after restarting notebook

Resource         ../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource         ../../Resources/Common.robot
Suite Setup      Test Setup
Suite Teardown   End Web Test


*** Test Cases ***
Verify pip Changes not permenant
    [Documentation]
    ...   Verify if installed pip changes are permenant
    ...   after stopping and starting notebook

    [Tags]  Sanity
    ...     ODS-909
    Install And Import Package In JupyterLab  paramiko
    Stop JupyterLab Notebook Server
    Capture Page Screenshot
    Fix Spawner Status
    Spawn Notebook With Arguments
    Verify Package Is Not Installed In JupyterLab  paramiko
    Capture Page Screenshot


*** Keywords ***
Test Setup
    [Documentation]  Added customized Setup
    Begin Web Test
    Wait for RHODS Dashboard to Load
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments
