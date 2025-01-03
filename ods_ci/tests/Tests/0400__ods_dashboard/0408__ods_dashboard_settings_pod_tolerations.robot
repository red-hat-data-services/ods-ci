*** Settings ***
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource         ../../Resources/Page/OCPDashboard/Pods/Pods.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Library          ../../../libs/Helpers.py
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown
Test Tags        Dashboard


*** Variables ***
@{UNSUPPORTED_TOLERATIONS}=    --UNSUPPORTED--    Unsupported-    -Unsupported    Unsupported!    1-_.a@    L@5t0n3!


*** Test Cases ***
Test Setting Unsupported Pod Toleration Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]  Sanity
    ...     ODS-1788
    Clean All Standalone Notebooks
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains    Notebook pod tolerations
    FOR    ${toleration}    IN    @{UNSUPPORTED_TOLERATIONS}
        Verify Unsupported Toleration Is Not Allowed    ${toleration}
    END

Verify Toleration Is Applied To Pod
    [Documentation]    Sets Toleration via the admin UI, and verifies Pod spawns with expected toleration
    [Tags]  Sanity
    ...     ODS-1684    ODS-1685
    Menu.Navigate To Page    Settings    Cluster settings
    Set Pod Toleration Via UI    TestToleration
    Save Changes In Cluster Settings
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=minimal-notebook
    Verify Server Pod Has The Expected Toleration    TestToleration


*** Keywords ***
Verify Server Pod Has The Expected Toleration
    [Documentation]    Verifies Pod contains toleration
    [Arguments]    ${toleration}
    ${expected} =    Set Variable    ${toleration}:NoSchedule op=Exists
    ${current_user} =    Get Current User In JupyterLab
    ${notebook_pod_name} =   Get User Notebook Pod Name  ${current_user}
    ${received} =  Get Pod Tolerations    ${notebook_pod_name}
    List Should Contain Value  ${received}  ${expected}
    ...    msg=Unexpected Pod Toleration

Verify Unsupported Toleration Is Not Allowed
    [Documentation]    Test an unsupported pod toleration and expect it
    ...    to not be allowed.
    [Arguments]    ${toleration}
    Set Pod Toleration Via UI    ${toleration}
    Page Should Contain    Toleration key must consist of alphanumeric characters, '-', '_' or '.', and must start and end with an alphanumeric character.
    Element Should Be Disabled    xpath://button[.="Save changes"]

Suite Setup
    [Documentation]    Setup for the Toleration tests
    Begin Web Test    jupyter_login=${FALSE}
    Clean All Standalone Notebooks

Suite Teardown
    [Documentation]    Removes Tolerations and cleans up
    Clean All Standalone Notebooks
    Open ODS Dashboard With Admin User
    Menu.Navigate To Page    Settings    Cluster settings
    Disable Pod Toleration Via UI
    Save Changes In Cluster Settings
    Close Browser
