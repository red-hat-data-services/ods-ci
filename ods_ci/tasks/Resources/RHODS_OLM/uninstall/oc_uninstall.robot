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
        ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
        ...       field_selector=metadata.name=addon-managed-odh-catalog
  ELSE IF  "${cluster_type}" == "selfmanaged"
        Run Keyword And Expect Error  *Not Found*
        ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
        ...       field_selector=metadata.name=self-managed-rhods
  END
  Verify Project Does Not Exists  redhat-ods-monitoring
  Verify Project Does Not Exists  redhat-ods-applications
  Verify Project Does Not Exists  redhat-ods-operator

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
