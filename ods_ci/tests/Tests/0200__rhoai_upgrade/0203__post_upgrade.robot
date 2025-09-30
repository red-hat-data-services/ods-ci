*** Settings ***
Documentation       Test Suite for Upgrade testing,to be run after the upgrade

Library             OpenShiftLibrary
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/OCP.resource
Resource            ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource            ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource            ../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource            ../../Resources/Page/LoginPage.robot
Resource            ../../Resources/Page/OCPLogin/OCPLogin.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/OCPDashboard/Pods/Pods.robot
Resource            ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource            ../../Resources/Page/HybridCloudConsole/OCM.robot
Resource            ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Resource            ../../Resources/Page/DistributedWorkloads/WorkloadMetricsUI.resource
Resource            ../../Resources/CLI/MustGather/MustGather.resource
Resource            ../../Resources/CLI/DataSciencePipelines/DataSciencePipelinesUpgradeTesting.resource
Resource            ../../Resources/Page/ModelRegistry/ModelRegistry.resource
Resource            ../../Resources/Page/FeatureStore/FeatureStore.resource

Suite Setup         Upgrade Suite Setup

Test Tags           PostUpgrade


*** Variables ***
${S_SIZE}                   25
${DW_PROJECT_CREATED}       False
${UPGRADE_NS}    upgrade
${UPGRADE_CONFIG_MAP}    upgrade-config-map
${USERGROUPS_CONFIG_MAP}    usergroups-config-map
${ALLOWED_GROUPS}       system:authenticated


*** Test Cases ***
Verify PVC Size
    [Documentation]    Verify PVC Size after the upgrade
    [Tags]      Upgrade    Dashboard
    Get Dashboard Config Data
    ${size}     Set Variable        ${payload[0]['spec']['notebookController']['pvcSize']}[:-2]
    Should Be Equal As Strings      '${size}'       '${S_SIZE}'

Verify Pod Toleration
    [Documentation]    Verify Pod toleration after the upgrade
    [Tags]      Upgrade    Dashboard
    ${enable}    Set Variable
    ...    ${payload[0]['spec']['notebookController']['notebookTolerationSettings']['enabled']}
    Should Be Equal As Strings      '${enable}'     'True'

Verify RHODS User Groups
    [Documentation]    Verify User Configuration after the upgrade
    [Tags]      Upgrade     Platform        RHOAIENG-19806
    Get Auth Cr Config Data
    ${auth_admins}       Set Variable        ${AUTH_PAYLOAD[0]['spec']['adminGroups']}
    ${auth_allowed}      Set Variable        ${AUTH_PAYLOAD[0]['spec']['allowedGroups']}

    ${rc}    ${adm_groups}=    Run And Return Rc And Output
    ...    oc get configmap ${USERGROUPS_CONFIG_MAP} -n ${UPGRADE_NS} -o jsonpath='{.data.adm_groups}'
    Should Be Equal As Integers     ${rc}      0

    ${rc}    ${allwd_groups}=    Run And Return Rc And Output
    ...    oc get configmap ${USERGROUPS_CONFIG_MAP} -n ${UPGRADE_NS} -o jsonpath='{.data.allwd_groups}'
    Should Be Equal As Integers     ${rc}      0

    Should Be Equal    "${adm_groups}"    "${auth_admins}"   msg="Admin groups are not equal"
    Should Be Equal    "${allwd_groups}"    "${auth_allowed}"   msg="Allowed groups are not equal"

    [Teardown]      Set Default Users

Verify Culler is Enabled
    [Documentation]    Verify Culler Configuration after the upgrade
    [Tags]      Upgrade    Dashboard
    ${status}    Check If ConfigMap Exists
    ...    ${APPLICATIONS_NAMESPACE}
    ...    notebook-controller-culler-config
    IF    '${status}' != 'PASS'
        Fail        msg=Culler has been diabled after the upgrade
    END

Verify Notebook Has Not Restarted
    [Documentation]    Verify Notebook pod has not restarted after the upgrade
    [Tags]      Upgrade    IDE
    ${notebook_name}=    Get User CR Notebook Name    ${TEST_USER2.USERNAME}
    ${notebook_pod_name}=    Get User Notebook Pod Name    ${TEST_USER2.USERNAME}

    # Get the running notebook creation timestamp
    ${return_code}    ${new_timestamp}    Run And Return Rc And Output
    ...    oc get pod -n ${NOTEBOOKS_NAMESPACE} ${notebook_pod_name} --no-headers --output='custom-columns=TIMESTAMP:.metadata.creationTimestamp'    # robocop: disable: line-too-long
    Should Be Equal As Integers    ${return_code}    0    msg=${new_timestamp}

    # Get the running notebook creation timestamp from the upgrade ConfigMap safed in the previous
    # phase (before the actual RHOAI upgrade)
    ${return_code}    ${ntb_creation_timestamp}    Run And Return Rc And Output
    ...    oc get configmap ${UPGRADE_CONFIG_MAP} -n ${UPGRADE_NS} -o jsonpath='{.data.ntb_creation_timestamp}'
    Should Be Equal As Integers    ${return_code}    0    msg=${ntb_creation_timestamp}

    # The timestamps should be equal
    Should Be Equal    ${ntb_creation_timestamp}    ${new_timestamp}    msg=Running notebook pod has restarted

    [Teardown]    Terminate Running Notebook    ${notebook_name}

Verify Custom Image Is Present
    [Documentation]    Verify Custom Noteboook is not deleted after the upgrade
    [Tags]      Upgrade    IDE
    ${status}       Run Keyword And Return Status
    ...    Oc Get
    ...    kind=ImageStream
    ...    namespace=${APPLICATIONS_NAMESPACE}
    ...    field_selector=metadata.name==byon-upgrade
    IF    not ${status}    Fail    Notebook image is deleted after the upgrade
    [Teardown]      Delete OOTB Image

Verify Disable Runtime Is Present
    [Documentation]    Disable the Serving runtime using Cli
    [Tags]      Upgrade    ModelServing
    ${rn}       Set Variable        ${payload[0]['spec']['templateDisablement']}
    List Should Contain Value       ${rn}       ovms-gpu
    [Teardown]      Enable Model Serving Runtime Using CLI      namespace=redhat-ods-applications

Reset PVC Size Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]      Upgrade    Dashboard
    [Setup]     Begin Web Test
    Set PVC Value In RHODS Dashboard        20
    [Teardown]      Dashboard Test Teardown

Reset Culler Timeout
    [Documentation]    Sets a culler timeout via the admin UI
    [Tags]      Upgrade    Dashboard
    [Setup]     Begin Web Test
    Disable Notebook Culler
    [Teardown]      Dashboard Test Teardown

Resetting Pod Toleration Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]                  Upgrade    Dashboard
    [Setup]                 Begin Web Test
    Menu.Navigate To Page       Settings        Cluster settings
    Wait Until Page Contains        Notebook pod tolerations
    Disable Pod Toleration Via UI
    Enable "Usage Data Collection"
    IF    ${is_data_collection_enabled}
        Fail        msg=Usage data colletion is enbaled after the upgrade
    END
    [Teardown]      Dashboard Test Teardown

Verify POD Status
    [Documentation]    Verify all the pods are up and running
    [Tags]                  Upgrade    Platform
    Wait For Pods Status    namespace=${APPLICATIONS_NAMESPACE}     timeout=60
    Log     Verified ${APPLICATIONS_NAMESPACE}      console=yes
    Wait For Pods Status    namespace=${OPERATOR_NAMESPACE}     timeout=60
    Log     Verified ${OPERATOR_NAMESPACE}      console=yes
    Wait For Pods Status    namespace=${MONITORING_NAMESPACE}   timeout=60
    Log     Verified ${MONITORING_NAMESPACE}        console=yes
    Oc Get      kind=Namespace      field_selector=metadata.name=${NOTEBOOKS_NAMESPACE}
    Log     "Verified rhods-notebook"

Test Inference Post RHODS Upgrade
    # robocop: off=too-many-calls-in-test-case
    # robocop: off=too-long-test-case
    [Documentation]    Test the inference result after having deployed a model
    [Tags]                  Upgrade    ModelServing    ModelServer
    Set Suite Variable    ${TEST_NS}    ovmsmodel-upgrade
    Set Suite Variable    ${KSERVE_MODE}    Serverless    # RawDeployment   # Serverless
    Set Suite Variable    ${INFERENCE_INPUT}    @tests/Resources/Files/modelmesh-mnist-input.json
    Set Suite Variable    ${EXPECTED_INFERENCE_OUTPUT}    {"model_name":"ovms-model","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}    # robocop: off=line-too-long
    Setup Test Variables    model_name=ovms-model    use_gpu=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}

    ${pod_name}=  Get Pod Name    namespace=${TEST_NS}
    ...    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ${service_port}=    Extract Service Port    service_name=${model_name}-predictor    protocol=TCP
    ...    namespace=${TEST_NS}
    IF   "${KSERVE_MODE}"=="RawDeployment"
        Start Port-forwarding    namespace=${TEST_NS}    pod_name=${pod_name}  local_port=${service_port}
        ...    remote_port=${service_port}    process_alias=ovms-process
    END
    Verify Model Inference With Retries   model_name=${model_name}    inference_input=${INFERENCE_INPUT}
    ...    expected_inference_output=${EXPECTED_INFERENCE_OUTPUT}   project_title=${TEST_NS}
    ...    deployment_mode=Cli  kserve_mode=${KSERVE_MODE}    service_port=${service_port}
    ...    end_point=/v2/models/${model_name}/infer  retries=2
    [Teardown]      Run     oc delete project ${TEST_NS}

Verify Custom Runtime Exists After Upgrade
    [Documentation]    Test the inference result after having deployed a model that requires Token Authentication
    [Tags]      Upgrade    ModelServing
    [Setup]     Begin Web Test
    Menu.Navigate To Page       Settings        Serving runtimes
    Wait Until Page Contains        Add serving runtime     timeout=15s
    Page Should Contain Element     //tr[@id='caikit-runtime']
    Delete Serving Runtime Template From CLI By Runtime Name OR Display Name
    ...    runtime_name=caikit-runtime
    [Teardown]      Dashboard Test Teardown

Verify Ray Cluster Exists And Monitor Workload Metrics By Submitting Ray Job After Upgrade
    # robocop: off=too-long-test-case
    # robocop: off=too-many-calls-in-test-case
    [Documentation]    check the Ray Cluster exists , submit ray job and    verify resource usage after upgrade
    [Tags]      Upgrade    WorkloadOrchestration
    [Setup]     Prepare Codeflare-SDK Test Setup
    ${PRJ_UPGRADE}      Set Variable        test-ns-rayupgrade
    ${LOCAL_QUEUE}      Set Variable        local-queue-mnist
    ${JOB_NAME}     Set Variable        mnist
    Run Codeflare-SDK Test
    ...    upgrade
    ...    raycluster_sdk_upgrade_test.py::TestMnistJobSubmit
    ...    3.11
    ...    ${RAY_CUDA_IMAGE_3.11}
    ...    ${CODEFLARE-SDK-RELEASE-TAG}
    Set Global Variable     ${DW_PROJECT_CREATED}       True        # robocop: disable:replace-set-variable-with-var
    Set Library Search Order        SeleniumLibrary
    RHOSi Setup
    Launch Dashboard
    ...    ${TEST_USER.USERNAME}
    ...    ${TEST_USER.PASSWORD}
    ...    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}
    ...    ${BROWSER.NAME}
    ...    ${BROWSER.OPTIONS}
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name     ${PRJ_UPGRADE}
    Select Refresh Interval     15 seconds
    Click Button    ${PROJECT_METRICS_TAB_XP}
    Wait Until Element Is Visible
    ...    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}
    ...    timeout=20
    Wait Until Element Is Visible       xpath=//*[text()="Running"]     timeout=30

    ${cpu_requested}        Get CPU Requested       ${PRJ_UPGRADE}          ${LOCAL_QUEUE}
    ${memory_requested}     Get Memory Requested    ${PRJ_UPGRADE}          ${LOCAL_QUEUE}          RayCluster
    Check Requested Resources Chart                 ${PRJ_UPGRADE}          ${cpu_requested}        ${memory_requested}
    Check Requested Resources
    ...    ${PRJ_UPGRADE}
    ...    ${CPU_SHARED_QUOTA}
    ...    ${MEMEORY_SHARED_QUOTA}
    ...    ${cpu_requested}
    ...    ${memory_requested}
    ...    RayCluster

    Click Button    ${WORKLOAD_STATUS_TAB_XP}
    Check Distributed Workload Resource Metrics Status      ${JOB_NAME}     Running
    Check Distributed Worklaod Status Overview      ${JOB_NAME}     Running
    ...     All pods reached readiness and the workload is running

    Click Button    ${PROJECT_METRICS_TAB_XP}
    Check Distributed Workload Resource Metrics Chart       ${PRJ_UPGRADE}      ${cpu_requested}
    ...     ${memory_requested}     RayCluster      ${JOB_NAME}

    [Teardown]      Run Keywords        Cleanup Codeflare-SDK Setup     AND
    ...     Codeflare Upgrade Tests Teardown        ${PRJ_UPGRADE}      ${DW_PROJECT_CREATED}

Run Training Operator KFTO Run PyTorchJob Test Use Case with NVIDIA CUDA image (PyTorch 2_5_1)
    [Documentation]    Run Training Operator KFTO Run PyTorchJob Test Use Case with NVIDIA CUDA image (PyTorch 2_5_1)
    [Tags]      Upgrade    TrainingKubeflow
    [Setup]     Prepare Training Operator KFTO E2E Test Suite
    Run Training Operator KFTO Test          TestRunPytorchjob
    [Teardown]      Teardown Training Operator KFTO E2E Test Suite

Run Training Operator KFTO Run Sleep PyTorchJob Test Use Case with NVIDIA CUDA image (PyTorch 2_5_1)
    [Documentation]    Verify that running PyTorchJob Pod wasn't restarted with NVIDIA CUDA image (PyTorch 2_5_1)
    [Tags]      Upgrade    TrainingKubeflow
    [Setup]     Prepare Training Operator KFTO E2E Test Suite
    Run Training Operator KFTO Test      TestVerifySleepPytorchjob
    [Teardown]      Teardown Training Operator KFTO E2E Test Suite

Verify that the must-gather image provides RHODS logs and info
    [Documentation]    Tests the must-gather image for ODH/RHOAI after upgrading
    [Tags]      Upgrade    ODS-505    ExcludeOnDisconnected    Platform
    Get Must-Gather Logs
    Verify Logs For ${APPLICATIONS_NAMESPACE}
    IF    "${PRODUCT}" == "RHODS"
        Verify Logs For ${OPERATOR_NAMESPACE}
        Run Keyword If RHODS Is Managed     Verify Logs For ${MONITORING_NAMESPACE}
    END
    [Teardown]      Cleanup Must-Gather Logs

Verify That DSC And DSCI Release.Name Attribute matches ${expected_release_name}        # robocop: disable:not-allowed-char-in-name
    [Documentation]    Tests the release.name attribute from the DSC and DSCI matches the desired value.
    ...    ODH: Open Data Hub
    ...    RHOAI managed: OpenShift AI Cloud Service
    ...    RHOAI selfmanaged: OpenShift AI Self-Managed
    [Tags]      Upgrade    Platform
    Should Be Equal As Strings      ${DSC_RELEASE_NAME}     ${expected_release_name}
    Should Be Equal As Strings      ${DSCI_RELEASE_NAME}    ${expected_release_name}

Verify That DSC And DSCI Release.Version Attribute matches the value in the subscription        # robocop: disable:not-allowed-char-in-name
    [Documentation]    Tests the release.version attribute from the DSC and DSCI matches the value in the subscription.
    [Tags]      Upgrade    Platform
    ${rc}    ${csv_name}    Run And Return Rc And Output
    ...    oc get subscription -n ${OPERATOR_NAMESPACE} -l ${OPERATOR_SUBSCRIPTION_LABEL} -ojson | jq '.items[0].status.currentCSV' | tr -d '"'     # robocop: disable:line-too-long
    Should Be Equal As Integers     ${rc}       ${0}        ${rc}
    ${csv_version}      Get Resource Attribute      ${OPERATOR_NAMESPACE}
    ...     ClusterServiceVersion       ${csv_name}     .spec.version
    Should Be Equal As Strings      ${DSC_RELEASE_VERSION}      ${csv_version}
    Should Be Equal As Strings      ${DSCI_RELEASE_VERSION}     ${csv_version}

Data Science Pipelines Post Upgrade Verifications
    [Documentation]    Verifies the status of the resources created in project dsp-test-upgrade after the upgradea
    [Tags]      Upgrade     DataSciencePipelines-Backend
    DataSciencePipelinesUpgradeTesting.Verify Resources After Upgrade

Model Registry Post Upgrade Verification
    [Documentation]    Verifies that registered model/version in pre-upgrade is present after the upgrade
    [Tags]      Upgrade     ModelRegistryUpgrade    deprecatedTest
    Skip If Operator Starting Version Is Not Supported      minimum_version=2.14.0
    Model Registry Post Upgrade Scenario
    [Teardown]      Post Upgrade Scenario Teardown

Run Feast operator TestRemoteRegistryFeastCR Test Use Case
    [Documentation]    Run TestRemoteRegistryFeastCR Test Use Case
    [Tags]  Upgrade    FeatureStoreUpgrade
    [Setup]    Prepare Feast E2E Test Suite
    Run Feast Operator E2E Test    TestRemoteRegistryFeastCR    e2e
    [Teardown]    Teardown Feast E2E Test Suite

Run Feast operator PostUpgrade Test Use Case
    [Documentation]    Verifies the Feast CR status and perform Feast apply and materialize functionality
    [Tags]  Upgrade    FeatureStoreUpgrade
    [Setup]    Prepare Feast E2E Test Suite
    Run Feast Operator E2E Test    feastPostUpgrade    e2e_rhoai
    [Teardown]    Teardown Feast E2E Test Suite


*** Keywords ***
Dashboard Suite Setup
    [Documentation]    Basic suite setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Dashboard Test Teardown
    [Documentation]    Basic suite Teradown
    IF    not ${IS_SELF_MANAGED}    Managed RHOAI Upgrade Test Teardown
    Close All Browsers

Get Dashboard Config Data
    [Documentation]    Get OdhDashboardConfig CR data
    ${payload}    Oc Get    kind=OdhDashboardConfig    namespace=${APPLICATIONS_NAMESPACE}
    ...    field_selector=metadata.name==odh-dashboard-config
    Set Suite Variable    ${payload}    # robocop:disable

Get Auth Cr Config Data
    [Documentation]    Get payload from Auth CR
    ${AUTH_PAYLOAD}    Oc Get    kind=Auth    namespace=${APPLICATIONS_NAMESPACE}
    ...    field_selector=metadata.name==auth
    Set Suite Variable    ${AUTH_PAYLOAD}

Set Default Users
    [Documentation]    Set Default user settings
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings
    IF    not ${IS_SELF_MANAGED}    Managed RHOAI Upgrade Test Teardown
    # Get upgrade-config-map to check whether it exists
    ${rc}    ${cmd_output}=    Run And Return Rc And Output
    ...    oc get configmap ${USERGROUPS_CONFIG_MAP} -n ${UPGRADE_NS}
    IF  ${rc} == 0
        # Clean up upgrade-config-map
        ${return_code}    ${cmd_output}=    Run And Return Rc And Output
        ...    oc delete configmap ${USERGROUPS_CONFIG_MAP} -n ${UPGRADE_NS}
        Should Be Equal As Integers     ${return_code}      0       msg=${cmd_output}
    END

Delete OOTB Image
    [Documentation]    Delete the Custom notbook create
    # robocop:disable
    ${status}    Run Keyword And Return Status
    ...    Oc Delete
    ...    kind=ImageStream
    ...    name=byon-upgrade
    ...    namespace=${APPLICATIONS_NAMESPACE}
    IF    not ${status}    Fail    Notebook image is deleted after the upgrade
    IF    not ${IS_SELF_MANAGED}    Managed RHOAI Upgrade Test Teardown

Terminate Running Notebook
    [Documentation]    Terminates the running notebook instance
    [Arguments]     ${notebook_name}
    ${return_code}    ${cmd_output}    Run And Return Rc And Output
    ...    oc delete Notebook.kubeflow.org -n ${NOTEBOOKS_NAMESPACE} ${notebook_name}
    Should Be Equal As Integers    ${return_code}    0    msg=${cmd_output}

Managed RHOAI Upgrade Test Teardown
    # robocop: off=too-many-calls-in-keyword
    [Documentation]    Check rhods_aggregate_availability metric when RHOAI is installed as managed
    ${expression}    Set Variable    rhods_aggregate_availability&step=1
    ${resp}    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values}    Create List    1      # robocop: disable:replace-create-with-var
    Run Keyword And Warn On Failure
    ...    Should Contain
    ...    ${list_values}
    ...    ${resp.json()["data"]["result"][0]["value"][-1]}
    ${expression}    Set Variable    rhods_aggregate_availability{name="rhods-dashboard"}&step=1
    ${resp}    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values}    Create List    1      # robocop: disable:replace-create-with-var
    Run Keyword And Warn On Failure
    ...    Should Contain
    ...    ${list_values}
    ...    ${resp.json()["data"]["result"][0]["value"][-1]}
    ${expression}    Set Variable    rhods_aggregate_availability{name="notebook-spawner"}&step=1
    ${resp}    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values}    Create List    1      # robocop: disable:replace-create-with-var
    Run Keyword And Warn On Failure
    ...    Should Contain
    ...    ${list_values}
    ...    ${resp.json()["data"]["result"][0]["value"][-1]}

Upgrade Suite Setup
    [Documentation]    Set of action to run as Suite setup
    RHOSi Setup
    ${IS_SELF_MANAGED}    Is RHODS Self-Managed
    Set Suite Variable    ${IS_SELF_MANAGED}        # robocop: disable:replace-set-variable-with-var
    Gather Release Attributes From DSC And DSCI
    Set Expected Value For Release Name
