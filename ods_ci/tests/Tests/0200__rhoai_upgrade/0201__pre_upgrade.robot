*** Settings ***
Documentation       Test Suite for Upgrade testing, to be run before the upgrade

Library             OpenShiftLibrary
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/ODS.robot
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
Resource            ../../Resources/CLI/ModelServing/modelmesh.resource
Resource            ../../Resources/CLI/DataSciencePipelines/DataSciencePipelinesUpgradeTesting.resource
Resource            ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Resource            ../../Resources/Page/DistributedWorkloads/WorkloadMetricsUI.resource
Resource            ../../Resources/Page/ModelRegistry/ModelRegistry.resource

Suite Setup         Upgrade Suite Setup
Suite Teardown      RHOSi Teardown

Test Tags           PreUpgrade


*** Variables ***
${CUSTOM_CULLER_TIMEOUT}    60000
${S_SIZE}                   25
${DW_PROJECT_CREATED}       False
${CODE}     while True: import time ; time.sleep(10); print ("Hello")
${UPGRADE_NS}    upgrade
${UPGRADE_CONFIG_MAP}    upgrade-config-map


*** Test Cases ***
Set PVC Size Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]      Upgrade    Dashboard
    [Setup]     Begin Web Test
    Set PVC Value In RHODS Dashboard        ${S_SIZE}
    [Teardown]      Dashboard Test Teardown

Set Culler Timeout
    [Documentation]     Sets a culler timeout via the admin UI
    [Tags]      Upgrade    Dashboard
    [Setup]     Begin Web Test
    Modify Notebook Culler Timeout      ${CUSTOM_CULLER_TIMEOUT}
    [Teardown]      Dashboard Test Teardown

Setting Pod Toleration Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]      Upgrade    Dashboard
    [Setup]     Begin Web Test
    Menu.Navigate To Page       Settings        Cluster settings
    Wait Until Page Contains        Notebook pod tolerations
    Set Pod Toleration Via UI       TestToleration
    Disable "Usage Data Collection"
    [Teardown]      Dashboard Test Teardown

Verify RHODS Accept Multiple Admin Groups And CRD Gets Updates
    [Documentation]    Verify that users can set multiple admin groups and
    ...    check OdhDashboardConfig CRD gets updated according to Admin UI
    [Tags]      Upgrade     RHOAIENG-14306    Platform
    [Setup]     Begin Web Test
    # robocop: disable
    Launch Dashboard And Check User Management Option Is Available For The User
    ...    ${TEST_USER.USERNAME}
    ...    ${TEST_USER.PASSWORD}
    ...    ${TEST_USER.AUTH_TYPE}
    Clear User Management Settings
    Add OpenShift Groups To Data Science Administrators     rhods-admins        rhods-users
    Add OpenShift Groups To Data Science User Groups        system:authenticated
    Save Changes In User Management Setting
    [Teardown]      Dashboard Test Teardown

Verify Custom Image Can Be Added
    [Documentation]    Create Custome notebook using Cli
    [Tags]      Upgrade    IDE
    Oc Apply        kind=ImageStream        src=tests/Tests/0200__rhoai_upgrade/custome_image.yaml

Verify User Can Disable The Runtime
    [Documentation]    Disable the Serving runtime using Cli
    [Tags]      Upgrade    ModelServing
    Disable Model Serving Runtime Using CLI     namespace=redhat-ods-applications

Verify Model Can Be Deployed For Upgrade
    # robocop: off=too-long-test-case
    # robocop: off=too-many-calls-in-test-case
    [Documentation]    Verify Model Can Be Deployed Via UI For Upgrade
    [Tags]                  Upgrade    ModelServing    xxx
    Set Suite Variable    ${TEST_NS}    ovmsmodel-upgrade
    Set Suite Variable    ${KSERVE_MODE}    RawDeployment    # RawDeployment   # Serverless
    Setup Test Variables    model_name=test-dir    use_pvc=${TRUE}    use_gpu=${FALSE}
    ...    kserve_mode=${KSERVE_MODE}
    Set Project And Runtime    runtime=ovms-runtime     protocol=http     namespace=${TEST_NS}
    ...    download_in_pvc=${TRUE}    model_name=${model_name}
    ...    storage_size=100Mi    memory_request=100Mi
    ${requests}=    Create Dictionary    memory=1Gi
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${EMPTY}
    ...    model_storage_uri=pvc://${model_name}-claim/${model_name}
    ...    model_format=onnx    serving_runtime=ovms-runtime
    ...    limits_dict=&{EMPTY}    requests_dict=${requests}    kserve_mode=${KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    # File is not needed anymore after applying
    Remove File    ${INFERENCESERVICE_FILLED_FILEPATH}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    ${pod_name}=  Get Pod Name    namespace=${test_namespace}
    ...    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ${service_port}=    Extract Service Port    service_name=${model_name}-predictor    protocol=TCP
    ...    namespace=${test_namespace}
    IF   "${KSERVE_MODE}"=="RawDeployment"
        Start Port-forwarding    namespace=${test_namespace}    pod_name=${pod_name}  local_port=${service_port}
        ...    remote_port=${service_port}    process_alias=ovms-process
    END
    Verify Model Inference With Retries   model_name=${model_name}    inference_input=${INFERENCE_INPUT}
    ...    expected_inference_output=${EXPECTED_INFERENCE_OUTPUT}   project_title=${test_namespace}
    ...    deployment_mode=Cli  kserve_mode=${KSERVE_MODE}    service_port=${service_port}
    ...    end_point=/v2/models/${model_name}/infer  retries=10


Verify User Can Deploy Custom Runtime For Upgrade
    [Documentation]     Verify User Can Deploy Custom Runtime For Upgrade
    [Tags]      Upgrade    ModelServing
    Create Custom Serving Runtime Using Template By CLI
    ...    tests/Resources/Files/caikit_runtime_template.yaml
    Begin Web Test
    Menu.Navigate To Page       Settings        Serving runtimes
    Wait Until Page Contains        Add serving runtime     timeout=15s
    Page Should Contain Element     //tr[@id='caikit-runtime']
    [Teardown]      Dashboard Test Teardown

Verify Distributed Workload Metrics Resources By Creating Ray Cluster Workload
    # robocop: off=too-long-test-case
    # robocop: off=too-many-calls-in-test-case
    [Documentation]    Creates the Ray Cluster and verify resource usage
    [Tags]      Upgrade    WorkloadOrchestration
    [Setup]     Prepare Codeflare-SDK Test Setup
    ${PRJ_UPGRADE}=     Set Variable        test-ns-rayupgrade
    ${JOB_NAME}=        Set Variable        mnist
    Run Codeflare-SDK Test
    ...    upgrade
    ...    raycluster_sdk_upgrade_test.py::TestMNISTRayClusterUp
    ...    3.11
    ...    ${RAY_CUDA_IMAGE_3.11}
    ...    ${CODEFLARE-SDK-RELEASE-TAG}
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
    Set Global Variable     ${DW_PROJECT_CREATED}       True        # robocop: disable:replace-set-variable-with-var
    Select Refresh Interval     15 seconds
    Click Button    ${PROJECT_METRICS_TAB_XP}
    Wait Until Element Is Visible
    ...    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}
    ...    timeout=20
    Wait Until Element Is Visible       xpath=//*[text()="Running"]     timeout=30

    ${cpu_requested}=       Get CPU Requested       ${PRJ_UPGRADE}      local-queue-mnist
    ${memory_requested}=    Get Memory Requested    ${PRJ_UPGRADE}      local-queue-mnist       RayCluster
    Check Requested Resources Chart     ${PRJ_UPGRADE}      ${cpu_requested}        ${memory_requested}
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
    ...     All pods were ready or succeeded since the workload admission

    Click Button    ${PROJECT_METRICS_TAB_XP}
    Check Distributed Workload Resource Metrics Chart       ${PRJ_UPGRADE}      ${cpu_requested}
    ...     ${memory_requested}     RayCluster      ${JOB_NAME}

    [Teardown]      Run Keywords        Cleanup Codeflare-SDK Setup     AND
    ...     Run Keyword If Test Failed      Codeflare Upgrade Tests Teardown        ${PRJ_UPGRADE}      ${DW_PROJECT_CREATED}       # robocop: disable:line-too-long

Run Training Operator KFTO Setup PyTorchJob Test Use Case
    [Documentation]    Run Training Operator KFTO Setup PyTorchJob Test Use Case
    [Tags]      Upgrade    Training
    [Setup]     Prepare Training Operator KFTO E2E Test Suite
    Skip If Operator Starting Version Is Not Supported      minimum_version=2.12.0
    Run Training Operator KFTO Test    TestSetupPytorchjob    ${CUDA_TRAINING_IMAGE}
    [Teardown]    Teardown Training Operator KFTO E2E Test Suite

Run Training Operator KFTO Setup Sleep PyTorchJob Test Use Case
    [Documentation]    Setup PyTorchJob which is kept running for 24 hours
    [Tags]      Upgrade    Training
    [Setup]     Prepare Training Operator KFTO E2E Test Suite
    Skip If Operator Starting Version Is Not Supported      minimum_version=2.12.0
    Run Training Operator KFTO Test    TestSetupSleepPytorchjob    ${CUDA_TRAINING_IMAGE}
    [Teardown]    Teardown Training Operator KFTO E2E Test Suite

Data Science Pipelines Pre Upgrade Configuration
    [Documentation]    Creates project dsp-test-upgrade and configures the pipeline resources testing upgrade
    [Tags]      Upgrade     DataSciencePipelines-Backend
    DataSciencePipelinesUpgradeTesting.Setup Environment For Upgrade Testing

Model Registry Pre Upgrade Set Up
    [Documentation]    Creates a Model Registry instance and registers a model/version
    [Tags]      Upgrade     ModelRegistryUpgrade
    Model Registry Pre Upgrade Scenario

Long Running Jupyter Notebook
    [Documentation]    Launch a long running notebook before the upgrade
    [Tags]      Upgrade    IDE
    Launch Notebook
    Add And Run JupyterLab Code Cell In Active Notebook     ${CODE}

    # Get the notebook pod creation timestamp
    ${notebook_pod_name}=    Get User Notebook Pod Name    ${TEST_USER2.USERNAME}
    ${return_code}    ${ntb_creation_timestamp} =    Run And Return Rc And Output
    ...    oc get pod -n ${NOTEBOOKS_NAMESPACE} ${notebook_pod_name} --no-headers --output='custom-columns=TIMESTAMP:.metadata.creationTimestamp'    # robocop: disable: line-too-long
    Should Be Equal As Integers     ${return_code}    0    msg=${ntb_creation_timestamp}

    # Save the timestamp to the OpenShift ConfigMap so it can be used in test in the next phase
    ${return_code}    ${cmd_output} =    Run And Return Rc And Output
    ...    oc create configmap ${UPGRADE_CONFIG_MAP} -n ${UPGRADE_NS} --from-literal=ntb_creation_timestamp=${ntb_creation_timestamp}    # robocop: disable: line-too-long
    Should Be Equal As Integers     ${return_code}    0    msg=${cmd_output}

    Close Browser


*** Keywords ***
Launch Notebook
    [Documentation]    Launch notebook for the suite
    [Arguments]     ${notebook_image}=minimal-notebook
    ...    ${username}=${TEST_USER2.USERNAME}
    ...    ${password}=${TEST_USER2.PASSWORD}
    ...    ${auth_type}=${TEST_USER2.AUTH_TYPE}
    Begin Web Test    username=${username}    password=${password}    auth_type=${auth_type}
    Launch Jupyter From RHODS Dashboard Link
    Spawn Notebook With Arguments
    ...    image=${notebook_image}
    ...    username=${username}
    ...    password=${password}
    ...    auth_type=${auth_type}

Upgrade Suite Setup
    [Documentation]    Basic suite setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    # Prepare a namespace for storing values that should be shared between different upgrade test phases
    # 1. if the namespace exists already, let's remove it
    ${return_code}    ${cmd_output} =    Run And Return Rc And Output
    ...    oc delete namespace --wait --ignore-not-found ${UPGRADE_NS}
    Should Be Equal As Integers     ${return_code}    0    msg=${cmd_output}
    # 2. create the namespace now
    ${return_code}    ${cmd_output} =    Run And Return Rc And Output
    ...    oc create namespace ${UPGRADE_NS}
    Should Be Equal As Integers     ${return_code}    0    msg=${cmd_output}

Dashboard Test Teardown
    [Documentation]    Basic suite teardown
    Close All Browsers
