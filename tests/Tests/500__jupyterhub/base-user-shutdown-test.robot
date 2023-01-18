*** Settings ***
Documentation    Test Case that verifies a base user has the permission to stop their own servers
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Suite Setup      Setup
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Test Cases ***
Verify Base User Can Stop A Running Server
    Launch KFNBC Spawner As Base User
    Launch Notebook And Go Back To Control Panel Window
    Verify That Server Can Be Stopped


*** Keywords ***
Setup
    Set Library Search Order    SeleniumLibrary

Launch KFNBC Spawner As Base User
    Launch Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Launch JupyterHub Spawner From Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}
    ...    ${TEST_USER.AUTH_TYPE}

Launch Notebook And Go Back To Control Panel Window
    ${handle} = 	Switch Window    CURRENT
    Select Notebook Image    s2i-minimal-notebook
    Select Container Size    Small
    Spawn Notebook    same_tab=${False}
    Switch Window    ${handle}

Verify That Server Can Be Stopped
    [Arguments]    ${timeout}=30
    Handle Control Panel
    Wait Until JupyterHub Spawner Is Ready
    ${notebook_pod_name} =   Get User Notebook Pod Name  ${TEST_USER_3.USERNAME}
    ${stopped} =    Set Variable    ${False}
    TRY
        WHILE    not ${stopped}    limit=${timeout}
            ${stopped} =  Run Keyword And Return Status  Run Keyword And Expect Error
            ...    Pods not found in search  OpenShiftLibrary.Search Pods
            ...    ${notebook_pod_name}  namespace=rhods-notebooks
            Sleep    1s
        END
    EXCEPT    WHILE loop was aborted    type=start
        Fail    Notebook pod was not removed within ${timeout}s
    END