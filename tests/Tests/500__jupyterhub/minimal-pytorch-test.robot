*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             DebugLibrary
Library             JupyterLibrary

Suite Setup         Begin Web Test
Suite Teardown      End Web Test

Force Tags          Sanity


*** Test Cases ***
Minimal PyTorch test
    [Tags]    Regression    PLACEHOLDER    #category tags    #Polarion tags
    Wait for RHODS Dashboard to Load
    ${version-check} =    Is RHODS Version Greater Or Equal Than    1.4.0
    IF    ${version-check}==True
        Launch JupyterHub From RHODS Dashboard Link
    ELSE
        Launch JupyterHub From RHODS Dashboard Dropdown
    END
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    Run Keyword If    ${authorization_required}    Authorize jupyterhub service account
    Wait Until Page Contains Element    xpath://span[@id='jupyterhub-logo']
    Fix Spawner Status
    Spawn Notebook With Arguments    image=pytorch    size=Default

PyTorch Workload test
    [Tags]    Regression    PLACEHOLDER    #category tags    #Polarion tags
    Run Repo and Clean    https://github.com/lugi0/notebook-benchmarks
    ...    notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
