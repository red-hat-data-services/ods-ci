*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/gpu.resource
Library          DebugLibrary
Library          JupyterLibrary
Library          Screenshot
Suite Setup      Begin Web Test
Suite Teardown   End Web Test


*** Test Cases ***
Minimal Tensorflow test
    [Documentation]    Spawns tensorflow image
    [Tags]  Sanity
    ...     PLACEHOLDER  #Category tags
    ...     ODS-XYZ
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=tensorflow  size=Default

Tensorflow Workload Test
    [Documentation]    Runs tensorflow workload
    [Tags]  Sanity
    ...     PLACEHOLDER  #category tags
    ...     ODS-XYZ
    Run Repo and Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb 
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible

Tensorflow GPU Test
    [Documentation]  Spawns Tensorflow image with GPU, confirms it can see it, runs a workload
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-XYZ
    Clean Up Server
    Stop JupyterLab Notebook Server
    Handle Start My Server
    Wait Until JupyterHub Spawner Is Ready
    Spawn Notebook With Arguments  image=tensorflow  size=Default  gpus=1
    Verify Tensorflow Can See GPU
    Run Repo and Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb 
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
