*** Settings ***
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../Resources/RHOSi.resource
Suite Setup         Rbac Suite Setup
Suite Teardown      Rbac Suite Teardown


*** Test Cases ***
Verify RHODS Has The Expected Default Access Groups Settings
    [Documentation]    Verify that RHODS is installed with the expected default user groups configuration
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1164
    [Setup]    Set Standard RHODS Groups Variables
    Verify Default Access Groups Settings

Verify Empty Group Doesnt Allow Users To Spawn Notebooks
    [Documentation]   Verifies that User is unable to Access Jupyterhub after setting Access Groups OdhDashboardConfig CRD to Empty
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-572
    ...       AutomationBug
    Apply Access Groups Settings    admins_group=    users_group=
    Verify User Is Unable To Spawn Notebook
    [Teardown]   Set Default Access Groups And Close Browser


*** Keywords ***
Verify User Can Spawn A Notebook
    [Documentation]    Verifies User is able to Spawn a Minimal notebook
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=minimal-notebook    size=Small

Verify User Is Unable To Spawn Notebook
    [Documentation]    Verifies User is unable to access notebooks in jupyterhub
    Launch Dashboard    ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}  ${ODH_DASHBOARD_URL}  ${BROWSER.NAME}  ${BROWSER.OPTIONS}
    ${version_check}=    Is RHODS Version Greater Or Equal Than    1.20.0
    IF    ${version_check} == True
        ${status}=    Run Keyword And Return Status     Launch Jupyter From RHODS Dashboard Link
        Run Keyword And Continue On Failure    Should Be Equal    ${status}    ${FALSE}
        Run Keyword And Continue On Failure    Page Should Contain    Access permissions needed
        Run Keyword And Continue On Failure    Page Should Contain    ask your administrator to adjust your permissions.
    ELSE
        Launch Jupyter From RHODS Dashboard Link
        Verify Jupyter Access Level    expected_result=none
    END

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
