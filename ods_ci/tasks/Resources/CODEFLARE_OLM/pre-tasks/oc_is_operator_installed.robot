*** Keywords ***
Is CodeFlare Installed
  IF  "${cluster_type}" == "selfmanaged"
      ${result}=  Run Keyword And Return Status
      ...  Run Keywords
      ...  Oc Get  kind=Deployment  label_selector=app.kubernetes.io/name=codeflare-operator  AND
      ...  Oc Get  kind=CatalogSource  namespace=openshift-marketplace
      ...          field_selector=metadata.name=redhat-operators
  ELSE IF  "${cluster_type}" == "managed"
      ${result}=  Run Keyword And Return Status
      ...  Run Keywords
      ...  Oc Get  kind=Deployment  label_selector=app.kubernetes.io/name=codeflare-operator  AND
      ...  Oc Get  kind=CatalogSource  namespace=redhat-ods-operator
      ...          field_selector=metadata.name=addon-managed-odh-catalog
  END
  RETURN  ${result}
