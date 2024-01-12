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
@{IMAGE_LIST}    minimal-notebook    science-notebook    tensorflow    pytorch    minimal-gpu


*** Test Cases ***
Verify All OOTB Images Have Version Dropdowns
    [Documentation]    Verifies all images in ${IMAGE_LIST} have a version dropdown
    ...                with an N and N-1 pick.
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-2125
    [Setup]    Multiple Image Tags Suite Setup
    FOR    ${image}    IN    @{IMAGE_LIST}
        Verify Version Dropdown Is Present    ${image}
    END
    [Teardown]    End Web Test

Verify All OOTB Images Spawn Previous Versions
    [Documentation]    Verifies all images in ${IMAGE_LIST} can be spawned using
    ...                the previous version, and the spawned image is the correct one.
    [Tags]    Sanity    Tier1
    ...       ODS-2126
    [Setup]    Multiple Image Tags Suite Setup
    FOR    ${image}    IN    @{IMAGE_LIST}
        Spawn Notebook With Arguments    image=${image}    version=previous
        Close Previous Server
    END
    [Teardown]    End Web Test

Workload Test For Previous Image Versions
    [Documentation]    Spawns each notebook image using the previous available
    ...                version, and runs a workload on it.
    [Tags]    Tier2    LiveTesting
    ...       ODS-2127
    [Setup]    Multiple Image Tags Suite Setup
    FOR    ${image}    IN    @{IMAGE_LIST}
        Spawn Notebook With Arguments    image=${image}    version=previous
        Run Regression Workload On Notebook Image    ${image}
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

Run Regression Workload On Notebook Image
    [Documentation]    Runs a workload based on the image argument
    [Arguments]    ${image}
    IF    "minimal-notebook" in "${image}"
        Run Repo And Clean  https://github.com/lugi0/minimal-nb-image-test    minimal-nb-image-test/minimal-nb.ipynb
    ELSE IF    "science-notebook" in "${image}"
        Run Repo And Clean  https://github.com/lugi0/clustering-notebook  clustering-notebook/customer-segmentation-k-means-analysis.ipynb
    ELSE IF    "minimal-gpu" in "${image}"
        ${nvcc_version} =  Run Cell And Get Output    input=!nvcc --version
        Should Not Contain    ${nvcc_version}  /usr/bin/sh: nvcc: command not found
        Run Repo And Clean  https://github.com/lugi0/minimal-nb-image-test    minimal-nb-image-test/minimal-nb.ipynb
    ELSE IF    "tensorflow" in "${image}"
        Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb
    ELSE IF    "pytorch" in "${image}"
        Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
    ELSE
        Log To Console    Unknown image
        Fail
    END
