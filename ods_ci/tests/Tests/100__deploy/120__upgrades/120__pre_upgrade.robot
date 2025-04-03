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

Verify Model Can Be Deployed For Upgrade
    # robocop: off=too-long-test-case
    # robocop: off=too-many-calls-in-test-case
    [Documentation]    Verify Model Can Be Deployed Via UI For Upgrade
    [Tags]                  Upgrade    ModelServing    ModelServer
    Set Suite Variable    ${TEST_NS}    ovmsmodel-upgrade
    Set Suite Variable    ${KSERVE_MODE}    Serverless
    Set Suite Variable    ${MODELS_BUCKET}    ${S3.BUCKET_1}
    Set Suite Variable    ${INFERENCE_INPUT}    @tests/Resources/Files/modelmesh-mnist-input.json
    Set Suite Variable    ${EXPECTED_INFERENCE_OUTPUT}    {"model_name": "test-dir","model_version": "1","outputs": [{"name": "Plus214_Output_0","shape": [1, 10],"datatype": "FP32","data": [-8.233053207397461, -7.749703407287598, -3.4236814975738527, 12.363029479980469, -12.079103469848633, 17.2665958404541, -10.570976257324219, 0.7130761742591858, 3.3217151165008547, 1.3621227741241456]}]}  #robocop: disable
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
    ...    namespace=${TEST_NS}
    # File is not needed anymore after applying
    Remove File    ${INFERENCESERVICE_FILLED_FILEPATH}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${TEST_NS}
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
    ...    end_point=/v2/models/${model_name}/infer  retries=10

Verify User Can Deploy Custom Runtime For Upgrade
    [Tags]  Upgrade
    Create Custom Serving Runtime Using Template By CLI   tests/Resources/Files/caikit_runtime_template.yaml
    Begin Web Test
    Menu.Navigate To Page    Settings    Serving runtimes
    Wait Until Page Contains   Add serving runtime    timeout=15s
    Page Should Contain Element  //tr[@id='caikit-runtime']
    [Teardown]   Dashboard Test Teardown

*** Keywords ***
Dashboard Suite Setup
    [Documentation]  Basic suite setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Dashboard Test Teardown
    [Documentation]  Basic suite teardown
    Close All Browsers
