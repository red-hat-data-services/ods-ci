*** Settings ***
Documentation      Test Suite for Upgrade testing, to be run before the upgrade
Library            OpenShiftLibrary
Resource           ../../../Resources/RHOSi.resource
Resource           ../../../Resources/ODS.robot
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource           ../../../Resources/Page/ODH/AiApps/Rhosak.resource
Resource           ../../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource           ../../../Resources/Page/LoginPage.robot
Resource           ../../../Resources/Page/OCPLogin/OCPLogin.robot
Resource           ../../../Resources/Common.robot
Resource           ../../../Resources/Page/OCPDashboard/Pods/Pods.robot
Resource           ../../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource           ../../../Resources/Page/HybridCloudConsole/OCM.robot
Suite Setup        Dashboard Suite Setup
Suite Teardown     RHOSi Teardown


*** Variables ***
${CUSTOM_CULLER_TIMEOUT}      60000
${S_SIZE}       25


*** Test Cases ***
Set PVC Size Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Set PVC Value In RHODS Dashboard    ${S_SIZE}
    [Teardown]   Dashboard Test Teardown

Set Culler Timeout
    [Documentation]    Sets a culler timeout via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Modify Notebook Culler Timeout     ${CUSTOM_CULLER_TIMEOUT}
    [Teardown]   Dashboard Test Teardown

Setting Pod Toleration Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains    Notebook pod tolerations
    Set Pod Toleration Via UI    TestToleration
    Disable "Usage Data Collection"
    [Teardown]   Dashboard Test Teardown

Verify RHODS Accept Multiple Admin Groups And CRD Gets Updates
    [Documentation]    Verify that users can set multiple admin groups and
    ...                check OdhDashboardConfig CRD gets updated according to Admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}  #robocop: disable
    Clear User Management Settings
    Add OpenShift Groups To Data Science Administrators   rhods-admins  rhods-users
    Add OpenShift Groups To Data Science User Groups    system:authenticated
    Save Changes In User Management Setting
    [Teardown]   Dashboard Test Teardown

Verify Custom Image Can Be Added
    [Documentation]  Create Custome notebook using Cli
    [Tags]  Upgrade
    Oc Apply    kind=ImageStream   src=ods_ci/tests/Tests/100__deploy/120__upgrades/custome_image.yaml


*** Keywords ***
Dashboard Suite Setup
    [Documentation]  Basic suite setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Dashboard Test Teardown
    [Documentation]  Basic suite teardown
    Close All Browsers
