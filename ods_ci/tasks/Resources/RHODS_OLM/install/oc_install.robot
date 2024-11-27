*** Settings ***
Library    String
Library    OpenShiftLibrary
Library    OperatingSystem
Resource   ../../../../tests/Resources/Page/Operators/ISVs.resource
Resource   ../../../../tests/Resources/Page/OCPDashboard/UserManagement/Groups.robot


*** Variables ***
${DSC_NAME} =    default-dsc
${DSCI_NAME} =    default-dsci
@{COMPONENT_LIST} =    codeflare
...    dashboard
...    datasciencepipelines
...    kserve
...    kueue
...    modelmeshserving
...    ray
...    trainingoperator
...    trustyai
...    workbenches
...    modelregistry
${SERVERLESS_OP_NAME}=     serverless-operator
${SERVERLESS_SUB_NAME}=    serverless-operator
${SERVERLESS_NS}=    openshift-serverless
${OPENSHIFT_OPERATORS_NS}=    openshift-operators
${SERVICEMESH_OP_NAME}=     servicemeshoperator
${SERVICEMESH_SUB_NAME}=    servicemeshoperator
${AUTHORINO_OP_NAME}=     authorino-operator
${AUTHORINO_SUB_NAME}=    authorino-operator
${AUTHORINO_CHANNEL_NAME}=  tech-preview-v1
${RHODS_CSV_DISPLAY}=    Red Hat OpenShift AI
${ODH_CSV_DISPLAY}=    Open Data Hub Operator
${CUSTOM_MANIFESTS}=    ${EMPTY}

*** Keywords ***
Install RHODS
  [Arguments]  ${cluster_type}     ${image_url}
  Install Kserve Dependencies
  Clone OLM Install Repo
  IF  "${PRODUCT}" == "ODH"
      ${csv_display_name} =    Set Variable    ${ODH_CSV_DISPLAY}
  ELSE
      ${csv_display_name} =    Set Variable    ${RHODS_CSV_DISPLAY}
  END
  IF  "${cluster_type}" == "selfmanaged"
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "CLi"
             Install RHODS In Self Managed Cluster Using CLI  ${cluster_type}     ${image_url}
      ELSE IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "OperatorHub"
          ${file_path} =    Set Variable    tasks/Resources/RHODS_OLM/install/
          Copy File    source=${file_path}cs_template.yaml    destination=${file_path}cs_apply.yaml
          IF  "${PRODUCT}" == "ODH"
              Run    sed -i'' -e 's/<CATALOG_SOURCE>/community-operators/' ${file_path}cs_apply.yaml
          ELSE
              Run    sed -i'' -e 's/<CATALOG_SOURCE>/rhoai-catalog-dev/' ${file_path}cs_apply.yaml
          END
          Run    sed -i'' -e 's/<OPERATOR_NAME>/${OPERATOR_NAME}/' ${file_path}cs_apply.yaml
          Run    sed -i'' -e 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}cs_apply.yaml
          Run    sed -i'' -e 's/<UPDATE_CHANNEL>/${UPDATE_CHANNEL}/' ${file_path}cs_apply.yaml
          Oc Apply   kind=List   src=${file_path}cs_apply.yaml
          Remove File    ${file_path}cs_apply.yml
      ELSE
           FAIL    Provided test environment and install type is not supported
      END
  ELSE IF  "${cluster_type}" == "managed"
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "CLi" and "${UPDATE_CHANNEL}" == "odh-nightlies"
          # odh-nightly is not build for Managed, it is only possible for Self-Managed
          Set Global Variable    ${OPERATOR_NAMESPACE}    openshift-marketplace
          Install RHODS In Self Managed Cluster Using CLI  ${cluster_type}     ${image_url}
          Set Global Variable    ${OPERATOR_NAME}         opendatahub-operator
      ELSE IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "CLi"
          Install RHODS In Managed Cluster Using CLI  ${cluster_type}     ${image_url}
      ELSE
          FAIL    Provided test environment is not supported
      END
  END
  Wait Until Csv Is Ready    display_name=${csv_display_name}    operators_namespace=${OPERATOR_NAMESPACE}

Verify RHODS Installation
  Set Global Variable    ${DASHBOARD_APP_NAME}    ${PRODUCT.lower()}-dashboard
  Log  Verifying RHODS installation  console=yes
  Log To Console    Waiting for all RHODS resources to be up and running
  Wait For Deployment Replica To Be Ready    namespace=${OPERATOR_NAMESPACE}
  ...    label_selector=name=${OPERATOR_NAME_LABEL}    timeout=2000s
  Wait For Pods Status  namespace=${OPERATOR_NAMESPACE}  timeout=1200
  Log  Verified ${OPERATOR_NAMESPACE}  console=yes

  IF  "${UPDATE_CHANNEL}" == "odh-nightlies" or "${cluster_type}" != "managed"
    IF  "${PRODUCT}" == "ODH"
        Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
        IF    "${TEST_ENV.lower()}" == "crc"
            ${timeout_in_seconds} =   Set Variable   180
        ELSE
            ${timeout_in_seconds} =   Set Variable   60
        END
        Wait For DSCInitialization CustomResource To Be Ready    timeout=${timeout_in_seconds}
    END
    Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
  END

  ${dashboard} =    Is Component Enabled    dashboard    ${DSC_NAME}
  IF    "${dashboard}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=${DASHBOARD_APP_NAME}    timeout=1200s
    IF  "${PRODUCT}" == "ODH"
        #This line of code is strictly used for the exploratory cluster to accommodate UI/UX team requests
        Add UI Admin Group To Dashboard Admin
    END
  END

  ${workbenches} =    Is Component Enabled    workbenches    ${DSC_NAME}
  IF    "${workbenches}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=notebook-controller    timeout=400s
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=odh-notebook-controller    timeout=400s
    Oc Get  kind=Namespace  field_selector=metadata.name=${NOTEBOOKS_NAMESPACE}
    Log  Verified Notebooks NS: ${NOTEBOOKS_NAMESPACE}
  END

  ${modelmeshserving} =    Is Component Enabled    modelmeshserving    ${DSC_NAME}
  IF    "${modelmeshserving}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=odh-model-controller    timeout=400s
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=component=model-mesh-etcd    timeout=400s
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/name=modelmesh-controller    timeout=400s
  END

  ${datasciencepipelines} =    Is Component Enabled    datasciencepipelines    ${DSC_NAME}
  IF    "${datasciencepipelines}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/name=data-science-pipelines-operator    timeout=400s
  END

  ${kserve} =    Is Component Enabled    kserve    ${DSC_NAME}
  IF    "${kserve}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=odh-model-controller    timeout=400s
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=control-plane=kserve-controller-manager    timeout=400s
  END

  ${kueue} =     Is Component Enabled     kueue    ${DSC_NAME}
  IF    "${kueue}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=kueue   timeout=400s
  END

  ${codeflare} =     Is Component Enabled     codeflare    ${DSC_NAME}
  IF    "${codeflare}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=codeflare   timeout=400s
  END

  ${ray} =     Is Component Enabled     ray    ${DSC_NAME}
  IF    "${ray}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=ray   timeout=400s
  END

  ${trustyai} =    Is Component Enabled    trustyai    ${DSC_NAME}
  IF    "${trustyai}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=trustyai    timeout=400s
  END

  ${modelregistry} =    Is Component Enabled    modelregistry    ${DSC_NAME}
  IF    "${modelregistry}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=model-registry-operator    timeout=400s
  END

  ${trainingoperator} =    Is Component Enabled    trainingoperator    ${DSC_NAME}
  IF    "${trainingoperator}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=trainingoperator   timeout=400s
  END

  IF    "${dashboard}" == "true" or "${workbenches}" == "true" or "${modelmeshserving}" == "true" or "${datasciencepipelines}" == "true" or "${kserve}" == "true" or "${kueue}" == "true" or "${codeflare}" == "true" or "${ray}" == "true" or "${trustyai}" == "true" or "${modelregistry}" == "true" or "${trainingoperator}" == "true"    # robocop: disable
      Log To Console    Waiting for pod status in ${APPLICATIONS_NAMESPACE}
      Wait For Pods Status  namespace=${APPLICATIONS_NAMESPACE}  timeout=200
      Log  Verified Applications NS: ${APPLICATIONS_NAMESPACE}  console=yes
  END

  # Monitoring stack only deployed for managed, as modelserving monitoring stack is no longer deployed
  IF  "${cluster_type}" == "managed"
     Log To Console    Waiting for pod status in ${MONITORING_NAMESPACE}
     Wait For Pods Status  namespace=${MONITORING_NAMESPACE}  timeout=600
     Log  Verified Monitoring NS: ${MONITORING_NAMESPACE}  console=yes
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
  ${return_code}    Run and Watch Command    cd ${EXECDIR}/${OLM_DIR} && ./setup.sh -t operator -u ${UPDATE_CHANNEL} -i ${image_url} -n ${OPERATOR_NAME} -p ${OPERATOR_NAMESPACE}   timeout=20 min
  Should Be Equal As Integers   ${return_code}   0   msg=Error detected while installing RHODS

Install RHODS In Managed Cluster Using CLI
  [Documentation]   Install rhods on managed managed cluster using cli
  [Arguments]     ${cluster_type}     ${image_url}
  ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${OLM_DIR} && ./setup.sh -t addon -u ${UPDATE_CHANNEL} -i ${image_url} -n ${OPERATOR_NAME} -p ${OPERATOR_NAMESPACE} -a ${APPLICATIONS_NAMESPACE} -m ${MONITORING_NAMESPACE}  #robocop:disable
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
               BREAK
         END
         Sleep    1 sec
  END
  IF    '${status}' == 'False'
        Run Keyword And Continue On Failure    FAIL    Timeout- ${output} pods found with the label selector ${label_selector} in ${namespace} namespace
  END

Apply DSCInitialization CustomResource
    [Documentation]
    [Arguments]        ${dsci_name}=${DSCI_NAME}
    ${return_code}    ${output} =    Run And Return Rc And Output    oc get DSCInitialization --output json | jq -j '.items | length'
    Log To Console    output : ${output}, return_code : ${return_code}
    IF  ${output} != 0
        Log to Console    Skip creation of DSCInitialization
        RETURN
    END
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Log to Console    Requested Configuration:
    Create DSCInitialization CustomResource Using Test Variables
    ${yml} =    Get File    ${file_path}dsci_apply.yml
    Log To Console    Applying DSCI yaml
    Log To Console    ${yml}
    ${return_code}    ${output} =    Run And Return Rc And Output    oc apply -f ${file_path}dsci_apply.yml
    Log To Console    ${output}
    Should Be Equal As Integers  ${return_code}  0  msg=Error detected while applying DSCI CR
    Remove File    ${file_path}dsci_apply.yml

Create DSCInitialization CustomResource Using Test Variables
    [Documentation]
    [Arguments]    ${dsci_name}=${DSCI_NAME}
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Copy File    source=${file_path}dsci_template.yml    destination=${file_path}dsci_apply.yml
    Run    sed -i'' -e 's/<dsci_name>/${dsci_name}/' ${file_path}dsci_apply.yml
    Run    sed -i'' -e 's/<application_namespace>/${APPLICATIONS_NAMESPACE}/' ${file_path}dsci_apply.yml
    Run    sed -i'' -e 's/<monitoring_namespace>/${MONITORING_NAMESPACE}/' ${file_path}dsci_apply.yml

Wait For DSCInitialization CustomResource To Be Ready
    [Documentation]   Wait ${timeout} seconds for DSCInitialization CustomResource To Be Ready
    [Arguments]     ${timeout}
    Log To Console    Waiting ${timeout} seconds for DSCInitialization CustomResource To Be Ready
    ${result} =    Run Process    oc wait DSCInitialization --timeout\=${timeout}s --for jsonpath\='{.status.phase}'\=Ready --all
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        Run Keyword And Continue On Failure    FAIL    ${result.stdout}
    END

Apply DataScienceCluster CustomResource
    [Documentation]
    [Arguments]        ${dsc_name}=${DSC_NAME}      ${custom}=False       ${custom_cmp}=''
    ${file_path} =    Set Variable    tasks/Resources/Files/
    IF      ${custom} == True
        Log to Console    message=Creating DataScience Cluster using custom configuration
        Generate CustomManifest In DSC YAML
        Rename DevFlags in DataScienceCluster CustomResource
        ${yml} =    Get File    ${file_path}dsc_apply.yml
        Log To Console    Applying DSC yaml
        Log To Console    ${yml}
        ${return_code}    ${output} =    Run And Return Rc And Output    oc apply -f ${file_path}dsc_apply.yml
        Log To Console    ${output}
        Should Be Equal As Integers  ${return_code}  0  msg=Error detected while applying DSC CR
        #Remove File    ${file_path}dsc_apply.yml
        Wait For DSC Conditions Reconciled    ${OPERATOR_NS}     ${DSC_NAME}
    ELSE
        Log to Console    Requested Configuration:
        FOR    ${cmp}    IN    @{COMPONENT_LIST}
            TRY
                Log To Console    ${cmp} - ${COMPONENTS.${cmp}}
            EXCEPT
                Log To Console    ${cmp} - Removed
            END
        END
        Log to Console    message=Creating DataScience Cluster using yml template
        Create DataScienceCluster CustomResource Using Test Variables
        Apply Custom Manifest in DataScienceCluster CustomResource Using Test Variables
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
    END

Create DataScienceCluster CustomResource Using Test Variables
    [Documentation]
    [Arguments]    ${dsc_name}=${DSC_NAME}
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Copy File    source=${file_path}dsc_template.yml    destination=${file_path}dsc_apply.yml
    Run    sed -i'' -e 's/<dsc_name>/${dsc_name}/' ${file_path}dsc_apply.yml
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
            IF    $cmp not in $COMPONENTS
                Run    sed -i'' -e 's/<${cmp}_value>/Removed/' ${file_path}dsc_apply.yml
            ELSE IF    '${COMPONENTS.${cmp}}' == 'Managed'
                Run    sed -i'' -e 's/<${cmp}_value>/Managed/' ${file_path}dsc_apply.yml
            ELSE IF    '${COMPONENTS.${cmp}}' == 'Removed'
                Run    sed -i'' -e 's/<${cmp}_value>/Removed/' ${file_path}dsc_apply.yml
            END
            # The model registry component needs to set the namespace used, so adding this special statement just for it
            IF    '${cmp}' == 'modelregistry'
                Run    sed -i'' -e 's/<${cmp}_namespace>/${MODEL_REGISTRY_NAMESPACE}/' ${file_path}dsc_apply.yml
            END
    END

Generate CustomManifest In DSC YAML
    [Arguments]    ${dsc_name}=${DSC_NAME}
    Log To Console      ${custom_cmp}.items
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Copy File    source=${file_path}dsc_template.yml    destination=${file_path}dsc_apply.yml
    Run    sed -i'' -e 's/<dsc_name>/${dsc_name}/' ${file_path}dsc_apply.yml
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
            ${value}=       Get From Dictionary 	${custom_cmp} 	${cmp}
            ${status}=       Get From Dictionary 	${value} 	managementState
            Log To Console      ${status}
            IF    '${status}' == 'Managed'
                Run    sed -i'' -e 's/<${cmp}_value>/Managed/' ${file_path}dsc_apply.yml
            ELSE IF    '${status}' == 'Removed'
                Run    sed -i'' -e 's/<${cmp}_value>/Removed/' ${file_path}dsc_apply.yml
            END
            # The model registry component needs to set the namespace used, so adding this special statement just for it
            IF    '${cmp}' == 'modelregistry'
                Run    sed -i'' -e 's/<${cmp}_namespace>/${MODEL_REGISTRY_NAMESPACE}/' ${file_path}dsc_apply.yml
            END
    END

Apply Custom Manifest in DataScienceCluster CustomResource Using Test Variables
    [Documentation]    Apply custom manifests to a DSC file
    Log To Console    Applying Custom Manifests
    ${file_path} =    Set Variable    tasks/Resources/Files/
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
         IF    $cmp in $CUSTOM_MANIFESTS
              ${manifest_string}=    Convert To String    ${CUSTOM_MANIFESTS}[${cmp}]
              # Use sed to replace the placeholder with the YAML string
              Run    sed -i'' -e "s|<${cmp}_devflags>|${manifest_string}|g" ${file_path}dsc_apply.yml
         ELSE
              Run    sed -i'' -e "s|<${cmp}_devflags>||g" ${file_path}dsc_apply.yml
         END
    END

Rename DevFlags in DataScienceCluster CustomResource
    [Documentation]     Filling devFlags fields for every component in DSC
    Log To Console    Filling devFlags fields for every component in DSC
    ${file_path} =    Set Variable    tasks/Resources/Files/
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
        Run     sed -i'' -e "s|<${cmp}_devflags>||g" ${file_path}dsc_apply.yml
    END

Wait For DataScienceCluster CustomResource To Be Ready
  [Documentation]   Wait for DataScienceCluster CustomResource To Be Ready
  [Arguments]     ${timeout}
  Log To Console    Waiting for DataScienceCluster CustomResource To Be Ready
  ${status} =   Set Variable   False
  FOR    ${counter}    IN RANGE   ${timeout}
         ${return_code}    ${output} =    Run And Return Rc And Output   oc get DataScienceCluster --no-headers -o custom-columns=":status.phase"        #robocop:disable
         IF    '${output}' == 'Ready'
               ${status} =  Set Variable  True
               Log To Console  DataScienceCluster CustomResource is Ready
               BREAK
         END
         Sleep    1 sec
  END
  IF    '${status}' == 'False'
        Run Keyword And Continue On Failure    FAIL    Timeout- DataScienceCluster CustomResource is not Ready
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
    ${return_code}    ${output} =    Run And Return Rc And Output    oc get datasciencecluster ${dsc_name} -o json | jq '.spec.components.${component}.managementState // "Removed"'  #robocop:disable
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

Wait for Catalog To Be Ready
    [Documentation]    Verify catalog is Ready OR NOT
    [Arguments]    ${namespace}=openshift-marketplace   ${catalog_name}=odh-catalog-dev   ${timeout}=30
    Log    Waiting for the '${catalog_name}' CatalogSource in '${namespace}' namespace to be in 'Ready' status state
    ...    console=yes
    Wait Until Keyword Succeeds    12 times   10 seconds
    ...   Catalog Is Ready    ${namespace}   ${catalog_name}
    Log    CatalogSource '${catalog_name}' in '${namespace}' namespace in 'Ready' status now, let's continue
    ...    console=yes

Catalog Is Ready
    [Documentation]   Check whether given CatalogSource is Ready
    [Arguments]    ${namespace}=openshift-marketplace   ${catalog_name}=odh-catalog-dev
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    oc get catalogsources ${catalog_name} -n ${namespace} -o json | jq ."status.connectionState.lastObservedState"    # robocop: disable:line-too-long
    Should Be Equal As Integers   ${rc}  0  msg=Error detected while getting CatalogSource status state
    Should Be Equal As Strings    "READY"    ${output}

Install Authorino Operator Via Cli
    [Documentation]    Install Authorino Operator Via CLI
    Install ISV Operator From OperatorHub Via CLI    operator_name=${AUTHORINO_OP_NAME}
          ...    subscription_name=${AUTHORINO_SUB_NAME}
          ...    channel=${AUTHORINO_CHANNEL_NAME}
          ...    catalog_source_name=redhat-operators
    Wait Until Operator Subscription Last Condition Is
          ...    type=CatalogSourcesUnhealthy    status=False
          ...    reason=AllCatalogSourcesHealthy    subcription_name=${AUTHORINO_SUB_NAME}
          ...    retry=150
    Wait For Pods To Be Ready    label_selector=control-plane=authorino-operator
          ...    namespace=${OPENSHIFT_OPERATORS_NS}
    Wait For Pods To Be Ready    label_selector=authorino-component=authorino-webhooks
          ...    namespace=${OPENSHIFT_OPERATORS_NS}

Install Service Mesh Operator Via Cli
    [Documentation]    Install Service Mesh Operator Via CLI
    Install ISV Operator From OperatorHub Via CLI    operator_name=${SERVICEMESH_OP_NAME}
          ...    subscription_name=${SERVICEMESH_SUB_NAME}
          ...    catalog_source_name=redhat-operators
    Wait Until Operator Subscription Last Condition Is
          ...    type=CatalogSourcesUnhealthy    status=False
          ...    reason=AllCatalogSourcesHealthy    subcription_name=${SERVICEMESH_SUB_NAME}
          ...    retry=150
    Wait For Pods To Be Ready    label_selector=name=istio-operator
          ...    namespace=${OPENSHIFT_OPERATORS_NS}

Install Serverless Operator Via Cli
    [Documentation]    Install Serverless Operator Via CLI
    ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${SERVERLESS_NS}
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
          ...    retry=150
    Wait For Pods To Be Ready    label_selector=name=knative-openshift
          ...    namespace=${SERVERLESS_NS}
    Wait For Pods To Be Ready    label_selector=name=knative-openshift-ingress
          ...    namespace=${SERVERLESS_NS}
    Wait For Pods To Be Ready    label_selector=name=knative-operator
          ...    namespace=${SERVERLESS_NS}

Install Kserve Dependencies
    [Documentation]    Install Dependent Operators For Kserve
    Set Suite Variable   ${FILES_RESOURCES_DIRPATH}    tests/Resources/Files
    Set Suite Variable   ${SUBSCRIPTION_YAML_TEMPLATE_FILEPATH}    ${FILES_RESOURCES_DIRPATH}/isv-operator-subscription.yaml
    Set Suite Variable   ${OPERATORGROUP_YAML_TEMPLATE_FILEPATH}    ${FILES_RESOURCES_DIRPATH}/isv-operator-group.yaml
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${AUTHORINO_OP_NAME}
    IF    not ${is_installed}
          Install Authorino Operator Via Cli
    ELSE
          Log To Console    message=Authorino Operator is already installed
    END
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${SERVICEMESH_OP_NAME}
    IF    not ${is_installed}
          Install Service Mesh Operator Via Cli
    ELSE
          Log To Console    message=ServiceMesh Operator is already installed
    END
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${SERVERLESS_OP_NAME}
    IF    not ${is_installed}
         Install Serverless Operator Via Cli
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

Get DSC Component State
    [Documentation]    Get component management state
    [Arguments]    ${dsc}    ${component}    ${namespace}

    ${rc}   ${state}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster/${dsc} -n ${namespace} -o 'jsonpath={.spec.components.${component}.managementState}'
    Should Be Equal    "${rc}"    "0"    msg=${state}
    Log To Console    Component ${component} state ${state}

    RETURN    ${state}
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
    ${result} =    Run Process    oc wait "${cluster_name}" --for condition\=${component}Ready\=true --timeout\=10m
    ...    shell=true    stderr=STDOUT
    IF    $result.rc != 0
        ${suffix} =  Generate Random String  4  [LOWER]
        ${result_dsc_get} =    Run Process    oc get datascienceclusters.datasciencecluster.opendatahub.io -o yaml > dsc-${component}-dump-${suffix}.yaml
        ...    shell=true    stderr=STDOUT
        IF  ${result_dsc_get.rc} == ${0}     FAIL    Timeout waiting for ${component} to be ready, DSC CR content stored in 'dsc-${component}-dump-${suffix}.yaml'
        FAIL    Timeout waiting for ${component} to be ready, DSC CR cannot be retrieved
    END
    Log To Console    ${component} is ready

Add UI Admin Group To Dashboard Admin
    [Documentation]    Add UI admin group to ODH dashboard admin group [only for odh-nightly]
    ${status} =     Run Keyword And Return Status    Check Group In Cluster    odh-ux-admins
    IF    ${status} == ${TRUE}
              ${rc}  ${output}=    Run And Return Rc And Output
              ...   oc wait --for=condition=ready pod -l app=odh-dashboard -n ${APPLICATIONS_NAMESPACE} --timeout=400s  #robocop: disable
              IF  ${rc} != ${0}     Log    message=Dashboard Pod is not up and running   level=ERROR
              ${rc}  ${output}=    Run And Return Rc And Output
              ...    oc patch OdhDashboardConfig odh-dashboard-config -n ${APPLICATIONS_NAMESPACE} --type merge -p '{"spec":{"groupsConfig":{"adminGroups":"odh-admins,odh-ux-admins"}}}'  #robocop: disable
              IF  ${rc} != ${0}     Log    message=Unable to update the admin config   level=WARN
    END
