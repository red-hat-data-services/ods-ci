*** Settings ***
Library    String
Library    OpenShiftLibrary

*** Keywords ***
Install RHODS
  [Arguments]  ${cluster_type}     ${image_url}
  Clone OLM Install Repo
  IF  "${cluster_type}" == "selfmanaged"
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "CLi"
          Install RHODS In Self Managed Cluster Using CLI  ${cluster_type}     ${image_url}
      ELSE IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "OperatorHub"
          Oc Apply   kind=List   src=tasks/Resources/RHODS_OLM/install/catalogsource.yaml
      ELSE
           FAIL    Provided test envrioment and install type is not supported
      END
  ELSE IF  "${cluster_type}" == "managed"
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "CLi"
          Install RHODS In Managed Cluster Using CLI  ${cluster_type}     ${image_url}
      ELSE
          FAIL    Provided test envrioment is not supported
      END
  END

Verify RHODS Installation
  Log  Verifying RHODS installation  console=yes
  Wait For Pods Numbers  1
  ...                   namespace=redhat-ods-operator
  ...                   label_selector=name=rhods-operator
  ...                   timeout=2000
  Wait For Pods Numbers  5
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app=rhods-dashboard
  ...                   timeout=1200
  Wait For Pods Numbers  1
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app=notebook-controller
  ...                   timeout=400
  Wait For Pods Numbers  1
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app=odh-notebook-controller
  ...                   timeout=400
  Wait For Pods Numbers   3
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app=odh-model-controller
  ...                   timeout=400
  Wait For Pods Numbers   1
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=component=model-mesh-etcd
  ...                   timeout=400
  Wait For Pods Numbers   3
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app.kubernetes.io/name=modelmesh-controller
  ...                   timeout=400
  Wait For Pods Numbers   1
  ...                   namespace=redhat-ods-applications
  ...                   label_selector=app.kubernetes.io/created-by=data-science-pipelines-operator
  ...                   timeout=400
  Wait For Pods Numbers   3
  ...                   namespace=redhat-ods-monitoring
  ...                   label_selector=prometheus=rhods-model-monitoring
  ...                   timeout=400
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

Clone OLM Install Repo
  [Documentation]   Clone OLM git repo
  ${return_code}	  Run And Return Rc    git clone ${RHODS_OSD_INSTALL_REPO} ${EXECDIR}/${OLM_DIR}
  Should Be Equal As Integers	${return_code}	 0

Install RHODS In Self Managed Cluster Using CLI
  [Documentation]   Install rhods on self managed cluster using cli
  [Arguments]     ${cluster_type}     ${image_url}
  ${return_code}    Run and Watch Command    cd ${EXECDIR}/${OLM_DIR} && ./setup.sh -t operator -u ${UPDATE_CHANNEL} -i ${image_url}    timeout=20 min
  Should Be Equal As Integers	${return_code}	 0   msg=Error detected while installing RHODS

Install RHODS In Managed Cluster Using CLI
  [Documentation]   Install rhods on managed managed cluster using cli
  [Arguments]     ${cluster_type}     ${image_url}
  ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${OLM_DIR} && ./setup.sh -t addon -u ${UPDATE_CHANNEL} -i ${image_url}  #robocop:disable
  Log To Console    ${output}
  Should Be Equal As Integers	${return_code}	 0  msg=Error detected while installing RHODS

Wait For Pods Numbers
  [Documentation]   Wait for number of pod during installtion
  [Arguments]     ${count}     ${namespace}     ${label_selector}    ${timeout}
  ${status}   Set Variable   False
  FOR    ${counter}    IN RANGE   ${timeout}
         ${return_code}    ${output}    Run And Return Rc And Output   oc get pod -n ${namespace} -l ${label_selector} | tail -n +2 | wc -l
         IF    ${output} == ${count}
               ${status}  Set Variable  True
               Log To Console  pods ${label_selector} created
               Exit For Loop
         END
         Sleep    1 sec
  END
  IF    '${status}' == 'False'
        Run Keyword And Continue On Failure    FAIL    Timeout- ${output} pods found with the label selector ${label_selector} in ${namespace} namespace
  END
