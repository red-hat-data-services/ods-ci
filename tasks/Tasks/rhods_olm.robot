*** Settings ***
Documentation    Perform and verify RHODS OLM tasks
Metadata         RHODS OLM Version    1.0.0
Resource         ../Resources/RHODS_OLM/RHODS_OLM.resource
Library          OpenShiftLibrary
Library          OperatingSystem
Library          String

***Variables***
${cluster_type}          OSD
${operator_version}      latest
${RHODS_INSTALL_REPO}    None
*** Tasks ***
Can Install RHODS Operator
  [Tags]  install
  Given Selected Cluster Type ${cluster_type}
  When Installing RHODS Operator ${operator_version}
  Then RHODS Operator Should Be Installed
  [Teardown]   Install Teardown

Can Uninstall RHODS Operator
  [Tags]  uninstall
  Given Selected Cluster Type ${cluster_type}
  When Uninstalling RHODS Operator
  Then RHODS Operator Should Be Uninstalled

Can Upgrade RHODS Operator
  [Tags]  upgrade
  ...     ODS-543
  Given Selected Cluster Type ${cluster_type}
  When Upgrading RHODS Operator ${operator_version}
  Then RHODS Operator Should Be Upgraded
