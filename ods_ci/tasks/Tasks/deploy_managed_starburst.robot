*** Settings ***
Documentation     Perform and verify Managed Starburst,
...               a.k.a Starburst Enterprise for Red Hat (SERH), OLM tasks
Metadata          Managed Starburst OLM Version    1.0.0
Resource          ../Resources/SERH_OLM/install.resource
Resource          ../Resources/RedHatMarketplace.resource
Resource          ../../tests/Resources/Common.robot
Resource          ../../tests/Resources/RHOSi.resource
Library           OperatingSystem
Library           String
Library           OpenShiftLibrary
Library           ../../libs/Helpers.py
Suite Setup       Managed Starburst Installation Setup
Suite Teardown    RHOSi Teardown


*** Tasks ***
Install Managed Starburst Addon
    [Documentation]    Installs Managed Starburst using Addon flow (OCM APIs)
    ...                and checks status
    [Tags]  MISV-79    MISV-84
    Check Managed Staburst Is Not Installed
    ${cluster_id}=   Get Cluster ID
    ${CLUSTER_NAME}=   Get Cluster Name By Cluster ID     cluster_id=${cluster_id}
    Install Managed Starburst Addon    email_address=${DEFAULT_NOTIFICATION_EMAIL}
    ...    license=${STARBURST.LICENSE}    cluster_name=${CLUSTER_NAME}
    Wait Until Managed Starburst Installation Is Completed

Uninstall Managed Starburst
    [Documentation]    Uninstalls Managed Starburst using Addon flow (OCM APIs)
    ...                and checks status
    [Tags]    MISV-82
    ${cluster_id}=   Get Cluster ID
    ${CLUSTER_NAME}=   Get Cluster Name By Cluster ID     cluster_id=${cluster_id}
    Delete Managed Starburst CRs    starburst_enterprise_cr=starburstenterprise
    Uninstall Managed Starburst Using Addon Flow    ${CLUSTER_NAME}
    Check Managed Staburst Is Not Installed


*** Keywords ***
Managed Starburst Installation Setup
    [Documentation]    Setup steps before running the tasks.
    ...                Register the clusters to RHM if not and run RHOSi Setup
    Check Cluster Is Not Already Registered    warn_on_failure=${TRUE}
    Create RedHat Marketplace Project
    Install RedHat Marketplace Operator
    Create RedHat Marketplace Secret    token=${RHM_TOKEN}
    RHOSi Setup
