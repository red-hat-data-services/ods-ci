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
@{COMPONENT_LIST} =    dashboard
...    aipipelines
...    kserve
...    kueue
...    ray
...    trainingoperator
...    trainer
...    trustyai
...    workbenches
...    modelregistry
...    feastoperator
...    llamastackoperator
...    mlflowoperator
...    modelsasservice
${LWS_OP_NAME}=    leader-worker-set
${LWS_OP_NS}=    openshift-lws-operator
${LWS_SUB_NAME}=    leader-worker-set
${LWS_CHANNEL_NAME}=  stable-v1.0
${OPENSHIFT_OPERATORS_NS}=    openshift-operators
${COMMUNITY_OPERATORS_NS}=    openshift-marketplace
${COMMUNITY_OPERATORS_CS}=    community-operators
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
${KUEUE_CHANNEL_NAME}=  stable-v1.2
${KUEUE_NS}=  openshift-kueue-operator
${JOBSET_OP_NAME}=  job-set
${JOBSET_SUB_NAME}=  job-set
${JOBSET_CHANNEL_NAME}=  stable-v1.0
${JOBSET_NS}=  openshift-jobset-operator
${JOBSETOPERATOR_NAME}=  cluster
${CERT_MANAGER_OP_NAME}=  openshift-cert-manager-operator
${CERT_MANAGER_SUB_NAME}=  openshift-cert-manager-operator
${CERT_MANAGER_CHANNEL_NAME}=  stable-v1
${CERT_MANAGER_NS}=  cert-manager-operator
${CONNECTIVITY_LINK_OP_NAME}=  rhcl-operator
${CONNECTIVITY_LINK_SUB_NAME}=  rhcl-operator
${CONNECTIVITY_LINK_CHANNEL_NAME}=  stable
${CONNECTIVITY_LINK_NS}=  kuadrant-system
${AUTHORINO_CSV_NAME}=  Authorino Operator
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
${DSCI_TEMPLATE}=    dsci_template.yml
${CONFIG_ENV}=    ${EMPTY}
${NFS_OP_NAME}=    nfs-provisioner-operator
${NFS_OP_NS}=    openshift-operators
${NFS_SUB_NAME}=    nfs-provisioner-operator-sub
${NFS_CHANNEL_NAME}=    alpha
${RESOURCES_DIRPATH}=    tasks/Resources/Files
${RHODS_OSD_INSTALL_REPO}=      ${EMPTY}
${OLM_DIR}=                     rhodsolm
@{SUPPORTED_TEST_ENV}=          AWS   AWS_DIS   GCP   GCP_DIS   PSI   PSI_DIS   ROSA   IBM_CLOUD   CRC    AZURE	ROSA_HCP
${install_plan_approval}=       Manual
${GITOPS_DEFAULT_REPO_BRANCH}=    main
${GITOPS_DEFAULT_REPO}=    ${EMPTY}
${HELM_CUSTOM_VALUES_FILE}=    ${EMPTY}
@{HELM_SET_VALUES}=    @{EMPTY}
${COMPONENT_NAMES}=    ${EMPTY}

*** Keywords ***
Install RHODS
  [Arguments]  ${cluster_type}     ${image_url}     ${install_plan_approval}
  ...    ${rhoai_version}=${EMPTY}    ${is_upgrade}=False
  Log    Start installing RHOAI with:\n\- cluster type: ${cluster_type}\n\- image_url: ${image_url}\n\- update_channel: ${UPDATE_CHANNEL}    console=yes    #robocop:disable
  Log    \- rhoai_version: ${rhoai_version}\n\- is_upgrade: ${is_upgrade}\n\- install_plan_approval: ${install_plan_approval}\n\- CATALOG_SOURCE: ${CATALOG_SOURCE}   console=yes    #robocop:disable
  Assign Vars According To Product
  ${enable_new_observability_stack} =    Is New Observability Stack Enabled
  IF  "${INSTALL_TYPE}" == "Helm"
    Parse Component Names For Helm Install
    Log To Console    Helm installation handles dependencies and operator together
  ELSE IF  "${INSTALL_TYPE}" == "Kustomize"
    Log To Console    Kustomize install method, installing dependencies via GitOps repo, operator via CLI
    Install RHOAI Dependencies With GitOps Repo    ${enable_new_observability_stack}
    ...    ${GITOPS_REPO_BRANCH}    ${GITOPS_REPO_URL}
  ELSE
    # Cli or OperatorHub - installs dependencies via CLI
    Install RHOAI Dependencies With CLI
    IF    ${enable_new_observability_stack}
            Install Observability Dependencies
    END
  END
  Clone OLM Install Repo
  Configure Custom Namespaces
  IF   "${PRODUCT}" == "ODH" and "${UPDATE_CHANNEL}" != "odh-stable"
       ${csv_display_name} =    Set Variable    ${ODH_CSV_DISPLAY}
  ELSE
       ${csv_display_name} =    Set Variable    ${RHODS_CSV_DISPLAY}
  END
  IF   "${cluster_type}" == "selfmanaged"
      ${is_cli_install} =    Evaluate    "${INSTALL_TYPE}" in ["Cli", "Kustomize"]
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and ${is_cli_install}
             Install RHODS In Self Managed Cluster Using CLI  ${cluster_type}     ${image_url}
      ELSE IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and "${INSTALL_TYPE}" == "Helm"
             Install RHOAI In Self Managed Cluster Using Helm  ${enable_new_observability_stack}
             ...    ${GITOPS_REPO_BRANCH}    ${GITOPS_REPO_URL}
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
      ${is_cli_install_managed} =    Evaluate    "${INSTALL_TYPE}" in ["Cli", "Kustomize"]
      IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and ${is_cli_install_managed} and "${UPDATE_CHANNEL}" == "odh-nightlies"
          # odh-nightly is not build for Managed, it is only possible for Self-Managed
          Set Global Variable    ${OPERATOR_NAMESPACE}    openshift-marketplace
          Install RHODS In Self Managed Cluster Using CLI  ${cluster_type}     ${image_url}
          Set Global Variable    ${OPERATOR_NAME}         opendatahub-operator
      ELSE IF  "${TEST_ENV}" in "${SUPPORTED_TEST_ENV}" and ${is_cli_install_managed}
          Install RHODS In Managed Cluster Using CLI  ${cluster_type}     ${image_url}
      ELSE
          FAIL    Provided test environment is not supported
      END
  END
  Wait Until Csv Is Ready    display_name=${csv_display_name}    operators_namespace=${OPERATOR_NAMESPACE}
  # Approve any pending installplans for transitive OLM dependencies (e.g. ServiceMesh)
  Approve All Pending Installplans    openshift-operators
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

Parse Component Names For Helm Install
    [Documentation]    Parses COMPONENT_NAMES string (received from Jenkins job) for Helm install method.
    ...                Converts COMPONENT_NAMES to HELM_SET_VALUES list for Helm.
    ...                Format: "componentName:managementState,componentName:managementState"
    ...                Example: "dashboard:Managed,workbenches:Removed,feastoperator:Managed"
    IF    "${COMPONENT_NAMES}" == "${EMPTY}"
        Log To Console    COMPONENT_NAMES not set, will use defaults from Helm chart values
        RETURN
    END
    Log To Console    Parsing COMPONENT_NAMES: ${COMPONENT_NAMES}

    ${helm_values} =    Create List

    # Get individual componentName:managementState pairs
    @{pairs} =    Split String    ${COMPONENT_NAMES}    separator=,
    FOR    ${pair}    IN    @{pairs}
        ${pair} =    Strip String    ${pair}
        IF    "${pair}" == "${EMPTY}"    CONTINUE

        # Get component name and its managementState
        @{parts} =    Split String    ${pair}    separator=:    max_split=1
        ${len} =    Get Length    ${parts}
        IF    ${len} != 2
            Log To Console    WARNING: Invalid format '${pair}', expected 'component:state', skipping
            CONTINUE
        END
        ${component} =    Strip String    ${parts}[0]
        ${state} =    Strip String    ${parts}[1]

        @{valid_states} =    Create List    Managed    Removed    Unmanaged
        ${is_valid} =    Evaluate    "${state}" in ${valid_states}
        IF    not ${is_valid}
            Log To Console    WARNING: Invalid state '${state}' for component '${component}', skipping
            CONTINUE
        END

        # For Helm install method, convert each parsed key-value pair to the expected Helm chart path
        # and collect them into a list
        ${helm_path} =    Get Helm Path For Component    ${component}
        IF    "${helm_path}" != "${EMPTY}"
            Append To List    ${helm_values}    ${helm_path}=${state}
        END

        Log To Console    Parsed component: ${component} -> ${state}
    END

    Set Global Variable    @{HELM_SET_VALUES}    @{helm_values}
    Log To Console    HELM_SET_VALUES list: @{HELM_SET_VALUES}

Get Helm Path For Component
    [Documentation]    Maps component name to Helm chart path for managementState.
    ...                Returns empty string for unknown components.
    [Arguments]    ${component}

    # Handling of special component cases:
    # 1. modelsasservice is nested under kserve
    IF    "${component}" == "modelsasservice"
        RETURN    components.kserve.dsc.modelsAsService.managementState
    END

    # Handling of standard component cases:
    ${is_known} =    Evaluate    "${component}" in ${COMPONENT_LIST}
    IF    ${is_known}
        RETURN    components.${component}.dsc.managementState
    END

    Log To Console    WARNING: Unknown component '${component}', no Helm path mapping available
    RETURN    ${EMPTY}

Verify RHODS Installation

  IF    "${UPDATE_CHANNEL}" == "odh-stable"
      Set Global Variable    ${DASHBOARD_APP_NAME}    rhods-dashboard
  ELSE
      Set Global Variable    ${DASHBOARD_APP_NAME}    ${PRODUCT.lower()}-dashboard
  END

  Log    Verifying RHODS installation    console=yes
  Log    Waiting for all RHODS resources to be up and running    console=yes
  Wait For Deployment Replica To Be Ready    namespace=${OPERATOR_NAMESPACE}
  ...    label_selector=name=${OPERATOR_NAME_LABEL}    timeout=2000s
  Wait For Pods Status  namespace=${OPERATOR_NAMESPACE}  timeout=1200
  Log  Verified ${OPERATOR_NAMESPACE}  console=yes

  IF   "${cluster_type}" == "managed"
       IF   "${PRODUCT}" == "ODH" and "${UPDATE_CHANNEL}" != "odh-stable"
            Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
            Wait For DSCInitialization CustomResource To Be Ready
            Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
       ELSE
            # If managed and RHOAI, we need to wait for the operator to create the DSCI and then patch it with
            # the monitoring info in case the new obs stack flag is enabled
            Wait Until Keyword Succeeds    6 min    0 sec
            ...    Is Resource Present    DSCInitialization    ${DSCI_NAME}
            ...    ${OPERATOR_NAMESPACE}      ${IS_PRESENT}
            Wait Until Keyword Succeeds    6 min    0 sec
            ...    Is Resource Present    Auth    auth
            ...    ${OPERATOR_NAMESPACE}      ${IS_PRESENT}
            Wait Until Keyword Succeeds    6 min    0 sec
            ...    Is Resource Present    GatewayConfig    default-gateway
            ...    ${OPERATOR_NAMESPACE}      ${IS_PRESENT}
            Wait Until Keyword Succeeds    6 min    0 sec
            ...    Is Resource Present    HardwareProfile    default-profile
            ...    ${APPLICATIONS_NAMESPACE}      ${IS_PRESENT}
            ${enable_new_observability_stack} =    Is New Observability Stack Enabled
            IF    ${enable_new_observability_stack}
                    Patch DSCInitialization With Monitoring Info
            END
            Wait Until Keyword Succeeds    3 min    0 sec
            ...    Is Resource Present    DataScienceCluster    ${DSC_NAME}
            ...    ${OPERATOR_NAMESPACE}      ${IS_PRESENT}

       END
  ELSE
      IF  "${APPLICATIONS_NAMESPACE}" != "${DEFAULT_APPLICATIONS_NAMESPACE_RHOAI}" and "${APPLICATIONS_NAMESPACE}" != "${DEFAULT_APPLICATIONS_NAMESPACE_ODH}"
          Create DSCI With Custom Namespaces
      ELSE IF   "${UPDATE_CHANNEL}" != "odh-nightlies" and "${UPDATE_CHANNEL}" != "odh-stable" and "${PRODUCT}" == "ODH"
            # this case is to handle ODH community, which needs to create the DSCI
            Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
            Wait For DSCInitialization CustomResource To Be Ready
      END
      Wait Until Keyword Succeeds    6 min    0 sec
      ...    Is Resource Present    DSCInitialization    ${DSCI_NAME}
      ...    ${OPERATOR_NAMESPACE}      ${IS_PRESENT}
      Wait Until Keyword Succeeds    6 min    0 sec
      ...    Is Resource Present    Auth    auth
      ...    ${OPERATOR_NAMESPACE}      ${IS_PRESENT}
      Wait Until Keyword Succeeds    6 min    0 sec
      ...    Is Resource Present    GatewayConfig    default-gateway
      ...    ${OPERATOR_NAMESPACE}      ${IS_PRESENT}
      Wait Until Keyword Succeeds    6 min    0 sec
      ...    Is Resource Present    HardwareProfile    default-profile
      ...    ${APPLICATIONS_NAMESPACE}      ${IS_PRESENT}
      ${enable_new_observability_stack} =    Is New Observability Stack Enabled
      IF    ${enable_new_observability_stack}
              Patch DSCInitialization With Monitoring Info
      END
      Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
  END

  IF  "${CLUSTER_AUTH}" == "oidc"
      Patch GatewayConfig With OIDC Info
  END

  ${workbenches} =    Is Component Enabled    workbenches    ${DSC_NAME}
  IF    "${workbenches}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=notebook-controller
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=odh-notebook-controller
    Oc Get  kind=Namespace  field_selector=metadata.name=${NOTEBOOKS_NAMESPACE}
    Log  Verified Notebooks NS: ${NOTEBOOKS_NAMESPACE}
  END

  ${aipipelines} =    Is Component Enabled    aipipelines    ${DSC_NAME}
  IF    "${aipipelines}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/name=data-science-pipelines-operator
  END

  ${kserve} =    Is Component Enabled    kserve    ${DSC_NAME}
  IF    "${kserve}" == "true"
    Configure Gateway API
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=odh-model-controller    timeout=400s
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=control-plane=kserve-controller-manager
  END

  ${kueue} =     Is Component Enabled     kueue    ${DSC_NAME}
  IF    "${kueue}" == "true"
    ${kueue_state}=    Get DSC Component State    ${DSC_NAME}    kueue    ${OPERATOR_NAMESPACE}
    IF    "${kueue_state}" == "Managed"
        Fail    msg=Kueue Managed mode is not supported on ODH/RHOAI 3.0+
    END
    Wait For Deployment Replica To Be Ready    namespace=${KUEUE_NS}
    ...    label_selector=app.kubernetes.io/name=kueue
  END

  ${ray} =     Is Component Enabled     ray    ${DSC_NAME}
  IF    "${ray}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=ray
  END

  ${trustyai} =    Is Component Enabled    trustyai    ${DSC_NAME}
  IF    "${trustyai}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=trustyai
  END

  ${modelregistry} =    Is Component Enabled    modelregistry    ${DSC_NAME}
  IF    "${modelregistry}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=model-registry-operator    timeout=400s
  END

  ${trainingoperator} =    Is Component Enabled    trainingoperator    ${DSC_NAME}
  IF    "${trainingoperator}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=trainingoperator
  END

  ${trainer} =     Is Component Enabled    trainer    ${DSC_NAME}
  IF     "${trainer}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/name=trainer
  END

  ${feastoperator} =    Is Component Enabled    feastoperator    ${DSC_NAME}
  IF    "${feastoperator}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=feastoperator
  END

  ${llamastackoperator} =    Is Component Enabled    llamastackoperator    ${DSC_NAME}
  IF    "${llamastackoperator}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=llamastackoperator
  END

  ${mlflowoperator} =    Is Component Enabled    mlflowoperator    ${DSC_NAME}
  IF    "${mlflowoperator}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=mlflowoperator
  END

  ${modelsasservice} =    Is Nested Component Enabled    kserve    modelsAsService    ${DSC_NAME}
  IF    "${modelsasservice}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app.kubernetes.io/part-of=models-as-a-service
  END

  ${dashboard} =    Is Component Enabled    dashboard    ${DSC_NAME}
  IF    "${dashboard}" == "true"
    Wait For Deployment Replica To Be Ready    namespace=${APPLICATIONS_NAMESPACE}
    ...    label_selector=app=${DASHBOARD_APP_NAME}
    IF  "${PRODUCT}" == "ODH"
        #This line of code is strictly used for the exploratory cluster to accommodate UI/UX team requests
        Add UI Admin Group To Dashboard Admin
    END
  END

  IF    "${dashboard}" == "true" or "${workbenches}" == "true" or "${aipipelines}" == "true" or "${kserve}" == "true" or "${kueue}" == "true" or "${ray}" == "true" or "${trustyai}" == "true" or "${modelregistry}" == "true" or "${trainingoperator}" == "true"    # robocop: disable
      Log To Console    Waiting for pod status in ${APPLICATIONS_NAMESPACE}
      Wait For Pods Status  namespace=${APPLICATIONS_NAMESPACE}  timeout=600
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

Install RHOAI In Self Managed Cluster Using Helm
  [Documentation]   Install ODH/RHOAI using Helm on a self-managed cluster, including its dependencies
  ...
  ...   Optional variables that can be set to customize Helm installation:
  ...   - ${HELM_CUSTOM_VALUES_FILE}: Path to additional Helm values file to override the default chart
  ...   - @{HELM_SET_VALUES}: List of key=value pairs for Helm --set flags, applied after the custom values file if used
  ...   - ${GITOPS_REPO_BRANCH}: GitOps repository branch (uses ${GITOPS_DEFAULT_REPO_BRANCH} if not set)
  ...   - ${GITOPS_REPO_URL}: Custom GitOps repository URL (uses ${GITOPS_DEFAULT_REPO} if not set)
  [Arguments]     ${enable_monitoring}=${TRUE}
  ...    ${gitops_branch}=${GITOPS_DEFAULT_REPO_BRANCH}
  ...    ${gitops_repo}=${GITOPS_DEFAULT_REPO}
  Log To Console    Installing ${PRODUCT} using Helm method
  ${operator_type} =    Set Variable If    "${PRODUCT}" == "ODH"    odh    rhoai
  Log To Console    Operator type for Helm: ${operator_type}

  ${monitoring_flag} =    Set Variable If    not ${enable_monitoring}    -M    ${EMPTY}
  ${branch_flag} =    Set Variable If    "${gitops_branch}" != "${EMPTY}"    -b ${gitops_branch}    ${EMPTY}
  ${repo_flag} =    Set Variable If    "${gitops_repo}" != "${EMPTY}"    -r ${gitops_repo}    ${EMPTY}
  ${values_file_flag} =    Set Variable If    "${HELM_CUSTOM_VALUES_FILE}" != "${EMPTY}"    -f ${HELM_CUSTOM_VALUES_FILE}    ${EMPTY}

  ${set_values_flags} =    Set Variable    ${EMPTY}
  FOR    ${set_value}    IN    @{HELM_SET_VALUES}
      ${set_values_flags} =    Set Variable    ${set_values_flags} -s ${set_value}
  END

  # this ensures that the following namespaces/subscription name will match
  ${required_helm_operator_flags} =    Catenate
  ...    -s operator.${operator_type}.applicationsNamespace=${APPLICATIONS_NAMESPACE}
  ...    -s operator.${operator_type}.monitoringNamespace=${MONITORING_NAMESPACE}
  ...    -s operator.${operator_type}.olm.namespace=${OPERATOR_NAMESPACE}
  ...    -s operator.${operator_type}.olm.name=${OPERATOR_NAME}

  # Log configuration
  IF    not ${enable_monitoring}
      ${monitoring_dependencies_state} =    Set Variable    Skipped
  ELSE
      ${monitoring_dependencies_state} =    Set Variable    Enabled
  END
  Log To Console    Monitoring dependencies: ${monitoring_dependencies_state}

  IF    "${gitops_branch}" != "${EMPTY}"
      Log To Console    Using GitOps repo branch: ${gitops_branch}
  END
  IF    "${gitops_repo}" != "${EMPTY}"
      Log To Console    Using custom GitOps repo: ${gitops_repo}
  END
  IF    "${HELM_CUSTOM_VALUES_FILE}" != "${EMPTY}"
      Log To Console    Using custom values file: ${HELM_CUSTOM_VALUES_FILE}
  END
  IF    @{HELM_SET_VALUES}
      Log To Console    Custom Helm values: @{HELM_SET_VALUES}
  END
  Log To Console    Enforcing Helm operator values: applicationsNamespace=${APPLICATIONS_NAMESPACE}, monitoringNamespace=${MONITORING_NAMESPACE}, operatorNamespace=${OPERATOR_NAMESPACE}, operatorSubscriptionName=${OPERATOR_NAME}

  ${return_code} =    Run And Watch Command
  ...    cd ${EXECDIR}/${OLM_DIR} && ./setup-helm.sh -o ${operator_type} ${monitoring_flag} ${repo_flag} ${branch_flag} ${values_file_flag} ${set_values_flags} ${required_helm_operator_flags}
  ...    timeout=20 min
  Should Be Equal As Integers   ${return_code}   0   msg=Error detected while installing ${PRODUCT} with Helm

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
    ${enable_new_observability_stack} =    Is New Observability Stack Enabled
    ${return_code}    ${output} =    Run And Return Rc And Output    oc get DSCInitialization --output json | jq -j '.items | length'
    Log To Console    output : ${output}, return_code : ${return_code}
    IF  ${output} != 0
        Log to Console    Skip creation of DSCInitialization because its already created by the operator
        IF    ${enable_new_observability_stack}
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
    IF    ${enable_new_observability_stack}
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

Patch GatewayConfig With OIDC Info
    [Documentation]  Patches the GatewayConfig with values necessary for external OIDC
    Log  Patching gatewayconfig for OIDC  console=yes
    ${file_path} =    Set Variable    tasks/Resources/Files/
    ${gw_config_file} =  Set Variable  ${file_path}/gatewayconfig-patch-payload-apply.json
    Copy File    source=${file_path}gatewayconfig-patch-payload.json    destination=${gw_config_file}
    Run    sed -i'' -e 's|<issuerURL>|${CLUSTER_OIDC_ISSUER}|' ${gw_config_file}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...         oc patch gatewayconfig/default-gateway --patch-file="${gw_config_file}" --type merge    #robocop:disable
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

Is Nested Component Enabled
    [Documentation]    Returns the enabled status of a nested component (true/false)
    [Arguments]    ${parent_component}    ${nested_component}    ${dsc_name}=${DSC_NAME}
    ${return_code}    ${output} =    Run And Return Rc And Output    oc get datasciencecluster ${dsc_name} -o json | jq '.spec.components.${parent_component}.${nested_component}.managementState // "Removed"'  #robocop:disable
    Log    ${output}
    Should Be Equal As Integers  ${return_code}  0  msg=Error detected while getting nested component status
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
             ...    operator_group_name=${CERT_MANAGER_OP_NAME}
             ...    operator_group_ns=${CERT_MANAGER_NS}
             ...    operator_group_target_ns=${NONE}
             ...    channel=${CERT_MANAGER_CHANNEL_NAME}
        Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subscription_name=${CERT_MANAGER_SUB_NAME}
             ...    namespace=${CERT_MANAGER_NS}
             ...    retry=150
        Wait For Pods To Be Ready    label_selector=name=cert-manager-operator
             ...    namespace=${CERT_MANAGER_NS}
    END

Install Leader Worker Set Operator Via Cli
    [Documentation]    Install Leader Worker Set Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${LWS_OP_NAME}
    IF    ${is_installed}
        Log To Console    message=Leader Worker Set Operator is already installed
    ELSE
        ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${LWS_OP_NS}
        Install ISV Operator From OperatorHub Via CLI    operator_name=${LWS_OP_NAME}
             ...    namespace=${LWS_OP_NS}
             ...    subscription_name=${LWS_SUB_NAME}
             ...    catalog_source_name=redhat-operators
             ...    operator_group_name=${LWS_OP_NAME}
             ...    operator_group_ns=${LWS_OP_NS}
             ...    operator_group_target_ns=${LWS_OP_NS}
             ...    channel=${LWS_CHANNEL_NAME}
        Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subscription_name=${LWS_SUB_NAME}
             ...    namespace=${LWS_OP_NS}
             ...    retry=150
        Wait For Pods To Be Ready    label_selector=name=openshift-lws-operator
             ...    namespace=${LWS_OP_NS}
        Configure Leader Worker Set Operator
    END

Configure Leader Worker Set Operator
    [Documentation]    Configure LeaderWorkerSetOperator custom resource after operator installation
    Log To Console    Configuring LeaderWorkerSetOperator resource
    ${rc}    ${output} =    Run And Return Rc And Output    sh tasks/Resources/RHODS_OLM/install/configure_lws_operator.sh
    Log    ${output}    console=yes
    Run Keyword And Continue On Failure    Should Be Equal As Numbers    ${rc}    ${0}
    IF    ${rc} != ${0}
        Log    Unable to configure LeaderWorkerSetOperator resource.\nCheck the cluster please    console=yes
        ...    level=ERROR
    END

Install Connectivity Link Operator Via Cli
    [Documentation]    Install Red Hat Connectivity Link Operator Via CLI
    ...                Installing in ${CONNECTIVITY_LINK_NS} namespace with operator group
    ...                ensures all resources are created in ${CONNECTIVITY_LINK_NS}.
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${CONNECTIVITY_LINK_OP_NAME}
    IF    ${is_installed}
        Log To Console    message=Red Hat Connectivity Link Operator is already installed
    ELSE
        Configure Gateway API
        ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${CONNECTIVITY_LINK_NS} --dry-run=client -o yaml | oc apply -f -
        Should Be Equal As Integers    ${rc}    ${0}    msg=Failed to create namespace ${CONNECTIVITY_LINK_NS}: ${out}
        Install ISV Operator From OperatorHub Via CLI    operator_name=${CONNECTIVITY_LINK_OP_NAME}
             ...    namespace=${CONNECTIVITY_LINK_NS}
             ...    subscription_name=${CONNECTIVITY_LINK_SUB_NAME}
             ...    catalog_source_name=redhat-operators
             ...    channel=${CONNECTIVITY_LINK_CHANNEL_NAME}
             ...    operator_group_name=${CONNECTIVITY_LINK_OP_NAME}
             ...    operator_group_ns=${CONNECTIVITY_LINK_NS}
             ...    operator_group_target_ns=${NONE}
        Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subscription_name=${CONNECTIVITY_LINK_SUB_NAME}
             ...    namespace=${CONNECTIVITY_LINK_NS}
             ...    retry=150
        # Wait for rhcl-operator to be ready
        Wait Until Csv Is Ready    display_name=${CONNECTIVITY_LINK_OP_NAME}
             ...    operators_namespace=${CONNECTIVITY_LINK_NS}    timeout=5m
        # Wait for authorino-operator to be ready (installed by rhcl-operator as OLM dependency)
        Wait Until Csv Is Ready    display_name=${AUTHORINO_CSV_NAME}
             ...    operators_namespace=${CONNECTIVITY_LINK_NS}    timeout=5m
        ${rc}    ${output} =    Run And Return Rc And Output    sh tasks/Resources/RHODS_OLM/install/configure_connectivity_link_operator.sh
        Log    ${output}    console=yes
        IF    ${rc} != ${0}
            Log    Unable to configure Connectivity Link.\nCheck the cluster please    console=yes
            ...    level=ERROR
            FAIL    Unable to configure Connectivity Link
        END
        Configure Authorino
    END

Configure Authorino
    [Documentation]    Configure Authorino with SSL after Kuadrant is configured.

    Log To Console    Configuring Authorino with SSL
    ${rc}    ${output} =    Run And Return Rc And Output    sh tasks/Resources/RHODS_OLM/install/configure_authorino.sh
    Log    ${output}    console=yes
    Run Keyword And Continue On Failure    Should Be Equal As Numbers    ${rc}    ${0}
    IF    ${rc} != ${0}
        Log    Unable to configure Authorino namespace.\nCheck the cluster please    console=yes
        ...    level=ERROR
        FAIL    Unable to configure Authorino
    END

    Log To Console    Updating Authorino to enable SSL...
    ${rc}    ${output} =    Run And Return Rc And Output    sh tasks/Resources/RHODS_OLM/install/update_authorino_ssl.sh
    Log    ${output}    console=yes
    Run Keyword And Continue On Failure    Should Be Equal As Numbers    ${rc}    ${0}
    IF    ${rc} != ${0}
        Log    Unable to update Authorino with SSL configuration.\nCheck the cluster please    console=yes
        ...    level=ERROR
        FAIL    Unable to update Authorino with SSL configuration
    END

    Log To Console    Waiting for Authorino deployment rollout to complete...
    ${rc}    ${out} =    Run And Return Rc And Output
    ...    oc rollout status deployment/authorino -n ${CONNECTIVITY_LINK_NS} --timeout=120s
    Log    ${out}    console=yes

    Log To Console    Waiting for Authorino to be ready with SSL...
    # workaround for https://github.com/kubernetes/kubectl/issues/1120 (old authorino pod is still terminating when we run oc wait)
    Sleep  15s
    Wait For Pods To Be Ready    label_selector=authorino-resource=authorino
    ...    namespace=${CONNECTIVITY_LINK_NS}    timeout=150s

Install Kueue Operator Via Cli
    [Documentation]    Install Kueue Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${KUEUE_OP_NAME}
    IF    ${is_installed}
        Log To Console    message=Kueue Operator is already installed
    ELSE
        ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${KUEUE_NS}
        Install ISV Operator From OperatorHub Via CLI    operator_name=${KUEUE_OP_NAME}
             ...    namespace=${KUEUE_NS}
             ...    subscription_name=${KUEUE_SUB_NAME}
             ...    catalog_source_name=redhat-operators
             ...    operator_group_name=${KUEUE_OP_NAME}
             ...    operator_group_ns=${KUEUE_NS}
             ...    operator_group_target_ns=${NONE}
             ...    channel=${KUEUE_CHANNEL_NAME}
        Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subscription_name=${KUEUE_SUB_NAME}
             ...    namespace=${KUEUE_NS}
             ...    retry=150
        Wait For Pods To Be Ready    label_selector=name=openshift-kueue-operator
             ...    namespace=${KUEUE_NS}
    END

Create JobSetOperator CR
    [Documentation]      Deploys JobSetOperator cluster CR for trainer component
    ${file_path} =    Set Variable    tasks/Resources/Files/
    Copy File    source=${file_path}jobsetoperator_template.yaml   destination=${file_path}jobsetoperator_apply.yml
    Run    sed -i'' -e 's/<jobsetoperator_name>/${JOBSETOPERATOR_NAME}/' ${file_path}jobsetoperator_apply.yml
    Run    sed -i'' -e 's/<jobsetoperator_namespace>/${JOBSET_NS}/' ${file_path}jobsetoperator_apply.yml
    ${return_code}    ${output} =    Run And Return Rc And Output    oc apply -f ${file_path}jobsetoperator_apply.yml
    Log To Console    ${output}
    Should Be Equal As Integers  ${return_code}  0  msg=Error detected while creating JobSetOperator CR

Install JobSet Operator Via Cli
    [Documentation]    Install JobSet Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${JOBSET_OP_NAME}
    IF    ${is_installed}
        Log To Console    message=JobSet Operator is already installed
    ELSE
        ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${JOBSET_NS}
        Install ISV Operator From OperatorHub Via CLI    operator_name=${JOBSET_OP_NAME}
             ...    namespace=${JOBSET_NS}
             ...    subscription_name=${JOBSET_SUB_NAME}
             ...    catalog_source_name=redhat-operators
             ...    operator_group_name=${JOBSET_OP_NAME}
             ...    operator_group_ns=${JOBSET_NS}
             ...    operator_group_target_ns=${JOBSET_NS}
             ...    channel=${JOBSET_CHANNEL_NAME}
        Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subscription_name=${JOBSET_SUB_NAME}
             ...    namespace=${JOBSET_NS}
             ...    retry=150
        Wait For Pods To Be Ready    label_selector=name=jobset-operator
             ...    namespace=${JOBSET_NS}
    END

Install Kueue Dependencies
    [Documentation]    Install Dependent Operators For Kueue
    Install Cert Manager Operator Via Cli
    Install Kueue Operator Via Cli

Install JobSet Dependencies
    Install JobSet Operator Via Cli
    Create JobSetOperator CR

Install Cluster Observability Operator Via Cli
    [Documentation]    Install Cluster Observability Operator Via CLI
    ${is_installed} =   Check If Operator Is Installed Via CLI   ${CLUSTER_OBS_OP_NAME}
    IF    not ${is_installed}
          ${rc}    ${out} =    Run And Return Rc And Output    oc create namespace ${CLUSTER_OBS_NS}
          Install ISV Operator From OperatorHub Via CLI    operator_name=${CLUSTER_OBS_OP_NAME}
             ...    subscription_name=${CLUSTER_OBS_SUB_NAME}
             ...    namespace=${CLUSTER_OBS_NS}
             ...    catalog_source_name=redhat-operators
             ...    operator_group_name=${CLUSTER_OBS_OP_NAME}
             ...    operator_group_ns=${CLUSTER_OBS_NS}
             ...    operator_group_target_ns=${NONE}
          Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subscription_name=${CLUSTER_OBS_SUB_NAME}
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
             ...    operator_group_name=${TEMPO_OP_NAME}
             ...    operator_group_ns=${TEMPO_NS}
             ...    operator_group_target_ns=${NONE}
          Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subscription_name=${TEMPO_SUB_NAME}
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
             ...    operator_group_name=${TELEMETRY_OP_NAME}
             ...    operator_group_ns=${TELEMETRY_NS}
             ...    operator_group_target_ns=${NONE}
          Wait Until Operator Subscription Last Condition Is
             ...    type=CatalogSourcesUnhealthy    status=False
             ...    reason=AllCatalogSourcesHealthy    subscription_name=${TELEMETRY_SUB_NAME}
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
            ...    operator_group_name=${CMA_OP_NAME}
            ...    operator_group_ns=${CMA_NS}
            ...    operator_group_target_ns=${NONE}
            ...    channel=${CMA_CHANNEL_NAME}
        Wait Until Operator Subscription Last Condition Is
            ...    type=CatalogSourcesUnhealthy    status=False
            ...    reason=AllCatalogSourcesHealthy    subscription_name=${CMA_SUB_NAME}
            ...    namespace=${CMA_NS}
            ...    retry=150
        Wait For Pods To Be Ready    label_selector=name=custom-metrics-autoscaler-operator
            ...    namespace=${CMA_NS}
    ELSE
        Log To Console    message=Custom Metrics Autoscaler Operator (KEDA) is already installed
    END

Install RHOAI Dependencies With GitOps Repo
    [Documentation]    Install dependent operators required for RHOAI installation using GitOps
    [Arguments]     ${enable_new_observability_stack}
    ...    ${gitops_repo_branch}=${GITOPS_DEFAULT_REPO_BRANCH}
    ...    ${gitops_repo}=${GITOPS_DEFAULT_REPO}
    Clone OLM Install Repo
    ${m_flag} =    Set Variable If    not ${enable_new_observability_stack}    -M    ${EMPTY}
    ${r_flag} =    Set Variable If    "${gitops_repo}" != "${EMPTY}"    -r ${gitops_repo}    ${EMPTY}
    ${return_code} =    Run And Watch Command
    ...    cd ${EXECDIR}/${OLM_DIR} && ./setup-dependencies.sh -b ${gitops_repo_branch} ${m_flag} ${r_flag}
    ...    timeout=20 min
    Should Be Equal As Integers   ${return_code}   0   msg=Error detected installing RHOAI dependencies using GitOps

Install RHOAI Dependencies With CLI
    [Documentation]    Install dependent operators required for RHOAI installation using CLI
    Install Kueue Dependencies
    Install Leader Worker Set Operator Via Cli
    Install Connectivity Link Operator Via Cli
    Install JobSet Dependencies
    Configure MaaS Gateway API

Install Observability Dependencies
    [Documentation]    Install dependent operators related to Observability
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

Set Nested Component State
    [Documentation]    Set nested component state in Data Science Cluster (e.g., kserve.modelsAsService)
    [Arguments]    ${parent_component}    ${nested_component}    ${state}
    ${result} =    Run Process    oc get datascienceclusters.datasciencecluster.opendatahub.io -o name
    ...    shell=true    stderr=STDOUT
    IF    $result.stdout == ""
        FAIL    Can not find datasciencecluster
    END
    ${cluster_name} =    Set Variable    ${result.stdout}
    ${result} =    Run Process    oc patch ${cluster_name} --type 'json' -p '[{"op" : "replace" ,"path" : "/spec/components/${parent_component}/${nested_component}/managementState" ,"value" : "${state}"}]'
    ...    shell=true    stderr=STDOUT
    IF    $result.rc != 0
        FAIL    Can not set ${parent_component}.${nested_component} to ${state}: ${result.stdout}
    END
    Log To Console    Nested component ${parent_component}.${nested_component} state was set to ${state}

Get DSC Component State
    [Documentation]    Get component management state
    [Arguments]    ${dsc}    ${component}    ${namespace}

    ${rc}   ${state}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster/${dsc} -n ${namespace} -o 'jsonpath={.spec.components.${component}.managementState}'
    Should Be Equal    "${rc}"    "0"    msg=${state}
    Log To Console    Component ${component} state ${state}

    RETURN    ${state}

Get DSC Nested Component State
    [Documentation]    Get nested component management state (e.g., kserve.modelsAsService)
    [Arguments]    ${dsc}    ${parent_component}    ${nested_component}    ${namespace}

    ${rc}   ${state}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster/${dsc} -n ${namespace} -o 'jsonpath={.spec.components.${parent_component}.${nested_component}.managementState}'
    Should Be Equal    "${rc}"    "0"    msg=${state}
    Log To Console    Nested component ${parent_component}.${nested_component} state ${state}

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
             ...    reason=AllCatalogSourcesHealthy    subscription_name=${NFS_SUB_NAME}
             ...    retry=150
             ...    namespace=${NFS_OP_NS}
          # Wait for CSV to be ready to ensure CRDs are installed
          Wait Until Csv Is Ready    display_name=${NFS_OP_NAME}
             ...    operators_namespace=${NFS_OP_NS}    timeout=5m
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

Configure Gateway API
    [Documentation]    Configure Gateway API for KServe inference traffic routing
    Log To Console    Configuring Gateway API for KServe
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    bash tasks/Resources/Gateway/configure_gateway.sh
    Log To Console    ${output}
    Should Be Equal As Integers    ${rc}    0    msg=Error configuring Gateway for KServe

Configure MaaS Gateway API
    [Documentation]    Configure Gateway API for MaaS traffic routing
    Log To Console    Configuring Gateway API for MaaS
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    bash tasks/Resources/Gateway/configure_maas_gateway.sh
    Log To Console    ${output}
    Should Be Equal As Integers    ${rc}    0    msg=Error configuring Gateway for MaaS
