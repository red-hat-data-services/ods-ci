*** Settings ***
Documentation      Test Suite for Upgrade testing, to be run before the upgrade
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
Resource           ../../../Resources/CLI/ModelServing/modelmesh.resource
Resource           ../../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Suite Setup        Dashboard Suite Setup
Suite Teardown     RHOSi Teardown
Test Tags          PreUpgrade


*** Variables ***
${CUSTOM_CULLER_TIMEOUT}      60000
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

*** Test Cases ***
Set PVC Size Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Set PVC Value In RHODS Dashboard    ${S_SIZE}
    [Teardown]   Dashboard Test Teardown

Set Culler Timeout
    [Documentation]    Sets a culler timeout via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Modify Notebook Culler Timeout     ${CUSTOM_CULLER_TIMEOUT}
    [Teardown]   Dashboard Test Teardown

Setting Pod Toleration Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains    Notebook pod tolerations
    Set Pod Toleration Via UI    TestToleration
    Disable "Usage Data Collection"
    [Teardown]   Dashboard Test Teardown

Verify RHODS Accept Multiple Admin Groups And CRD Gets Updates
    [Documentation]    Verify that users can set multiple admin groups and
    ...                check OdhDashboardConfig CRD gets updated according to Admin UI
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Launch Dashboard And Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}  #robocop: disable
    Clear User Management Settings
    Add OpenShift Groups To Data Science Administrators   rhods-admins  rhods-users
    Add OpenShift Groups To Data Science User Groups    system:authenticated
    Save Changes In User Management Setting
    [Teardown]   Dashboard Test Teardown

Verify Custom Image Can Be Added
    [Documentation]  Create Custome notebook using Cli
    [Tags]  Upgrade
    Oc Apply    kind=ImageStream   src=tests/Tests/100__deploy/120__upgrades/custome_image.yaml

Verify User Can Disable The Runtime
    [Documentation]  Disable the Serving runtime using Cli
    [Tags]  Upgrade
    Disable Model Serving Runtime Using CLI   namespace=redhat-ods-applications

Verify Model Can Be Deployed Via UI For Upgrade
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    ${runtime_pod_name} =    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Fetch CA Certificate If RHODS Is Self-Managed
    Clean All Models Of Current User
    Open Data Science Projects Home Page
    Wait For RHODS Dashboard To Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=openvino_ir    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=openvino-example-model
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT_OPENVINO}    ${EXPECTED_INFERENCE_OUTPUT_OPENVINO}    token_auth=${FALSE}
    Remove File    openshift_ca.crt
    [Teardown]   Run Keywords    Dashboard Test Teardown
    ...    AND
    ...    Run Keyword If Test Failed    Get Events And Pod Logs    namespace=${PRJ_TITLE}
    ...    label_selector=name=modelmesh-serving-${runtime_pod_name}

Verify User Can Deploy Custom Runtime For Upgrade
    [Tags]  Upgrade
    Create Custom Serving Runtime Using Template By CLI   tests/Resources/Files/caikit_runtime_template.yaml
    Begin Web Test
    Menu.Navigate To Page    Settings    Serving runtimes
    Wait Until Page Contains   Add serving runtime    timeout=15s
    Page Should Contain Element  //tr[@id='caikit-runtime']
    [Teardown]   Dashboard Test Teardown

Run Training Operator ODH Setup PyTorchJob Test Use Case
    [Documentation]    Run Training Operator ODH Setup PyTorchJob Test Use Case
    [Tags]             Upgrade
    [Setup]            Prepare Training Operator E2E Upgrade Test Suite
    Run Training Operator ODH Upgrade Test    TestSetupPytorchjob
    [Teardown]         Teardown Training Operator E2E Upgrade Test Suite

Run Training Operator ODH Setup Sleep PyTorchJob Test Use Case
    [Documentation]    Setup PyTorchJob which is kept running for 24 hours
    [Tags]             Upgrade
    [Setup]            Prepare Training Operator E2E Upgrade Test Suite
    Run Training Operator ODH Upgrade Test    TestSetupSleepPytorchjob
    [Teardown]         Teardown Training Operator E2E Upgrade Test Suite

*** Keywords ***
Dashboard Suite Setup
    [Documentation]  Basic suite setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Dashboard Test Teardown
    [Documentation]  Basic suite teardown
    Close All Browsers
