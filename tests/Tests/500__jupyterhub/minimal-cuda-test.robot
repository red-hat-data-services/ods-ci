*** Settings ***
Documentation    Minimal test for the CUDA image
Force Tags       Sanity
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test


*** Test Cases ***
Spawn CUDA Image
    [Documentation]    Spawns CUDA image with 1 GPU
    [Tags]  Regression
    ...     PLACEHOLDER  # category tags
    ...     PLACEHOLDER  # Polarion tags
    Wait For RHODS Dashboard To Load
    Launch JupyterHub From RHODS Dashboard Link
    Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
    Spawn Notebook With Arguments  image=minimal-gpu  size=Default  gpu_check=True  gpus=1

Minimal CUDA Verification
    [Documentation]    Checks CUDA version (WIP)
    [Tags]  Regression
    ...     PLACEHOLDER  # category tags
    ...     PLACEHOLDER  # Polarion tags
    Run Cell And Check Output    !nvidia-smi | grep "CUDA Version:" | awk '{split($0,a); print a[9]}'    11.4
