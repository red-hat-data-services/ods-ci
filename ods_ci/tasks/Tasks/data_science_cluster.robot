*** Settings ***
Documentation    Perform and verify DataScienceCluster tasks
Metadata         DataScienceCluster Version    1.0.0
Resource         ../Resources/DSC/DSC.resource
Resource         ../../tests/Resources/Common.robot
Library          OpenShiftLibrary
Library          OperatingSystem
Library          String

***Variables***
${UPDATE_CHANNEL}            beta

*** Tasks ***
Can Install DataScienceCluster
  [Tags]  install
  When Installing DataScienceCluster
  Then DataScienceCluster Should Be Installed

Can Uninstall DataScienceCluster
  [Tags]  uninstall
  When Uninstalling DataScienceCluster
  Then DataScienceCluster Should Be Uninstalled
