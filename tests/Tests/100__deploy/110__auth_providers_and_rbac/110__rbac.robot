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


*** Keywords ***
Verify User Can Spawn A Notebook
    [Documentation]    Verifies User is able to Spawn a Minimal notebook
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Default
