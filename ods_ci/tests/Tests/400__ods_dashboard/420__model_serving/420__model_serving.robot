*** Settings ***
Library           OperatingSystem
Library           ../../../../libs/Helpers.py
Resource          ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/CLI/ModelServing/modelmesh.resource
Suite Setup       Model Serving Suite Setup
Suite Teardown    Model Serving Suite Teardown
Test Tags         ModelMesh

*** Variables ***
${INFERENCE_INPUT}=    @ods_ci/tests/Resources/Files/modelmesh-mnist-input.json
${INFERENCE_INPUT_OPENVINO}=    @ods_ci/tests/Resources/Files/openvino-example-input.json
${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"test-model__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}
${EXPECTED_INFERENCE_OUTPUT_OPENVINO}=    {"model_name":"test-model__isvc-8655dc7979","model_version":"1","outputs":[{"name":"Func/StatefulPartitionedCall/output/_13:0","datatype":"FP32","shape":[1,1],"data":[0.99999994]}]}
${PRJ_TITLE}=    model-serving-project
${PRJ_DESCRIPTION}=    project used for model serving tests
${MODEL_CREATED}=    ${FALSE}
${MODEL_NAME}=    test-model
${RUNTIME_NAME}=    Model Serving Test
${SECURED_MODEL}=    test-model-secured
${SECURED_RUNTIME}=    Model Serving With Authentication


*** Test Cases ***
Verify Model Serving Installation
    [Documentation]    Verifies that the core components of model serving have been
    ...    deployed in the ${APPLICATIONS_NAMESPACE} namespace
    [Tags]    Smoke
    ...       Tier1
    ...       OpenDataHub
    ...       ODS-1919
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify odh-model-controller Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify ModelMesh Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Etcd Pod

Verify Model Can Be Deployed Via UI
    [Documentation]    Verifies that a model can be deployed using only the UI.
    ...    At the end of the process, verifies the correct resources have been deployed.
    [Tags]    Sanity    Tier1
    ...    ODS-1921
    Open Data Science Projects Home Page
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}    reuse_existing=${TRUE}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    server_name=${RUNTIME_NAME}    reuse_existing=${TRUE}
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=onnx    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=mnist-8.onnx
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${RUNTIME_POD_NAME}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    True
    [Teardown]    Run Keyword If Test Failed    Get Events And Pod Logs    namespace=${PRJ_TITLE}
    ...    label_selector=name=modelmesh-serving-${RUNTIME_POD_NAME}

Test Inference With Token Authentication
    [Documentation]    Test the inference result after having deployed a model that requires Token Authentication
    [Tags]    Sanity    Tier1
    ...    ODS-1920
    # Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}    # robocop: disable
    Run Keyword And Continue On Failure    Verify Model Inference With Retries
    ...    ${MODEL_NAME}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}
    # Testing the same endpoint without token auth, should receive login page
    Open Model Serving Home Page
    ${out}=    Get Model Inference   ${MODEL_NAME}    ${INFERENCE_INPUT}    token_auth=${FALSE}
    Should Contain    ${out}    <button type="submit" class="btn btn-lg btn-primary">Log in with OpenShift</button>

Verify Openvino_IR Model Via UI
    [Documentation]    Test the deployment of an openvino_ir model
    [Tags]    Smoke
    ...    ODS-2054
    Open Data Science Projects Home Page
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}    existing_project=${TRUE}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}    existing_server=${TRUE}
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=openvino_ir    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=openvino-example-model
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${RUNTIME_POD_NAME}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    [Teardown]    Run Keyword If Test Failed    Get Events And Pod Logs    namespace=${PRJ_TITLE}
    ...    label_selector=name=modelmesh-serving-${RUNTIME_POD_NAME}

Test Inference Without Token Authentication
    [Documentation]    Test the inference result after having deployed a model that doesn't require Token Authentication
    [Tags]    Smoke
    ...    ODS-2053
    Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT_OPENVINO}    ${EXPECTED_INFERENCE_OUTPUT_OPENVINO}    token_auth=${FALSE}

Verify Tensorflow Model Via UI
    [Documentation]    Test the deployment of a tensorflow (.pb) model
    [Tags]    Sanity    Tier1
    ...    ODS-2268    RHOAIENG-2869
    Open Data Science Projects Home Page
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}    existing_project=${TRUE}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}    existing_server=${TRUE}
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=tensorflow    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=inception_resnet_v2.pb
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${RUNTIME_POD_NAME}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    ${url}=    Get Model Route via UI    ${MODEL_NAME}
    ${status_code}    ${response_text} =    Send Random Inference Request     endpoint=${url}    name=input
    ...    shape={"B": 1, "H": 299, "W": 299, "C": 3}    no_requests=1
    Should Be Equal As Strings    ${status_code}    200
    [Teardown]    Run Keyword If Test Failed    Get Events And Pod Logs    namespace=${PRJ_TITLE}
    ...    label_selector=name=modelmesh-serving-${RUNTIME_POD_NAME}

Verify Secure Model Can Be Deployed Via UI
    [Documentation]    Verifies that a model can be deployed using only the UI.
    ...    At the end of the process, verifies the correct resources have been deployed.
    [Tags]    Sanity    Tier1
    ...    ODS-1921    RHOAIENG-2759
    Open Data Science Projects Home Page
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}    existing_project=${TRUE}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${TRUE}    server_name=${SECURED_RUNTIME}    existing_server=${TRUE}
    Serve Model    project_name=${PRJ_TITLE}    model_name=${SECURED_MODEL}    model_server=${SECURED_RUNTIME}
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection    existing_model=${TRUE}
    ...    framework=onnx    model_path=mnist-8.onnx
    ${runtime_pod_name} =    Replace String Using Regexp    string=${SECURED_RUNTIME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Verify Model Status    ${SECURED_MODEL}    success
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}

Test Inference With Token Authentication
    [Documentation]    Test the inference result after having deployed a model that requires Token Authentication
    [Tags]    Sanity    Tier1
    ...    ODS-1920
    # Run Keyword And Continue On Failure    Verify Model Inference    ${SECURED_MODEL}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}    # robocop: disable
    Run Keyword And Continue On Failure    Verify Model Inference With Retries
    ...    ${SECURED_MODEL}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}
    # Testing the same endpoint without token auth, should receive login page
    Open Model Serving Home Page
    ${out}=    Get Model Inference   ${SECURED_MODEL}    ${INFERENCE_INPUT}    token_auth=${FALSE}
    Should Contain    ${out}    <button type="submit" class="btn btn-lg btn-primary">Log in with OpenShift</button>

Verify Multiple Projects With Same Model
    [Documentation]    Test the deployment of multiple DS project with same openvino_ir model
    [Tags]    Sanity
    ...    RHOAIENG-549    RHOAIENG-2724
    Create Openvino Models    num_projects=5

*** Keywords ***
Model Serving Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    Skip If Component Is Not Enabled    modelmeshserving
    RHOSi Setup
    ${runtime_pod_name} =    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Set Suite Variable    ${RUNTIME_POD_NAME}    ${runtime_pod_name}
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Fetch CA Certificate If RHODS Is Self-Managed
    Run Keyword And Ignore Error    Clean All Models Of Current User

Verify Etcd Pod
    [Documentation]    Verifies the correct deployment of the etcd pod in the rhods namespace
    ${etcd_name} =    Run    oc get pod -l component=model-mesh-etcd -n ${APPLICATIONS_NAMESPACE} | grep etcd | awk '{split($0, a); print a[1]}'
    ${etcd_running} =    Run    oc get pod ${etcd_name} -n ${APPLICATIONS_NAMESPACE} | grep 1/1 -o
    Should Be Equal As Strings    ${etcd_running}    1/1

Verify Serving Service
    [Documentation]    Verifies the correct deployment of the serving service in the project namespace
    [Arguments]    ${project_name}=${PRJ_TITLE}
    ${service} =    Oc Get    kind=Service    namespace=${project_name}    label_selector=modelmesh-service=modelmesh-serving
    Should Not Be Equal As Strings    Error from server (NotFound): services "modelmesh-serving" not found    ${service}

Verify ModelMesh Deployment
    [Documentation]    Verifies the correct deployment of modelmesh in the rhods namespace
    @{modelmesh_controller} =  Oc Get    kind=Pod    namespace=${APPLICATIONS_NAMESPACE}    label_selector=control-plane=modelmesh-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${modelmesh_controller}  3  1  ${containerNames}

Verify odh-model-controller Deployment
    [Documentation]    Verifies the correct deployment of the model controller in the rhods namespace
    @{odh_model_controller} =  Oc Get    kind=Pod    namespace=${APPLICATIONS_NAMESPACE}    label_selector=control-plane=odh-model-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${odh_model_controller}  3  1  ${containerNames}

Verify Openvino Deployment
    [Documentation]    Verifies the correct deployment of the ovms server pod(s) in the rhods namespace
    [Arguments]    ${runtime_name}    ${project_name}=${PRJ_TITLE}    ${num_replicas}=1
    @{ovms} =  Oc Get    kind=Pod    namespace=${project_name}   label_selector=name=modelmesh-serving-${runtime_name}
    ${containerNames} =  Create List  rest-proxy  oauth-proxy  ovms  ovms-adapter  mm
    Verify Deployment    ${ovms}  ${num_replicas}  5  ${containerNames}
    ${all_ready} =    Run    oc get deployment -n ${project_name} -l name=modelmesh-serving-${runtime_name} | grep ${num_replicas}/${num_replicas} -o  # robocop:disable
    Should Be Equal As Strings    ${all_ready}    ${num_replicas}/${num_replicas}

Create Openvino Models
    [Documentation]    Create Openvino model in N projects (more than 1 will add index to project name)
    [Arguments]    ${server_name}=${RUNTIME_NAME}    ${model_name}=${MODEL_NAME}    ${project_name}=${PRJ_TITLE}
    ...    ${num_projects}=1    ${token}=${FALSE}
    ${project_postfix}=    Set Variable    ${EMPTY}
    FOR  ${idx}  IN RANGE  0  ${num_projects}
        ${new_project}=    Set Variable    ${project_name}${project_postfix}
        Log To Console    Creating new DS Project '${new_project}' with Model '${model_name}'
        Open Data Science Projects Home Page
        Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
        Create Data Science Project    title=${new_project}    description=${PRJ_DESCRIPTION}    existing_project=${TRUE}
        Recreate S3 Data Connection    project_title=${new_project}    dc_name=model-serving-connection
        ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
        ...            aws_bucket_name=ods-ci-s3
        Create Model Server    token=${FALSE}    server_name=${server_name}    existing_server=${TRUE}
        Serve Model    project_name=${new_project}    model_name=${model_name}    framework=openvino_ir    existing_data_connection=${TRUE}
        ...    data_connection_name=model-serving-connection    model_path=openvino-example-model    existing_model=${TRUE}
        ${runtime_pod_name} =    Replace String Using Regexp    string=${server_name}    pattern=\\s    replace_with=-
        ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
        Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
        ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}    project_name=${new_project}
        Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service    ${new_project}
        Verify Model Status    ${model_name}    success
        ${project_postfix} =    Evaluate  ${idx}+1
    END
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}

Model Serving Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    # Even if kw fails, deleting the whole project will also delete the model
    # Failure will be shown in the logs of the run nonetheless
    IF    ${MODEL_CREATED}
        Clean All Models Of Current User
    ELSE
        Log    Model not deployed, skipping deletion step during teardown    console=true
    END
    ${projects}=    Create List    ${PRJ_TITLE}
    Delete Data Science Projects From CLI   ocp_projects=${projects}
    # Will only be present on SM cluster runs, but keyword passes
    # if file does not exist
    Remove File    openshift_ca.crt
    Close All Browsers
    RHOSi Teardown



