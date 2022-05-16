*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             ../../../../libs/Helpers.py
Library             DateTime
Library             OpenShiftCLI
Library             DebugLibrary

Suite Setup         Load Spawner Page
Suite Teardown      End Web Test


*** Variables ***
@{LIST_OF_IMAGES}       s2i-minimal-notebook    s2i-generic-data-science-notebook
...                     pytorch                 tensorflow    minimal-gpu

${LIMIT_TIME} =    40

*** Test Cases ***
Average Time For Spawning
    [Documentation]    Verifies that average spawn time for all JupyterHub images is less than 40 seconds
    [Tags]    ODS-691
    ...       Tier2
    ${total_avg} =    Set Variable
    FOR    ${image}    IN    @{LIST_OF_IMAGES}
        ${avg} =    Set Variable
        Spawn and Stop Server    ${image}
        FOR    ${counter}    IN RANGE    4
            Close Previous Tabs
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
    ${result} =    lt    ${total_avg}.0    ${LIMIT_TIME}.0.0
    Run Keyword Unless    ${result}    Fail


*** Keywords ***
Load Spawner Page
    [Documentation]    Suite Setup, loads JH Spawner
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard

Spawn and Stop Server
    [Documentation]    Returns time to start a server
    [Arguments]    ${image}
    Select Notebook Image  ${image}
    Run Keyword And Return Status    Wait Until JupyterHub Spawner Is Ready
    ${time1} =    Get Time    format=%H:%M:%S.%f
    Spawn Notebook
    Run Keyword And Continue On Failure  Wait Until Page Does Not Contain Element
         ...    id:progress-bar    timeout=600s
    Wait For JupyterLab Splash Screen    timeout=30
    ${time2} =    Get Time
    ${time} =    Subtract Date From Date    ${time2}    ${time1}
    Stop JupyterLab Notebook Server
    Go To    ${ODH_DASHBOARD_URL}
    Wait For RHODS Dashboard To Load

    Launch JupyterHub From RHODS Dashboard Link
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready
    [Return]    ${time}

Close Previous Tabs
    ${windowhandles}=  Get Window Handles

    ${len} =    Get Length    ${windowhandles}
    ${len} =    Evaluate    ${len} - 1

    FOR    ${counter}    IN RANGE    ${len}
        Switch Window  ${windowhandles}[${counter}]
        close window
    END
    Switch Window  ${windowhandles}[${len}]
