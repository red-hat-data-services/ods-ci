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
    Wait Until RHOAM Installation Is Completed    retries=35   retries_interval=2min
    Verify RHOAM Is Enabled IN RHODS Dashboard

Verify RHODS Can Be Uninstalled When RHOAM Is Installed
    [Documentation]    Verifies RHODS can be successfully uninstalled when
    ...                RHOAM addon is installed on the same cluster
    [Tags]  Tier3
    ...     ODS-1136
    ${cluster_id}=   Get Cluster ID
    ${CLUSTER_NAME}=   Get Cluster Name By ID     cluster_id=${cluster_id}
    Set Suite Variable     ${CLUSTER_NAME}
    Verify RHOAM Is Enabled In RHODS Dashboard
    Uninstall RHODS From OSD Cluster
    Wait Until RHODS Installation Is Completed


*** Keywords ***
RHOAM Suite Setup
    [Documentation]    RHOAM Suite setup
    Set Library Search Order  OpenShiftLibrary  SeleniumLibrary
    # Set Library Search Order  OpenShiftLibrary

RHOAM Suite Teardown
    [Documentation]    RHOAM Suite teardown. It triggers RHOAM Uninstallation
    Log To Console    Starting uninstallation of RHOAM Addon...
    Uninstall Rhoam Addon    cluster_name=${CLUSTER_NAME}
    Log To Console    RHOAM Addon has been uninstalled!
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

Wait Until RHODS Installation Is Completed
    [Arguments]     ${retries}=30   ${retries_interval}=2min
    FOR  ${retry_idx}  IN RANGE  0  1+${retries}
        Log To Console    checking RHODS uninstall status: retry ${retry_idx}
        ${ns_deleted}=     Run Keyword And Return Status    RHODS Namespaces Should Not Exist
        Exit For Loop If    $ns_deleted == True
        Sleep    ${retries_interval}
    END
    IF    $ns_deleted == False
        Fail    RHODS didn't get "complete" stage after ${retries} retries
        ...     (time between retries: ${retries_interval}). Check the cluster..
    END

RHODS Namespaces Should Not Exist
    Verify Project Does Not Exists  rhods-notebook
    Verify Project Does Not Exists  redhat-ods-monitoring
    Verify Project Does Not Exists  redhat-ods-applications
    Verify Project Does Not Exists  redhat-ods-operator
