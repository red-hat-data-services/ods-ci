*** Settings ***
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/OCPDashboard/OCPDashboard.resource

Suite Setup         Set Library Search Order  SeleniumLibrary
Suite Teardown      End Web Test


*** Test Cases ***
Verify Any OpenShift User Can Spawn JupyterLab Notebooks
    [Documentation]    Verify that any OpenShift user should also be a RHODS user
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1164
    Verify Groups ConfigMap Contains The Expected OCP Groups
    Verify User Can Spawn A Notebook


*** Keywords ***
Verify Groups ConfigMap Contains The Expected OCP Groups
    [Documentation]    Verify that ConfigMap contains expected Groups
    ${version_check} =    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check} == True
        Verify Config Map Group Contains Expected Values   rhods-groups-config  admin_groups   dedicated-admins
        Verify Config Map Group Contains Expected Values   rhods-groups-config  allowed_groups   system:authenticated
    ELSE
        Verify Config Map Group Contains Expected Values   rhods-groups-config  admin_groups   rhods-admins
        Verify Config Map Group Contains Expected Values   rhods-groups-config  allowed_groups   rhods-users
    END

Verify User Can Spawn A Notebook
    [Documentation]    Verifies User is able to Spawn a Minimal notebook
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Default
