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
${MODEL_MESH_NAMESPACE}=    mesh-test
${ODH_NAMESPACE}=    redhat-ods-applications
${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"test-model__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}
#${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"example-onnx-mnist__isvc-b29c3d91f3","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}
${PRJ_TITLE}=    model-serving-project
${PRJ_DESCRIPTION}=    project used for model serving tests


*** Test Cases ***
Verify Model Serving Installation
    [Documentation]    Verifies Model Serving resources
    [Tags]    ModelMesh_Serving
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify odh-model-controller Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify ModelMesh Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Etcd Pod

Verify Model Can Be Deployed Via UI
    Open Model Serving Home Page
    # Verify No Models Are Present
    Click Button    Create server
    Wait Until Page Contains    Data science projects
    # Verify moved to DSP page
    Wait Until Page Contains Element    //button[.="Create data science project"]
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=test-model    framework=onnx    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=mnist-8.onnx
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Openvino Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    test-model    success

Test Inference
    [Documentation]    Test the inference result
    [Tags]    ModelMesh_Serving_Inference
    # //div[.="test-model-no-token "]/../../td[@data-label="Project"] (.= project name)
    # //div[.="test-model-no-token "]/../../td[@data-label="Inference endpoint"]//div[@class="pf-c-clipboard-copy__group"]/input (value=url)
    # //div[.="test-model-no-token "]/../../td[@data-label="Status"]//span[contains(@class,"pf-c-icon__content")] (class=status?) (pf-m-danger > failed)  (pf-m-danger) (pf-m-success)
    # //div[.="test-model-no-token "]/../../td[@data-label="Status"]//span[contains(@class,"pf-c-icon__content")]
    # //div[.="test-model-no-token "]/../../td[@class="pf-c-table__action"]//button
    # //div[.="test-model-no-token "]/../../td[@class="pf-c-table__action"]//button/..//button[.="Edit"]
    # //div[.="test-model-no-token "]/../../td[@class="pf-c-table__action"]//button/..//button[.="Delete"]
    ${url}=    Get Model Route via UI    test-model
    ${token}=    Get Access Token via UI    ${PRJ_TITLE}
    ${inference_output} =    Run    curl -ks ${url} -d @tests/Resources/Files/modelmesh-mnist-input.json -H "Authorization: Bearer ${token}"
    Should Be Equal As Strings    ${inference_output}    ${EXPECTED_INFERENCE_OUTPUT}

*** Keywords ***
Model Serving Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}

Verify Etcd Pod
    ${etcd_name} =    Run    oc get pod -l app=model-mesh,app.kubernetes.io/part-of=model-mesh -n ${ODH_NAMESPACE} | grep etcd | awk '{split($0, a); print a[1]}'
    ${etcd_running} =    Run    oc get pod ${etcd_name} -n ${ODH_NAMESPACE} | grep 1/1 -o
    Should Be Equal As Strings    ${etcd_running}    1/1

Verify Serving Service
    [Arguments]    ${project_name}=${PRJ_TITLE}
    ${service} =    Oc Get    kind=Service    namespace=${project_name}    label_selector=modelmesh-service=modelmesh-serving
    Should Not Be Equal As Strings    Error from server (NotFound): services "modelmesh-serving" not found    ${service}

Verify ModelMesh Deployment
    @{modelmesh_controller} =  Oc Get    kind=Pod    namespace=${ODH_NAMESPACE}    label_selector=control-plane=modelmesh-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${modelmesh_controller}  3  1  ${containerNames}

Verify odh-model-controller Deployment
    @{odh_model_controller} =  Oc Get    kind=Pod    namespace=${ODH_NAMESPACE}    label_selector=control-plane=odh-model-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${odh_model_controller}  3  1  ${containerNames}

Verify Openvino Deployment
    [Arguments]    ${project_name}=${PRJ_TITLE}    ${num_replicas}=1
    @{ovms} =  Oc Get    kind=Pod    namespace=${project_name}   label_selector=name=modelmesh-serving-model-server-${project_name}
    ${containerNames} =  Create List  rest-proxy  oauth-proxy  ovms  ovms-adapter  mm
    Verify Deployment    ${ovms}  ${num_replicas}  5  ${containerNames}
    ${all_ready} =    Run    oc get deployment -n ${project_name} -l name=modelmesh-serving-model-server-${project_name} | grep ${num_replicas}/${num_replicas} -o
    Should Be Equal As Strings    ${all_ready}    ${num_replicas}/${num_replicas}

Get Access Token via UI
    [Documentation]
    [Arguments]    ${project_name}    ${service_account_name}=default-name
    Open Data Science Projects Home Page
    Project Should Be Listed    ${project_name}
    Open Data Science Project Details Page    ${project_name}
    ${token}=    Get Model Serving Access Token via UI    ${service_account_name}
    Open Model Serving Home Page
    [Return]    ${token}

Model Serving Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Delete Model Via UI    test-model
    Close All Browsers
    ${projects}=    Create List    ${PRJ_TITLE}
    Delete Data Science Projects From CLI   ocp_projects=${projects}
    RHOSi Teardown