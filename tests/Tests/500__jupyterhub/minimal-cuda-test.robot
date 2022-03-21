*** Settings ***
Documentation    Minimal test for the CUDA image
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Library          JupyterLibrary
Suite Setup      Verify CUDA Image Suite Setup
Suite Teardown   End Web Test


*** Variables ***
${NOTEBOOK_IMAGE} =         minimal-gpu
${EXPECTED_CUDA_VERSION} =  11.4


*** Test Cases ***
Verify CUDA Image Can Be Spawned With GPU
    [Documentation]    Spawns CUDA image with 1 GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1141    ODS-346
    Pass Execution    Passing tests, as suite setup ensures that image can be spawned

Verify CUDA Image Includes Expected CUDA Version
    [Documentation]    Checks CUDA version
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1142
    Verify Installed CUDA Version    ${EXPECTED_CUDA_VERSION}

Verify PyTorch Library Can See GPUs In Minimal CUDA
    [Documentation]    Installs PyTorch and verifies it can see the GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1144
    Verify Pytorch Can See GPU    install=True

Verify Tensorflow Library Can See GPUs In Minimal CUDA
    [Documentation]    Installs Tensorflow and verifies it can see the GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1143
    Verify Tensorflow Can See GPU    install=True


*** Keywords ***
Verify CUDA Image Suite Setup
    [Documentation]    Suite Setup, spawns CUDA img with one GPU attached
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Default  gpus=1
