*** Settings ***
Documentation       Test Suite for Upgrade testing, to be run before the upgrade

Library             OpenShiftLibrary
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource            ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource            ../../Resources/Page/LoginPage.robot
Resource            ../../Resources/Page/OCPLogin/OCPLogin.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/OCPDashboard/Pods/Pods.robot
Resource            ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource            ../../Resources/Page/HybridCloudConsole/OCM.robot
Resource            ../../Resources/CLI/DataSciencePipelines/DataSciencePipelinesUpgradeTesting.resource
Resource            ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Resource            ../../Resources/Page/DistributedWorkloads/WorkloadMetricsUI.resource
Resource            ../../Resources/Page/FeatureStore/FeatureStore.resource

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
${USERGROUPS_CONFIG_MAP}    usergroups-config-map


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
    [Tags]      Upgrade     RHOAIENG-14306    Platform      RHOAIENG-19806
    [Setup]     Begin Web Test
    # robocop: disable
    Launch Dashboard And Check User Management Option Is Available For The User
    ...    ${TEST_USER.USERNAME}
    ...    ${TEST_USER.PASSWORD}
    ...    ${TEST_USER.AUTH_TYPE}
    Clear User Management Settings
    # Create a configmap and store both groups
    ${return_code}    ${cmd_output}=    Run And Return Rc And Output
    ...    oc create configmap ${USERGROUPS_CONFIG_MAP} -n ${UPGRADE_NS} --from-literal=adm_groups="['rhods-admins', 'rhods-users']" --from-literal=allwd_groups="['system:authenticated']"
    Should Be Equal As Integers     ${return_code}      0       msg=${cmd_output}

    Add OpenShift Groups To Data Science Administrators     rhods-admins    rhods-users
    Add OpenShift Groups To Data Science User Groups        system:authenticated
    Save Changes In User Management Setting
    [Teardown]      Dashboard Test Teardown

Verify Custom Image Can Be Added
    [Documentation]    Create Custome notebook using Cli
    [Tags]      Upgrade    IDE
    Oc Apply        kind=ImageStream        src=tests/Tests/0200__rhoai_upgrade/custome_image.yaml

Verify Distributed Workload Metrics Resources By Creating Ray Cluster Workload
    # robocop: off=too-long-test-case
    # robocop: off=too-many-calls-in-test-case
    [Documentation]    Creates the Ray Cluster and verify resource usage
    [Tags]      Upgrade    WorkloadOrchestration
    [Setup]     Prepare Codeflare-SDK Upgrade Test Setup
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
    ...     All pods reached readiness and the workload is running

    Click Button    ${PROJECT_METRICS_TAB_XP}
    Check Distributed Workload Resource Metrics Chart       ${PRJ_UPGRADE}      ${cpu_requested}
    ...     ${memory_requested}     RayCluster      ${JOB_NAME}

    [Teardown]      Run Keywords        Cleanup Codeflare-SDK Setup     AND
    ...     Run Keyword If Test Failed      Codeflare Upgrade Tests Teardown        ${PRJ_UPGRADE}      ${DW_PROJECT_CREATED}       # robocop: disable:line-too-long



Data Science Pipelines Pre Upgrade Configuration
    [Documentation]    Creates project dsp-test-upgrade and configures the pipeline resources testing upgrade
    [Tags]      Upgrade     DataSciencePipelines-Backend
    DataSciencePipelinesUpgradeTesting.Setup Environment For Upgrade Testing

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

Run Feast operator Preupgrade Test Use Case
    [Documentation]    Run Test to Create Feature store CR
    [Tags]  Upgrade    FeatureStoreUpgrade
    [Setup]    Prepare Feast E2E Test Suite
    Run Feast Operator E2E Test    feastPreUpgrade    e2e_rhoai
    [Teardown]    Teardown Feast E2E Test Suite


*** Keywords ***
Launch Notebook
    [Documentation]    Launch notebook for the suite
    [Arguments]     ${notebook_image}=minimal-notebook
    ...    ${username}=${TEST_USER2.USERNAME}
    ...    ${password}=${TEST_USER2.PASSWORD}
    ...    ${auth_type}=${TEST_USER2.AUTH_TYPE}
    Clean All Standalone Notebooks
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
