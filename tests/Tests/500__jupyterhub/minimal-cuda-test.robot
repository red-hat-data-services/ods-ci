*** Settings ***
Documentation    Minimal test for the CUDA image
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/gpu.resource
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test


*** Test Cases ***
Spawn CUDA Image
    [Documentation]    Spawns CUDA image with 1 GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-XYZ
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=minimal-gpu  size=Default  gpus=1

Minimal CUDA Verification
    [Documentation]    Checks CUDA version
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-XYZ
    Verify Installed CUDA Version  11.4

Verify PyTorch Can See GPUs
    [Documentation]    Installs PyTorch and verifies it can see the GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-XYZ
    Verify Pytorch Can See GPU  install=True

Verify Tensorflow Can See GPUs
    [Documentation]    Installs Tensorflow and verifies it can see the GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-XYZ
    Verify Tensorflow Can See GPU  install=True