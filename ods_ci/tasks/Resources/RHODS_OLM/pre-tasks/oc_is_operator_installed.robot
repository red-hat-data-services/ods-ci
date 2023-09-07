*** Keywords ***
Is RHODS Installed
  IF  "${cluster_type}" == "selfmanaged"
      IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Oc Get  kind=OdhDashboardConfig  namespace=opendatahub  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-operator  AND
          ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
          ...          field_selector=metadata.name=redhat-operators
      ELSE
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Oc Get  kind=OdhDashboardConfig  namespace=redhat-ods-applications  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-monitoring  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-applications  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-operator  AND
          ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
          ...          field_selector=metadata.name=redhat-operators
      END
  ELSE IF  "${cluster_type}" == "managed"
      ${result}=  Run Keyword And Return Status
      ...  Run Keywords
      ...  Oc Get  kind=OdhDashboardConfig  namespace=redhat-ods-applications  AND
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-monitoring  AND
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-applications  AND
      ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-operator  AND
      ...  Oc Get  kind=CatalogSource  namespace=redhat-ods-operator
      ...          field_selector=metadata.name=addon-managed-odh-catalog
  END
  RETURN  ${result}
