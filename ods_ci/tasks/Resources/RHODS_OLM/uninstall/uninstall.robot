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
  Should Be Equal As Integers  ${return_code}   0   msg=Error detected while un-installing RHODS
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
  Should Be Equal As Integers  ${return_code}   0   msg=Error detected while un-installing RHODS

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

Uninstall RHODS V2
    [Documentation]    Keyword to uninstall the version 2 of the RHODS operator in Self-Managed
    Log To Console    message=Deleting DSC CR From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc get DataScienceCluster --all-namespaces -o custom-columns=:metadata.name --ignore-not-found | xargs -I {} oc patch DataScienceCluster {} --type=merge -p '{"metadata": {"finalizers":null}}' || true  #robocop:disable
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete datasciencecluster --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting DataScienceCluster CR
    Log To Console    message=Deleting DSCi CR From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...   oc get DSCInitialization --all-namespaces -o custom-columns=:metadata.name --ignore-not-found | xargs -I {} oc patch DSCInitialization {} --type=merge -p '{"metadata": {"finalizers":null}}' || true  #robocop:disable
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete dscinitialization --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting DSCInitialization CR
    Log To Console    message=Deleting Operator Subscription From Cluster
    ${return_code}    ${subscription_name}    Run And Return Rc And Output
    ...    oc get subscription -n ${OPERATOR_NAMESPACE} --no-headers | awk '{print $1}'
    IF  "${return_code}" == "0" and "${subscription_name}" != "${EMPTY}"
        ${return_code}    ${csv_name}    Run And Return Rc And Output
        ...    oc get subscription ${subscription_name} -n ${OPERATOR_NAMESPACE} -ojson | jq '.status.currentCSV' | tr -d '"'
        IF  "${return_code}" == "0" and "${csv_name}" != "${EMPTY}"
          ${return_code}    ${output}    Run And Return Rc And Output
          ...    oc delete clusterserviceversion ${csv_name} -n ${OPERATOR_NAMESPACE} --ignore-not-found
          Should Be Equal As Integers  ${return_code}   0   msg=Error deleting RHODS CSV ${csv_name}
        END
        ${return_code}    ${output}    Run And Return Rc And Output
        ...    oc delete subscription ${subscription_name} -n ${OPERATOR_NAMESPACE} --ignore-not-found
        Should Be Equal As Integers  ${return_code}   0   msg=Error deleting RHODS subscription
    END
    Log To Console    message=Deleting Operator CSV From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete clusterserviceversion opendatahub-operator.1.18.0 -n openshift-operators --ignore-not-found
    Log To Console    message=Deleting Operator Catalog From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete CatalogSource rhoai-catalog-dev -n openshift-marketplace --ignore-not-found  # robocop: disable
    ${return_code}    ${output}    Run And Return Rc And Output
        ...    oc delete CatalogSource addon-managed-odh-catalog -n openshift-marketplace --ignore-not-found  # robocop: disable
    Log To Console    message=Deleting Operator Group From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete operatorgroup --all -n ${OPERATOR_NAMESPACE} --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting operatorgroup
    Log To Console    message=Deleting Operator and it's associate namepsace
    ${return_code}    ${output}    Run And Return Rc And Output    oc delete ns -l opendatahub.io/generated-namespace --ignore-not-found
    Verify Project Does Not Exists  ${APPLICATIONS_NAMESPACE}
    Verify Project Does Not Exists  ${MONITORING_NAMESPACE}
    Verify Project Does Not Exists  ${NOTEBOOKS_NAMESPACE}
    IF  "${OPERATOR_NAMESPACE}" != "openshift-marketplace"
        ${return_code}    ${output}    Run And Return Rc And Output   oc delete namespace ${OPERATOR_NAMESPACE} --ignore-not-found
        Verify Project Does Not Exists  ${OPERATOR_NAMESPACE}
    END

Uninstall Service Mesh Operator CLI
    [Documentation]    Keyword to uninstall the Service Mesh Operator
    Log To Console    message=Deleting ServiceMeshControlPlane CR From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete ServiceMeshControlPlane --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting ServiceMeshControlPlane CR
    Wait Until Keyword Succeeds    2 min    0 sec
    ...        Check Number Of Resource Instances Equals To      ServiceMeshControlPlane    ${ISTIO_SYSTEM_NS}    0
    Log To Console    message=Deleting ServiceMeshMember CR From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete ServiceMeshMember --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting ServiceMeshMember CR
    Wait Until Keyword Succeeds    2 min    0 sec
    ...        Check Number Of Resource Instances Equals To      ServiceMeshMember     ${ISTIO_SYSTEM_NS}     0
    Log To Console    message=Deleting ServiceMeshMemberRoll CR From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete ServiceMeshMemberRoll --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting ServiceMeshMemberRoll CR
    Wait Until Keyword Succeeds    2 min    0 sec
    ...        Check Number Of Resource Instances Equals To      ServiceMeshMemberRoll     ${KNATIVE_SERVING_NS}      0
    Log To Console    message=Deleting Service Mesh Operator Subscription From Cluster
    ${return_code}    ${csv_name}    Run And Return Rc And Output
    ...    oc get subscription servicemeshoperator -n ${OPENSHIFT_OPERATORS_NS} -o json | jq '.status.currentCSV' | tr -d '"'
    IF  "${return_code}" == "0" and "${csv_name}" != "${EMPTY}"
       ${return_code}    ${output}    Run And Return Rc And Output
       ...    oc delete clusterserviceversion ${csv_name} -n ${OPENSHIFT_OPERATORS_NS}
       Should Be Equal As Integers  ${return_code}   0   msg=Error deleting ServiceMesh CSV ${csv_name}
    END
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete subscription servicemeshoperator -n ${OPENSHIFT_OPERATORS_NS}

Uninstall Serverless Operator CLI
    [Documentation]    Keyword to uninstall the Serverless Operator
    Log To Console    message=Deleting KnativeServing CR From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete KnativeServing --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting KnativeServing CR
    Wait Until Keyword Succeeds    2 min    0 sec
    ...        Check Number Of Resource Instances Equals To      KnativeServing     ${KNATIVE_SERVING_NS}      0
    Log To Console    message=Deleting KnativeEventing CR From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete KnativeEventing --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting KnativeEventing CR
    Wait Until Keyword Succeeds    2 min    0 sec
    ...        Check Number Of Resource Instances Equals To      KnativeEventing     ${KNATIVE_EVENTING_NS}      0
    Log To Console    message=Deleting KnativeKafka CR From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete KnativeKafka --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting KnativeKafka CR
    Wait Until Keyword Succeeds    2 min    0 sec
    ...        Check Number Of Resource Instances Equals To      KnativeKafka     ${KNATIVE_EVENTING_NS}      0
    Log To Console    message=Deleting Serverless Operator Subscription From Cluster
    ${return_code}    ${csv_name}    Run And Return Rc And Output
    ...    oc get subscription serverless-operator -n ${SERVERLESS_NS} -o json | jq '.status.currentCSV' | tr -d '"'
    IF  "${return_code}" == "0" and "${csv_name}" != "${EMPTY}"
       ${return_code}    ${output}    Run And Return Rc And Output
       ...    oc delete clusterserviceversion ${csv_name} -n ${SERVERLESS_NS}
       Should Be Equal As Integers  ${return_code}   0   msg=Error deleting Serverless CSV ${csv_name}
    END
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete subscription serverless-operator -n openshift-serverless
    Log To Console    message=Deleting Serverless Operator Group From Cluster
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete operatorgroup --all -n ${SERVERLESS_NS} --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting Serverless operator group

Check Number Of Resource Instances Equals To
    [Documentation]    Keyword to check if the amount of instances of a specific CRD in a given namespace
    ...                equals to a given number
    [Arguments]     ${resource}      ${namespace}     ${desired_amount}
    ${return_code}    ${amount}    Run And Return Rc And Output
    ...    oc get ${resource} -n ${namespace} -o json | jq -r '.items | length'
    Should Be Equal As Integers  ${return_code}   0   msg=Error calculating number of ${resource}
    Should Be Equal As Integers  ${amount}   ${desired_amount}   msg=Error: ${amount} not equals to ${desired_amount}
