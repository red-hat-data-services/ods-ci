*** Settings ***
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../Resources/RHOSi.resource
Suite Setup         Rbac Suite Setup
Suite Teardown      Rbac Suite Teardown


*** Test Cases ***
Verify Default Access Groups Settings And JupyterLab Notebook Access
    [Documentation]    Verify that ODS Contains Expected Groups and User Can Spawn Notebook
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1164
    Verify Default Access Groups Settings
    Verify User Can Spawn A Notebook
    [Teardown]  End Web Test

Verify Empty Group Doesnt Allow Users To Spawn Notebooks
    [Documentation]   Verifies that User is unable to Access Jupyterhub after setting Access Groups in rhods-groups-config to Empty
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-572
    ...       FlakyTest
    Apply Access Groups Settings    admins_group=    users_group=    groups_modified_flag=true
    Verify User Is Unable To Spawn Notebook
    [Teardown]   Set Default Access Groups And Close Browser


*** Keywords ***
Verify User Can Spawn A Notebook
    [Documentation]    Verifies User is able to Spawn a Minimal notebook
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Small

Verify User Is Unable To Spawn Notebook
    [Documentation]    Verifies User is unable to access notebooks in jupyterhub
    Launch Dashboard    ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}  ${ODH_DASHBOARD_URL}  ${BROWSER.NAME}  ${BROWSER.OPTIONS}
    Launch Jupyter From RHODS Dashboard Link
    Login Verify Access Level    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}    none

Set Default Access Groups And Close Browser
    [Documentation]  Sets values of RHODS Groups to Default Values and closes browser
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings
    Close Browser

Rbac Suite Setup
    [Documentation]    Suite setup
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup

Rbac Suite Teardown
    [Documentation]    Suite teardown
    RHOSi Teardown
