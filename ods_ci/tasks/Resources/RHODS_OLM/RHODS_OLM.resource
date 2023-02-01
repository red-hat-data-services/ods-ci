*** Settings ***
Resource  config/cluster.robot
Resource  install/oc_install.robot
Resource  install/install.robot
Resource  post-tasks/oc_version.robot
Resource  pre-tasks/oc_is_operator_installed.robot
Resource  uninstall/oc_uninstall.robot
Resource  uninstall/uninstall.robot
Resource  upgrade/oc_upgrade.robot
Resource  upgrade/upgrade.robot
