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
    [Documentation]   Verify that User is unable to Access Jupyterhub after modifying Access Groups in rhods-groups-config
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-572
    Apply Access Groups Settings    admins_group=    users_group=    groups_modified_flag=true
    Run Keyword And Expect Error  *  Verify User Can Spawn A Notebook
    [Teardown]    Set Default Access Groups


*** Keywords ***
Verify User Can Spawn A Notebook
    [Documentation]    Verifies User is able to Spawn a Minimal notebook
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Default

Set Default Access Groups
    [Documentation]  Sets values of RHODS Groups to Default Values
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings
