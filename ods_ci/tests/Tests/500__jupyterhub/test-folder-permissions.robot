*** Settings ***
Documentation       Test Suite to check the folder permissions

Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource            ../../Resources/Page/OCPDashboard/Builds/Builds.robot

Library             JupyterLibrary

Suite Setup         Load Spawner Page
Suite Teardown      End Web Test


*** Variables ***
@{LIST_OF_IMAGES} =    minimal-notebook    science-notebook
...                    pytorch    tensorflow    minimal-gpu
@{EXPECTED_PERMISSIONS} =       0775    0    1001
@{FOLDER_TO_CHECK} =            /opt/app-root/lib    /opt/app-root/share


*** Test Cases ***
Verify Folder Permissions
    [Documentation]    Checks Access, Gid, Uid of /opt/app-root/lib and /opt/app-root/shares
    [Tags]    ODS-486
    ...       Tier2
    Verify Folder Permissions For Images    image_list=${LIST_OF_IMAGES}
    ...    folder_to_check=${FOLDER_TO_CHECK}    expected_permissions=${EXPECTED_PERMISSIONS}


*** Keywords ***
Load Spawner Page
    [Documentation]    Suite Setup, loads JH Spawner
    ${version_check} =  Is RHODS Version Greater Or Equal Than  1.20.0
    IF    ${version_check}==False
       Wait Until All Builds Are Complete    namespace=${APPLICATIONS_NAMESPACE}    build_timeout=45m
    END
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
    Launch Jupyter From RHODS Dashboard Link
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready

Verify The Permissions Of Folder
    [Documentation]    It checks for the folder permissions ${permission}[0], ${permission}[1], ${permission}[2]
    ...                should be of Access, Uid and Gid respectively.
    [Arguments]    ${path}    @{permission}
    Run Keyword And Continue On Failure
    ...    Run Cell And Check Output
    ...    !stat ${path} | grep Access | awk '{split($2,b,"."); printf "%s", b[1]}' | awk '{split($0, c, "/"); printf c[1]}' | cut -c 2-5
    ...    ${permission}[0]
    Run Keyword And Continue On Failure
    ...    Run Cell And Check Output
    ...    !stat ${path} | grep Uid | awk '{split($9,b,"."); printf "%s", b[1]}' | awk '{split($0, c, "/"); printf c[1]}'
    ...    ${permission}[1]
    Run Keyword And Continue On Failure
    ...    Run Cell And Check Output
    ...    !stat ${path} | grep Gid | awk '{split($5,b,"."); printf "%s", b[1]}' | awk '{split($0, c, "/"); printf c[1]}'
    ...    ${permission}[2]

Verify Folder Permissions For Images
    [Documentation]    Checks the folder permissions in each image
    [Arguments]    ${image_list}    ${folder_to_check}    ${expected_permissions}
    FOR    ${img}    IN    @{image_list}
        Verify The Permissions Of Folder In Image    ${img}    ${folder_to_check}    ${expected_permissions}
    END
