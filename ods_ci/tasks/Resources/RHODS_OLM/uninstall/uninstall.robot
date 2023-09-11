*** Settings ***
Resource   ../install/oc_install.robot
Resource   ../../../../tests/Resources/Common.robot
Resource   oc_uninstall.robot

Library    Process

*** Keywords ***
Uninstalling RHODS Operator
  ${is_operator_installed} =  Is RHODS Installed
  IF  ${is_operator_installed}  Run Keywords
  ...  Log  Uninstalling RHODS operator in ${cluster_type}  console=yes  AND
  ...  Uninstall RHODS

Uninstall RHODS
  ${new_operator} =    Is RHODS Version Greater Or Equal Than    2.0.0
  IF  "${cluster_type}" == "managed" and ${new_operator} == $False
    Uninstall RHODS In OSD
  ELSE IF  "${cluster_type}" == "selfmanaged" and ${new_operator} == $False
    Uninstall RHODS In Self Managed Cluster
  ELSE IF  ${new_operator}
    Uninstall RHODS V2
  ELSE
    Fail  Kindly provide supported cluster type
  END

Uninstall RHODS In OSD
  Clone OLM Install Repo
  ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${OLM_DIR} && ./cleanup.sh -t addon   #robocop:disable
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
  ${return_code}    Run and Watch Command    cd ${EXECDIR}/${OLM_DIR} && ./cleanup.sh -t operator    timeout=10 min
  Should Be Equal As Integers	${return_code}	 0   msg=Error detected while un-installing RHODS

Uninstall RHODS In Self Managed Cluster For Operatorhub
  [Documentation]   Uninstall rhods on self-managed cluster for operatorhub installtion
  ${return_code}    ${output}    Run And Return Rc And Output   oc create configmap delete-self-managed-odh -n redhat-ods-operator
  Should Be Equal As Integers	${return_code}	 0   msg=Error creation deletion configmap
  ${return_code}    ${output}    Run And Return Rc And Output   oc label configmap/delete-self-managed-odh api.openshift.com/addon-managed-odh-delete=true -n redhat-ods-operator
  Should Be Equal As Integers	${return_code}	 0   msg=Error observed while adding label to configmap
  Verify Project Does Not Exists  redhat-ods-applications
  Verify Project Does Not Exists  redhat-ods-monitoring
  Verify Project Does Not Exists  rhods-notebooks
  ${return_code}    ${output}    Run And Return Rc And Output   oc delete namespace redhat-ods-operator

Uninstall RHODS V2
    [Documentation]    Keyword to uninstall the version 2 of the RHODS operator in Self-Managed
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete datasciencecluster $(oc get datasciencecluster --no-headers | awk '{print $1}')
    Should Be Equal As Integers	${return_code}	 0   msg=Error deleting DataScienceCluster CR
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete dscinitialization $(oc get dscinitialization --no-headers | awk '{print $1}')
    Should Be Equal As Integers	${return_code}	 0   msg=Error deleting DSCInitialization CR
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete subscription $(oc get subscription -n redhat-ods-operator --no-headers | awk '{print $1}')
    Should Be Equal As Integers	${return_code}	 0   msg=Error deleting RHODS subscription
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete operatorgroup $(oc get operatorgroup -n redhat-ods-operator --no-headers | awk '{print $1}')
    Should Be Equal As Integers	${return_code}	 0   msg=Error deleting operatorgroup
    ${return_code}    ${output}    Run And Return Rc And Output    oc delete ns -l opendatahub.io/generated-namespace
    Verify Project Does Not Exists  redhat-ods-applications
    Verify Project Does Not Exists  redhat-ods-monitoring
    Verify Project Does Not Exists  rhods-notebooks
    ${return_code}    ${output}    Run And Return Rc And Output   oc delete namespace redhat-ods-operator
    Verify Project Does Not Exists  redhat-ods-operator
