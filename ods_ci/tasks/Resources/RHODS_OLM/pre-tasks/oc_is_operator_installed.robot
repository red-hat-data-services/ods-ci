*** Keywords ***
Is RHODS Installed
  Log   Checking if RHODS is installed with "${clusterType}" "${UPDATE_CHANNEL}" "${INSTALL_TYPE}"      console=yes
  IF  "${cluster_type}" == "selfmanaged"
      IF  "${INSTALL_TYPE}" == "Cli"
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Check A RHODS Family Operator Is Installed  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${MONITORING_NAMESPACE}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${APPLICATIONS_NAMESPACE}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${OPERATOR_NAMESPACE}  AND
          ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
          ...          field_selector=metadata.name=rhoai-catalog-dev
      ELSE IF  "${INSTALL_TYPE}" == "OperatorHub"
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Check A RHODS Family Operator Is Installed  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${MONITORING_NAMESPACE}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${APPLICATIONS_NAMESPACE}  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=${OPERATOR_NAMESPACE}
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
      ...  Check A RHODS Family Operator Is Installed  AND
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
  [Documentation]   Returns if RHODS operator has a CSV

  ${result} =  Set Variable    False
  Log   Check if the RHODS operator installed.    console=yes
  ${subscription}=    Get RHODS Subscription Name
  ${namespace}=    Get RHODS Namespace
  IF  "${subscription}" != "${EMPTY}"
      Log   Getting CSV from subscription ${subscription} namespace ${namespace}      console=yes
      ${rc}    ${current_csv_name} =    Run And Return Rc And Output
      ...    oc get subscription ${subscription} -n ${namespace} -ojson | jq '.status.currentCSV' | tr -d '"'
      Log   Got CSV '${current_csv_name}' from subscription '${subscription}', result: ${rc}      console=yes
      IF  "${rc}" == "0" and "${current_csv_name}" != "${EMPTY}"
          ${rc}=    Run Keyword And Return Status    oc get csv ${current_csv_name} -n ${namespace}
          ${result}=    Evaluate    ${rc} == 0
          Log   The csv exists: ${result}      console=yes
      END
  END
  Log   Operator with sub '${subscription}' is installed result: ${result}      console=yes
  IF  not ${result}     FAIL    The operator with sub ${subscription} is not installed.

Get RHODS Subscription Name
    [Documentation]    Returns the subscription name of RHOAI/ODH operator
    Log   Get the RHODS subscription name by package name: '${RHODS_PACKAGE_NAME}'    console=yes
    ${rc}    ${out}=    Run And Return RC And Output
    ...    oc get sub -A -o json | jq --arg pkgName "${RHODS_PACKAGE_NAME}" -r '.items[] | select(.spec.name==$pkgName) | .metadata.name'
    Should Be Equal As Integers    ${rc}    0
    Log   The RHODS Subscription Name is: '${out}'    console=yes
    RETURN    ${out}

Get RHODS Namespace
    [Documentation]    Returns the namespace of RHOAI/ODH operator
    Log   Get the RHODS namespace by package name: '${RHODS_PACKAGE_NAME}'    console=yes
    ${rc}    ${out}=    Run And Return RC And Output
    ...    oc get sub -A -o json | jq --arg pkgName "${RHODS_PACKAGE_NAME}" -r '.items[] | select(.spec.name==$pkgName) | .metadata.namespace'
    Should Be Equal As Integers    ${rc}    0
    Log   The RHODS Namespace is: '${out}'    console=yes
    RETURN    ${out}
