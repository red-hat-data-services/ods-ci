*** Keywords ***
Install RHODS  
  [Arguments]  ${operator_version}
  New Project  redhat-ods-monitoring
  New Project  redhat-ods-applications
  New Project  redhat-ods-operator
  Oc Apply  kind=Secret  src=${RHODS_BUILD.PULL_SECRET}  namespace=openshift-marketplace
  Oc Apply  kind=Secret  src=${RHODS_BUILD.SECRET_FILE}
  &{image}=  Create Dictionary  image=quay.io/modh/qe-catalog-source:${operator_version}
  Oc Create  kind=List  src=tasks/Resources/RHODS_OLM/install/catalogsource.yaml  
  ...        template_data=${image}

Verify RHODS Installation
  Log  Verifying RHODS installation  console=yes
  Wait For Pods Number  1
  ...                   namespace=redhat-ods-operator
  ...                   label_selector=name=rhods-operator  
  ...                   timeout=2000
  Log  pod operator created
  Wait For Pods Number  2  
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app=rhods-dashboard  
  ...                   timeout=1200 
  Log  pods rhods-dashboard created
  Wait For Pods Number  3  
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app=jupyterhub  
  ...                   timeout=1200 
  Wait For Pods Number  4  
  ...                   namespace=redhat-ods-monitoring 
  ...                   timeout=1200
  Verify Builds In redhat-ods-applications
  Wait For Pods Status  namespace=redhat-ods-applications  timeout=60
  Log  Verified redhat-ods-applications  console=yes
  Wait For Pods Status  namespace=redhat-ods-operator  timeout=1200
  Log  Verified redhat-ods-operator  console=yes
  Wait For Pods Status  namespace=redhat-ods-monitoring  timeout=1200
  Log  Verified redhat-ods-monitoring  console=yes
  Oc Get  kind=Namespace  field_selector=metadata.name=rhods-notebooks
  Log  "Verified rhods-notebook"

Verify Builds In redhat-ods-applications
  Log  Verifying Builds  console=yes
  Wait Until Keyword Succeeds  45 min  15 s  Verify Builds Number  7
  Wait Until Keyword Succeeds  45 min  15 s  Verify Builds Status  Complete
  Log  Builds Verified  console=yes

Verify Builds Number
  [Arguments]  ${expected_builds}
  @{builds}=  Oc Get  kind=Build  namespace=redhat-ods-applications
  ${build_length}=  Get Length  ${builds}
  Should Be Equal As Integers  ${build_length}  ${expected_builds}
  [Return]  ${builds}

Verify Builds Status 
  [Arguments]  ${build_status}
  @{builds}=  Oc Get  kind=Build  namespace=redhat-ods-applications
  FOR  ${build}  IN  @{builds}
    Should Be Equal As Strings  ${build}[status][phase]  ${build_status}  
    Should Not Be Equal As Strings  ${build}[status][phase]  Cancelled
    Should Not Be Equal As Strings  ${build}[status][phase]  Failed
    Should Not Be Equal As Strings  ${build}[status][phase]  Error
  END