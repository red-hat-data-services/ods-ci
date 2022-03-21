*** Settings ***
Documentation    Test Suite for PyTorch image
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Verify PyTorch Image Suite Setup
Suite Teardown   End Web Test


*** Variables ***
${NOTEBOOK_IMAGE} =         pytorch
${EXPECTED_CUDA_VERSION} =  11.4


*** Test Cases ***
Verify PyTorch Image Can Be Spawned
    [Documentation]    Spawns pytorch image
    [Tags]  Sanity
    ...     PLACEHOLDER  # category tags
    ...     ODS-1149
    Pass Execution    Passing tests, as suite setup ensures that image can be spawned

PyTorch Image Workload Test
    [Documentation]    Runs a pytorch workload
    [Tags]  Sanity
    ...     PLACEHOLDER  # category tags
    ...     ODS-1150
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible

Verify PyTorch Image Can Be Spawned With GPU
    [Documentation]    Spawns PyTorch image with 1 GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1145
    Clean Up Server
    Stop JupyterLab Notebook Server
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Default  gpus=1

Verify PyTorch Image Includes Expected CUDA Version
    [Documentation]    Checks CUDA version
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1146
    Verify Installed CUDA Version    ${EXPECTED_CUDA_VERSION}

Verify PyTorch Library Can See GPUs In PyTorch Image
    [Documentation]    Verifies PyTorch can see the GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1147
    Verify Pytorch Can See GPU

Verify PyTorch Image GPU Workload
    [Documentation]  Runs a workload on GPUs in PyTorch image
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1148
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
    JupyterLab Code Cell Error Output Should Not Be Visible


*** Keywords ***
Verify PyTorch Image Suite Setup
    [Documentation]    Suite Setup, spawns pytorch image
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Default
