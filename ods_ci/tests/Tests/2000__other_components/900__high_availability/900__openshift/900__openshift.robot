*** Settings ***
Documentation    Test cases that verify High Availability

Library          OperatingSystem
Library          OpenShiftLibrary
Library          DateTime
Library          RequestsLibrary

Resource         ../../../../Resources/ODS.robot
Resource         ../../../../Resources/Page/ODH/Prometheus/Prometheus.robot


*** Test Cases ***
Verify ODS Availability After OpenShift Node Failure
    [Documentation]    Verifies if ODS is prepared to handle node failures
    [Tags]
    ...       Tier3
    ...       ODS-568
    ...       Execution-Time-Over-5min
    ...       AutomationBug
    @{cluster_nodes_info}=    Fetch Cluster Worker Nodes Info
    &{cluster_node_info_dict}=    Set Variable    ${cluster_nodes_info}[0]
    Force Reboot OpenShift Cluster Node    ${cluster_node_info_dict.metadata.name}
    Verify ODS Availability

Verify rhods_aggregated_availability Detects Downtime In Jupyterhub And Dashboard
    [Documentation]    Verifies if rhods_aggregated_availability detects downtime in Jupyterhub and Dashboard.
    [Tags]    ODS-1608
    ...       Tier3
    ...       AutomationBug
    Verify rhods_aggregated_availability Detects Downtime In Component    jupyterhub
    Verify rhods_aggregated_availability Detects Downtime In Component    rhods-dashboard
    Verify rhods_aggregated_availability Detects Downtime In Component    combined


*** Keywords ***
Verify rhods_aggregated_availability Detects Downtime In Component
    [Documentation]  Verifies if rhods_aggregated_availability detects downtime
    ...    in the component specified.
    ...    Args:
    ...        component: Component to be checked.
    ...    Returns:
    ...        None
    [Arguments]    ${component}
    ${label_selector}=    Set Variable If
    ...    "${component}" == "combined"    app in (jupyterhub, rhods-dashboard)    app=${component}
    ${component_delete_result} =    Oc Delete    kind=Pod    api_version=v1
    ...    label_selector=${label_selector}    namespace=${APPLICATIONS_NAMESPACE}
    ${count}=    Get Length    ${component_delete_result[0]['items']}
    Log    ${count}
    ${component_downtime_start_date}=
    ...    Wait Until Keyword Succeeds    1m    1s    Get Date When Availability Value Matches Expected Value    0
    ${component_downtime_end_date}=
    ...    Wait Until Keyword Succeeds    10m    1s    Get Date When Availability Value Matches Expected Value    1
    Run Keyword And Expect Error    There is a Downtime of *
    ...    Verify ODS Availability Range   ${component_downtime_start_date}  ${component_downtime_end_date}
    ...    1s    ${component}
