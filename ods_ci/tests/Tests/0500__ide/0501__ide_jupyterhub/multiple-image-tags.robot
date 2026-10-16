*** Settings ***
Documentation    Test Suite for the multiple notebook image versions
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
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


*** Keywords ***
Multiple Image Tags Suite Setup
    [Documentation]    Suite Setup, launches spawner page
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
