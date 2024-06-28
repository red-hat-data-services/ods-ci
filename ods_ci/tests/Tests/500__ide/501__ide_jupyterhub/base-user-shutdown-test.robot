*** Settings ***
Documentation    Test Case that verifies a base user has the permission to stop their own servers
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Suite Setup      Setup
Suite Teardown   End Web Test


*** Test Cases ***
Verify Base User Can Stop A Running Server
    [Documentation]    Verifies that a base user has enough permission to start
    ...                and stop a notebook server
    [Tags]    Smoke
    ...       Tier1
    ...       OpenDataHub
    ...       ODS-1978
    Launch KFNBC Spawner As Base User
    Launch Notebook And Go Back To Control Panel Window
    Verify That Server Can Be Stopped


*** Keywords ***
Setup
    [Documentation]    Suite setup keyword
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Launch KFNBC Spawner As Base User
    [Documentation]    Launches a browser and logs into KFNBC as a base user
    Launch Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Launch JupyterHub Spawner From Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}
    ...    ${TEST_USER.AUTH_TYPE}

Launch Notebook And Go Back To Control Panel Window
    [Documentation]    Spawns a notebook server, opens it in a new tab, and Switches
    ...    back to the dashboard control panel
    ${handle} =    Switch Window    CURRENT
    Select Notebook Image    minimal-notebook
    Select Container Size     Small
    Spawn Notebook    same_tab=${False}
    Switch Window    ${handle}

Verify That Server Can Be Stopped
    [Documentation]    Tries to stop a server and verifies that the pod is group_name
    ...    from the cluster, waiting for a configurable `${timeout}` for it to disappear
    [Arguments]    ${timeout}=30
    Handle Control Panel
    Wait Until JupyterHub Spawner Is Ready
    ${notebook_pod_name} =   Get User Notebook Pod Name  ${TEST_USER_3.USERNAME}
    ${stopped} =    Set Variable    ${False}
    TRY
        WHILE    not ${stopped}    limit=${timeout}
            ${stopped} =  Run Keyword And Return Status  Run Keyword And Expect Error
            ...    Pods not found in search  OpenShiftLibrary.Search Pods
            ...    ${notebook_pod_name}  namespace=${NOTEBOOKS_NAMESPACE}
            Sleep    1s
        END
    EXCEPT    WHILE loop was aborted    type=start
        Delete User Notebook CR    ${TEST_USER_3.USERNAME}
        Fail    User Notebook pod was not removed within ${timeout}s
    END
