*** Keywords ***
Upgrade CodeFlare
   [Arguments]  ${operator_version}
   Oc Patch  kind=CatalogSource
   ...    name=addon-managed-odh-catalog
   ...    src={spec:{image: ${RHODS_BUILD.IMAGE}:${operator_version}}}
   ...    namespace=openshift-marketplace

Verify CodeFlare Upgrade
  Wait For Pods Number  1
  ...                   namespace=openshift-operators
  ...                   label_selector=app.kubernetes.io/name=codeflare-operator
  ...                   timeout=600
  Wait For Pods Status  namespace=openshift-operators label_selector=app.kubernetes.io/name=codeflare-operator timeout=1200
  Log  "Verified CodeFlare pod after upgrade"  console=yes
