*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             DateTime
Library             OpenShiftCLI
Library             DebugLibrary

Suite Setup         Load Spawner Page
Suite Teardown      End Web Test


*** Variables ***
@{LIST_OF_IMAGES}       s2i-minimal-notebook    s2i-generic-data-science-notebook
...                     pytorch                 tensorflow    minimal-gpu


*** Test Cases ***
Average Time For Spawning
    [Documentation]    Calculates avg time taken by server to start
    [Tags]    Tag
    ${total_avg} =    Set Variable
    FOR    ${image}    IN    @{LIST_OF_IMAGES}
        ${avg} =    Set Variable
        FOR    ${counter}    IN RANGE    4
            ${sum} =    Spawn and Stop Server    ${image}
            ${avg} =    Evaluate    ${avg} + ${sum}
        END
        ${avg} =    Evaluate    ${avg}/4
        Log    ${avg}
        ${total_avg} =    Evaluate    ${total_avg} + ${avg}

    END
    ${len} =    Get Length    ${LIST_OF_IMAGES}
    ${total_avg} =    Evaluate    ${total_avg} / ${len}
    Log    total_avg time to spawn ${total_avg}


*** Keywords ***
Load Spawner Page
    [Documentation]    Suite Setup, loads JH Spawner
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard

Spawn and Stop Server
    [Documentation]    Returns time to start a server
    [Arguments]    ${image}
    ${time1} =    Get Time    format=%H:%M:%S.%f
    Spawn Notebook With Arguments    image=${image}
    ${time2} =    Get Time
    ${time} =    Subtract Date From Date    ${time2}    ${time1}
    Clean Up Server
    Stop JupyterLab Notebook Server
    Go To    ${ODH_DASHBOARD_URL}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub From RHODS Dashboard Link
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready
    [Return]    ${time}
