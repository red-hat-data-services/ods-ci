*** Settings ***
Documentation       Test Suite for Upgrade testing,to be run after the upgrade
Library            OpenShiftLibrary
Resource           ../../Resources/RHOSi.resource
Resource           ../../Resources/ODS.robot
Resource           ../../Resources/OCP.resource
Resource           ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource           ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource           ../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource           ../../Resources/Page/LoginPage.robot
Resource           ../../Resources/Page/OCPLogin/OCPLogin.robot
Resource           ../../Resources/Common.robot
Resource           ../../Resources/Page/OCPDashboard/Pods/Pods.robot
Resource           ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource           ../../Resources/Page/HybridCloudConsole/OCM.robot
Resource           ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Resource           ../../Resources/Page/DistributedWorkloads/WorkloadMetricsUI.resource
Resource           ../../Resources/CLI/MustGather/MustGather.resource
Suite Setup    Upgrade Suite Setup


*** Variables ***
${S_SIZE}       25
${INFERENCE_INPUT}=    @tests/Resources/Files/modelmesh-mnist-input.json
${INFERENCE_INPUT_OPENVINO}=    @tests/Resources/Files/openvino-example-input.json
${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"test-model__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}
${EXPECTED_INFERENCE_OUTPUT_OPENVINO}=    {"model_name":"test-model__isvc-8655dc7979","model_version":"1","outputs":[{"name":"Func/StatefulPartitionedCall/output/_13:0","datatype":"FP32","shape":[1,1],"data":[0.99999994]}]}
${PRJ_TITLE}=    model-serving-upgrade
${PRJ_DESCRIPTION}=    project used for model serving tests
${MODEL_NAME}=    test-model
${MODEL_CREATED}=    ${FALSE}
${RUNTIME_NAME}=    Model Serving Test
${DW_PROJECT_CREATED}=    False


*** Test Cases ***
Verify PVC Size
    [Documentation]    Verify PVC Size after the upgrade
    [Tags]  Upgrade
    Get Dashboard Config Data
    ${size}   Set Variable      ${payload[0]['spec']['notebookController']['pvcSize']}[:-2]
    Should Be Equal As Strings    '${size}'    '${S_SIZE}'

Verify Pod Toleration
    [Documentation]    Verify Pod toleration after the upgrade
    [Tags]  Upgrade
    ${enable}   Set Variable      ${payload[0]['spec']['notebookController']['notebookTolerationSettings']['enabled']}
    Should Be Equal As Strings    '${enable}'    'True'

Verify RHODS User Groups
    [Documentation]    Verify User Configuration after the upgrade
    [Tags]  Upgrade
    ${admin}     Set Variable      ${payload[0]['spec']['groupsConfig']['adminGroups']}
    ${user}      Set Variable      ${payload[0]['spec']['groupsConfig']['allowedGroups']}
    Should Be Equal As Strings    '${admin}'    'rhods-admins,rhods-users'
    Should Be Equal As Strings    '${user}'   'system:authenticated'
    [Teardown]  Set Default Users

Verify Culler is Enabled
    [Documentation]    Verify Culler Configuration after the upgrade
    [Tags]  Upgrade
    ${status}    Check If ConfigMap Exists   ${APPLICATIONS_NAMESPACE}     notebook-controller-culler-config
    IF    '${status}' != 'PASS'
         Fail    msg=Culler has been diabled after the upgrade
    END

Verify Notebook Has Not Restarted
    [Documentation]    Verify Notbook pod has not restarted after the upgrade
    [Tags]  Upgrade
    ${return_code}    ${new_timestamp}    Run And Return Rc And Output   oc get pod -n ${NOTEBOOKS_NAMESPACE} jupyter-nb-ldap-2dadmin2-0 --no-headers --output='custom-columns=TIMESTAMP:.metadata.creationTimestamp'   #robocop:disable
    Should Be Equal As Integers    ${return_code}     0
    Should Be Equal   ${timestamp}      ${new_timestamp}    msg=Running notebook pod has restarted

Verify Custom Image Is Present
   [Tags]  Upgrade
   [Documentation]    Verify Custom Noteboook is not deleted after the upgrade
   ${status}  Run Keyword And Return Status     Oc Get    kind=ImageStream   namespace=${APPLICATIONS_NAMESPACE}
   ...   field_selector=metadata.name==byon-upgrade
   IF    not ${status}   Fail    Notebook image is deleted after the upgrade
   [Teardown]  Delete OOTB Image

Verify Disable Runtime Is Present
    [Documentation]  Disable the Serving runtime using Cli
    [Tags]  Upgrade
    ${rn}   Set Variable      ${payload[0]['spec']['templateDisablement']}
    List Should Contain Value   ${rn}    ovms-gpu
    [Teardown]  Enable Model Serving Runtime Using CLI   namespace=redhat-ods-applications

Reset PVC Size Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Set PVC Value In RHODS Dashboard    20
    [Teardown]   Dashboard Test Teardown

Reset Culler Timeout
    [Documentation]    Sets a culler timeout via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Disable Notebook Culler
    [Teardown]   Dashboard Test Teardown

Resetting Pod Toleration Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains    Notebook pod tolerations
    Disable Pod Toleration Via UI
    Enable "Usage Data Collection"
    IF    ${is_data_collection_enabled}==True
          Fail    msg=Usage data colletion is enbaled after the upgrade
    END
    [Teardown]   Dashboard Test Teardown

Verify POD Status
    [Documentation]    Verify all the pods are up and running
    [Tags]  Upgrade
    Wait For Pods Status  namespace=${APPLICATIONS_NAMESPACE}  timeout=60
    Log  Verified ${APPLICATIONS_NAMESPACE}  console=yes
    Wait For Pods Status  namespace=${OPERATOR_NAMESPACE}  timeout=60
    Log  Verified ${OPERATOR_NAMESPACE}  console=yes
    Wait For Pods Status  namespace=${MONITORING_NAMESPACE}  timeout=60
    Log  Verified ${MONITORING_NAMESPACE}  console=yes
    Oc Get  kind=Namespace  field_selector=metadata.name=${NOTEBOOKS_NAMESPACE}
    Log  "Verified rhods-notebook"

Test Inference Post RHODS Upgrade
    [Documentation]    Test the inference result after having deployed a model that requires Token Authentication
    [Tags]  Upgrade
    [Setup]  Begin Web Test
    Fetch CA Certificate If RHODS Is Self-Managed
    Open Model Serving Home Page
    Verify Model Status    ${MODEL_NAME}    success
    Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT_OPENVINO}    ${EXPECTED_INFERENCE_OUTPUT_OPENVINO}    token_auth=${FALSE}
    Remove File    openshift_ca.crt
    [Teardown]   Run   oc delete project ${PRJ_TITLE}

Verify Custom Runtime Exists After Upgrade
    [Documentation]    Test the inference result after having deployed a model that requires Token Authentication
    [Tags]  Upgrade
    [Setup]  Begin Web Test
    Menu.Navigate To Page    Settings    Serving runtimes
    Wait Until Page Contains   Add serving runtime    timeout=15s
    Page Should Contain Element  //tr[@id='caikit-runtime']
    Delete Serving Runtime Template From CLI By Runtime Name OR Display Name  runtime_name=caikit-runtime
    [Teardown]   Dashboard Test Teardown

Verify Ray Cluster Exists And Monitor Workload Metrics By Submitting Ray Job After Upgrade
    [Documentation]    check the Ray Cluster exists , submit ray job and  verify resource usage after upgrade
    [Tags]    Upgrade
    [Setup]    Prepare Codeflare-SDK Test Setup
    ${PRJ_UPGRADE}    Set Variable    test-ns-rayupgrade
    ${LOCAL_QUEUE}    Set Variable    local-queue-mnist
    ${JOB_NAME}    Set Variable    mnist
    Run Codeflare-SDK Test    upgrade    raycluster_sdk_upgrade_test.py::TestMnistJobSubmit
    Set Global Variable    ${DW_PROJECT_CREATED}    True
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_UPGRADE}
    Select Refresh Interval    15 seconds
    Wait Until Element Is Visible    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}    timeout=20
    Wait Until Element Is Visible    xpath=//*[text()="Running"]    timeout=30

    ${cpu_requested} =   Get CPU Requested    ${PRJ_UPGRADE}    ${LOCAL_QUEUE}
    ${memory_requested} =   Get Memory Requested    ${PRJ_UPGRADE}    ${LOCAL_QUEUE}    RayCluster
    Check Requested Resources Chart    ${PRJ_UPGRADE}    ${cpu_requested}    ${memory_requested}
    Check Requested Resources    ${PRJ_UPGRADE}    ${CPU_SHARED_QUOTA}
    ...    ${MEMEORY_SHARED_QUOTA}    ${cpu_requested}    ${memory_requested}    RayCluster

    Check Distributed Workload Resource Metrics Status    ${JOB_NAME}    Running
    Check Distributed Worklaod Status Overview    ${JOB_NAME}    Running
    ...    All pods were ready or succeeded since the workload admission

    Click Button    ${PROJECT_METRICS_TAB_XP}
    Check Distributed Workload Resource Metrics Chart    ${PRJ_UPGRADE}    ${cpu_requested}
    ...    ${memory_requested}    RayCluster    ${JOB_NAME}

    [Teardown]    Run Keywords    Cleanup Codeflare-SDK Setup    AND
    ...    Codeflare Upgrade Tests Teardown    ${PRJ_UPGRADE}    ${DW_PROJECT_CREATED}

Run Training Operator ODH Run PyTorchJob Test Use Case
    [Documentation]    Run Training Operator ODH Run PyTorchJob Test Use Case
    [Tags]             Upgrade
    [Setup]            Prepare Training Operator E2E Upgrade Test Suite
    Run Training Operator ODH Upgrade Test    TestRunPytorchjob
    [Teardown]         Teardown Training Operator E2E Upgrade Test Suite

Run Training Operator ODH Run Sleep PyTorchJob Test Use Case
    [Documentation]    Verify that running PyTorchJob Pod wasn't restarted
    [Tags]             Upgrade
    [Setup]            Prepare Training Operator E2E Upgrade Test Suite
    Run Training Operator ODH Upgrade Test    TestVerifySleepPytorchjob
    [Teardown]         Teardown Training Operator E2E Upgrade Test Suite

Verify that the must-gather image provides RHODS logs and info
    [Documentation]   Tests the must-gather image for ODH/RHOAI after upgrading
    [Tags]   Upgrade
    Get must-gather Logs
    Verify logs for ${APPLICATIONS_NAMESPACE}
    IF  "${PRODUCT}" == "RHODS"
        Verify Logs For ${OPERATOR_NAMESPACE}
        Run Keyword If RHODS Is Managed    Verify logs for ${MONITORING_NAMESPACE}
    END
    [Teardown]  Cleanup must-gather Logs


Verify That DSC And DSCI Release.Name Attribute matches ${expected_release_name}
    [Documentation]    Tests the release.name attribute from the DSC and DSCI matches the desired value.
    ...                ODH: Open Data Hub
    ...                RHOAI managed: OpenShift AI Cloud Service
    ...                RHOAI selfmanaged: OpenShift AI Self-Managed
    [Tags]    Upgrade
    Should Be Equal As Strings    ${DSC_RELEASE_NAME}     ${expected_release_name}
    Should Be Equal As Strings    ${DSCI_RELEASE_NAME}    ${expected_release_name}

Verify That DSC And DSCI Release.Version Attribute matches the value in the subscription
    [Documentation]    Tests the release.version attribute from the DSC and DSCI matches the value in the subscription.
    [Tags]    Upgrade
    ${rc}    ${csv_name}=    Run And Return Rc And Output
    ...    oc get subscription -n ${OPERATOR_NAMESPACE} -l ${OPERATOR_SUBSCRIPTION_LABEL} -ojson | jq '.items[0].status.currentCSV' | tr -d '"'

    Should Be Equal As Integers    ${rc}    ${0}    ${rc}

    ${csv_version}=     Get Resource Attribute      ${OPERATOR_NAMESPACE}
    ...                 ClusterServiceVersion      ${csv_name}        .spec.version

    Should Be Equal As Strings    ${DSC_RELEASE_VERSION}    ${csv_version}
    Should Be Equal As Strings    ${DSCI_RELEASE_VERSION}    ${csv_version}


*** Keywords ***
Dashboard Suite Setup
    [Documentation]  Basic suite setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Dashboard Test Teardown
    [Documentation]  Basic suite Teradown
    IF    not ${IS_SELF_MANAGED}    Managed RHOAI Upgrade Test Teardown
    Close All Browsers

Get Dashboard Config Data
    [Documentation]  Get OdhDashboardConfig CR data
    ${payload}    Oc Get  kind=OdhDashboardConfig  namespace=${APPLICATIONS_NAMESPACE}
    ...    field_selector=metadata.name==odh-dashboard-config
    Set Suite Variable    ${payload}   #robocop:disable

Set Default Users
    [Documentation]  Set Default user settings
    Set Standard RHODS Groups Variables
    Set Default Access Groups Settings
    IF    not ${IS_SELF_MANAGED}    Managed RHOAI Upgrade Test Teardown

Delete OOTB Image
   [Documentation]  Delete the Custom notbook create
   ${status}  Run Keyword And Return Status     Oc Delete  kind=ImageStream  name=byon-upgrade  namespace=${APPLICATIONS_NAMESPACE}  #robocop:disable
   IF    not ${status}   Fail    Notebook image is deleted after the upgrade
   IF    not ${IS_SELF_MANAGED}    Managed RHOAI Upgrade Test Teardown

Managed RHOAI Upgrade Test Teardown
    [Documentation]    Check rhods_aggregate_availability metric when RHOAI is installed as managed
    ${expression} =    Set Variable    rhods_aggregate_availability&step=1
    ${resp} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values} =    Create List    1
     Run Keyword And Warn On Failure    Should Contain    ${list_values}    ${resp.json()["data"]["result"][0]["value"][-1]}
    ${expression} =    Set Variable     rhods_aggregate_availability{name="rhods-dashboard"}&step=1
    ${resp} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values} =    Create List    1
    Run Keyword And Warn On Failure    Should Contain    ${list_values}    ${resp.json()["data"]["result"][0]["value"][-1]}
    ${expression} =    Set Variable     rhods_aggregate_availability{name="notebook-spawner"}&step=1
    ${resp} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values} =    Create List    1
    Run Keyword And Warn On Failure    Should Contain    ${list_values}    ${resp.json()["data"]["result"][0]["value"][-1]}

Upgrade Suite Setup
    [Documentation]    Set of action to run as Suite setup
    RHOSi Setup
    ${IS_SELF_MANAGED}=    Is RHODS Self-Managed
    Set Suite Variable    ${IS_SELF_MANAGED}
    Gather Release Attributes From DSC And DSCI
    Set Expected Value For Release Name
