*** Settings ***
Resource   ../install/oc_install.robot
*** Keywords ***
Uninstalling RHODS Operator
  ${is_operator_installed} =  Is RHODS Installed
  IF  ${is_operator_installed}  Run Keywords
  ...  Log  Uninstalling RHODS operator in ${cluster_type}  console=yes  AND
  ...  Uninstall RHODS

Uninstall RHODS
  IF  "${cluster_type}" == "managed"
    Uninstall RHODS In OSD
  ELSE IF  "${cluster_type}" == "selfmanaged"
    Uninstall RHODS In Self Managed Cluster
  ELSE
    Fail  Kindly provide supported cluster type
  END

Uninstall RHODS In OSD
  Clone OLM Install Repo
  ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${filename} && ./cleanup.sh -t addon   #robocop:disable
  Should Be Equal As Integers	${return_code}	 0   msg=Error detected while un-installing RHODS
  Log To Console   ${output}

Uninstall RHODS In Self Managed Cluster
  Clone OLM Install Repo
  ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${filename} && ./cleanup.sh -t operator   #robocop:disable
  Should Be Equal As Integers	${return_code}	 0   msg=Error detected while un-installing RHODS
  Log To Console   ${output}

RHODS Operator Should Be Uninstalled
  Verify RHODS Uninstallation
  Log  RHODS has been uninstalled  console=yes
