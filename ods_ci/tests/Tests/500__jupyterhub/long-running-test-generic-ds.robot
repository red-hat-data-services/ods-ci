*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             DebugLibrary
Library             JupyterLibrary

Suite Setup         Begin Web Test
Suite Teardown      End Web Test

Test Tags          JupyterHub


*** Test Cases ***
Long Running Test Case
    [Tags]    Tier2
    ...       Execution-Time-Over-15m
    Launch JupyterLab
    Run Repo And Clean  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb
    Run Repo And Clean  https://github.com/lugi0/clustering-notebook  clustering-notebook/CCFraud-clustering.ipynb
    Run Repo And Clean  https://github.com/lugi0/clustering-notebook  clustering-notebook/customer-segmentation-k-means-analysis.ipynb
    Run Repo And Clean  https://github.com/lugi0/clustering-notebook  clustering-notebook/CCFraud-clustering-S3.ipynb
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb


*** Keywords ***
Launch JupyterLab
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize jupyterhub service account
    Fix Spawner Status
    Spawn Notebooks And Set S3 Credentials    image=science-notebook
