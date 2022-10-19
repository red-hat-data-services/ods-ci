*** Settings ***
Library          DebugLibrary
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Suite Setup      JupyterHub Testing Suite Setup
Suite Teardown   End Web Test
Force Tags       JupyterHub

*** Variables ***
@{UNSUPPORTED_VAR_NAMES}=    1    invalid!    my_v@r_name    with space    L45t_0n3?!


*** Test Cases ***
Logged into OpenShift
    [Tags]  Sanity  Smoke  ODS-127
    Open OCP Console
    Login To Openshift  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait Until OpenShift Console Is Loaded

Can Launch Jupyterhub
    [Tags]  Sanity  Smoke  ODS-935
    #This keyword will work with accounts that are not cluster admins.
    Launch Jupyterhub via App
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Launch Jupyter From RHODS Dashboard Link

Can Login to Jupyterhub
    [Tags]  Sanity  Smoke  ODS-936
    Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Wait Until Page Contains  Start a notebook server

Can Spawn Notebook
    [Tags]  Sanity  Smoke
    ...     ODS-1808
    Fix Spawner Status
    Select Notebook Image  s2i-generic-data-science-notebook
    Select Notebook Image  s2i-minimal-notebook
    Select Container Size  Small
    # Cannot set number of required GPUs on clusters without GPUs anymore
    #Set Number of required GPUs  9
    #Set Number of required GPUs  0
    Add Spawner Environment Variable  env_one  one
    Remove Spawner Environment Variable  env_one
    Add Spawner Environment Variable  env_two  two
    Remove Spawner Environment Variable  env_two
    Add Spawner Environment Variable  env_three  three
    Remove Spawner Environment Variable  env_three
    Add Spawner Environment Variable  env_four  four
    Add Spawner Environment Variable  env_five  five
    Add Spawner Environment Variable  env_six  six
    Remove Spawner Environment Variable  env_four
    Remove Spawner Environment Variable  env_five
    Remove Spawner Environment Variable  env_six
    ${version-check}=   Is RHODS Version Greater Or Equal Than  1.18.0
    IF  ${version-check}==True
        FOR    ${env_var}    IN    @{UNSUPPORTED_VAR_NAMES}
            Verify Unsupported Environment Variable Is Not Allowed    ${env_var}
        END
    END
    Verify Notebook Spawner Modal Does Not Get Stuck When Requesting Too Many Resources To Spawn Server
    Spawn Notebook  same_tab=${False}
    Login To Openshift  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
    Sleep  3
    Maybe Close Popup
    ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
    Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
    Launch a new JupyterLab Document
    Close Other JupyterLab Tabs

Verify Message That Image Builds Are In Progress
    [Documentation]     Verifies that Image Builds In Progress are Shown In RHODS Dashboard
    [Tags]      Tier2
    ...         ODS-460
    ...         ODS-381
    ...         ODS-1348
    ...         FlakyTest
    Delete Last Pytorch Build
    ${new_buildname}=  Start New Pytorch Build
    Launch Dashboard   ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}   ocp_user_auth_type=${TEST_USER.AUTH_TYPE}   dashboard_url=${ODH_DASHBOARD_URL}   browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    RHODS Notification Drawer Should Contain  message=Notebook images are building
    Wait Until Build Status Is    namespace=redhat-ods-applications    build_name=${new_buildname}   expected_status=Complete
    RHODS Notification Drawer Should Contain  message=All notebook image builds are complete


*** Keywords ***
JupyterHub Testing Suite Setup
    Set Library Search Order  SeleniumLibrary
    RHOSi Setup

Delete Last Pytorch Build
    [Documentation]     Searches for last build which contains pytorch and deletes it
    ${build_name}=  Search Last Build  namespace=redhat-ods-applications    build_name_includes=pytorch
    Delete Build    namespace=redhat-ods-applications    build_name=${build_name}

Start New Pytorch Build
    [Documentation]     Starts new Pytorch build and waits until status is running
    ${new_buildname}=  Start New Build    namespace=redhat-ods-applications    buildconfig=s2i-pytorch-gpu-cuda-11.4.2-notebook
    Wait Until Build Status Is    namespace=redhat-ods-applications    build_name=${new_buildname}   expected_status=Running
    [Return]    ${new_buildname}

Verify Notebook Spawner Modal Does Not Get Stuck When Requesting Too Many Resources To Spawn Server
   [Documentation]    Try spawning a server size for which there's not enough resources
   ...    spawner modal should show an error instead of being stuck waiting for resources
   Select Container Size    X Large
   Click Button    Start server
   # This could fail because of https://bugzilla.redhat.com/show_bug.cgi?id=2132043
   Wait Until Page Contains    Insufficient resources to start    timeout=1min
   ...    error=Modal did not fail within 1 minute
   Click Button    Cancel
   Select Container Size    Small
   
Verify Unsupported Environment Variable Is Not Allowed
    [Documentation]    Test an unsupported environment variable name
    ...     and expect it to not be allowed.
    [Arguments]    ${env_var}
    Add Spawner Environment Variable    ${env_var}    ${env_var}
    Page Should Contain    Invalid variable name. The name must consist of alphabetic characters, digits, '_', '-', or '.', and must not start with a digit.
    #Element Should Be Disabled    xpath://button[.="Start server"]
    Remove Spawner Environment Variable    ${env_var}
