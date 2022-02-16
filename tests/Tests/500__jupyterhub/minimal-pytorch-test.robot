*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/gpu.resource
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test


*** Test Cases ***
Minimal PyTorch test
    [Documentation]    Spawns pytorch image
    [Tags]  Sanity
    ...     PLACEHOLDER  #category tags
    ...     ODS-XYZ
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=pytorch  size=Default

PyTorch Workload test
    [Documentation]    Runs a pytorch workload
    [Tags]  Sanity
    ...     PLACEHOLDER  #category tags
    ...     ODS-XYZ
    Run Repo and Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible

PyTorch GPU Test
    [Documentation]  Spawns PyTorch image with a GPU, verifies it can see it, runs a workload
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-XYZ
    Clean Up Server
    Stop JupyterLab Notebook Server
    Handle Start My Server
    Wait Until JupyterHub Spawner Is Ready
    Spawn Notebook With Arguments  image=pytorch  size=Default  gpus=1
    Verify Pytorch Can See GPU
    Run Repo and Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
    JupyterLab Code Cell Error Output Should Not Be Visible