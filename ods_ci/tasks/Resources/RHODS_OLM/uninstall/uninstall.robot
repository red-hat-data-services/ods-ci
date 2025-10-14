*** Settings ***
Resource   ../install/oc_install.robot
Resource   ../pre-tasks/oc_is_operator_installed.robot
Resource   ../../../../tests/Resources/Common.robot
Resource   oc_uninstall.robot
Library    Process

*** Variables ***
${SERVERLESS_NS}=    openshift-serverless
${OPENSHIFT_OPERATORS_NS}=    openshift-operators
${KNATIVE_SERVING_NS}=      knative-serving
${KNATIVE_EVENTING_NS}=       knative-eventing
${ISTIO_SYSTEM_NS}=       istio-system
${KUEUE_NS}=    openshift-kueue-operator
${CERT_MANAGER_NS}=    cert-manager-operator


*** Keywords ***
Uninstalling RHODS Operator
  IF  "${cluster_type}" == "selfmanaged"
      Set Global Variable    ${CATALOG_NAME}    rhoai-catalog-dev
  ELSE IF  "${cluster_type}" == "managed"
      Set Global Variable    ${CATALOG_NAME}     addon-managed-odh-catalog
      #For managed cluster
      IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
           Set Global Variable    ${CATALOG_NAME}    rhoai-catalog-dev
      END
  ELSE
      FAIL    Provided test environment and install type ${INSTALL_TYPE} ${UPDATE_CHANNEL} ${cluster_type} combination
      ...     is not supported
  END
  Run Keywords
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
  [Documentation]   UnInstall rhods on managed cluster using cli
  Clone OLM Install Repo
  ${return_code}    Run and Watch Command
  ...    cd ${EXECDIR}/${OLM_DIR} && ./cleanup.sh -t addon -a "authorino serverless servicemesh clusterobservability tempo opentelemetry kueue certmanager cma"
  ...    timeout=20 min
  Should Be Equal As Integers  ${return_code}   0   msg=Error detected while un-installing ODH/RHOAI

Uninstall RHODS In Self Managed Cluster
  [Documentation]  Uninstall rhods from self-managed cluster
  IF  "${INSTALL_TYPE}" == "Cli"
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
  [Documentation]   UnInstall rhods on self-managed cluster using cli
  Clone OLM Install Repo
  ${return_code}    Run and Watch Command
  ...    cd ${EXECDIR}/${OLM_DIR} && ./cleanup.sh -t operator -a "authorino serverless servicemesh clusterobservability tempo opentelemetry kueue certmanager cma"
  ...    timeout=20 min
  Should Be Equal As Integers  ${return_code}   0   msg=Error detected while un-installing ODH/RHOAI

Uninstall RHODS In Self Managed Cluster For Operatorhub
  [Documentation]   Uninstall rhods on self-managed cluster for operatorhub installtion
  ${return_code}    ${output}    Run And Return Rc And Output   oc create configmap delete-self-managed-odh -n ${OPERATOR_NAMESPACE}
  Should Be Equal As Integers  ${return_code}   0   msg=Error creation deletion configmap
  ${return_code}    ${output}    Run And Return Rc And Output   oc label configmap/delete-self-managed-odh api.openshift.com/addon-managed-odh-delete=true -n ${OPERATOR_NAMESPACE}
  Should Be Equal As Integers  ${return_code}   0   msg=Error observed while adding label to configmap
  Verify Project Does Not Exists  ${APPLICATIONS_NAMESPACE}
  Verify Project Does Not Exists  ${MONITORING_NAMESPACE}
  Verify Project Does Not Exists  ${NOTEBOOKS_NAMESPACE}
  ${return_code}    ${output}    Run And Return Rc And Output   oc delete namespace ${OPERATOR_NAMESPACE}

Uninstall Kueue Operator CLI
    [Documentation]    Keyword to uninstall the Kueue Operator
    Log To Console    message=Deleting Kueue Operator Subscription From Cluster
    ${return_code}    ${csv_name}    Run And Return Rc And Output
    ...    oc get subscription kueue-operator -n ${KUEUE_NS} -o json | jq '.status.currentCSV' | tr -d '"'
    IF  "${return_code}" == "0" and "${csv_name}" != "${EMPTY}"
       ${return_code}    ${output}    Run And Return Rc And Output
       ...    oc delete clusterserviceversion ${csv_name} -n ${KUEUE_NS}
       Should Be Equal As Integers  ${return_code}   0   msg=Error deleting Kueue CSV ${csv_name}
    END
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete subscription kueue-operator -n ${KUEUE_NS}
    Log To Console    message=Deleting Kueue Operator Group From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete operatorgroup --all -n ${KUEUE_NS} --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting Kueue operator group
    Log To Console    message=Deleting Kueue CR From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc patch kueues.kueue.openshift.io cluster --type=merge -p '{"metadata": {"finalizers":null}}'
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete kueues.kueue.openshift.io --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting Kueue CR

Check Number Of Resource Instances Equals To
    [Documentation]    Keyword to check if the amount of instances of a specific CRD in a given namespace
    ...                equals to a given number
    [Arguments]     ${resource}      ${namespace}     ${desired_amount}
    ${return_code}    ${amount}    Run And Return Rc And Output
    ...    oc get ${resource} -n ${namespace} -o json | jq -r '.items | length'
    Should Be Equal As Integers  ${return_code}   0   msg=Error calculating number of ${resource}
    Should Be Equal As Integers  ${amount}   ${desired_amount}   msg=Error: ${amount} not equals to ${desired_amount}
