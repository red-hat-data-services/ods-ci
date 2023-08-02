*** Settings ***
Library    String
Library    OpenShiftLibrary
Library    OperatingSystem


*** Variables ***
${DSC_NAME} =    default
@{COMPONENT_LIST} =    dashboard    datasciencepipelines    distributedWorkloads    kserve    modelmeshserving    workbenches  # robocop: disable


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
  IF  "${UPDATE_CHANNEL}" != "stable" and "${UPDATE_CHANNEL}" != "beta"
      Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
  END

Verify RHODS Installation
  Log  Verifying RHODS installation  console=yes
  Log To Console    Waiting for all RHODS resources to be up and running
  Wait For Pods Numbers  1
  ...                   namespace=redhat-ods-operator
  ...                   label_selector=name=rhods-operator
  ...                   timeout=2000
  ${dashboard} =    Is Component Enabled    dashboard    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta") or "${dashboard}" == "true"
    Wait For Pods Numbers  5
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app=rhods-dashboard
    ...                   timeout=1200
  END
  ${workbenches} =    Is Component Enabled    workbenches    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta") or "${workbenches}" == "true"
    Wait For Pods Numbers  1
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app=notebook-controller
    ...                   timeout=400
    Wait For Pods Numbers  1
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app=odh-notebook-controller
    ...                   timeout=400
  END
  ${modelmeshserving} =    Is Component Enabled    modelmeshserving    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta") or "${modelmeshserving}" == "true"
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
  END
  ${datasciencepipelines} =    Is Component Enabled    datasciencepipelines    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta") or "${datasciencepipelines}" == "true"
    Wait For Pods Numbers   1
    ...                   namespace=redhat-ods-applications
    ...                   label_selector=app.kubernetes.io/created-by=data-science-pipelines-operator
    ...                   timeout=400
  END
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
  ${return_code}    ${output} 	  Run And Return Rc And Output    git clone ${RHODS_OSD_INSTALL_REPO} ${EXECDIR}/${OLM_DIR}
  Log To Console    ${output}
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

Apply DataScienceCluster CustomResource
    [Documentation]
    [Arguments]        ${dsc_name}=default
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Log to Console    Requested Configuration:
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
        TRY
            Log To Console    ${cmp} - ${COMPONENTS.${cmp}}
        EXCEPT
            Log To Console    ${cmp} - False
        END
    END
    Create DataScienceCluster CustomResource Using Test Variables
    ${yml} =    Get File    ${file_path}dsc_apply.yml
    Log To Console    Applying DSC yaml
    Log To Console    ${yml}
    Run    oc apply -f ${file_path}dsc_apply.yml
    Remove File    ${file_path}dsc_apply.yml
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
        IF    ${cmp} not in ${COMPONENTS}
            Component Should Not Be Enabled    ${cmp}
        ELSE IF    ${COMPONENTS.${cmp}} == ${True}
            Component Should Be Enabled    ${cmp}
        ELSE IF    ${COMPONENTS.${cmp}} == ${False}
            Component Should Not Be Enabled    ${cmp}
        END
    END

Create DataScienceCluster CustomResource Using Test Variables
    [Documentation]
    [Arguments]    ${dsc_name}=default
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Copy File    source=${file_path}dsc_template.yml    destination=${file_path}dsc_apply.yml
    Run    sed -i 's/<dsc_name>/${dsc_name}/' ${file_path}dsc_apply.yml
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
        IF    ${cmp} not in ${COMPONENTS}
            Run    sed -i 's/<${cmp}_value>/false/' ${file_path}dsc_apply.yml
        ELSE IF    ${COMPONENTS.${cmp}} == ${True}
            Run    sed -i 's/<${cmp}_value>/true/' ${file_path}dsc_apply.yml
        ELSE IF    ${COMPONENTS.${cmp}} == ${False}
            Run    sed -i 's/<${cmp}_value>/false/' ${file_path}dsc_apply.yml
        END
    END

Component Should Be Enabled
    [Arguments]    ${component}    ${dsc_name}=default
    ${status} =    Is Component Enabled    ${component}    ${dsc_name}
    IF    '${status}' != 'true'    Fail

Component Should Not Be Enabled
    [Arguments]    ${component}    ${dsc_name}=default
    ${status} =    Is Component Enabled    ${component}    ${dsc_name}
    IF    '${status}' != 'false'    Fail

Is Component Enabled
    [Documentation]    Returns the enabled status of a single component (true/false)
    [Arguments]    ${component}    ${dsc_name}=default
    ${status} =    Run    oc get datasciencecluster ${dsc_name} -o json | jq '.spec.components.${component}\[]'
    RETURN    ${status}
