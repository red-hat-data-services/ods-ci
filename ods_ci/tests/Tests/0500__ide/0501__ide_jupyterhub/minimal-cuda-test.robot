*** Settings ***
Documentation    Minimal test for the CUDA image
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/GPU.resource
Library          JupyterLibrary
Suite Setup      Verify CUDA Image Suite Setup
Suite Teardown   End Web Test
Test Tags       JupyterHub


*** Variables ***
${NOTEBOOK_IMAGE} =         minimal-gpu
${EXPECTED_CUDA_VERSION} =  12.9
${EXPECTED_CUDA_VERSION_N_1} =  12.6


*** Test Cases ***
Verify CUDA Image Can Be Spawned With GPU
    [Documentation]    Spawns CUDA image with 1 GPU and verifies that the GPU is
    ...    not available for other users.
    [Tags]  Tier2
    ...     Resources-GPU    NVIDIA-GPUs
    ...     ODS-1141    ODS-346    ODS-1359
    Pass Execution    Passing tests, as suite setup ensures that image can be spawned

Verify CUDA Image Includes Expected CUDA Version
    [Documentation]    Checks CUDA version
    [Tags]  Tier2
    ...     Resources-GPU    NVIDIA-GPUs
    ...     ODS-1142
    Verify Installed CUDA Version    ${EXPECTED_CUDA_VERSION}

Verify PyTorch Library Can See GPUs In Minimal CUDA
    [Documentation]    Installs PyTorch and verifies it can see the GPU
    [Tags]  Tier2
    ...     Resources-GPU    NVIDIA-GPUs
    ...     ODS-1144
    Verify Pytorch Can See GPU    install=True

Verify Tensorflow Library Can See GPUs In Minimal CUDA
    [Documentation]    Installs Tensorflow and verifies it can see the GPU
    [Tags]  Tier2
    ...     Resources-GPU    NVIDIA-GPUs
    ...     ODS-1143
    Verify Tensorflow Can See GPU    install=True

Verify Cuda Image Has NVCC Installed
    [Documentation]     Verifies NVCC Version in Minimal CUDA Image
    [Tags]  Tier2
    ...     Resources-GPU    NVIDIA-GPUs
    ...     ODS-483
    ${nvcc_version} =  Run Cell And Get Output    input=!nvcc --version
    Should Not Contain    ${nvcc_version}  /usr/bin/sh: nvcc: command not found

Verify Previous CUDA Notebook Image With GPU
    [Documentation]    Runs a workload after spawning the N-1 CUDA Notebook
    [Tags]    Tier2    LiveTesting
    ...       Resources-GPU    NVIDIA-GPUs
    ...       ODS-2128
    [Setup]    N-1 CUDA Setup
    Spawn Notebook With Arguments    image=${NOTEBOOK_IMAGE}    hardware_profile=NVIDIA GPU    version=previous
    Verify Installed CUDA Version    ${EXPECTED_CUDA_VERSION_N_1}
    Verify PyTorch Can See GPU    install=True
    Verify Tensorflow Can See GPU    install=True
    ${nvcc_version} =  Run Cell And Get Output    input=!nvcc --version
    Should Not Contain    ${nvcc_version}  /usr/bin/sh: nvcc: command not found
    [Teardown]    End Web Test


*** Keywords ***
Verify CUDA Image Suite Setup
    [Documentation]    Suite Setup, spawns CUDA img with one GPU attached
    ...    Additionally, checks that the number of available GPUs decreases
    ...    after the GPU is assigned.
    Set Library Search Order  SeleniumLibrary
    Close All Browsers
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  hardware_profile=NVIDIA GPU
    # TODO: GPU allocation check skipped — Fetch Max Number Of GPUs In Spawner Page
    # relies on the removed accelerator dropdown (dashboard PRs #5053/#5140/#5206/#5484).
    # Needs rewrite to use hardware profiles before re-enabling.
    Log    Skipping GPU allocation check (accelerator dropdown removed in 3.5)    console=yes

N-1 CUDA Setup
    [Documentation]    Closes the previous browser (if any) and starts a clean
    ...                run spawning the N-1 PyTorch image
    End Web Test
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Sleep    30s    reason=Wait for resources to become available again
    Reload Page
    Wait Until JupyterHub Spawner Is Ready
