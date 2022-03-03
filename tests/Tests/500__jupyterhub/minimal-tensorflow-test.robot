*** Settings ***
Documentation    Test Suite for Tensorflow image
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Library          Screenshot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Verify Tensorflow Image Suite Setup
Suite Teardown   End Web Test


*** Variables ***
${NOTEBOOK_IMAGE} =         tensorflow
${EXPECTED_CUDA_VERSION} =  11.4


*** Test Cases ***
Verify Tensorflow Image Can Be Spawned
    [Documentation]    Spawns tensorflow image
    [Tags]  Sanity
    ...     PLACEHOLDER  # Category tags
    ...     ODS-1155
    Pass Execution    Passing tests, as suite setup ensures that image can be spawned

Tensorflow Workload Test
    [Documentation]    Runs tensorflow workload
    [Tags]  Sanity
    ...     PLACEHOLDER  # category tags
    ...     ODS-1156
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible

Verify Tensorflow Image Can Be Spawned With GPU
    [Documentation]    Spawns PyTorch image with 1 GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1151
    Clean Up Server
    Stop JupyterLab Notebook Server
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Default  gpus=1

Verify Tensorflow Image Includes Expected CUDA Version
    [Documentation]    Checks CUDA version
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1152
    Verify Installed CUDA Version    ${EXPECTED_CUDA_VERSION}

Verify Tensorflow Library Can See GPUs In Tensorflow Image
    [Documentation]    Verifies Tensorlow can see the GPU
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1153
    Verify Tensorflow Can See GPU

Verify Tensorflow Image GPU Workload
    [Documentation]  Runs a workload on GPUs in Tensorflow image
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1154
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb
    JupyterLab Code Cell Error Output Should Not Be Visible


*** Keywords ***
Verify Tensorflow Image Suite Setup
    [Documentation]    Suite Setup, spawns tensorflow image
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Default
