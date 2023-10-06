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
Suite Setup        Dashboard Suite Setup
Suite Teardown     RHOSi Teardown


*** Variables ***
${CUSTOM_CULLER_TIMEOUT}      60000
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
    Oc Apply    kind=ImageStream   src=ods_ci/tests/Tests/100__deploy/120__upgrades/custome_image.yaml

Verify User Can Disable The Runtime
    [Documentation]  Disable the Serving runtime using Cli
    [Tags]  Upgrade
    Disable Model Serving Runtime Using CLI   namespace=redhat-ods-applications

Verify Model Can Be Deployed Via UI For Upgrade
    [Tags]  Upgrade
    [Setup]    Begin Web Test
    Fetch CA Certificate If RHODS Is Self-Managed
    Open Model Serving Home Page
    Try Opening Create Server
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data science projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=openvino_ir    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=openvino-example-model
    ${runtime_pod_name} =    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    True
    Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT_OPENVINO}    ${EXPECTED_INFERENCE_OUTPUT_OPENVINO}    token_auth=${FALSE}
    Remove File    openshift_ca.crt
    [Teardown]   Dashboard Test Teardown

Verify User Can Deploy Custom Runtime For Upgrade
    [Tags]  Upgrade
    Create Custom Serving Runtime Using Template By CLI   ods_ci/tests/Resources/Files/caikit_runtime_template.yaml
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

Try Opening Create Server
    [Documentation]    Tries to clean up DSP and Model Serving pages
    ...    In order to deploy a single model in a new project. ${retries}
    ...    controls how many retries are made.
    [Arguments]    ${retries}=3
    FOR    ${try}    IN RANGE    0    ${retries}
        ${status} =    Run Keyword And Return Status    Page Should Contain    Create server
        IF    ${status}
            Click Button    Create server
            RETURN
        ELSE
            Clean Up Model Serving Page
            Clean Up DSP Page
            Open Model Serving Home Page
            Reload Page
            Sleep  5s
        END
    END

Clean Up DSP Page
    [Documentation]    Removes all DSP Projects, if any are present
    Open Data Science Projects Home Page
    WHILE    ${TRUE}
        ${projects} =    Get All Displayed Projects
        IF    len(${projects})==0
            BREAK
        END
        Delete Data Science Projects From CLI    ${projects}
        Reload Page
        Wait Until Page Contains    Data science projects
    END

Verify Openvino Deployment
    [Documentation]    Verifies the correct deployment of the ovms server pod(s) in the rhods namespace
    [Arguments]    ${runtime_name}    ${project_name}=${PRJ_TITLE}    ${num_replicas}=1
    @{ovms} =  Oc Get    kind=Pod    namespace=${project_name}   label_selector=name=modelmesh-serving-${runtime_name}
    ${containerNames} =  Create List  rest-proxy  oauth-proxy  ovms  ovms-adapter  mm
    Verify Deployment    ${ovms}  ${num_replicas}  5  ${containerNames}
    ${all_ready} =    Run    oc get deployment -n ${project_name} -l name=modelmesh-serving-${runtime_name} | grep ${num_replicas}/${num_replicas} -o  # robocop:disable
    Should Be Equal As Strings    ${all_ready}    ${num_replicas}/${num_replicas}

Verify Serving Service
    [Documentation]    Verifies the correct deployment of the serving service in the project namespace
    [Arguments]    ${project_name}=${PRJ_TITLE}
    ${service} =    Oc Get    kind=Service    namespace=${project_name}    label_selector=modelmesh-service=modelmesh-serving
    Should Not Be Equal As Strings    Error from server (NotFound): services "modelmesh-serving" not found    ${service}
