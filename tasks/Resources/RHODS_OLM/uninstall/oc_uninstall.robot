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
  Run Keyword And Expect Error  *Not Found*
  ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
  ...       field_selector=metadata.name=addon-managed-odh-catalog
  Verify Project Does Not Exists  redhat-ods-monitoring
  Verify Project Does Not Exists  redhat-ods-applications
  Verify Project Does Not Exists  redhat-ods-operator
  
Verify Project Does Not Exists 
  [Arguments]  ${project}
  Log  ${project}
  ${project_exists}=  Run Keyword and return status
  ...  Oc Get  kind=Namespace  field_selector=metadata.name=${project}
  Run Keyword if  ${project_exists}  
  ...  wait until project does not exists  ${project}  3600
  Log  ${project} deleted  console=yes