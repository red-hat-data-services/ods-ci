*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Common.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/Page/ODH/AiApps/Rhoam.resource
Resource        ../../../../tasks/Resources/RHODS_OLM/uninstall/uninstall.robot
Resource        ../../../../tasks/Resources/RHODS_OLM/uninstall/oc_uninstall.robot
Resource        ../../../../tasks/Resources/RHODS_OLM/config/cluster.robot
Library         ../../../../libs/Helpers.py
Library         SeleniumLibrary
Library         OpenShiftLibrary
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
    Verify RHOAM Is Enabled IN RHODS Dashboard

Verify RHODS Can Be Uninstalled When RHOAM Is Installed
    [Documentation]    Verifies RHODS can be successfully uninstalled when
    ...                RHOAM addon is installed on the same cluster
    [Tags]  Tier3
    ...     ODS-1136
    ${cluster_id}=   Get Cluster ID
    ${CLUSTER_NAME}=   Get Cluster Name By ID     cluster_id=${cluster_id}
    Set Suite Variable     ${CLUSTER_NAME}
    Verify RHOAM Is Enabled IN RHODS Dashboard
    Uninstall RHODS From OSD Cluster
    RHODS Operator Should Be Uninstalled


*** Keywords ***
RHOAM Suite Setup
    [Documentation]    RHOAM Suite setup
    Set Library Search Order  SeleniumLibrary
    Set Library Search Order  OpenShiftLibrary

RHOAM Suite Teardown
    [Documentation]    RHOAM Suite teardown. It triggers RHOAM Uninstallation
    Uninstall Rhoam Addon    cluster_name=${CLUSTER_NAME}
    Close All Browsers

Uninstall RHODS From OSD Cluster
    [Documentation]    Selects the cluster type and triggers the RHODS uninstallation
    ${addon_installed}=     Is Rhods Addon Installed    ${CLUSTER_NAME}
    IF    ${addon_installed} == ${TRUE}
        Uninstall Rhods Using Addon    ${CLUSTER_NAME}
    ELSE
        Uninstall RHODS Using OLM
    END

Uninstall RHODS Using OLM
    Selected Cluster Type OSD
    Uninstall RHODS
