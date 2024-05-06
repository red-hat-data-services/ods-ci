*** Keywords ***
Delete RHODS CatalogSource
  Oc Delete  kind=CatalogSource
  ...        name=addon-managed-odh-catalog
  ...        namespace=openshift-marketplace
  Log  CatalogSource deleted

Trigger RHODS Uninstall
  Oc Create  kind=ConfigMap  namespace=redhat-ods-operator
  ...        src=tasks/Resources/RHODS_OLM/uninstall/delconfigmap.yaml
  Log  Triggered RHODS uninstallation

Verify RHODS Uninstallation
  IF  "${cluster_type}" == "managed"
        Run Keyword And Expect Error  *Not Found*
        ...  Oc Get  kind=CatalogSource  namespace=${OPERATOR_NAMESPACE}
        ...       field_selector=metadata.name=${CATALOG_NAME}
  ELSE IF  "${cluster_type}" == "selfmanaged"
        Run Keyword And Expect Error  *Not Found*
        ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
        ...       field_selector=metadata.name=rhoai-catalog-dev
  END
  Verify Project Does Not Exists  ${MONITORING_NAMESPACE}
  Verify Project Does Not Exists  ${APPLICATIONS_NAMESPACE}
  IF  "${OPERATOR_NAMESPACE}" != "openshift-marketplace"
       Verify Project Does Not Exists  ${OPERATOR_NAMESPACE}
  END


Verify Project Does Not Exists
  [Arguments]  ${project}
  Log  ${project}
  ${project_exists}=  Run Keyword and return status
  ...  Oc Get  kind=Namespace  field_selector=metadata.name=${project}
  IF  ${project_exists}
  ...  Wait Until Project Is Deleted  ${project}  3600
  Log  ${project} deleted  console=yes

Wait Until Project Is Deleted
  [Arguments]  ${project}    ${timeout}
   FOR    ${counter}    IN RANGE    ${timeout}
        ${project_exists}=  Run Keyword and return status
        ...  Oc Get  kind=Namespace  field_selector=metadata.name=${project}
        Exit For Loop If     not ${project_exists}
   END
   IF  ${project_exists}
   ...  Fail    Project ${project} has not been deleted after ${timeout} attempts!
