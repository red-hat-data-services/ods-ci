*** Settings ***
Documentation    Test Suite for Visual Studio Code (VSCode) image
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../../Resources/Page/OCPDashboard/Builds/Builds.robot
Library          Screenshot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Verify VSCode Image Suite Setup
Suite Teardown   End Non JupyterLab Web Test
Test Tags       JupyterHub


*** Variables ***
${NOTEBOOK_IMAGE} =         code-server


*** Test Cases ***
Verify VSCode Image Can Be Spawned
    [Documentation]    Spawns vscode image
    [Tags]  Tier1
    Pass Execution    Passing tests, as suite setup ensures that image can be spawned


*** Keywords ***
Verify VSCode Image Suite Setup
    [Documentation]    Suite Setup, spawns vscode image
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Small
