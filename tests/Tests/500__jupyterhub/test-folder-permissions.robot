*** Settings ***
Documentation       Test Suite to verify installed library versions

Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             JupyterLibrary

Suite Setup         Load Spawner Page
Suite Teardown      End Web Test


*** Test Cases ***
Verify Folder Permissions
    [Documentation]    It checks Access, Gid, Uid of /opt/app-root/lib and /opt/app-root/shares
    [Tags]    ODS-486
    ...       Tier2
    @{list_of_images} =    Create List
    Append To List
    ...    ${list_of_images}
    ...    s2i-minimal-notebook
    ...    s2i-generic-data-science-notebook
    ...    pytorch
    ...    tensorflow
    ${permissions} =    Create List    0775    0    1001
    ${path} =    Create List    lib    share
    FOR    ${img}    IN    @{list_of_images}
        Verify The Permissions Of Folder In Image    ${img}    ${path}    ${permissions}
    END


*** Keywords ***
Load Spawner Page
    [Documentation]    Suite Setup, loads JH Spawner
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard

Verify The Permissions Of Folder In Image
    [Documentation]    It verifies the ${permission} permissions of ${paths} folder in ${image} image
    [Arguments]    ${image}    ${paths}    ${permission}
    Spawn Notebook With Arguments    image=${image}
    FOR    ${path}    IN    @{paths}
        Verify The Permissions Of Folder    ${path}    @{permission}
    END
    Clean Up Server
    Stop JupyterLab Notebook Server
    Go To    ${ODH_DASHBOARD_URL}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub From RHODS Dashboard Link
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready

Verify The Permissions Of Folder
    [Documentation]    It checks for the folder permissions ${permission}[0], ${permission}[1], ${permission}[2]
    ...                should be of Access, Uid and Gid respectively.
    [Arguments]    ${path}    @{permission}
    Run Keyword And Continue On Failure
    ...    Run Cell And Check Output
    ...    !stat /opt/app-root/${path} | grep Access | awk '{split($2,b,"."); printf "%s", b[1]}' | awk '{split($0, c, "/"); printf c[1]}' | cut -c 2-5
    ...    ${permission}[0]
    Run Keyword And Continue On Failure
    ...    Run Cell And Check Output
    ...    !stat /opt/app-root/${path} | grep Uid | awk '{split($9,b,"."); printf "%s", b[1]}' | awk '{split($0, c, "/"); printf c[1]}'
    ...    ${permission}[1]
    Run Keyword And Continue On Failure
    ...    Run Cell And Check Output
    ...    !stat /opt/app-root/${path} | grep Gid | awk '{split($5,b,"."); printf "%s", b[1]}' | awk '{split($0, c, "/"); printf c[1]}'
    ...    ${permission}[2]
