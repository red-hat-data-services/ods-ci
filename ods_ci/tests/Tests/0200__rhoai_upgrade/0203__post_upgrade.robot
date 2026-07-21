*** Settings ***
Documentation       Test Suite for Upgrade testing,to be run after the upgrade

Library             OpenShiftLibrary
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/OCP.resource
Resource            ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource            ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource            ../../Resources/Page/LoginPage.robot
Resource            ../../Resources/Page/OCPLogin/OCPLogin.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/OCPDashboard/Pods/Pods.robot
Resource            ../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource            ../../Resources/Page/HybridCloudConsole/OCM.robot
Resource            ../../Resources/CLI/MustGather/MustGather.resource
Resource            ../../Resources/Page/FeatureStore/FeatureStore.resource

Suite Setup         Upgrade Suite Setup

Test Tags           PostUpgrade


*** Variables ***
${UPGRADE_NS}    upgrade
${UPGRADE_CONFIG_MAP}    upgrade-config-map
${USERGROUPS_CONFIG_MAP}    usergroups-config-map
${ALLOWED_GROUPS}       system:authenticated


*** Test Cases ***
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
    Run Feast Operator Upgrade Test    feastPostUpgrade
    [Teardown]    Teardown Feast E2E Test Suite


*** Keywords ***
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
