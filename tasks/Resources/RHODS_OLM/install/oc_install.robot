*** Settings ***
Library    String
*** Keywords ***
Install RHODS
  [Arguments]  ${cluster_type}     ${operator_version}=${EMPTY}
  IF  "${cluster_type}" == "selfmanaged"
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "CLi"
          Install RHODS In Self Managed Cluster Using CLI  ${cluster_type}     ${operator_version}
      ELSE
           FAIL    Provided test envrioment is not supported
      END
  ELSE IF  "${cluster_type}" == "managed"
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "CLi"
          Install RHODS In Managed Cluster Using CLI  ${cluster_type}     ${operator_version}
      ELSE
          FAIL    Provided test envrioment is not supported
      END
  END

Verify RHODS Installation
  Log  Verifying RHODS installation  console=yes
  Wait For Pods Number  1
  ...                   namespace=redhat-ods-operator
  ...                   label_selector=name=rhods-operator
  ...                   timeout=2000
  Log  pod operator created
  Wait For Pods Number  5
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app=rhods-dashboard
  ...                   timeout=1200
  Log  pods rhods-dashboard created
  Wait For Pods Number  1
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app=notebook-controller
  ...                   timeout=1200
  Log  pods notebook-controller created
  Wait For Pods Number  1
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app=odh-notebook-controller
  ...                   timeout=1200
  Log  pods odh-notebook-controller created
  Wait For Pods Number  3
  ...                   namespace=redhat-ods-monitoring
  ...                   timeout=1200
  #Verify Builds In redhat-ods-applications
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

Install RHODS In Self Managed Cluster Using CLI
   [Documentation]   Install rhods on sself managed cluster using cli
   [Arguments]     ${cluster_type}     ${operator_version}
   ${data}     Split String    ${RHODS_INSTALL_REPO}     /
   ${filename}  Split String     ${data}[-1]            .
   Set Test Variable     ${filename}       ${filename}[0]
   ${return_code}	  Run And Return Rc    git clone ${RHODS_INSTALL_REPO}
   Should Be Equal As Integers	${return_code}	 0
   IF    "${operator_version}" != "${EMPTY}"
          ${return_code}   Run And Return Rc   sed -i "s@quay.io/modh/self-managed-rhods-index:beta@${operator_version}@g" ${EXECDIR}/${filename}/manifests/catalogsource.yaml  #robocop:disable
          Should Be Equal As Integers	${return_code}	 0
   END
   ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${filename} && ./rhods install   #robocop:disable
   Log To Console    ${output}
   Should Be Equal As Integers	${return_code}	 0  msg=Error detected while installing RHODS

Install RHODS In Managed Cluster Using CLI
   [Documentation]   Install rhods on sself managed cluster using cli
   [Arguments]     ${cluster_type}     ${operator_version}
   ${return_code}	  Run And Return Rc    git clone https://gitlab.cee.redhat.com/data-hub/olminstall.git rhodsolm
   Should Be Equal As Integers	${return_code}	 0
   Set Test Variable     ${filename}    rhodsolm
   ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${filename} && ./setup.sh ${operator_version}   #robocop:disable
   Log To Console    ${output}
   Should Be Equal As Integers	${return_code}	 0
