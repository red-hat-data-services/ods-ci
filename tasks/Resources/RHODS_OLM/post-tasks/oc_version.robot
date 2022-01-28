*** Keywords ***  
Get RHODS Version
  @{versions} =  Oc Get  kind=ClusterServiceVersion  label_selector=olm.copiedFrom=redhat-ods-operator
  FOR  ${version}  IN  @{versions}
    ${csv_version} =  Set Variable  ${version}[spec][version]
  END
  [Return]  ${csv_version}