*** Settings ***
Documentation    Test Suite for the multiple notebook image versions
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Resource         ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Library          Screenshot
Library          DebugLibrary
Library          JupyterLibrary
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Variables ***
@{IMAGE_LIST}    s2i-minimal-notebook    s2i-generic-data-science-notebook    tensorflow    pytorch    minimal-gpu


*** Test Cases ***
Verify All OOTB Images Have Version Dropdowns
    [Documentation]    Verifies all images in ${IMAGE_LIST} have a version dropdown
    ...                with an N and N-1 pick.
    [Tags]    Smoke
    ...       ODS-XXXX
    [Setup]    Multiple Image Tags Suite Setup
    FOR    ${image}    IN    @{IMAGE_LIST}
        Verify Version Dropdown Is Present    ${image}
    END
    [Teardown]    End Web Test

Verify All OOTB Images Spawn Both Versions
    [Documentation]    Verifies all images in ${IMAGE_LIST} can be spawned in
    ...                either version, and the spawned image is the correct one.
    [Tags]    Sanity    Tier1
    ...       ODS-XXXX
    [Setup]    Multiple Image Tags Suite Setup
    FOR    ${image}    IN    @{IMAGE_LIST}
        Spawn Notebook With Arguments    image=${image}
        Close Previous Server
        Spawn Notebook With Arguments    image=${image}    version=previous
        Close Previous Server
    END
    [Teardown]    End Web Test


*** Keywords ***
Multiple Image Tags Suite Setup
    [Documentation]    Suite Setup, launches spawner page
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard

Close Previous Server
    [Documentation]  Closes previous server and goes back to Spawner
    Clean Up Server
    Stop JupyterLab Notebook Server
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready
