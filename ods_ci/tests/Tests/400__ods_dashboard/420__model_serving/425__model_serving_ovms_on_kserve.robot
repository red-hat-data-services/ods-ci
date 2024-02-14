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
${PRJ_TITLE}=    model-serving-project
${PRJ_DESCRIPTION}=    project used for model serving tests
${MODEL_CREATED}=    ${FALSE}
${MODEL_NAME}=    test-model
${RUNTIME_NAME}=    Model Serving Test
${SECOND_PROJECT}=    sec-model-serving-project
${SECURED_MODEL}=    test-model-secured
${SECURED_RUNTIME}=    Model Serving With Authentication
${EXPECTED_INFERENCE_SECURED_OUTPUT}=    {"model_name":"${SECURED_MODEL}__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}
${EXPECTED_INFERENCE_OUTPUT_OPENVINO}=    {"model_name":"${MODEL_NAME}__isvc-8655dc7979","model_version":"1","outputs":[{"name":"Func/StatefulPartitionedCall/output/_13:0","datatype":"FP32","shape":[1,1],"data":[0.99999994]}]}


*** Test Cases ***
Verify Openvino_IR Model Via UI
    [Documentation]    Test the deployment of an openvino_ir model
    [Tags]    Smoke
    ...    ODS-2054    ODS-2053
    Create Openvino Models For Kserve    server_name=${RUNTIME_NAME}    model_name=${MODEL_NAME}
    ...    project_name=${PRJ_TITLE}   num_projects=1
    Run Keyword And Continue On Failure    Verify Model Inference    ${MODEL_NAME}    ${INFERENCE_INPUT_OPENVINO}
    ...    ${EXPECTED_INFERENCE_OUTPUT_OPENVINO}    token_auth=${FALSE}
    Clean All Models Of Current User
    [Teardown]    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${MODEL_NAME}    project_title=${PRJ_TITLE}

Verify Tensorflow Model Via UI
    [Documentation]    Test the deployment of a tensorflow (.pb) model
    [Tags]    Sanity    Tier1
    ...    ODS-2268    ProductBug    RHOAIENG-2869
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}    existing_project=${TRUE}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${MODEL_NAME}     serving_runtime=OpenVINO Model Server
    ...    data_connection=model-serving-connection    path=tf-kserve    model_framework=tensorflow - 2
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${MODEL_NAME}
    ...    namespace=${PRJ_TITLE}
    Verify Model Status    ${MODEL_NAME}    success
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    ${url}=    Get Model Route via UI    ${MODEL_NAME}
    ${status_code}    ${response_text}=    Send Random Inference Request     endpoint=${url}    name=input
    ...    shape={"B": 1, "H": 299, "W": 299, "C": 3}    no_requests=1
    Should Be Equal As Strings    ${status_code}    200
    Clean All Models Of Current User
    [Teardown]    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${MODEL_NAME}    project_title=${PRJ_TITLE}

Verify Secure Model Can Be Deployed In Same Project
    [Documentation]    Verifies that a model can be deployed in a secured server (with token) using only the UI.
    ...    At the end of the process, verifies the correct resources have been deployed.
    [Tags]    Sanity    Tier1
    ...    ODS-1921    ProductBug    RHOAIENG-2759
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}    existing_project=${TRUE}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${SECURED_MODEL}    serving_runtime=OpenVINO Model Server
    ...    data_connection=model-serving-connection    path=test-dir    model_framework=onnx
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${SECURED_MODEL}
    ...    namespace=${PRJ_TITLE}
    Verify Model Status    ${SECURED_MODEL}    success
    Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    Clean All Models Of Current User
    [Teardown]    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${SECURED_MODEL}    project_title=${PRJ_TITLE}

Test Inference With Token Authentication
    [Documentation]    Test the inference result after having deployed a model that requires Token Authentication
    [Tags]    Sanity    Tier1
    ...    ODS-1920
    Open Data Science Projects Home Page
    Create Data Science Project    title=${SECOND_PROJECT}    description=${PRJ_DESCRIPTION}    existing_project=${FALSE}
    Recreate S3 Data Connection    project_title=${SECOND_PROJECT}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${SECURED_MODEL}    serving_runtime=OpenVINO Model Server
    ...    data_connection=model-serving-connection    path=test-dir    model_framework=onnx
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${SECURED_MODEL}
    ...    namespace=${SECOND_PROJECT}
    Run Keyword And Continue On Failure    Verify Model Inference With Retries
    ...    ${SECURED_MODEL}    ${INFERENCE_INPUT}    ${EXPECTED_INFERENCE_SECURED_OUTPUT}    token_auth=${FALSE}
    ...    project_title=${SECOND_PROJECT}
    Clean All Models Of Current User
    [Teardown]    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${SECURED_MODEL}    project_title=${SECOND_PROJECT}

Verify Multiple Projects With Same Model
    [Documentation]    Test the deployment of multiple DS project with same openvino_ir model
    [Tags]    Sanity
    ...    RHOAIENG-549    RHOAIENG-2724
    Create Openvino Models For Kserve    server_name=${RUNTIME_NAME}    model_name=${MODEL_NAME}
    ...    project_name=${PRJ_TITLE}    num_projects=5
    Clean All Models Of Current User
    [Teardown]    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${MODEL_NAME}    project_title=${PRJ_TITLE}

*** Keywords ***
Model Serving Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Fetch CA Certificate If RHODS Is Self-Managed
    Clean All Models Of Current User

Create Openvino Models For Kserve
    [Documentation]    Create Openvino model in N projects (more than 1 will add index to project name)
    [Arguments]    ${server_name}=${RUNTIME_NAME}    ${model_name}=${MODEL_NAME}    ${project_name}=${PRJ_TITLE}
    ...    ${num_projects}=1    ${token}=${FALSE}
    ${project_postfix}=    Set Variable    ${EMPTY}
    FOR  ${idx}  IN RANGE  0  ${num_projects}
        ${new_project}=    Set Variable    ${project_name}${project_postfix}
        Log To Console    Creating new DS Project '${new_project}' with Model '${model_name}'
        Open Data Science Projects Home Page
        Create Data Science Project    title=${new_project}    description=${PRJ_DESCRIPTION}    existing_project=${TRUE}
        Recreate S3 Data Connection    project_title=${new_project}    dc_name=model-serving-connection
        ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
        ...            aws_bucket_name=ods-ci-s3
        Deploy Kserve Model Via UI    model_name=${model_name}    serving_runtime=OpenVINO Model Server
        ...    data_connection=model-serving-connection    path=kserve-openvino-test/openvino-example-model
        ...    model_framework=openvino_ir
        Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
        ...    namespace=${new_project}
        Verify Model Status    ${model_name}    success
        ${project_postfix}=    Evaluate  ${idx}+1
        Set Suite Variable    ${MODEL_CREATED}    ${TRUE}
    END

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
