*** Settings ***
Documentation    Test cases that verify High Availability

Library          OperatingSystem
Library          OpenShiftLibrary

Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Page/ODH/Prometheus/Prometheus.robot


*** Test Cases ***
Verify ODS Availability After OpenShift Node Failure
    [Documentation]    Verifies if ODS is prepared to handle node failures. RHODS-4364
    [Tags]
    ...       Tier3
    ...       ODS-568
    ...       Execution-Time-Over-7min
    ...       ProductBug
    @{cluster_nodes_info}=    Fetch Cluster Worker Nodes Info
    &{cluster_node_info_dict}=    Set Variable    ${cluster_nodes_info}[0]
    Force Reboot OpenShift Cluster Node    ${cluster_node_info_dict.metadata.name}
    Verify ODS Availability
