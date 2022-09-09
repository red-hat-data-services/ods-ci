*** Settings ***
Library    String
*** Keywords ***
Install RHODS
  [Arguments]  ${operator_version}    ${cluster_type}     ${operator_url}=${EMPTY}
  IF   "${cluster_type}" == "PSI" or "${cluster_type}" == "OSD"
      ${status}    Run Keyword And Return Status    Should Start With    ${operator_version}    v
      IF  ${status}==True
           Set Local Variable    ${operator_url}        quay.io/modh/qe-catalog-source:${operator_version}
      ELSE
           Should Start With      ${operator_version}     quay.io     msg=you should provide the full build link
           Set Local Variable    ${operator_url}        ${operator_version}
      END
      ${data}     Split String    ${RHODS_INSTALL_REPO}     /
      ${filename}  Split String     ${data}[-1]            .
      Set Test Variable     ${filename}       ${filename}[0]
      ${return_code}	  Run And Return Rc    git clone ${RHODS_INSTALL_REPO}
      Should Be Equal As Integers	${return_code}	 0
      ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${filename} && ./rhods install    #robocop:disable
      Should Be Equal As Integers	${return_code}	 0
      Log    ${output}
  ELSE
       FAIL   Provided cluster type is not supported, Kindly check and provide correct cluster type.
  END

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

