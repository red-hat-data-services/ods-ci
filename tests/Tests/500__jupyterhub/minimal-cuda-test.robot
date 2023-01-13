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
Force Tags       JupyterHub


*** Variables ***
${NOTEBOOK_IMAGE} =         minimal-gpu
${EXPECTED_CUDA_VERSION} =  12.0


*** Test Cases ***
Verify CUDA Image Can Be Spawned With GPU
    [Documentation]    Spawns CUDA image with 1 GPU and verifies that the GPU is
    ...    not available for other users.
    [Tags]  Sanity    Tier1
    ...     Resources-GPU
    ...     ODS-1141    ODS-346    ODS-1359
    Pass Execution    Passing tests, as suite setup ensures that image can be spawned

Verify CUDA Image Includes Expected CUDA Version
    [Documentation]    Checks CUDA version
    [Tags]  Sanity    Tier1
    ...     Resources-GPU
    ...     ODS-1142
    Verify Installed CUDA Version    ${EXPECTED_CUDA_VERSION}

Verify PyTorch Library Can See GPUs In Minimal CUDA
    [Documentation]    Installs PyTorch and verifies it can see the GPU
    [Tags]  Sanity    Tier1
    ...     Resources-GPU
    ...     ODS-1144
    Verify Pytorch Can See GPU    install=True

Verify Tensorflow Library Can See GPUs In Minimal CUDA
    [Documentation]    Installs Tensorflow and verifies it can see the GPU
    [Tags]  Sanity    Tier1
    ...     Resources-GPU
    ...     ODS-1143
    Verify Tensorflow Can See GPU    install=True

Verify Cuda Image Have NVCC Installed
    [Documentation]     Verifies NVCC Version in Minimal CUDA Image
    [Tags]  Sanity    Tier1
    ...     Resources-GPU
    ...     ODS-483
    ${nvcc_version} =  Run Cell And Get Output    input=!nvcc --version
    Should Not Contain    ${nvcc_version}  /usr/bin/sh: nvcc: command not found


*** Keywords ***
Verify CUDA Image Suite Setup
    [Documentation]    Suite Setup, spawns CUDA img with one GPU attached
    ...    Additionally, checks that the number of available GPUs decreases
    ...    after the GPU is assigned.
    Set Library Search Order  SeleniumLibrary
    Close All Browsers
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small  gpus=1
    # Verifies that now there are no GPUs available for selection
    @{old_browser} =  Get Browser Ids
    Sleep  30s  msg=Give time to spawner to update GPU count
    Launch Dashboard    ${TEST_USER2.USERNAME}    ${TEST_USER2.PASSWORD}    ${TEST_USER2.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Launch JupyterHub Spawner From Dashboard    ${TEST_USER_2.USERNAME}    ${TEST_USER.PASSWORD}
    ...    ${TEST_USER.AUTH_TYPE}
    # This will fail in case there are two nodes with the same number of GPUs
    # Since the overall available number won't change even after 1 GPU is assigned
    # However I can't think of a better way to execute this check, under the assumption that
    # the Resources-GPU tag will always ensure there is 1 node with 1 GPU on the cluster.
    ${maxNo} =    Find Max Number Of GPUs In One Node
    ${maxSpawner} =    Fetch Max Number Of GPUs In Spawner Page
    # Need to continue execution even on failure or the whole suite will be failed
    # And not executed at all.
    Run Keyword And Warn On Failure  Should Be Equal    ${maxSpawner}    ${maxNo-1}
    Close Browser
    Switch Browser  ${old_browser}[0]
