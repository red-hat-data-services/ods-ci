*** Settings ***
Library           OperatingSystem
Resource          ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Suite Setup       Model Serving Suite Setup
Suite Teardown    Model Serving Suite Teardown


*** Variables ***
${RHODS_NAMESPACE}=    redhat-ods-applications
${INFERENCE_INPUT}=    @tests/Resources/Files/modelmesh-mnist-input.json
${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"test-model__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}
${PRJ_TITLE}=    model-serving-project
${PRJ_DESCRIPTION}=    project used for model serving tests
${MODEL_NAME}=    test-model


*** Test Cases ***
Verify Model Serving Installation
    [Documentation]    Verifies that the core components of model serving have been
    ...    deployed in the redhat-ods-applications namespace
    [Tags]    Smoke
    ...    ODS-1919
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify odh-model-controller Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify ModelMesh Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Etcd Pod

Verify Model Can Be Deployed Via UI
    [Documentation]    Verifies that a model can be deployed using only the UI.
    ...    At the end of the process, verifies the correct resources have been deployed.
    [Tags]    Sanity    Tier1
    ...    ODS-1921
    Open Model Serving Home Page
    # Verify No Models Are Present
    Click Button    Create server
    Wait Until Page Contains    Data science projects
    Wait Until Page Contains Element    //button[.="Create data science project"]
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=onnx    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=mnist-8.onnx
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Openvino Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success

Test Inference With Token Authentication
    [Documentation]    Test the inference result after having deployed a model that requires Token Authentication
    [Tags]    Sanity    Tier1
    ...    ODS-1920
    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}
    # Testing the same endpoint without token auth, should receive login page
    Open Model Serving Home Page
    ${out}=    Get Model Inference   ${MODEL_NAME}    ${INFERENCE_INPUT}    token_auth=${FALSE}
    Should Contain    ${out}    <button type="submit" class="btn btn-lg btn-primary">Log in with OpenShift</button>

*** Keywords ***
Model Serving Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}

Verify Etcd Pod
    [Documentation]    Verifies the correct deployment of the etcd pod in the rhods namespace
    ${etcd_name} =    Run    oc get pod -l app=model-mesh,app.kubernetes.io/part-of=model-mesh -n ${RHODS_NAMESPACE} | grep etcd | awk '{split($0, a); print a[1]}'
    ${etcd_running} =    Run    oc get pod ${etcd_name} -n ${RHODS_NAMESPACE} | grep 1/1 -o
    Should Be Equal As Strings    ${etcd_running}    1/1

Verify Serving Service
    [Documentation]    Verifies the correct deployment of the serving service in the project namespace
    [Arguments]    ${project_name}=${PRJ_TITLE}
    ${service} =    Oc Get    kind=Service    namespace=${project_name}    label_selector=modelmesh-service=modelmesh-serving
    Should Not Be Equal As Strings    Error from server (NotFound): services "modelmesh-serving" not found    ${service}

Verify ModelMesh Deployment
    [Documentation]    Verifies the correct deployment of modelmesh in the rhods namespace
    @{modelmesh_controller} =  Oc Get    kind=Pod    namespace=${RHODS_NAMESPACE}    label_selector=control-plane=modelmesh-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${modelmesh_controller}  3  1  ${containerNames}

Verify odh-model-controller Deployment
    [Documentation]    Verifies the correct deployment of the model controller in the rhods namespace
    @{odh_model_controller} =  Oc Get    kind=Pod    namespace=${RHODS_NAMESPACE}    label_selector=control-plane=odh-model-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${odh_model_controller}  3  1  ${containerNames}

Verify Openvino Deployment
    [Documentation]    Verifies the correct deployment of the ovms server pod(s) in the rhods namespace
    [Arguments]    ${project_name}=${PRJ_TITLE}    ${num_replicas}=1
    @{ovms} =  Oc Get    kind=Pod    namespace=${project_name}   label_selector=name=modelmesh-serving-model-server-${project_name}
    ${containerNames} =  Create List  rest-proxy  oauth-proxy  ovms  ovms-adapter  mm
    Verify Deployment    ${ovms}  ${num_replicas}  5  ${containerNames}
    ${all_ready} =    Run    oc get deployment -n ${project_name} -l name=modelmesh-serving-model-server-${project_name} | grep ${num_replicas}/${num_replicas} -o
    Should Be Equal As Strings    ${all_ready}    ${num_replicas}/${num_replicas}

Model Serving Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    # Even if kw fails, deleting the whole project will also delete the model
    # Failure will be shown in the logs of the run nonetheless
    Run Keyword And Continue On Failure    Delete Model Via UI    test-model
    Close All Browsers
    ${projects}=    Create List    ${PRJ_TITLE}
    Delete Data Science Projects From CLI   ocp_projects=${projects}
    RHOSi Teardown