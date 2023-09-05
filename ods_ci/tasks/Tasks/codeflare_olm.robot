*** Settings ***
Documentation    Perform and verify CodeFlare OLM tasks
Metadata         CodeFlare OLM Version    1.0.0
Resource         ../Resources/CODEFLARE_OLM/CODEFLARE_OLM.resource
Resource         ../../tests/Resources/Common.robot
Library          OpenShiftLibrary
Library          OperatingSystem
Library          String

***Variables***
${cluster_type}              selfmanaged
${UPDATE_CHANNEL}            beta

*** Tasks ***
Can Install CodeFlare Operator
  [Tags]  install
  Given Selected Cluster Type ${cluster_type}
  When Installing CodeFlare Operator ${image_url}
  Then CodeFlare Operator Should Be Installed
  [Teardown]   Install Teardown

Can Uninstall CodeFlare Operator
  [Tags]  uninstall
  Given Selected Cluster Type ${cluster_type}
  When Uninstalling CodeFlare Operator
  Then CodeFlare Operator Should Be Uninstalled
  [Teardown]   Install Teardown

Can Upgrade CodeFlare Operator
  [Tags]  upgrade
  Given Selected Cluster Type ${cluster_type}
  When Upgrading CodeFlare Operator ${image_url}
  Then CodeFlare Operator Should Be Upgraded
