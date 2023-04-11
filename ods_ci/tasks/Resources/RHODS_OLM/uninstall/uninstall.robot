*** Settings ***
Resource   ../install/oc_install.robot
Resource   oc_uninstall.robot
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
      [Documentation]  Uninstall rhods from self-managed cluster
      IF  "${INSTALL_TYPE}" == "CLi"
          Uninstall RHODS In Self Managed Cluster Using CLI
      ELSE IF  "${INSTALL_TYPE}" == "OperatorHub"
          Uninstall RHODS In Self Managed Cluster For Operatorhub
      ELSE
           FAIL    Provided install type is not supported
      END


RHODS Operator Should Be Uninstalled
  Verify RHODS Uninstallation
  Log  RHODS has been uninstalled  console=yes

Uninstall RHODS In Self Managed Cluster Using CLI
   [Documentation]   UnInstall rhods on self-managedcluster using cli
   Clone OLM Install Repo
   ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${filename} && ./cleanup.sh -t operator   #robocop:disable
   Should Be Equal As Integers	${return_code}	 0   msg=Error detected while un-installing RHODS
   Log To Console   ${output}

Uninstall RHODS In Self Managed Cluster For Operatorhub
   [Documentation]   Uninstall rhods on self-managed cluster for operatorhub installtion
   ${return_code}    ${output}    Run And Return Rc And Output   oc create configmap delete-self-managed-odh -n redhat-ods-operator
   Should Be Equal As Integers	${return_code}	 0   msg=Error creation deletion configmap
   ${return_code}    ${output}    Run And Return Rc And Output   oc label configmap/delete-self-managed-odh api.openshift.com/addon-managed-odh-delete=true -n redhat-ods-operator
   Should Be Equal As Integers	${return_code}	 0   msg=Error observed while adding label to configmap
   Verify Project Does Not Exists  redhat-ods-applications
   ${return_code}    ${output}    Run And Return Rc And Output   oc delete namespace redhat-ods-operator
