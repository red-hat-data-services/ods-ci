*** Settings ***
Documentation    Perform and verify Managed Starburst,
...              a.k.a Starburst Enterprise for Red Hat (SERH), OLM tasks
Metadata         Managed Starburst OLM Version    1.0.0
Resource         ../Resources/SERH_OLM/install.robot
Resource         ../../tests/Resources/Common.robot
Library          OpenShiftLibrary
Library          OperatingSystem
Library          String
Library          ../../libs/Helpers.py


*** Tasks ***
Install Managed Starburst Addon
  [Tags]  install-starburst
  Check Managed Starburst Addon Is Not Installed
  ${cluster_id}=   Get Cluster ID
  ${CLUSTER_NAME}=   Get Cluster Name By Cluster ID     cluster_id=${cluster_id}
  ${license_escaped}=    Replace String    ${STARBURST.LICENSE}   "    \\"
  Install Managed Starburst Addon    license=${license_escaped}    cluster_name=${CLUSTER_NAME}
  Wait Until Managed Starburst Installation Is Completed

Uninstall Managed Starburst
    [Tags]    uninstall-starburst
    ${cluster_id}=   Get Cluster ID
    ${CLUSTER_NAME}=   Get Cluster Name By Cluster ID     cluster_id=${cluster_id}
    Delete Managed Starburst CRs    starburst_enterprise_cr=starburstenterprise
    Uninstall Managed Starburst Using Addon Flow    ${CLUSTER_NAME}
