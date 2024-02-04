*** Settings ***
Library           OperatingSystem
Library           ../../../../libs/Helpers.py
Resource          ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../../Resources/CLI/ModelServing/modelmesh.resource
Suite Setup       Model Serving Suite Setup
Suite Teardown    Model Serving Suite Teardown
Test Tags         ModelMesh

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
    Clean All Models Of Current User
    Open Data Science Projects Home Page
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data Science Projects
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}
    ...    no_gpus=1
    Verify Displayed GPU Count    server_name=${RUNTIME_NAME}    no_gpus=1
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_NAME}    framework=openvino_ir    existing_data_connection=${TRUE}  # robocop:disable
    ...    data_connection_name=model-serving-connection    model_path=vehicle-detection
    ...    model_server=${RUNTIME_NAME}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds
    ...  5 min  10 sec  Verify Openvino Deployment    runtime_name=${RUNTIME_POD_NAME}
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    ${requests} =    Get Container Requests    namespace=${PRJ_TITLE}
    ...    label=name=modelmesh-serving-${RUNTIME_POD_NAME}    container_name=ovms
    Should Contain    ${requests}    "nvidia.com/gpu": "1"
    ${node} =    Get Node Pod Is Running On    namespace=${PRJ_TITLE}
    ...    label=name=modelmesh-serving-${RUNTIME_POD_NAME}
    ${type} =    Get Instance Type Of Node    ${node}
    Should Be Equal As Strings    ${type}    "g4dn.xlarge"
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    True
    [Teardown]    Run Keyword If Test Failed    Get Events And Pod Logs    namespace=${PRJ_TITLE}
    ...    label_selector=name=modelmesh-serving-${RUNTIME_POD_NAME}


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
    ${runtime_pod_name} =    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Set Suite Variable    ${RUNTIME_POD_NAME}    ${runtime_pod_name}
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}

Model Serving Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    # Even if kw fails, deleting the whole project will also delete the model
    # Failure will be shown in the logs of the run nonetheless
    IF    ${MODEL_CREATED}
        Run Keyword And Continue On Failure    Delete Model Via UI    ${MODEL_NAME}    ${PRJ_TITLE}
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
        Wait Until Page Contains    Data Science Projects
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
