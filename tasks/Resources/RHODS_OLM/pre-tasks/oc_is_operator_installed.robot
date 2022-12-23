*** Keywords ***
Is RHODS Installed
  IF  "${cluster_type}" == "selfmanaged"
      ${result}=  Run Keyword And Return Status
      ...  Run Keywords
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-monitoring  AND
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-applications  AND
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-operator  AND
      ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
      ...          field_selector=metadata.name=self-managed-rhods
  ELSE IF  "${cluster_type}" == "managed"
      ${result}=  Run Keyword And Return Status
      ...  Run Keywords
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-monitoring  AND
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-applications  AND
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-operator  AND
      ...  Oc Get  kind=CatalogSource  namespace=redhat-ods-operator
      ...          field_selector=metadata.name=addon-managed-odh-catalog
  END
  RETURN  ${result}
