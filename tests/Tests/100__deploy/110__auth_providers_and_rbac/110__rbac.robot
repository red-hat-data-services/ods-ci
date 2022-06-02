*** Settings ***
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/OCPDashboard/OCPDashboard.resource

Suite Setup         Set Library Search Order  SeleniumLibrary
Suite Teardown      End Web Test


*** Test Cases ***
Verify Default Access Groups Settings And JupyterLab Notebook Access
    [Documentation]    Verify that ODS Contains Expected Groups and User Can Spawn Notebook
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1164
    Verify Default Access Groups Settings
    Verify User Can Spawn A Notebook

Verify Empty Group Doesnt Allow Users To Spawn Notebooks
    [Documentation]   Verify that User is unable to Access Jupyterhub after setting Access Groups in rhods-groups-config to Empty
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-572
    Apply Access Groups Settings    admins_group=    users_group=    groups_modified_flag=true
    Verify User Can Spawn A Notebook
    [Teardown]    Set Default Access Groups


*** Keywords ***
Verify User Can Spawn A Notebook
    [Documentation]    Verifies User is able to Spawn a Minimal notebook
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Menu.Navigate To Page    Applications    Enabled
    Launch JupyterHub From RHODS Dashboard Link
    Login To Jupyterhub  ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Fix Spawner Status
    Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
    Run Keyword And Expect Error    *    Wait Until JupyterHub Spawner Is Ready

Set Default Access Groups
    [Documentation]  Sets values of RHODS Groups to Default Values
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings
