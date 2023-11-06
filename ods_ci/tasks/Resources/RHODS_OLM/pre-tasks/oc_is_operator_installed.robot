*** Keywords ***
Is RHODS Installed
  Log   Checking if RHODS is installed with "${clusterType}" "${UPDATE_CHANNEL}" "${INSTALL_TYPE}"      console=yes
  IF  "${cluster_type}" == "selfmanaged"
      IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Check A RHODS Family Operator Is Installed  namespace=openshift-operators
          ...                                              subscription=rhods-odh-nightly-operator  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=opendatahub  AND
          ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
          ...          field_selector=metadata.name=redhat-operators
      ELSE
          IF  "${INSTALL_TYPE}" == "CLi"
              ${result}=  Run Keyword And Return Status
              ...  Run Keywords
              ...  Check A RHODS Family Operator Is Installed  namespace=redhat-ods-operator
              ...                                              subscription=rhods-operator-dev  AND
              ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-monitoring  AND
              ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-applications  AND
              ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-operator  AND
              ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
              ...          field_selector=metadata.name=rhods-catalog-dev
          ELSE IF  "${INSTALL_TYPE}" == "OperatorHub"
              ${result}=  Run Keyword And Return Status
              ...  Run Keywords
              ...  Check A RHODS Family Operator Is Installed  namespace=redhat-ods-operator
              ...                                              subscription=rhods-operator  AND
              ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-monitoring  AND
              ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-applications  AND
              ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-operator  AND
              ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
              ...          field_selector=metadata.name=redhat-operators
          ELSE
              FAIL    Provided test environment and install type combination is not supported
          END
      END
  ELSE IF  "${cluster_type}" == "managed"
      IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Check A RHODS Family Operator Is Installed  namespace=openshift-operators
          ...                                              subscription=rhods-odh-nightly-operator  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=opendatahub  AND
          ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
          ...          field_selector=metadata.name=redhat-operators
      ELSE
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Check A RHODS Family Operator Is Installed  namespace=redhat-ods-operator
          ...                                              subscription=addon-managed-odh  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-monitoring  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-applications  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-operator  AND
          ...  Oc Get  kind=CatalogSource  namespace=redhat-ods-operator
          ...          field_selector=metadata.name=addon-managed-odh-catalog
      END
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
  ...    oc get subscription ${subscription} -n ${namespace} -ojson | jq '.status.currentCSV' | tr -d '"'
  Log   Got CSV ${current_csv_name} from subscription ${subscription}, result: ${rc}      console=yes
  IF  "${rc}" == "0" and "${current_csv_name}" != "${EMPTY}"
      ${result} =  Run Keyword And Return Status
      ...  Oc Get  kind=ClusterServiceVersion  namespace=${namespace}  name=${current_csv_name}
  ELSE
      ${result} = Set Variable    False
  END
  Log   Operator with sub ${subscription} is installed result: ${result}      console=yes
  IF  not ${result}     FAIL    The operator with sub ${subscription} is not installed.

Is CodeFlare Installed
  [Documentation]   Returns if the RHODS CodeFlare operator is currently installed
  ${result} =  Run Keyword And Return Status
  ...  Check A RHODS Family Operator Is Installed  namespace=openshift-operators  subscription=rhods-codeflare-operator
  Log   RHODS CodeFlare is installed: ${result}      console=yes
  RETURN  ${result}

Is CodeFlare Managed
  [Documentation]   Returns if the RHODS CodeFlare operator should be installed/uninstalled alongside RHODS operator
  ${isCodeFlareManaged} =    Convert To Boolean    ${MANAGE_CODEFLARE_OPERATOR}
  RETURN  ${isCodeFlareManaged}
