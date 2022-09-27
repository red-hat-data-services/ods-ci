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

${LIMIT_TIME} =    40

*** Test Cases ***
Verify Average Spawn Time Is Less Than 40 Seconds
    [Documentation]    Verifies that average spawn time for all JupyterHub images is less than 40 seconds
    [Tags]    ODS-691
    ...       Tier2
    ${len} =    Get Length    ${LIST_OF_IMAGES}
    ${avg_time} =    Get Average Time For Spawning    ${len}
    Log    total_avg time to spawn ${avg_time}
    Average Spawning Time Should Be Less Than    ${avg_time}    ${LIMIT_TIME}


*** Keywords ***
Load Spawner Page
    [Documentation]    Suite Setup, loads JH Spawner
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard

Get Average Time For Spawning
    [Documentation]    Returns the total of average time for spawning the images
    [Arguments]    ${number_of_images}
    ${total_time} =    Set Variable
    FOR    ${image}    IN    @{LIST_OF_IMAGES}
        ${avg} =    Set Variable
        Spawn and Stop Server    ${image}
        FOR    ${counter}    IN RANGE    4
            Close Previous Tabs
            ${sum} =    Spawn and Stop Server    ${image}
            ${avg} =    Evaluate    ${avg} + ${sum}
        END
        ${avg} =    Evaluate    ${avg}/4
        ${total_time} =    Evaluate    ${total_time} + ${avg}
    END
    ${average_time} =    Evaluate    ${total_time} / ${number_of_images}
    [Return]    ${average_time}

Average Spawning Time Should Be Less Than
    [Documentation]    Checks than average time is less than ${time}
    [Arguments]    ${avg_time}    ${time}
    ${result} =    Evaluate    float(${avg_time}) < float(${time})
    Run Keyword Unless    ${result}    Fail


Spawn and Stop Server
    [Documentation]    Returns time to start a server
    [Arguments]    ${image}
    Select Notebook Image  ${image}
    Run Keyword And Return Status    Wait Until JupyterHub Spawner Is Ready
    ${time1} =    Get Time    format=%H:%M:%S.%f
    Spawn Notebook
    Run Keyword And Warn On Failure   Login To Openshift  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    # If this fails we waited for 60s. Avg. time will be thrown off, might be acceptable
    # given that we weren't able to spawn?
    Run Keyword And Continue On Failure  Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
    ${time2} =    Get Time
    ${time} =    Subtract Date From Date    ${time2}    ${time1}
    Sleep  0.5s
    Stop JupyterLab Notebook Server
    Go To    ${ODH_DASHBOARD_URL}
    Wait For RHODS Dashboard To Load
    Launch Jupyter From RHODS Dashboard Link
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready
    [Return]    ${time}

Close Previous Tabs
    [Documentation]    Closes the previous opened tabs
    ${windowhandles}=  Get Window Handles
    ${len} =    Get Length    ${windowhandles}
    ${len} =    Evaluate    ${len} - 1

    FOR    ${counter}    IN RANGE    ${len}
        Switch Window  ${windowhandles}[${counter}]
        close window
    END
    Switch Window  ${windowhandles}[${len}]
