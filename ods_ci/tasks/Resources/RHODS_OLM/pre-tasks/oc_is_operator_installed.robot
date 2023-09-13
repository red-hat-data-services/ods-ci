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
      IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Oc Get  kind=OdhDashboardConfig  namespace=opendatahub  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-operator
      ELSE
          ${result}=  Run Keyword And Return Status
          ...  Run Keywords
          ...  Oc Get  kind=OdhDashboardConfig  namespace=redhat-ods-applications  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-monitoring  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-applications  AND
          ...  Oc Get  kind=Namespace  field_selector=metadata.name=redhat-ods-operator  AND
          ...  Oc Get  kind=CatalogSource  namespace=redhat-ods-operator
          ...          field_selector=metadata.name=addon-managed-odh-catalog
      END
  END
  RETURN  ${result}

Is CodeFlare Installed
  [Documentation]   Returns if the RHODS CodeFlare operator is currently installed
  IF  "${cluster_type}" == "selfmanaged"
      ${result}=  Run Keyword And Return Status
      ...  Oc Get  kind=Deployment    namespace=openshift-operators
      ...          label_selector=app.kubernetes.io/name=codeflare-operator
  ELSE IF  "${cluster_type}" == "managed"
      ${result}=  Run Keyword And Return Status
      ...  Oc Get  kind=Deployment  namespace=openshift-operators
      ...          label_selector=app.kubernetes.io/name=codeflare-operator
  END
  RETURN  ${result}

Is CodeFlare Managed
  [Documentation]   Returns if the RHODS CodeFlare operator should be installed/uninstalled alongside RHODS operator
  ${isCodeFlareManaged} =    Convert To Boolean    ${MANAGE_CODEFLARE_OPERATOR}
  RETURN  ${isCodeFlareManaged}
