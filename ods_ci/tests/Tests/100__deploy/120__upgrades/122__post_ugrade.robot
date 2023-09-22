*** Settings ***
Documentation       Test Suite for Upgrade testing,to be run after the upgrade
Library            OpenShiftLibrary
Resource           ../../../Resources/RHOSi.resource
Resource           ../../../Resources/ODS.robot
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource           ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource           ../../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource           ../../../Resources/Page/LoginPage.robot
Resource           ../../../Resources/Page/OCPLogin/OCPLogin.robot
Resource           ../../../Resources/Common.robot
Resource           ../../../Resources/Page/OCPDashboard/Pods/Pods.robot
Resource           ../../../Resources/Page/OCPDashboard/Builds/Builds.robot
Resource           ../../../Resources/Page/HybridCloudConsole/OCM.robot


*** Variables ***
${S_SIZE}       25
${INFERENCE_INPUT}=    @ods_ci/tests/Resources/Files/modelmesh-mnist-input.json
${INFERENCE_INPUT_OPENVINO}=    @ods_ci/tests/Resources/Files/openvino-example-input.json
${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"test-model__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}
${EXPECTED_INFERENCE_OUTPUT_OPENVINO}=    {"model_name":"test-model__isvc-8655dc7979","model_version":"1","outputs":[{"name":"Func/StatefulPartitionedCall/output/_13:0","datatype":"FP32","shape":[1,1],"data":[0.99999994]}]}
${PRJ_TITLE}=    model-serving-upgrade
${PRJ_DESCRIPTION}=    project used for model serving tests
${MODEL_NAME}=    test-model
${MODEL_CREATED}=    False
${RUNTIME_NAME}=    Model Serving Test


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

*** Keywords ***
Dashboard Suite Setup
    [Documentation]  Basic suite setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Dashboard Test Teardown
    [Documentation]  Basic suite Teradown
    Upgrade Test Teardown
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
    Upgrade Test Teardown

Delete OOTB Image
   [Documentation]  Delete the Custom notbook create
   ${status}  Run Keyword And Return Status     Oc Delete  kind=ImageStream  name=byon-upgrade  namespace=${APPLICATIONS_NAMESPACE}  #robocop:disable
   IF    not ${status}   Fail    Notebook image is deleted after the upgrade
   Upgrade Test Teardown

Upgrade Test Teardown
    Skip If RHODS Is Self-Managed
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
