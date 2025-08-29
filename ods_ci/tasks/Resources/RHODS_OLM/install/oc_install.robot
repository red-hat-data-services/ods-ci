*** Settings ***
Library    String
Library    OpenShiftLibrary
Library    OperatingSystem
Resource   ../../../../tests/Resources/Page/Operators/ISVs.resource
Resource   ../../../../tests/Resources/Page/OCPDashboard/UserManagement/Groups.robot
Resource   ../../../../tests/Resources/OCP.resource


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
...    feastoperator
...    llamastackoperator
${SERVERLESS_OP_NAME}=     serverless-operator
${SERVERLESS_SUB_NAME}=    serverless-operator
${SERVERLESS_NS}=    openshift-serverless
${OPENSHIFT_OPERATORS_NS}=    openshift-operators
${COMMUNITY_OPERATORS_NS}=    openshift-marketplace
${COMMUNITY_OPERATORS_CS}=    community-operators
${SERVICEMESH_OP_NAME}=     servicemeshoperator
${SERVICEMESH_SUB_NAME}=    servicemeshoperator
${AUTHORINO_OP_NAME}=     authorino-operator
${AUTHORINO_SUB_NAME}=    authorino-operator
${AUTHORINO_CHANNEL_NAME}=  stable
${CLUSTER_OBS_OP_NAME}=  cluster-observability-operator
${CLUSTER_OBS_SUB_NAME}=  cluster-observability-operator
${CLUSTER_OBS_CHANNEL_NAME}=  stable
${CLUSTER_OBS_NS}=  openshift-cluster-observability-operator
${CMA_OP_NAME}=  openshift-custom-metrics-autoscaler-operator
${CMA_SUB_NAME}=  openshift-custom-metrics-autoscaler-operator
${CMA_NS}=  openshift-keda
${CMA_CHANNEL_NAME}=  stable
${TEMPO_OP_NAME}=  tempo-product
${TEMPO_SUB_NAME}=  tempo-operator
${TEMPO_CHANNEL_NAME}=  stable
${TEMPO_NS}=  openshift-tempo-operator
${TELEMETRY_OP_NAME}=  opentelemetry-product
${TELEMETRY_SUB_NAME}=  opentelemetry-operator
${TELEMETRY_CHANNEL_NAME}=  stable
${TELEMETRY_NS}=  openshift-opentelemetry-operator
${KUEUE_OP_NAME}=  kueue-operator
${KUEUE_SUB_NAME}=  kueue-operator
${KUEUE_CHANNEL_NAME}=  stable-v1.0
${KUEUE_NS}=  openshift-kueue-operator
${CERT_MANAGER_OP_NAME}=  openshift-cert-manager-operator
${CERT_MANAGER_SUB_NAME}=  openshift-cert-manager-operator
${CERT_MANAGER_CHANNEL_NAME}=  stable-v1
${CERT_MANAGER_NS}=  cert-manager-operator
${RHODS_CSV_DISPLAY}=    Red Hat OpenShift AI
${ODH_CSV_DISPLAY}=    Open Data Hub Operator
${DEFAULT_OPERATOR_NAMESPACE_RHOAI}=    redhat-ods-operator
${DEFAULT_OPERATOR_NAMESPACE_ODH}=    opendatahub-operators
${DEFAULT_APPLICATIONS_NAMESPACE_RHOAI}=    redhat-ods-applications
${DEFAULT_APPLICATIONS_NAMESPACE_ODH}=    opendatahub
${DEFAULT_WORKBENCHES_NAMESPACE_RHOAI}=    rhods-notebooks
${DEFAULT_WORKBENCHES_NAMESPACE_ODH}=    opendatahub
${CUSTOM_MANIFESTS}=    ${EMPTY}
${IS_NOT_PRESENT}=      1
${DSC_TEMPLATE}=    dsc_template.yml
${DSC_TEMPLATE_RAW}=    dsc_template_raw.yml
${DSCI_TEMPLATE}=    dsci_template.yml
${DSCI_TEMPLATE_RAW}=    dsci_template_raw.yml
@{RHOAI_DEPENDENCIES}=    Create List
${CONFIG_ENV}=    ${EMPTY}
${NFS_OP_NAME}=    nfs-provisioner-operator
${NFS_OP_NS}=    openshift-operators
${NFS_SUB_NAME}=    nfs-provisioner-operator-sub
${NFS_CHANNEL_NAME}=    alpha
${RESOURCES_DIRPATH}=    tasks/Resources/Files
${RHODS_OSD_INSTALL_REPO}=      ${EMPTY}
${OLM_DIR}=                     rhodsolm
@{SUPPORTED_TEST_ENV}=          AWS   AWS_DIS   GCP   PSI   PSI_DIS   ROSA   IBM_CLOUD   CRC    AZURE	ROSA_HCP
${install_plan_approval}=       Manual

*** Keywords ***
Install RHODS
  [Arguments]  ${cluster_type}     ${image_url}     ${install_plan_approval}
  ...    ${rhoai_version}=${EMPTY}    ${is_upgrade}=False
  Log    Start installing RHOAI with:\n\- cluster type: ${cluster_type}\n\- image_url: ${image_url}\n\- update_channel: ${UPDATE_CHANNEL}    console=yes    #robocop:disable
  Log    \- rhoai_version: ${rhoai_version}\n\- is_upgrade: ${is_upgrade}\n\- install_plan_approval: ${install_plan_approval}\n\- CATALOG_SOURCE: ${CATALOG_SOURCE}   console=yes    #robocop:disable
  Assign Vars According To Product
  ${install_authorino_dependency} =    Get Variable Value    ${INSTALL_AUTHORINO_DEPENDENCY}    true
  IF    "${install_authorino_dependency}" == "true"
      Append To List     ${RHOAI_DEPENDENCIES}     authorino
  END
  ${kserve_raw_deployment} =    Get Variable Value    ${KSERVE_RAW_DEPLOYMENT}    false
  IF    "${kserve_raw_deployment}" == "true"
      Set Suite Variable    ${CONFIG_ENV}    -e DISABLE_DSC_CONFIG    # robocop: disable
      Set Suite Variable    ${DSC_TEMPLATE}    ${DSC_TEMPLATE_RAW}    # robocop: disable
      Set Suite Variable    ${DSCI_TEMPLATE}    ${DSCI_TEMPLATE_RAW}    # robocop: disable
  ELSE
      Append To List     ${RHOAI_DEPENDENCIES}     servicemesh
      Append To List     ${RHOAI_DEPENDENCIES}     serverless
  END
  Install Rhoai Dependencies
  ${enable_new_observability_stack} =    Get Variable Value    ${ENABLE_NEW_OBSERVABILITY_STACK}    true
  IF    "${enable_new_observability_stack}" == "true"
          Install Observability Dependencies
  END
  Clone OLM Install Repo
  Configure Custom Namespaces
  IF   "${cluster_type}" == "selfmanaged"
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "Cli"
             Install RHODS In Self Managed Cluster Using CLI  ${cluster_type}     ${image_url}
      ELSE IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "OperatorHub"
          IF  "${is_upgrade}" == "False"
              ${file_path} =    Set Variable    tasks/Resources/RHODS_OLM/install/
              ${starting_csv} =  Set Variable    ""
              IF  "${rhoai_version}" != "${EMPTY}"
                  Log    Start installing "${OPERATOR_NAME}" with version: ${rhoai_version}    console=yes
                  ${starting_csv} =  Set Variable    ${OPERATOR_NAME}.${rhoai_version}
              END
              Log    rhoai_version is: "${rhoai_version}"    console=yes
              Log    OPERATOR_NAME is: "${OPERATOR_NAME}"    console=yes
              Log    starting_csv is: "${starting_csv}"    console=yes
              ${destination_file} =    Set Variable    ${file_path}cs_apply.yaml
              Copy File    source=${file_path}cs_template.yaml    destination=${destination_file}
              Run    sed -i'' -e 's/<CATALOG_SOURCE>/${CATALOG_SOURCE}/' ${destination_file}
              Run    sed -i'' -e 's/<OPERATOR_NAME>/${OPERATOR_NAME}/' ${destination_file}
              Run    sed -i'' -e 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${destination_file}
              Run    sed -i'' -e 's/<UPDATE_CHANNEL>/${UPDATE_CHANNEL}/' ${destination_file}
              Run    sed -i'' -e 's/<STARTING_CSV>/${starting_csv}/' ${destination_file}
              Run    sed -i'' -e 's/<INSTALL_PLAN_APPROVAL>/${install_plan_approval}/' ${destination_file}
              Oc Apply   kind=List   src=${destination_file}
              Remove File    ${destination_file}
          ELSE
              ${patch_update_channel_status} =    Run And Return Rc   oc patch subscription ${OPERATOR_NAME} -n ${OPERATOR_NAMESPACE} --type='json' -p='[{"op": "replace", "path": "/spec/channel", "value": ${UPDATE_CHANNEL}}]'    #robocop:disable
              Should Be Equal As Integers    ${patch_update_channel_status}    0    msg=Error while changing the UPDATE_CHANNEL    #robocop:disable
              Sleep  30s      reason=wait for thirty seconds until old CSV is removed and new one is ready
          END
          Wait For Installplan And Approve It    ${OPERATOR_NAMESPACE}    ${OPERATOR_NAME}    ${OPERATOR_SUBSCRIPTION_NAME}    ${rhoai_version}    #robocop:disable
      ELSE
           FAIL    Provided test environment and install type is not supported
      END
  ELSE IF   "${cluster_type}" == "managed"
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "Cli" and "${UPDATE_CHANNEL}" == "odh-nightlies"
          # odh-nightly is not build for Managed, it is only possible for Self-Managed
          Set Global Variable    ${OPERATOR_NAMESPACE}    openshift-marketplace
          Install RHODS In Self Managed Cluster Using CLI  ${cluster_type}     ${image_url}
          Set Global Variable    ${OPERATOR_NAME}         opendatahub-operator
      ELSE IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "Cli"
          Install RHODS In Managed Cluster Using CLI  ${cluster_type}     ${image_url}
      ELSE
          FAIL    Provided test environment is not supported
      END
  END
  Wait Until Csv Is Ready    display_name=${OPERATOR_NAME}    operators_namespace=${OPERATOR_NAMESPACE}
  IF  "${is_upgrade}" == "False"
      Add StartingCSV To Subscription
  END


Add StartingCSV To Subscription
    [Documentation]    Retrieves current RHOAI version from subscription status and add
    ...                startingCSV field in the subscription only if it is empty.
    ...                Needed for post-upgrade test suites to identify which RHOAI version
    ...                was installed before upgrading
    ${current_starting_csv} =    Run And Return Rc And Output    oc get subscription ${OPERATOR_SUBSCRIPTION_NAME} -n ${OPERATOR_NAMESPACE} -o jsonpath='{.spec.startingCSV}'    #robocop:disable
    Log    Current startingCSV field: ${current_starting_csv}[1]    console=yes
    IF    "${current_starting_csv}[1]" == ""
        Log    StartingCSV field is empty, patching ODH/RHOAI subscription to add startingCSV field    console=yes
        ${rc}    ${out} =    Run And Return Rc And Output    sh tasks/Resources/RHODS_OLM/install/add_starting_csv.sh
        Log    ${out}    console=yes
        Run Keyword And Continue On Failure    Should Be Equal As Numbers    ${rc}    ${0}
        IF    ${rc} != ${0}
            Log    Unable to add startingCSV after RHOAI operator installation.\nCheck the cluster please    console=yes
            ...    level=ERROR
        END
    ELSE
        Log    StartingCSV field already exists: ${current_starting_csv}[1], skipping patch    console=yes
    END

Verify RHODS Installation
  Set Global Variable    ${DASHBOARD_APP_NAME}    ${PRODUCT.lower()}-dashboard
  Log    Verifying RHODS installation    console=yes
  Log    Waiting for all RHODS resources to be up and running    console=yes
  Wait For Deployment Replica To Be Ready    namespace=${OPERATOR_NAMESPACE}
  ...    label_selector=name=${OPERATOR_NAME_LABEL}    timeout=2000s
  Wait For Pods Status  namespace=${OPERATOR_NAMESPACE}  timeout=1200
  Log  Verified ${OPERATOR_NAMESPACE}  console=yes

  IF   "${cluster_type}" == "managed"
       IF   "${PRODUCT}" == "ODH"
            Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
            Wait For DSCInitialization CustomResource To Be Ready
            Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
       ELSE
            # If managed and RHOAI, we need to wait for the operator to create the DSCI and then patch it with
            # the monitoring info in case the new obs stack flag is enabled
            Wait Until Keyword Succeeds    5 min    0 sec
            ...        Run And Return Rc      oc get DSCInitialization ${DSCI_NAME}
            ${ENABLE_NEW_OBSERVABILITY_STACK} =    Get Variable Value    ${ENABLE_NEW_OBSERVABILITY_STACK}    true
            IF    "${ENABLE_NEW_OBSERVABILITY_STACK}" == "true"
                    Patch DSCInitialization With Monitoring Info
            END
       END
  ELSE
      IF  "${APPLICATIONS_NAMESPACE}" != "${DEFAULT_APPLICATIONS_NAMESPACE_RHOAI}" and "${APPLICATIONS_NAMESPACE}" != "${DEFAULT_APPLICATIONS_NAMESPACE_ODH}"
          Create DSCI With Custom Namespaces
      END
      Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
      Wait For DSCInitialization CustomResource To Be Ready
      Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
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
      ${kueue_state}=    Get DSC Component State    ${DSC_NAME}    kueue    ${OPERATOR_NAMESPACE}
      IF    "${kueue_state}" == "Unmanaged"
             Install Kueue Dependencies
             Wait For Deployment Replica To Be Ready    namespace=${KUEUE_NS}
      ...    label_selector=app.kubernetes.io/name=kueue   timeout=400s
      ELSE
             Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
      ...    label_selector=app.kubernetes.io/part-of=kueue   timeout=400s
      END
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

  ${feastoperator} =    Is Component Enabled    feastoperator    ${DSC_NAME}
  IF    "${feastoperator}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=feastoperator   timeout=400s
  END

  ${llamastackoperator} =    Is Component Enabled    llamastackoperator    ${DSC_NAME}
  IF    "${llamastackoperator}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=llamastackoperator   timeout=400s
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

Verify Builds In Application Namespace
  Log  Verifying Builds  console=yes
  Wait Until Keyword Succeeds  45 min  15 s  Verify Builds Number  7
  Wait Until Keyword Succeeds  45 min  15 s  Verify Builds Status  Complete
  Log  Builds Verified  console=yes

Clone OLM Install Repo
  [Documentation]   Clone OLM git repo
  ${status} =   Run Keyword And Return Status    Directory Should Exist   ${EXECDIR}/${OLM_DIR}
  IF    ${status}
      Log    "The directory ${EXECDIR}/${OLM_DIR} already exist, skipping clone of the repo."    console=yes
  ELSE
      ${return_code}    ${output} =    Run And Return Rc And Output    git clone ${RHODS_OSD_INSTALL_REPO} ${EXECDIR}/${OLM_DIR}    #robocop:disable
      Log    ${output}    console=yes
      Should Be Equal As Integers   ${return_code}   0
      ${return_code}    ${output} =    Run And Return Rc And Output    cd ${EXECDIR}/${OLM_DIR} && git checkout main    #robocop:disable
      Log    ${output}    console=yes
      Should Be Equal As Integers   ${return_code}   0
  END

Install RHODS In Self Managed Cluster Using CLI
  [Documentation]   Install rhods on self managed cluster using cli
  [Arguments]     ${cluster_type}     ${image_url}    ${config_env}=${CONFIG_ENV}
  ${return_code} =    Run And Watch Command
  ...    cd ${EXECDIR}/${OLM_DIR} && ./setup.sh -t operator -u ${UPDATE_CHANNEL} -i ${image_url} -n ${OPERATOR_NAME} -p ${OPERATOR_NAMESPACE} ${CONFIG_ENV}    # robocop: disable
  ...    timeout=20 min
  Should Be Equal As Integers   ${return_code}   0   msg=Error detected while installing RHODS

Install RHODS In Managed Cluster Using CLI
  [Documentation]   Install rhods on managed managed cluster using cli
  [Arguments]     ${cluster_type}     ${image_url}
  ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${OLM_DIR} && ./setup.sh -t addon -u ${UPDATE_CHANNEL} -i ${image_url} -n ${OPERATOR_NAME} -p ${OPERATOR_NAMESPACE} -a ${APPLICATIONS_NAMESPACE} -m ${MONITORING_NAMESPACE}  #robocop:disable
  Log To Console    ${output}
  Should Be Equal As Integers   ${return_code}   0  msg=Error detected while installing RHODS

Wait For Pods Numbers
  [Documentation]   Wait for number of pod during installation
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
    [Arguments]        ${dsci_name}=${DSCI_NAME}    ${dsci_template}=${DSCI_TEMPLATE}
    ${ENABLE_NEW_OBSERVABILITY_STACK} =    Get Variable Value    ${ENABLE_NEW_OBSERVABILITY_STACK}    true
    ${return_code}    ${output} =    Run And Return Rc And Output    oc get DSCInitialization --output json | jq -j '.items | length'
    Log To Console    output : ${output}, return_code : ${return_code}
    IF  ${output} != 0
        Log to Console    Skip creation of DSCInitialization because its already created by the operator
        IF    "${ENABLE_NEW_OBSERVABILITY_STACK}" == "true"
                Patch DSCInitialization With Monitoring Info
        END
        RETURN
    END
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Log to Console    Requested Configuration:
    Create DSCInitialization CustomResource Using Test Variables
    ...    dsci_name=${dsci_name}
    ...    dsci_template=${dsci_template}
    ${yml} =    Get File    ${file_path}dsci_apply.yml
    Log To Console    Applying DSCI yaml
    Log To Console    ${yml}
    ${return_code}    ${output} =    Run And Return Rc And Output    oc apply -f ${file_path}dsci_apply.yml
    Log To Console    ${output}
    Should Be Equal As Integers  ${return_code}  0  msg=Error detected while applying DSCI CR
    Remove File    ${file_path}dsci_apply.yml
    IF    "${ENABLE_NEW_OBSERVABILITY_STACK}" == "true"
                Patch DSCInitialization With Monitoring Info
    END

Create DSCInitialization CustomResource Using Test Variables
    [Documentation]
    [Arguments]    ${dsci_name}=${DSCI_NAME}    ${dsci_template}=${DSCI_TEMPLATE}
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Copy File    source=${file_path}${dsci_template}    destination=${file_path}dsci_apply.yml
    Run    sed -i'' -e 's/<dsci_name>/${dsci_name}/' ${file_path}dsci_apply.yml
    Run    sed -i'' -e 's/<application_namespace>/${APPLICATIONS_NAMESPACE}/' ${file_path}dsci_apply.yml
    Run    sed -i'' -e 's/<monitoring_namespace>/${MONITORING_NAMESPACE}/' ${file_path}dsci_apply.yml
    Run    sed -i'' -e 's/<operator_yaml_label>/${OPERATOR_YAML_LABEL}/' ${file_path}dsci_apply.yml

Patch DSCInitialization With Monitoring Info
    [Documentation]  Patches the DSCInitialization with the Monitoring info if the new obs stack is being used
    ${file_path} =    Set Variable    tasks/Resources/Files/
    ${rc}   ${output}=    Run And Return Rc And Output
    ...         oc patch DSCInitialization/default-dsci -n ${OPERATOR_NAMESPACE} --patch-file="${file_path}monitoring-patch-payload.json" --type merge    #robocop:disable
    Should Be Equal    "${rc}"    "0"   msg=${output}

Wait For DSCInitialization CustomResource To Be Ready
    [Documentation]   Wait ${timeout} seconds for DSCInitialization CustomResource To Be Ready
    [Arguments]     ${timeout}=600
    Log To Console    Waiting ${timeout} seconds for DSCInitialization CustomResource To Be Ready
    ${result} =    Run Process    oc wait DSCInitialization --timeout\=${timeout}s --for jsonpath\='{.status.phase}'\=Ready --all
    ...    shell=true    stderr=STDOUT
    IF    ${result.rc} != 0
        FAIL    ${result.stdout}
    END
    ${_}  ${dsci} =    Run And Return Rc And Output    oc get DSCInitialization -o yaml
    Log To Console    DSCInitialization CustomResource Is Ready
    Log To COnsole    ${dsci}

Apply DataScienceCluster CustomResource
    [Documentation]
    [Arguments]        ${dsc_name}=${DSC_NAME}      ${custom}=False       ${custom_cmp}=''
    ...    ${dsc_template}=${DSC_TEMPLATE}
    ${file_path} =    Set Variable    tasks/Resources/Files/
    IF      ${custom} == True
        Log to Console    message=Creating DataScience Cluster using custom configuration
        Generate CustomManifest In DSC YAML
        ...    dsc_name=${dsc_name}
        ...    dsc_template=${dsc_template}
        Rename DevFlags in DataScienceCluster CustomResource
        ${yml} =    Get File    ${file_path}dsc_apply.yml
        Log To Console    Applying DSC yaml
        Log To Console    ${yml}
        ${return_code}    ${output} =    Run And Return Rc And Output    oc apply -f ${file_path}dsc_apply.yml
        Log To Console    ${output}
        Should Be Equal As Integers  ${return_code}  0  msg=Error detected while applying DSC CR
        #Remove File    ${file_path}dsc_apply.yml
        Wait For DSC Ready State    ${OPERATOR_NAMESPACE}     ${DSC_NAME}
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
            ELSE IF    '${COMPONENTS.${cmp}}' == 'Unmanaged'
                    Component Should Be Enabled    ${cmp}
            ELSE IF    '${COMPONENTS.${cmp}}' == 'Removed'
                    Component Should Not Be Enabled    ${cmp}
            END
        END
    END

Create DataScienceCluster CustomResource Using Test Variables
    [Documentation]
    [Arguments]    ${dsc_name}=${DSC_NAME}    ${dsc_template}=${DSC_TEMPLATE}
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Copy File    source=${file_path}${dsc_template}    destination=${file_path}dsc_apply.yml
    Run    sed -i'' -e 's/<dsc_name>/${dsc_name}/' ${file_path}dsc_apply.yml
    Run    sed -i'' -e 's/<operator_yaml_label>/${OPERATOR_YAML_LABEL}/' ${file_path}dsc_apply.yml
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
            IF    $cmp not in $COMPONENTS
                Run    sed -i'' -e 's/<${cmp}_value>/Removed/' ${file_path}dsc_apply.yml
            ELSE IF    '${COMPONENTS.${cmp}}' == 'Managed'
                Run    sed -i'' -e 's/<${cmp}_value>/Managed/' ${file_path}dsc_apply.yml
            ELSE IF    '${COMPONENTS.${cmp}}' == 'Unmanaged'
                Run    sed -i'' -e 's/<${cmp}_value>/Unmanaged/' ${file_path}dsc_apply.yml
            ELSE IF    '${COMPONENTS.${cmp}}' == 'Removed'
                Run    sed -i'' -e 's/<${cmp}_value>/Removed/' ${file_path}dsc_apply.yml
            END
            # The model registry component needs to set the namespace used, so adding this special statement just for it
            IF    '${cmp}' == 'modelregistry'
                Run    sed -i'' -e 's/<modelregistry_namespace>/${MODEL_REGISTRY_NAMESPACE}/' ${file_path}dsc_apply.yml
            END
            # The workbenches component needs to set the namespace used, so adding this special statement just for it
            IF    '${cmp}' == 'workbenches'
                Run    sed -i'' -e 's/<workbenches_namespace>/${NOTEBOOKS_NAMESPACE}/' ${file_path}dsc_apply.yml
            END
    END

Generate CustomManifest In DSC YAML
    [Arguments]    ${dsc_name}=${DSC_NAME}    ${dsc_template}=${DSC_TEMPLATE}
    Log To Console      ${custom_cmp}.items
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Copy File    source=${file_path}${dsc_template}    destination=${file_path}dsc_apply.yml
    Run    sed -i'' -e 's/<dsc_name>/${dsc_name}/' ${file_path}dsc_apply.yml
    FOR    ${cmp}    IN    @{COMPONENT_LIST}
            ${value}=       Get From Dictionary 	${custom_cmp} 	${cmp}
            ${status}=       Get From Dictionary 	${value} 	managementState
            Log To Console      ${status}
            IF    '${status}' == 'Managed'
                Run    sed -i'' -e 's/<${cmp}_value>/Managed/' ${file_path}dsc_apply.yml
            ELSE IF    '${status}' == 'Unmanaged'
                Run    sed -i'' -e 's/<${cmp}_value>/Unmanaged/' ${file_path}dsc_apply.yml
            ELSE IF    '${status}' == 'Removed'
                Run    sed -i'' -e 's/<${cmp}_value>/Removed/' ${file_path}dsc_apply.yml
            END
            # The model registry component needs to set the namespace used, so adding this special statement just for it
            IF    '${cmp}' == 'modelregistry'
                Run    sed -i'' -e 's/<modelregistry_namespace>/${MODEL_REGISTRY_NAMESPACE}/' ${file_path}dsc_apply.yml
            END
            # The workbenches component needs to set the namespace used, so adding this special statement just for it
            IF    '${cmp}' == 'workbenches'
                Run    sed -i'' -e 's/<workbenches_namespace>/${NOTEBOOKS_NAMESPACE}/' ${file_path}dsc_apply.yml
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
    ${status} =   Set Variable   False
    WHILE   '${status}' != 'true'    limit=60 seconds
        ${status} =    Is Component Enabled    ${component}    ${dsc_name}
        IF    '${status}' == 'true'    BREAK
    END

Component Should Not Be Enabled
    [Arguments]    ${component}    ${dsc_name}=${DSC_NAME}
    ${status} =   Set Variable   True
    WHILE   '${status}' != 'false'    limit=60 seconds
        ${status} =    Is Component Enabled    ${component}    ${dsc_name}
        IF    '${status}' == 'false'    BREAK
    END

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
         ELSE IF    ${output} == "Unmanaged"
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
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${AUTHORINO_OP_NAME}
    IF    not ${is_installed}
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
    ELSE
          Log To Console    message=Authorino Operator is already installed
    END

Install Service Mesh Operator Via Cli
    [Documentation]    Install Service Mesh Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${SERVICEMESH_OP_NAME}
    IF    not ${is_installed}
          Install ISV Operator From OperatorHub Via CLI    operator_name=${SERVICEMESH_OP_NAME}
             ...    subscription_name=${SERVICEMESH_SUB_NAME}
             ...    catalog_source_name=redhat-operators
          Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subcription_name=${SERVICEMESH_SUB_NAME}
             ...    retry=150
          Wait For Pods To Be Ready    label_selector=name=istio-operator
             ...    namespace=${OPENSHIFT_OPERATORS_NS}
    ELSE
          Log To Console    message=Service Mesh Operator is already installed
    END

Install Serverless Operator Via Cli
    [Documentation]    Install Serverless Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${SERVERLESS_OP_NAME}
    IF    not ${is_installed}
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
    ELSE
        Log To Console    message=Serverless Operator is already installed
    END

Install Rhoai Dependencies
    [Documentation]    Install Dependent Operators For Rhoai
    [Arguments]    ${dependencies}=${RHOAI_DEPENDENCIES}
    Set Suite Variable   ${FILES_RESOURCES_DIRPATH}    tests/Resources/Files
    Set Suite Variable   ${SUBSCRIPTION_YAML_TEMPLATE_FILEPATH}    ${FILES_RESOURCES_DIRPATH}/isv-operator-subscription.yaml
    Set Suite Variable   ${OPERATORGROUP_YAML_TEMPLATE_FILEPATH}    ${FILES_RESOURCES_DIRPATH}/isv-operator-group.yaml
    IF    "authorino" in ${dependencies}
        Install Authorino Operator Via Cli
    ELSE
        Log To Console    message=Authorino Operator is skipped (not included in rhoai dependencies)
    END
    IF    "servicemesh" in ${dependencies}
        Install Service Mesh Operator Via Cli
    ELSE
        Log To Console    message=ServiceMesh Operator is skipped (not included in rhoai dependencies)
    END
    IF    "serverless" in ${dependencies}
        Install Serverless Operator Via Cli
    ELSE
        Log To Console    message=Serverless Operator is skipped (not included in rhoai dependencies)
    END

Install Cert Manager Operator Via Cli
    [Documentation]    Install Cert Manager Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${CERT_MANAGER_OP_NAME}
    IF    ${is_installed}
        Log To Console    message=Cert Manager Operator is already installed
    ELSE
        ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${CERT_MANAGER_NS}
        Install ISV Operator From OperatorHub Via CLI    operator_name=${CERT_MANAGER_OP_NAME}
             ...    namespace=${CERT_MANAGER_NS}
             ...    subscription_name=${CERT_MANAGER_SUB_NAME}
             ...    catalog_source_name=redhat-operators
             ...    operator_group_name=cert-manager-operator
             ...    operator_group_ns=${CERT_MANAGER_NS}
             ...    operator_group_target_ns=${NONE}
             ...    channel=${CERT_MANAGER_CHANNEL_NAME}
        Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subcription_name=${CERT_MANAGER_SUB_NAME}
             ...    namespace=${CERT_MANAGER_NS}
             ...    retry=150
        Wait For Pods To Be Ready    label_selector=name=cert-manager-operator
             ...    namespace=${CERT_MANAGER_NS}
    END

Install Kueue Operator Via Cli
    [Documentation]    Install Kueue Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${KUEUE_OP_NAME}
    ${ocp_version}=     Get Ocp Cluster Version
    ${install_kueue_by_ocp_version}=    GTE    ${ocp_version}    4.18.0
    # Kueue operator will be available just in OCP 4.18 and next versions
    IF    ${is_installed}
        Log To Console    message=Kueue Operator is already installed
    ELSE IF   not ${install_kueue_by_ocp_version}
        Log To Console    message=Kueue Operator is not available in OCP ${ocp_version}
    ELSE
        ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${KUEUE_NS}
        Install ISV Operator From OperatorHub Via CLI    operator_name=${KUEUE_OP_NAME}
             ...    namespace=${KUEUE_NS}
             ...    subscription_name=${KUEUE_SUB_NAME}
             ...    catalog_source_name=redhat-operators
             ...    operator_group_name=kueue-operators
             ...    operator_group_ns=${KUEUE_NS}
             ...    operator_group_target_ns=${NONE}
             ...    channel=${KUEUE_CHANNEL_NAME}
        Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subcription_name=${KUEUE_SUB_NAME}
             ...    namespace=${KUEUE_NS}
             ...    retry=150
        Wait For Pods To Be Ready    label_selector=name=openshift-kueue-operator
             ...    namespace=${KUEUE_NS}
    END

Install Kueue Dependencies
    [Documentation]    Install Dependent Operators For Kueue
    Set Suite Variable   ${FILES_RESOURCES_DIRPATH}    tests/Resources/Files
    Set Suite Variable   ${SUBSCRIPTION_YAML_TEMPLATE_FILEPATH}    ${FILES_RESOURCES_DIRPATH}/isv-operator-subscription.yaml
    Set Suite Variable   ${OPERATORGROUP_YAML_TEMPLATE_FILEPATH}    ${FILES_RESOURCES_DIRPATH}/isv-operator-group.yaml
    Install Cert Manager Operator Via Cli
    Install Kueue Operator Via Cli

Install Cluster Observability Operator Via Cli
    [Documentation]    Install Cluster Observability Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${CLUSTER_OBS_OP_NAME}
    IF    not ${is_installed}
          ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${CLUSTER_OBS_NS}
          Install ISV Operator From OperatorHub Via CLI    operator_name=${CLUSTER_OBS_OP_NAME}
             ...    subscription_name=${CLUSTER_OBS_SUB_NAME}
             ...    namespace=${CLUSTER_OBS_NS}
             ...    catalog_source_name=redhat-operators
             ...    operator_group_name=openshift-cluster-observability-operator
             ...    operator_group_ns=${CLUSTER_OBS_NS}
             ...    operator_group_target_ns=${NONE}
          Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subcription_name=${CLUSTER_OBS_SUB_NAME}
             ...    namespace=${CLUSTER_OBS_NS}
             ...    retry=150
          Wait For Pods To Be Ready    label_selector=app.kubernetes.io/part-of=observability-operator
             ...    namespace=${CLUSTER_OBS_NS}
    ELSE
          Log To Console    message=Cluster Observability Operator is already installed
    END

Install Tempo Operator Via Cli
    [Documentation]    Install Tempo Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${TEMPO_OP_NAME}
    IF    not ${is_installed}
          ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${TEMPO_NS}
          Install ISV Operator From OperatorHub Via CLI    operator_name=${TEMPO_OP_NAME}
             ...    subscription_name=${TEMPO_SUB_NAME}
             ...    namespace=${TEMPO_NS}
             ...    catalog_source_name=redhat-operators
             ...    operator_group_name=openshift-tempo-operator
             ...    operator_group_ns=${TEMPO_NS}
             ...    operator_group_target_ns=${NONE}
          Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subcription_name=${TEMPO_SUB_NAME}
             ...    namespace=${TEMPO_NS}
             ...    retry=150
          Wait For Pods To Be Ready    label_selector=app.kubernetes.io/part-of=tempo-operator
             ...    namespace=${TEMPO_NS}
    ELSE
          Log To Console    message=Tempo Operator is already installed
    END

Install OpenTelemetry Operator Via Cli
    [Documentation]    Install OpenTelemetry Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${TELEMETRY_OP_NAME}
    IF    not ${is_installed}
          ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${TELEMETRY_NS}
          Install ISV Operator From OperatorHub Via CLI    operator_name=${TELEMETRY_OP_NAME}
             ...    subscription_name=${TELEMETRY_SUB_NAME}
             ...    namespace=${TELEMETRY_NS}
             ...    catalog_source_name=redhat-operators
             ...    operator_group_name=openshift-opentelemetry-operator
             ...    operator_group_ns=${TELEMETRY_NS}
             ...    operator_group_target_ns=${NONE}
          Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subcription_name=${TELEMETRY_SUB_NAME}
             ...    namespace=${TELEMETRY_NS}
             ...    retry=150
          Wait For Pods To Be Ready    label_selector=app.kubernetes.io/name=opentelemetry-operator
             ...    namespace=${TELEMETRY_NS}
    ELSE
          Log To Console    message=OpenTelemetry Operator is already installed
    END

Install Custom Metrics Autoscaler Operator Via Cli
    [Documentation]    Install Custom Metrics Autoscaler Operator (KEDA) Via CLI
    ${is_installed} =    Check If Operator Is Installed Via CLI    ${CMA_OP_NAME}
    IF    not ${is_installed}
        ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${CMA_NS}
        Install ISV Operator From OperatorHub Via CLI    operator_name=${CMA_OP_NAME}
            ...    namespace=${CMA_NS}
            ...    subscription_name=${CMA_SUB_NAME}
            ...    catalog_source_name=redhat-operators
            ...    operator_group_name=openshift-keda-operator
            ...    operator_group_ns=${CMA_NS}
            ...    operator_group_target_ns=${NONE}
            ...    channel=${CMA_CHANNEL_NAME}
        Wait Until Operator Subscription Last Condition Is
            ...    type=CatalogSourcesUnhealthy    status=False
            ...    reason=AllCatalogSourcesHealthy    subcription_name=${CMA_SUB_NAME}
            ...    namespace=${CMA_NS}
            ...    retry=150
        Wait For Pods To Be Ready    label_selector=name=custom-metrics-autoscaler-operator
            ...    namespace=${CMA_NS}
    ELSE
        Log To Console    message=Custom Metrics Autoscaler Operator (KEDA) is already installed
    END

Install Observability Dependencies
    [Documentation]    Install dependent operators related to Observability
    Set Suite Variable   ${FILES_RESOURCES_DIRPATH}    tests/Resources/Files
    Set Suite Variable   ${SUBSCRIPTION_YAML_TEMPLATE_FILEPATH}    ${FILES_RESOURCES_DIRPATH}/isv-operator-subscription.yaml
    Set Suite Variable   ${OPERATORGROUP_YAML_TEMPLATE_FILEPATH}    ${FILES_RESOURCES_DIRPATH}/isv-operator-group.yaml
    Install Cluster Observability Operator Via Cli
    Install Tempo Operator Via Cli
    Install OpenTelemetry Operator Via Cli
    Install Custom Metrics AutoScaler Operator Via Cli

Create Namespace With Label
    [Documentation]    Creates a namespace and adds a specific label to it
    [Arguments]    ${namespace}   ${label}
    ${rc}=    Run And Return Rc    oc get namespace ${namespace}
    IF  ${rc} != ${0}
         ${create_ns_rc} =    Run And Return Rc    oc create namespace ${namespace}
         IF   ${create_ns_rc} == 0
                Log To Console    Namespace ${namespace} created successfully
         ELSE
                FAIL     Can not create namespace ${namespace}
         END
    END
    ${add_label_rc} =    Run And Return Rc     oc label namespace ${namespace} ${label}
    IF   ${add_label_rc} == 0
            Log To Console    Label ${label} added to namespace ${namespace} successfully
    ELSE
            FAIL     Can not add label ${label} to namespace ${namespace}
    END

Configure Custom Operator Namespace
    [Documentation]    Configures a custom namespace to be able to be used as the ODH/RHOAI operator namespace.
    ...                If this namespace does not exist, its created.
    [Arguments]    ${namespace}
    Create Namespace With Label    ${namespace}    opendatahub.io/custom-namespace=true

Configure Custom Applications Namespace
    [Documentation]    Configures a custom namespace to be able to be used as the ODH/RHOAI applications namespace.
    ...                If this namespace does not exist, its created.
    [Arguments]    ${namespace}
    Create Namespace With Label    ${namespace}    opendatahub.io/application-namespace=true

Configure Custom Workbenches Namespace
    [Documentation]    Configures a custom namespace to be able to be used as the ODH/RHOAI workbenches namespace.
    ...                If this namespace does not exist, its created.
    [Arguments]    ${namespace}
    Create Namespace With Label    ${namespace}    opendatahub.io/workbenches-namespace=true

Configure Custom Namespaces
    [Documentation]    Configures both operator, application and workbenches namespaces when they are setted as custom ones
    IF   "${OPERATOR_NAMESPACE}" != "${DEFAULT_OPERATOR_NAMESPACE_RHOAI}" and "${OPERATOR_NAMESPACE}" != "${DEFAULT_OPERATOR_NAMESPACE_ODH}"
       # If the operator namespace is not the default one, we need to check if exists
       # and create if not prior to installing ODH/RHOAI. Adding a custom label for automation purposes.
       Configure Custom Operator Namespace    ${OPERATOR_NAMESPACE}
    END
    IF   "${APPLICATIONS_NAMESPACE}" != "${DEFAULT_APPLICATIONS_NAMESPACE_RHOAI}" and "${APPLICATIONS_NAMESPACE}" != "${DEFAULT_APPLICATIONS_NAMESPACE_ODH}"
       # If the applications namespace is not the default one, we need to apply some steps prior to installing ODH/RHOAI
       Configure Custom Applications Namespace    ${APPLICATIONS_NAMESPACE}
    END
    IF  "${NOTEBOOKS_NAMESPACE}" != "${DEFAULT_WORKBENCHES_NAMESPACE_RHOAI}" and "${NOTEBOOKS_NAMESPACE}" != "${DEFAULT_WORKBENCHES_NAMESPACE_ODH}"
       # If the workbenches namespace is not the default one, we need to create prior to installing ODH/RHOAI
       Configure Custom Workbenches Namespace    ${NOTEBOOKS_NAMESPACE}
    END

Create DSCI With Custom Namespaces
    [Documentation]    Recreates a DSCI pointing to a custom applications namespace
    # If the applications namespace is not the default one, we need to add a new workflow where we need to wait the
    # DSCI to be deleted and recreate it using the proper applications namespace.
    # This is needed because by default, the DSCI is automatically created pointing to the default apps namespace.
    Wait Until Keyword Succeeds    2 min    0 sec
    ...        Run And Return Rc      oc get DSCInitialization default-dsci
    ${delete_dsci_rc}    ${delete_dsci_out}    Run And Return Rc And Output    oc delete DSCInitialization --all --ignore-not-found
    IF   ${delete_dsci_rc} == 0
         Log To Console    DSCInitialization CRs successfully deleted
    ELSE
         FAIL     Cannot delete DSCInitialization CRs: ${delete_dsci_out}
    END
    ${delete_auth_rc} =    Run And Return Rc    oc delete Auth --all --ignore-not-found
    IF   ${delete_auth_rc} == 0
         Log To Console    Auth CRs successfully deleted
    ELSE
         FAIL     Cannot delete Auth CRs
    END
    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Is Resource Present    DSCInitialization    ${DSCI_NAME}
    ...    ${OPERATOR_NAMESPACE}      ${IS_NOT_PRESENT}
    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Is Resource Present    Auth    auth
    ...    ${OPERATOR_NAMESPACE}      ${IS_NOT_PRESENT}
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Wait For DSCInitialization CustomResource To Be Ready

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

Install NFS Operator Via Cli
    [Documentation]    Install NFS Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${NFS_OP_NAME}
    IF    not ${is_installed}
          Install ISV Operator From OperatorHub Via CLI    operator_name=${NFS_OP_NAME}
             ...    subscription_name=${NFS_SUB_NAME}
             ...    catalog_source_name=${COMMUNITY_OPERATORS_CS}
             ...    channel=${NFS_CHANNEL_NAME}
             ...    namespace=${NFS_OP_NS}
          Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subcription_name=${NFS_SUB_NAME}
             ...    retry=150
             ...    namespace=${NFS_OP_NS}
    ELSE
          Log To Console    message=NFS Operator is already installed
    END

Deploy NFS Provisioner
    [Documentation]    Deploy a NFS instance, shared
    [Arguments]    ${storage_size}    ${nfs_provisioner_name}
    ${default_sc} =    Get Default Storage Class Name
    Set Test Variable    ${storage_class}    ${default_sc}
    Set Test Variable    ${storage_size}
    Set Test Variable    ${nfs_provisioner_name}
    Create File From Template    ${RESOURCES_DIRPATH}/nfsprovisioner_template.yaml    ${RESOURCES_DIRPATH}/nfsprovisioner_cr.yaml
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    oc apply -f ${RESOURCES_DIRPATH}/nfsprovisioner_cr.yaml
    Should Be Equal As Integers    ${rc}    0
    Log    ${output}    console=yes
    Wait For Pods To Be Ready    label_selector=nfsprovisioner_cr=${nfs_provisioner_name}
    ...    namespace=${NFS_OP_NS}
