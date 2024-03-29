*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Common.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/Page/ODH/AiApps/Rhoam.resource
Resource        ../../../Resources/ODS.robot
Library         ../../../../libs/Helpers.py
Library         SeleniumLibrary
Library         OpenShiftLibrary
Suite Setup     RHOAM Install Suite Setup
Suite Teardown  RHOAM Suite Teardown
Test Tags       ExcludeOnODH


*** Test Cases ***
Verify RHOAM Can Be Installed
    [Documentation]    Verifies RHOAM Addon can be successfully installed
    [Tags]  Tier3
    ...     ODS-1310    ODS-1249
    ...     Execution-Time-Over-30min
    Pass Execution    Passing tests, as suite setup ensures that RHOAM installs correctly

Verify RHODS Can Be Uninstalled When RHOAM Is Installed
    [Documentation]    Verifies RHODS can be successfully uninstalled when
    ...                RHOAM addon is installed on the same cluster
    [Tags]  Tier3
    ...     ODS-1136
    ...     DestructiveTest
    ...     Execution-Time-Over-2h
    Skip If RHODS Is Self-Managed
    Verify RHOAM Is Enabled In RHODS Dashboard
    Uninstall RHODS From OSD Cluster    clustername=${CLUSTER_NAME}
    Wait Until RHODS Uninstallation Is Completed


*** Keywords ***
RHOAM Install Suite Setup
    [Documentation]    RHOAM Suite setup
    Set Library Search Order  OpenShiftLibrary  SeleniumLibrary
    Skip If RHODS Is Self-Managed
    ${cluster_id}=   Get Cluster ID
    ${CLUSTER_NAME}=   Get Cluster Name By Cluster ID     cluster_id=${cluster_id}
    Set Suite Variable     ${CLUSTER_NAME}
    Install Rhoam Addon    cluster_name=${CLUSTER_NAME}
    Wait Until RHOAM Installation Is Completed    retries=40   retries_interval=5min
    Verify RHOAM Is Enabled IN RHODS Dashboard

RHOAM Suite Teardown
    [Documentation]    RHOAM Suite teardown. It triggers RHOAM Uninstallation
    Skip If RHODS Is Self-Managed
    Log To Console    Starting uninstallation of RHOAM Addon...
    Uninstall Rhoam Using Addon Flow    cluster_name=${CLUSTER_NAME}
    Log To Console    RHOAM Addon has been uninstalled!
    Close All Browsers

