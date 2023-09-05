*** Settings ***
Resource   ../install/oc_install.robot
Resource   ../../../../tests/Resources/Common.robot
Resource   oc_uninstall.robot

Library    Process

*** Keywords ***
Uninstalling CodeFlare Operator
  ${is_operator_installed} =  Is CodeFlare Installed
  IF  ${is_operator_installed}  Run Keywords
  ...  Log  Uninstalling CodeFlare operator in ${cluster_type}  console=yes  AND
  ...  Uninstall CodeFlare

Uninstall CodeFlare
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete subscription rhods-codeflare-operator -n openshift-operators
    Should Be Equal As Integers	${return_code}	 0   msg=Error deleting CodeFlare subscription
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete csv `oc get csv -n openshift-operators |grep rhods-codeflare-operator |awk '{print $1}'` -n openshift-operators
    Should Be Equal As Integers	${return_code}	 0   msg=Error deleting CodeFlare CSV

CodeFlare Operator Should Be Uninstalled
  Verify CodeFlare Uninstallation
  Log  CodeFlare has been uninstalled  console=yes
