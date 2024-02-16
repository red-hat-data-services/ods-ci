*** Settings ***
Library    String
Library    OpenShiftLibrary
Library    OperatingSystem
Resource          ../../../../tests/Resources/Page/Operators/ISVs.resource
Resource          ../../../../tests/Resources/Page/OCPDashboard/UserManagement/Groups.robot

*** Variables ***
${DSC_NAME} =    default-dsc
@{COMPONENT_LIST} =    dashboard    datasciencepipelines    kserve    modelmeshserving    workbenches    codeflare    ray    trustyai  # robocop: disable
${SERVERLESS_OP_NAME}=     serverless-operator
${SERVERLESS_SUB_NAME}=    serverless-operator
${SERVERLESS_NS}=    openshift-serverless
${SERVICEMESH_OP_NAME}=     servicemeshoperator
${SERVICEMESH_SUB_NAME}=    servicemeshoperator

*** Keywords ***
Install RHODS
  [Arguments]  ${cluster_type}     ${image_url}
  Install Kserve Dependencies
  Clone OLM Install Repo
  IF  "${cluster_type}" == "selfmanaged"
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "CLi"
            IF  "${UPDATE_CHANNEL}" != "odh-nightlies"
                 Install RHODS In Self Managed Cluster Using CLI  ${cluster_type}     ${image_url}
            ELSE
                 Create Catalog Source For Operator
                 Oc Apply    kind=List    src=tasks/Resources/Files/odh_nightly_sub.yml
            END
      ELSE IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "OperatorHub"
          ${file_path} =    Set Variable    tasks/Resources/RHODS_OLM/install/
          Copy File    source=${file_path}cs_template.yaml    destination=${file_path}cs_apply.yaml
          Run    sed -i 's/<UPDATE_CHANNEL>/${UPDATE_CHANNEL}/' ${file_path}cs_apply.yaml
          Oc Apply   kind=List   src=${file_path}cs_apply.yaml
          Remove File    ${file_path}cs_apply.yml
      ELSE
           FAIL    Provided test envrioment and install type is not supported
      END
  ELSE IF  "${cluster_type}" == "managed"
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "CLi"
           IF  "${UPDATE_CHANNEL}" != "odh-nightlies"
                Install RHODS In Managed Cluster Using CLI  ${cluster_type}     ${image_url}
           ELSE
                Create Catalog Source For Operator
                Oc Apply    kind=List    src=tasks/Resources/Files/odh_nightly_sub.yml
           END
      ELSE
          FAIL    Provided test envrioment is not supported
      END
  END

Verify RHODS Installation
  # Needs to be removed ASAP
  IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
    Set Global Variable    ${APPLICATIONS_NAMESPACE}    opendatahub
    Set Global Variable    ${MONITORING_NAMESPACE}    opendatahub
    Set Global Variable    ${OPERATOR_NAMESPACE}    openshift-operators
    Set Global Variable    ${NOTEBOOKS_NAMESPACE}    opendatahub
  END
  Log  Verifying RHODS installation  console=yes
  Log To Console    Waiting for all RHODS resources to be up and running
  IF  "${UPDATE_CHANNEL}" != "odh-nightlies"
       Wait For Pods Numbers  1
       ...                   namespace=${OPERATOR_NAMESPACE}
       ...                   label_selector=name=rhods-operator
       ...                   timeout=2000
       Wait For Pods Status  namespace=${OPERATOR_NAMESPACE}  timeout=1200
       Log  Verified redhat-ods-operator  console=yes
  END

  # The CodeFlare operator verification needs to happen after RHODS operator and before DataScienceCluster is created!
  ${is_codeflare_managed} =     Is CodeFlare Managed
  Log  Will verify CodeFlare operator: ${is_codeflare_managed}  console=yes
  IF  ${is_codeflare_managed}  CodeFlare Operator Should Be Installed
  IF  "${UPDATE_CHANNEL}" == "odh-nightlies" or "${cluster_type}" != "managed"
      Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
  END
  ${dashboard} =    Is Component Enabled    dashboard    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta") or "${dashboard}" == "true"
    # Needs to be removed ASAP
    IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
        Log To Console    "Waiting for 2 pods in ${APPLICATIONS_NAMESPACE}, label_selector=app=odh-dashboard"
        Wait For Pods Numbers  2
        ...                   namespace=${APPLICATIONS_NAMESPACE}
        ...                   label_selector=app=odh-dashboard
        ...                   timeout=1200
        Add UI Admin Group To Dashboard Admin
    ELSE
        Log To Console    "Waiting for 5 pods in ${APPLICATIONS_NAMESPACE}, label_selector=app=rhods-dashboard"
        Wait For Pods Numbers  5
        ...                   namespace=${APPLICATIONS_NAMESPACE}
        ...                   label_selector=app=rhods-dashboard
        ...                   timeout=1200
    END
  END
  ${workbenches} =    Is Component Enabled    workbenches    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta") or "${workbenches}" == "true"
    Log To Console    "Waiting for 1 pod in ${APPLICATIONS_NAMESPACE}, label_selector=app=notebook-controller"
    Wait For Pods Numbers  1
    ...                   namespace=${APPLICATIONS_NAMESPACE}
    ...                   label_selector=app=notebook-controller
    ...                   timeout=400
    Log To Console    "Waiting for 1 pod in ${APPLICATIONS_NAMESPACE}, label_selector=app=odh-notebook-controller"
    Wait For Pods Numbers  1
    ...                   namespace=${APPLICATIONS_NAMESPACE}
    ...                   label_selector=app=odh-notebook-controller
    ...                   timeout=400
  END
  ${modelmeshserving} =    Is Component Enabled    modelmeshserving    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta") or "${modelmeshserving}" == "true"
    Log To Console    "Waiting for 3 pods in ${APPLICATIONS_NAMESPACE}, label_selector=app=odh-model-controller"
    Wait For Pods Numbers   3
    ...                   namespace=${APPLICATIONS_NAMESPACE}
    ...                   label_selector=app=odh-model-controller
    ...                   timeout=400
    Log To Console    "Waiting for 1 pod in ${APPLICATIONS_NAMESPACE}, label_selector=component=model-mesh-etcd"
    Wait For Pods Numbers   1
    ...                   namespace=${APPLICATIONS_NAMESPACE}
    ...                   label_selector=component=model-mesh-etcd
    ...                   timeout=400
    Log To Console    "Waiting for 3 pods in ${APPLICATIONS_NAMESPACE}, label_selector=app.kubernetes.io/name=modelmesh-controller"
    Wait For Pods Numbers   3
    ...                   namespace=${APPLICATIONS_NAMESPACE}
    ...                   label_selector=app.kubernetes.io/name=modelmesh-controller
    ...                   timeout=400
  END
  ${datasciencepipelines} =    Is Component Enabled    datasciencepipelines    ${DSC_NAME}
  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta") or "${datasciencepipelines}" == "true"
    Log To Console    "Waiting for 1 pod in ${APPLICATIONS_NAMESPACE}, label_selector=app.kubernetes.io/name=data-science-pipelines-operator"
    Wait For Pods Numbers   1
    ...                   namespace=${APPLICATIONS_NAMESPACE}
    ...                   label_selector=app.kubernetes.io/name=data-science-pipelines-operator
    ...                   timeout=400
  END
  ${kserve} =    Is Component Enabled    kserve    ${DSC_NAME}
  IF    "${kserve}" == "true"
    Wait For Pods Numbers   1
       ...                   namespace=${APPLICATIONS_NAMESPACE}
       ...                   label_selector=control-plane=kserve-controller-manager
       ...                   timeout=120
  END

  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta") or "${dashboard}" == "true" or "${workbenches}" == "true" or "${modelmeshserving}" == "true" or "${datasciencepipelines}" == "true"  # robocop: disable
    Log To Console    "Waiting for pod status in ${APPLICATIONS_NAMESPACE}"
    Wait For Pods Status  namespace=${APPLICATIONS_NAMESPACE}  timeout=60
    Log  Verified Applications NS: ${APPLICATIONS_NAMESPACE}  console=yes
  END

  # Monitoring stack only deployed for managed, as modelserving monitoring stack is no longer deployed
  IF  "${cluster_type}" == "managed"
     Log To Console    "Waiting for pod status in ${MONITORING_NAMESPACE}"
     Wait For Pods Status  namespace=${MONITORING_NAMESPACE}  timeout=600
     Log  Verified Monitoring NS: ${MONITORING_NAMESPACE}  console=yes
  END

  IF    ("${UPDATE_CHANNEL}" == "stable" or "${UPDATE_CHANNEL}" == "beta") or "${workbenches}" == "true"
    Oc Get  kind=Namespace  field_selector=metadata.name=${NOTEBOOKS_NAMESPACE}
    Log  Verified Notebooks NS: ${NOTEBOOKS_NAMESPACE}
  END

Verify Builds In redhat-ods-applications
  Log  Verifying Builds  console=yes
  Wait Until Keyword Succeeds  45 min  15 s  Verify Builds Number  7
  Wait Until Keyword Succeeds  45 min  15 s  Verify Builds Status  Complete
  Log  Builds Verified  console=yes

Clone OLM Install Repo
  [Documentation]   Clone OLM git repo
  ${return_code}    ${output}     Run And Return Rc And Output    git clone ${RHODS_OSD_INSTALL_REPO} ${EXECDIR}/${OLM_DIR}
  Log To Console    ${output}
  Should Be Equal As Integers   ${return_code}   0

Install RHODS In Self Managed Cluster Using CLI
  [Documentation]   Install rhods on self managed cluster using cli
  [Arguments]     ${cluster_type}     ${image_url}
  ${return_code}    Run and Watch Command    cd ${EXECDIR}/${OLM_DIR} && ./setup.sh -t operator -u ${UPDATE_CHANNEL} -i ${image_url}    timeout=20 min
  Should Be Equal As Integers   ${return_code}   0   msg=Error detected while installing RHODS

Install RHODS In Managed Cluster Using CLI
  [Documentation]   Install rhods on managed managed cluster using cli
  [Arguments]     ${cluster_type}     ${image_url}
  ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${OLM_DIR} && ./setup.sh -t addon -u ${UPDATE_CHANNEL} -i ${image_url}  #robocop:disable
  Log To Console    ${output}
  Should Be Equal As Integers   ${return_code}   0  msg=Error detected while installing RHODS

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
    [Arguments]        ${dsc_name}=${DSC_NAME}
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Log to Console    Requested Configuration:
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
        TRY
            Log To Console    ${cmp} - ${COMPONENTS.${cmp}}
        EXCEPT
            Log To Console    ${cmp} - Removed
        END
    END
    Create DataScienceCluster CustomResource Using Test Variables
    ${yml} =    Get File    ${file_path}dsc_apply.yml
    Log To Console    Applying DSC yaml
    Log To Console    ${yml}
    ${return_code}    ${output} =    Run And Return Rc And Output    oc apply -f ${file_path}dsc_apply.yml
    Log To Console    ${output}
    Should Be Equal As Integers  ${return_code}  0  msg=Error detected while applying DSC CR
    Remove File    ${file_path}dsc_apply.yml
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
        IF    $cmp not in $COMPONENTS
            Component Should Not Be Enabled    ${cmp}
        ELSE IF    '${COMPONENTS.${cmp}}' == 'Managed'
            Component Should Be Enabled    ${cmp}
        ELSE IF    '${COMPONENTS.${cmp}}' == 'Removed'
            Component Should Not Be Enabled    ${cmp}
        END
    END

Create DataScienceCluster CustomResource Using Test Variables
    [Documentation]
    [Arguments]    ${dsc_name}=${DSC_NAME}
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Copy File    source=${file_path}dsc_template.yml    destination=${file_path}dsc_apply.yml
    Run    sed -i 's/<dsc_name>/${dsc_name}/' ${file_path}dsc_apply.yml
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
        IF    $cmp not in $COMPONENTS
            Run    sed -i 's/<${cmp}_value>/Removed/' ${file_path}dsc_apply.yml
        ELSE IF    '${COMPONENTS.${cmp}}' == 'Managed'
            Run    sed -i 's/<${cmp}_value>/Managed/' ${file_path}dsc_apply.yml
        ELSE IF    '${COMPONENTS.${cmp}}' == 'Removed'
            Run    sed -i 's/<${cmp}_value>/Removed/' ${file_path}dsc_apply.yml
        END
    END

Component Should Be Enabled
    [Arguments]    ${component}    ${dsc_name}=${DSC_NAME}
    ${status} =    Is Component Enabled    ${component}    ${dsc_name}
    IF    '${status}' != 'true'    Fail

Component Should Not Be Enabled
    [Arguments]    ${component}    ${dsc_name}=${DSC_NAME}
    ${status} =    Is Component Enabled    ${component}    ${dsc_name}
    IF    '${status}' != 'false'    Fail

Is Component Enabled
    [Documentation]    Returns the enabled status of a single component (true/false)
    [Arguments]    ${component}    ${dsc_name}=${DSC_NAME}
    ${return_code}    ${output} =    Run And Return Rc And Output    oc get datasciencecluster ${dsc_name} -o json | jq '.spec.components.${component}.managementState'  #robocop:disable
    Log    ${output}
    Should Be Equal As Integers  ${return_code}  0  msg=Error detected while getting component status
    ${n_output} =    Evaluate    '${output}' == ''
    IF  ${n_output}
          RETURN    false
    ELSE
         IF    ${output} == "Removed"
               RETURN    false
         ELSE IF    ${output} == "Managed"
              RETURN    true
         END
    END

Create Catalog Source For Operator
    [Documentation]    Create Catalog source for odh nightly build
    [Arguments]    ${file_path}=tasks/Resources/Files/
    ${return_code}    ${output} =    Run And Return Rc And Output    sed -i "s,image: .*,image: ${image_url},g" ${file_path}/odh_catalogsource.yml
    Should Be Equal As Integers  ${return_code}  0  msg=Error detected while making changes to file
    ${return_code}    ${output} =    Run And Return Rc And Output   oc apply -f ${file_path}/odh_catalogsource.yml
    Should Be Equal As Integers  ${return_code}  0  msg=Error detected while apply the catalog
    Wait for Catalog To Be Ready

Wait for Catalog To Be Ready
    [Documentation]    Verify catalog is Ready OR NOT
    [Arguments]    ${namespace}=openshift-marketplace   ${catalog_name}=odh-catalog-dev   ${timeout}=30
    FOR    ${counter}    IN RANGE    ${timeout}
           ${return_code}    ${output} =    Run And Return Rc And Output    oc get catalogsources ${catalog_name} -n ${namespace} -o json | jq ."status.connectionState.lastObservedState"
           Should Be Equal As Integers   ${return_code}  0  msg=Error detected while getting component status
           IF  ${output} == "READY"   Exit For Loop
    END

Install Kserve Dependencies
    [Documentation]    Install Dependent Operator For Kserve
    Set Suite Variable   ${FILES_RESOURCES_DIRPATH}    tests/Resources/Files
    Set Suite Variable   ${SUBSCRIPTION_YAML_TEMPLATE_FILEPATH}    ${FILES_RESOURCES_DIRPATH}/isv-operator-subscription.yaml
    Set Suite Variable   ${OPERATORGROUP_YAML_TEMPLATE_FILEPATH}    ${FILES_RESOURCES_DIRPATH}/isv-operator-group.yaml
    ${is_installed}=   Check If Operator Is Installed Via CLI   ${SERVICEMESH_OP_NAME}
    IF    not ${is_installed}
          Install ISV Operator From OperatorHub Via CLI    operator_name=${SERVICEMESH_OP_NAME}
          ...    subscription_name=${SERVICEMESH_SUB_NAME}
          ...    catalog_source_name=redhat-operators
          Wait Until Operator Subscription Last Condition Is
          ...    type=CatalogSourcesUnhealthy    status=False
          ...    reason=AllCatalogSourcesHealthy    subcription_name=${SERVICEMESH_SUB_NAME}
    ELSE
          Log To Console    message=ServiceMesh Operator is already installed
    END
    ${is_installed}=   Check If Operator Is Installed Via CLI   ${SERVERLESS_OP_NAME}
    IF    not ${is_installed}
          ${rc}    ${out}=    Run And Return Rc And Output    oc create namespace ${SERVERLESS_NS}
          Install ISV Operator From OperatorHub Via CLI    operator_name=${SERVERLESS_OP_NAME}
          ...    namespace=${SERVERLESS_NS}
          ...    subscription_name=${SERVERLESS_SUB_NAME}
          ...    catalog_source_name=redhat-operators
          ...    operator_group_name=serverless-operators
          ...    operator_group_ns=${SERVERLESS_NS}
          ...    operator_group_target_ns=${NONE}
          Wait Until Operator Subscription Last Condition Is
          ...    type=CatalogSourcesUnhealthy    status=False
          ...    reason=AllCatalogSourcesHealthy    subcription_name=${SERVERLESS_SUB_NAME}
          ...    namespace=${SERVERLESS_NS}
          Wait For Pods To Be Ready    label_selector=name=knative-openshift
          ...    namespace=${SERVERLESS_NS}
          Wait For Pods To Be Ready    label_selector=name=knative-openshift-ingress
          ...    namespace=${SERVERLESS_NS}
          Wait For Pods To Be Ready    label_selector=name=knative-operator
          ...    namespace=${SERVERLESS_NS}
    ELSE
         Log To Console    message=Serverless Operator is already installed
    END

Set Component State
    [Documentation]    Set component state in Data Science Cluster (state should be Managed or Removed)
    [Arguments]    ${component}    ${state}
    ${result} =    Run Process    oc get datascienceclusters.datasciencecluster.opendatahub.io -o name
    ...    shell=true    stderr=STDOUT
    IF    $result.stdout == ""
        FAIL    Can not find datasciencecluster
    END
    ${cluster_name} =    Set Variable    ${result.stdout}
    ${result} =    Run Process    oc patch ${cluster_name} --type 'json' -p '[{"op" : "replace" ,"path" : "/spec/components/${component}/managementState" ,"value" : "${state}"}]'
    ...    shell=true    stderr=STDOUT
    IF    $result.rc != 0
        FAIL    Can not enable ${component}: ${result.stdout}
    END
    Log To Console    Component ${component} state was set to ${state}

Enable Component
    [Documentation]    Enables a component in Data Science Cluster
    [Arguments]    ${component}
    Set Component State    ${component}    Managed

Disable Component
    [Documentation]    Disable a component in Data Science Cluster
    [Arguments]    ${component}
    Set Component State    ${component}    Removed

Wait Component Ready
    [Documentation]    Wait for DSC cluster component to be ready
    [Arguments]    ${component}
    ${result} =    Run Process    oc get datascienceclusters.datasciencecluster.opendatahub.io -o name
    ...    shell=true    stderr=STDOUT
    IF    $result.stdout == ""
        FAIL    Can not find datasciencecluster
    END
    ${cluster_name} =    Set Variable    ${result.stdout}
    
    Log To Console    Waiting for ${component} to be ready
    
    # oc wait "${cluster_name}" --for=condition\=${component}Ready\=true --timeout\=3m
    ${result} =    Run Process    oc wait "${cluster_name}" --for condition\=${component}Ready\=true --timeout\=3m
    ...    shell=true    stderr=STDOUT
    IF    $result.rc != 0
        FAIL    Timeout waiting for ${component} to be ready
    END
    Log To Console    ${component} is ready

Add UI Admin Group To Dashboard Admin
    [Documentation]    Add Ui admin group to ODH dashboard admin group
    ${status} =     Run Keyword And Return Status    Check Group In Cluster    odh-ux-admins
    IF    ${status} == ${TRUE}
              ${rc}  ${output}=    Run And Return Rc And Output
              ...    oc patch OdhDashboardConfig odh-dashboard-config -n ${APPLICATIONS_NAMESPACE} --type merge -p '{"spec":{"groupsConfig":{"adminGroups":"odh-admins,odh-ux-admins"}}}'  #robocop: disable
              IF  ${rc} != ${0}     Log    message=Unable to update the admin config   level=WARN
    END
