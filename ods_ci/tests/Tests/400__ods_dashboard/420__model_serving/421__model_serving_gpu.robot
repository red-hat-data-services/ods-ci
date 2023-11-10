*** Settings ***
Library           OperatingSystem
Library           ../../../../libs/Helpers.py
Resource          ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Suite Setup       Model Serving Suite Setup
Suite Teardown    Model Serving Suite Teardown


*** Variables ***
${RHODS_NAMESPACE}=    ${APPLICATIONS_NAMESPACE}
${PRJ_TITLE}=    model-serving-project-gpu
${PRJ_DESCRIPTION}=    project used for model serving tests (with GPUs)
${MODEL_NAME}=    vehicle-detection
${MODEL_CREATED}=    False
${RUNTIME_NAME}=    Model Serving GPU Test


*** Test Cases ***
Verify GPU Model Deployment Via UI
    [Documentation]    Test the deployment of an openvino_ir model on a model server with GPUs attached
    [Tags]    Sanity    Tier1    Resources-GPU
    ...    ODS-2214
    Open Model Serving Home Page
    Try Opening Create Server
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data science projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}
    ...    no_gpus=1    runtime=OpenVINO Model Server (Supports GPUs)
    Verify Displayed GPU Count    server_name=${RUNTIME_NAME}    no_gpus=1
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=openvino_ir    existing_data_connection=${TRUE}  # robocop:disable
    ...    data_connection_name=model-serving-connection    model_path=vehicle-detection    model_server=${RUNTIME_NAME}
    ${runtime_pod_name} =    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${runtime_pod_name}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    ${requests} =    Get Container Requests    namespace=${PRJ_TITLE}
    ...    label=name=modelmesh-serving-${runtime_pod_name}    container_name=ovms
    Should Contain    ${requests}    "nvidia.com/gpu": "1"
    ${node} =    Get Node Pod Is Running On    namespace=${PRJ_TITLE}    label=name=modelmesh-serving-${runtime_pod_name}
    ${type} =    Get Instance Type Of Node    ${node}
    Should Be Equal As Strings    ${type}    "g4dn.xlarge"
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    True

Test Inference Load On GPU
    [Documentation]    Test the inference load on the GPU after sending random requests to the endpoint
    [Tags]    Sanity    Tier1    Resources-GPU
    ...    ODS-2213
    ${url}=    Get Model Route via UI    ${MODEL_NAME}
    Send Random Inference Request     endpoint=${url}    no_requests=100
    # Verify metric DCGM_FI_PROF_GR_ENGINE_ACTIVE goes over 0
    ${prometheus_route} =    Get OpenShift Prometheus Route
    ${sa_token} =    Get OpenShift Prometheus Service Account Token
    ${expression} =    Set Variable    DCGM_FI_PROF_GR_ENGINE_ACTIVE
    ${resp} =    Prometheus.Run Query    ${prometheus_route}    ${sa_token}    ${expression}
    Log    DCGM_FI_PROF_GR_ENGINE_ACTIVE: ${resp.json()["data"]["result"][0]["value"][-1]}
    Should Be True    ${resp.json()["data"]["result"][0]["value"][-1]} > ${0}

*** Keywords ***
Model Serving Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}

Verify Serving Service
    [Documentation]    Verifies the correct deployment of the serving service in the project namespace
    [Arguments]    ${project_name}=${PRJ_TITLE}
    ${service} =    Oc Get    kind=Service    namespace=${project_name}    label_selector=modelmesh-service=modelmesh-serving
    Should Not Be Equal As Strings    Error from server (NotFound): services "modelmesh-serving" not found    ${service}

Verify Openvino Deployment
    [Documentation]    Verifies the correct deployment of the ovms server pod(s) in the rhods namespace
    [Arguments]    ${runtime_name}    ${project_name}=${PRJ_TITLE}    ${num_replicas}=1
    @{ovms} =  Oc Get    kind=Pod    namespace=${project_name}   label_selector=name=modelmesh-serving-${runtime_name}
    ${containerNames} =  Create List  rest-proxy  oauth-proxy  ovms  ovms-adapter  mm
    Verify Deployment    ${ovms}  ${num_replicas}  5  ${containerNames}
    ${all_ready} =    Run    oc get deployment -n ${project_name} -l name=modelmesh-serving-${runtime_name} | grep ${num_replicas}/${num_replicas} -o  # robocop:disable
    Should Be Equal As Strings    ${all_ready}    ${num_replicas}/${num_replicas}

Model Serving Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    # Even if kw fails, deleting the whole project will also delete the model
    # Failure will be shown in the logs of the run nonetheless
    IF    ${MODEL_CREATED}
        Run Keyword And Continue On Failure    Delete Model Via UI    ${MODEL_NAME}
        ${projects}=    Create List    ${PRJ_TITLE}
        Delete Data Science Projects From CLI   ocp_projects=${projects}
    ELSE
        Log    Model not deployed, skipping deletion step during teardown    console=true
    END
    Close All Browsers
    RHOSi Teardown

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

Try Opening Create Server
    [Documentation]    Tries to clean up DSP and Model Serving pages
    ...    In order to deploy a single model in a new project. ${retries}
    ...    controls how many retries are made.
    [Arguments]    ${retries}=3
    FOR    ${try}    IN RANGE    0    ${retries}
        ${status} =    Run Keyword And Return Status    Page Should Contain    Select a project
        IF    ${status}
            Click Button    Select a project
            RETURN
        ELSE
            Clean Up Model Serving Page
            Clean Up DSP Page
            Open Model Serving Home Page
            Reload Page
            Sleep  5s
        END
    END

Get OpenShift Prometheus Route
    [Documentation]    Fetches the route for the Prometheus instance of openshift-monitoring
    ${host} =    Run    oc get route prometheus-k8s -n openshift-monitoring -o json | jq '.status.ingress[].host'
    ${host} =    Strip String    ${host}    characters="
    ${route} =    Catenate    SEPARATOR=    https://    ${host}
    RETURN    ${route}

Get OpenShift Prometheus Service Account Token
    [Documentation]    Returns a token for a service account to be used with Prometheus
    ${token} =    Run    oc create token prometheus-k8s -n openshift-monitoring --duration 10m
    RETURN    ${token}
