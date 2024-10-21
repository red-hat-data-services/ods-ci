*** Settings ***
Documentation    Tests for a scenario in which multiple GPUs are present in the cluster
...              Specifically, we want to test for two nodes with 1 GPU each.
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/GPU.resource
Resource         ../../../Resources/Page/OCPDashboard/Pods/Pods.robot
Library          JupyterLibrary
Suite Setup      Spawner Suite Setup
Suite Teardown   Double User Teardown
Test Tags       JupyterHub


*** Variables ***
${NOTEBOOK_IMAGE} =         minimal-gpu


*** Test Cases ***
Verify Number Of Available GPUs Is Correct
    [Documentation]  Verifies that the number of available GPUs in the
    ...    Spawner dropdown is correct; i.e., it should show the maximum
    ...    Number of GPUs available in a single node.
    [Tags]    Tier1  Sanity  Resources-2GPUS    NVIDIA-GPUs
    ...       ODS-1256
    ${maxNo} =    Find Max Number Of GPUs In One Node
    ${maxSpawner} =    Fetch Max Number Of GPUs In Spawner Page
    Should Be Equal    ${maxSpawner}    ${maxNo}

Verify Two Servers Can Be Spawned
    [Documentation]    Spawns two servers requesting 1 gpu each, and checks
    ...    that both can schedule and are scheduled on different nodes.
    [Tags]    Tier1  Sanity  Resources-2GPUS    NVIDIA-GPUs
    ...       ODS-1257
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small  gpus=1
    ${serial_first} =    Get GPU Serial Number
    ${node_first} =    Get User Server Node
    Close Browser
    # GPU count should update within 30s, sleep to avoid issues here
    Sleep    60s
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER_2.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub Spawner From Dashboard    username=${TEST_USER_2.USERNAME}
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small  gpus=1
    ${serial_second} =    Get GPU Serial Number
    ${node_second} =    Get User Server Node    username=${TEST_USER_2.USERNAME}
    Should Not Be Equal    ${serial_first}    ${serial_second}
    Should Not Be Equal    ${node_first}    ${node_second}
    @{gpu_nodes} =    Get GPU nodes
    List Should Contain Value    ${gpu_nodes}    ${node_first}
    List Should Contain Value    ${gpu_nodes}    ${node_second}


*** Keywords ***
Spawner Suite Setup
    [Documentation]    Suite Setup
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard

Double User Teardown
    [Documentation]    Suite Teardown to close two servers
    Clean Up Server    username=${TEST_USER_2.USERNAME}
    Stop JupyterLab Notebook Server
    Close Browser
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub Spawner From Dashboard
    End Web Test
