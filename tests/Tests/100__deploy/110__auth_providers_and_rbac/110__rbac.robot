*** Settings ***
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Library             OpenShiftCLI

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
    [Documentation]   Verify that USer is unable to Access Jupyterhub after modifying Access Groups in rhods-groups-config
    [Tags]    Sanity
    ...       ODS-572
    Run  oc patch configmap rhods-groups-config -n redhat-ods-applications --type="json" -p='[{"op":"replace", "path":"/data/admin_groups", "value":""}]'
    Run  oc patch configmap rhods-groups-config -n redhat-ods-applications --type="json" -p='[{"op":"replace", "path":"/data/allowed_groups", "value":""}]'
    Run  oc rollout latest dc/jupyterhub -n redhat-ods-applications
    Run Keyword And Expect Error  *  Verify User Can Spawn A Notebook
    [Teardown]  Update Access Groups In RHODS Groups Config


*** Keywords ***
Verify User Can Spawn A Notebook
    [Documentation]    Verifies User is able to Spawn a Minimal notebook
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    size=Default

Update Access Groups In RHODS Groups Config
    [Documentation]    Updates the values of Access Groups in rhods-group-config.
    ${version_check}=    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check} == True
        Run  oc patch configmap rhods-groups-config -n redhat-ods-applications --type="json" -p='[{"op":"replace", "path":"/data/admin_groups", "value":"dedicated-admins"}]'
        Run  oc patch configmap rhods-groups-config -n redhat-ods-applications --type="json" -p='[{"op":"replace", "path":"/data/allowed_groups", "value":"system:authenticated"}]'
    ELSE
        Run  oc patch configmap rhods-groups-config -n redhat-ods-applications --type="json" -p='[{"op":"replace", "path":"/data/admin_groups", "value":"rhods-admins"}]'
        Run  oc patch configmap rhods-groups-config -n redhat-ods-applications --type="json" -p='[{"op":"replace", "path":"/data/allowed_groups", "value":"rhods-users"}]'
    END
    Run  oc rollout latest dc/jupyterhub -n redhat-ods-applications
