*** Settings ***
Documentation    Test Suite for the multiple notebook image versions
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Suite Teardown   End Web Test
Test Tags       JupyterHub


*** Variables ***
@{IMAGE_LIST}    minimal-notebook    science-notebook    tensorflow    pytorch    minimal-gpu


*** Test Cases ***
Verify All OOTB Images Have Version Dropdowns
    [Documentation]    Verifies all images in ${IMAGE_LIST} have a version dropdown
    ...                with an N and N-1 pick.
    [Tags]    Smoke
    ...       ODS-2125
    [Setup]    Multiple Image Tags Suite Setup
    FOR    ${image}    IN    @{IMAGE_LIST}
        Verify Version Dropdown Is Present    ${image}
    END
    [Teardown]    End Web Test

Verify All OOTB Images Spawn Previous Versions
    [Documentation]    Verifies all images in ${IMAGE_LIST} can be spawned using
    ...                the previous version, and the spawned image is the correct one.
    [Tags]    Tier1
    ...       ODS-2126
    [Setup]    Multiple Image Tags Suite Setup
    FOR    ${image}    IN    @{IMAGE_LIST}
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
    [Documentation]    Closes previous server and goes back to Spawner
    Clean Up Server
    Stop JupyterLab Notebook Server
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready
