*** Settings ***
Documentation       Post install test cases that verify OCP JupyterHub resources and objects

Library             OpenShiftLibrary
Resource          ../../../Resources/ODS.robot
Resource          ../../../Resources/RHOSi.resource
Suite Setup       RHOSi Setup
Suite Teardown    RHOSi Teardown


*** Test Cases ***
Verify JupyterHub DB Is Shipped And Enabled Within ODS
    [Documentation]    Verifies if JupyterHub DB is shipped and enabled within ODS
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-236
    Skip If RHODS Version Greater Or Equal Than    version=1.16.0
    ${cluster_platform_type}=    Fetch Cluster Platform Type
    Skip if    "${cluster_platform_type}" != "OpenStack"
    ...    This test only applies to PSI clusters
    @{jupyterhub_db_pods_info}=    Fetch JupyterHub DB Pods Info
    @{jupyterhub_db_services_info}=    Fetch JupyterHub DB Services Info
    @{jupyterhub_db_replicationcontrollers_info}=    Fetch JupyterHub DB ReplicationControllers Info
    OpenShift Resource Field Value Should Be Equal As Strings    status.phase    Running    @{jupyterhubdb_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.containerStatuses[0].name    postgresql    @{jupyterhubdb_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.conditions[2].status    True    @{jupyterhubdb_pods_info}
    OpenShift Resource Field Value Should Be Equal As Strings    status.replicas    1    @{jupyterhubdb_replicationcontrollers_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.replicas    1    @{jupyterhubdb_replicationcontrollers_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].name    5432-tcp    @{jupyterhubdb_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].port    5432    @{jupyterhubdb_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].protocol    TCP    @{jupyterhubdb_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    spec.ports[0].targetPort    5432    @{jupyterhubdb_services_info}
    OpenShift Resource Field Value Should Be Equal As Strings    metadata.labels.app    jupyterhub    @{jupyterhubdb_services_info}
    OpenShift Resource Field Value Should Match Regexp    spec.clusterIP    ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$
    ...    @{jupyterhubdb_services_info}

Verify PostgreSQL Is Not Deployed When AWS RDS Is Enabled
    [Documentation]    Verifies if PostgreSQL is not deployed when AWS RDS is enabled
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-336
    Skip      msg=PostgreSQL Pod is removed after KFNBC migration

Verify JupyterHub Receives Credentials And Creates Instance Of AWS RDS
    [Documentation]    Verifies if JupyterHub receives the credentials for AWS RDS
    ...                and creates the AWS RDS instance
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-337
    ...       ODS-338
    Skip  msg=JupyterHub Secret is removed after KFNBC migration

*** Keywords ***
Fetch JupyterHub DB Pods Info
    [Documentation]  Fetches information about JupyterHub DB Pods
    ...    Args:
    ...        None
    ...    Returns:
    ...        jupyterhub_db_pod_info(list(dict)): JupyterHub DB Pods information
    @{jupyterhub_db_pods_info}=    Oc Get    kind=Pod    api_version=v1    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=deployment=jupyterhub-db-1
    RETURN    @{jupyterhub_db_pods_info}

Fetch JupyterHub DB Services Info
    [Documentation]  Fetches information about JupyterHub DB services
    ...    Args:
    ...        None
    ...    Returns:
    ...        jupyterhubdb_services_info(list(dict): JupyterHub DB Services information
    @{jupyterhub_db_services_info}=    Oc Get    kind=Service   api_version=v1    name=jupyterhub-db    namespace=${APPLICATIONS_NAMESPACE}
    RETURN    @{jupyterhub_db_services_info}

Fetch JupyterHub DB ReplicationControllers Info
    [Documentation]    Fetch information about JupyterHub DB ReplicationControllers
    ...    Args:
    ...        None
    ...    Returns:
    ...        jupyterhubdb_replicationcontrollers_info(list(dict)): JupyterHub DB ReplicationControllers information
    @{jupyterhub_db_replicationcontrollers_info} =    Oc Get    kind=ReplicationController    api_version=v1    namespace=${APPLICATIONS_NAMESPACE}
    ...    name=jupyterhub-db-1
    RETURN    @{jupyterhub_db_replicationcontrollers_info}

Fetch JupyterHub RDS Secret Info
    [Documentation]  Fetches information about JupyterHub RDS Secret
    ...    Args:
    ...        None
    ...    Returns:
    ...        jupyterhub_rds_secret(dict): JupyterHub RDS Secret information
    @{resources_info_list}=    Oc Get    kind=Secret    api_version=v1    namespace=${APPLICATIONS_NAMESPACE}
    ...    name=jupyterhub-rds-secret
     &{jupyterhub_rds_secret_info}=    Set Variable    ${resources_info_list}[0]
    RETURN    &{jupyterhub_rds_secret_info}
