*** Keywords ***
Is RHODS Installed
  Log   Checking if RHODS is installed with "${clusterType}" "${UPDATE_CHANNEL}" "${INSTALL_TYPE}"      console=yes
  IF  "${cluster_type}" == "selfmanaged"
      IF  "${INSTALL_TYPE}" in ["Cli", "Kustomize"]
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Check A RHODS Family Operator Is Installed  namespace=${OPERATOR_NAMESPACE}
          ...                                              subscription=rhoai-operator-dev  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${MONITORING_NAMESPACE}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${APPLICATIONS_NAMESPACE}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${OPERATOR_NAMESPACE}  AND
          ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
          ...          field_selector=metadata.name=rhoai-catalog-dev
      ELSE IF  "${INSTALL_TYPE}" == "OperatorHub"
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Check A RHODS Family Operator Is Installed  namespace=${OPERATOR_NAMESPACE}
          ...                                              subscription=${OPERATOR_NAME}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${MONITORING_NAMESPACE}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${APPLICATIONS_NAMESPACE}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${OPERATOR_NAMESPACE}
      ELSE IF  "${INSTALL_TYPE}" == "Helm"
          ${enable_new_observability_stack}=  Get Variable Value    ${ENABLE_NEW_OBSERVABILITY_STACK}    false
          ${enable_new_observability_stack}=  Convert To Boolean    ${enable_new_observability_stack}
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Check A RHODS Family Operator Is Installed  namespace=${OPERATOR_NAMESPACE}
          ...                                              subscription=${OPERATOR_NAME}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${APPLICATIONS_NAMESPACE}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${OPERATOR_NAMESPACE}
          IF  ${result} and ${enable_new_observability_stack}
              ${result}=  Run Keyword And Return Status
              ...  Oc Get  kind=Namespace  field_selector=metadata.name=${MONITORING_NAMESPACE}
          ELSE IF  not ${enable_new_observability_stack}
              Log  Monitoring namespace check skipped because ENABLE_NEW_OBSERVABILITY_STACK is disabled  console=yes
          END
      ELSE
          FAIL    Provided test environment and install type combination is not supported
      END
  ELSE IF  "${cluster_type}" == "managed"
      Set Global Variable    ${SUB_NAME}               addon-managed-odh
      Set Global Variable    ${CATALOG_NAME}           addon-managed-odh-catalog
      #For managed cluster
      IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
           Set Global Variable    ${OPERATOR_NAMESPACE}    openshift-marketplace
           Set Global Variable    ${SUB_NAME}    rhoai-operator-dev
           Set Global Variable    ${CATALOG_NAME}    rhoai-catalog-dev
      END
      ${result}=  Run Keyword And Return Status
      ...  Run Keywords
      ...  Check A RHODS Family Operator Is Installed  namespace=${OPERATOR_NAMESPACE}
      ...                                              subscription=${SUB_NAME}  AND
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=${MONITORING_NAMESPACE}  AND
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=${APPLICATIONS_NAMESPACE}  AND
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=${OPERATOR_NAMESPACE}  AND
      ...  Oc Get  kind=CatalogSource  namespace=${OPERATOR_NAMESPACE}
      ...          field_selector=metadata.name=${CATALOG_NAME}
  ELSE
      FAIL    Provided test environment and install type ${INSTALL_TYPE} ${UPDATE_CHANNEL} ${cluster_type} combination
      ...     is not supported
  END
  Log   RHODS is installed: ${result}      console=yes
  RETURN  ${result}

Check A RHODS Family Operator Is Installed
  [Documentation]   Returns if an operator with given subscription name has a CSV in the given namespace
  [Arguments]    ${namespace}  ${subscription}
  Log   Getting CSV from subscription ${subscription} namespace ${namespace}      console=yes
  ${rc}    ${current_csv_name} =    Run And Return Rc And Output
  ...    oc get subscription ${subscription} -n ${namespace} -ojson | jq '.status.installedCSV' | tr -d '"'
  Log   Got CSV ${current_csv_name} from subscription ${subscription}, result: ${rc}      console=yes
  IF  "${rc}" == "0" and "${current_csv_name}" != "${EMPTY}"
      ${result} =  Run Keyword And Return Status
      ...  Oc Get  kind=ClusterServiceVersion  namespace=${namespace}  name=${current_csv_name}
  ELSE
      ${result} =  Set Variable    False
  END
  Log   Operator with sub ${subscription} is installed result: ${result}      console=yes
  IF  not ${result}     FAIL    The operator with sub ${subscription} is not installed.
