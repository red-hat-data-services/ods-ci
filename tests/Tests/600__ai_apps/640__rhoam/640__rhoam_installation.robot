*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Common.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/Page/ODH/AiApps/Rhoam.resource
Resource        ../../../../tasks/Resources/RHODS_OLM/uninstall/uninstall.robot
Resource        ../../../../tasks/Resources/RHODS_OLM/config/cluster.robot
Library         ../../../../libs/Helpers.py
Library         SeleniumLibrary
Library         OpenShiftCLI
Suite Setup     RHOAM Suite Setup
Suite Teardown  RHOAM Suite Teardown


*** Test Cases ***
Verify RHOAM Can Be Installed
    [Documentation]    Verifies RHOAM Addon can be successfully installed
    [Tags]  Tier3
    ${cluster_id}=   Get Cluster ID
    ${cluster_name}=   Get Cluster Name     cluster_identifier=${cluster_id}
    Install Rhoam Addon    cluster_name=${cluster_name}
    Wait Until RHOAM Installation Is Completed    retries=20   retries_interval=2min

Verify RHODS Can Be Uninstalled When RHOAM Is Installed
    [Documentation]    Verifies RHODS can be successfully uninstalled when
    ...                RHOAM addon is installed on the same cluster
    [Tags]  Tier3
    ...     ODS-1136
    ${cluster_id}=   Get Cluster ID
    ${cluster_name}=   Get Cluster Name     cluster_identifier=${cluster_id}
    Set Suite Variable     ${cluster_name}
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}    $ocp_user_name    $ocp_user_pw    $ocp_user_auth_type    $dashboard_url    $browser    $browser_options
    Verify Service Is Enabled    app_name=OpenShift API Management
    Uninstall RHODS From OSD Cluster
    RHODS Operator Should Be Uninstalled


*** Keywords ***
RHOAM Suite Setup
    [Documentation]    RHOAM Suite setup
    Set Library Search Order  SeleniumLibrary

RHOAM Suite Teardown
    [Documentation]    RHOAM Suite teardown. It triggers RHOAM Uninstallation
    Uninstall Rhoam Addon    cluster_name=${cluster_name}
    Close All Browsers

Uninstall RHODS From OSD Cluster
    [Documentation]    Selects the cluster type and triggers the RHODS uninstallation
    Selected Cluster Type OSD
    Uninstall RHODS
