# robocop: off=too-long-test-case,too-many-calls-in-test-case,wrong-case-in-keyword-name
*** Settings ***
Documentation     Suite of test cases for OVMS in Kserve and ModelMesh
Library           OperatingSystem
Library           ../../../libs/Helpers.py
Resource          ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource          ../../Resources/Page/ODH/Monitoring/Monitoring.resource
Resource          ../../Resources/OCP.resource
Resource          ../../Resources/CLI/ModelServing/modelmesh.resource
Test Teardown     Cross Auth Test Teardown
Test Tags             Sanity  ProductBug


*** Variables ***
${INFERENCE_INPUT}=    @tests/Resources/Files/modelmesh-mnist-input.json
${PRJ_TITLE}=    cross-auth-prj
${PRJ_DESCRIPTION}=    project used for validating cross-auth CVE
${MODEL_CREATED}=    ${FALSE}
${MODEL_NAME}=    test-model
${SECOND_MODEL_NAME}=    ${MODEL_NAME}-second
${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"${MODEL_NAME}__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}  #robocop: disable
${SECOND_EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"${SECOND_MODEL_NAME}__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}  #robocop: disable
${FIRST_SERVICE_ACCOUNT}=    first_account
${SECOND_SERVICE_ACCOUNT}=    second_account


*** Test Cases ***
Test Cross Model Authentication On Kserve
    [Documentation]    Tests for the presence of CVE-2024-7557 when using Kserve
    [Tags]  Kserve       RHOAIENG-11007    RHOAIENG-12048
    Set Test Variable    $serving_mode  kserve
    Set Test Variable    $project_name  ${PRJ_TITLE}-${serving_mode}
    Template with embedded arguments

Test Cross Model Authentication On ModelMesh
    [Documentation]    Tests for the presence of CVE-2024-7557 when using ModelMesh
    [Tags]  ModelMesh    RHOAIENG-11007      RHOAIENG-12853
    Set Test Variable    $serving_mode  modelmeshserving
    Set Test Variable    $project_name  ${PRJ_TITLE}-${serving_mode}
    Template with embedded arguments


*** Keywords ***
Template with embedded arguments    # robocop: off=too-many-calls-in-keyword
    [Documentation]    Template for cross-auth test cases
    Cross Auth Test Setup
    ${single_model}=    Set Variable If    "${serving_mode}" == "kserve"    ${True}    ${False}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${project_name}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Cross Auth Model Deployment     single_model=${single_model}
    ...     model_name=${MODEL_NAME}  service_account_name=${FIRST_SERVICE_ACCOUNT}

    ${first_token}=  Get Access Token Via UI    service_account_name=${FIRST_SERVICE_ACCOUNT}    
    ...    single_model=${single_model}    model_name=${MODEL_NAME}     project_name=${project_name}
    ...    multi_model_servers=not ${single_model}

    Cross Auth Model Deployment     single_model=${single_model}
    ...     model_name=${SECOND_MODEL_NAME}     service_account_name=${SECOND_SERVICE_ACCOUNT}

    ${second_token}=  Get Access Token Via UI    service_account_name=${SECOND_SERVICE_ACCOUNT}
    ...    single_model=${single_model}    model_name=${SECOND_MODEL_NAME}     project_name=${project_name}
    ...    multi_model_servers=not ${single_model}

    Verify Model Inference    model_name=${MODEL_NAME}    inference_input=${INFERENCE_INPUT}
    ...    expected_inference_output=${EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}    token=${first_token}
    ...    project_title=${project_name}

    Verify Model Inference    model_name=${SECOND_MODEL_NAME}    inference_input=${INFERENCE_INPUT}
    ...    expected_inference_output=${SECOND_EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}    token=${second_token}
    ...    project_title=${project_name}

    # Should not be able to query first model with second token
    # Will fail at this step until CVE is fixed from dashboard side
    ${inf_out}=  Get Model Inference    model_name=${MODEL_NAME}    inference_input=${INFERENCE_INPUT}
    ...    token_auth=${TRUE}    token=${second_token}
    Run Keyword And Warn On Failure    Should Contain    ${inf_out}    Log in with OpenShift
    ${inf_out}=  Get Model Inference    model_name=${SECOND_MODEL_NAME}    inference_input=${INFERENCE_INPUT}
    ...    token_auth=${TRUE}    token=${first_token}
    Run Keyword And Warn On Failure    Should Contain    ${inf_out}    Log in with OpenShift

Cross Auth Model Deployment    # robocop: off=too-many-calls-in-keyword
    [Documentation]    Deploys a model with cross auth enabled
    [Arguments]    ${single_model}  ${model_name}   ${service_account_name}
    ${dc_name}=     Set Variable    model-serving-connection-${serving_mode}
    Recreate S3 Data Connection    project_title=${project_name}    dc_name=${dc_name}
    ...     aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...     aws_bucket_name=ods-ci-s3
    Open Data Science Project Details Page    ${project_name}    tab_id=model-server
    IF    ${single_model}
        Deploy Kserve Model Via UI    model_name=${model_name}    serving_runtime=OpenVINO Model Server
        ...    data_connection=${dc_name}    path=test-dir    model_framework=onnx
        ...    service_account_name=${service_account_name}    token=${TRUE}
        Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
        ...    namespace=${project_name}
    ELSE
        Create Model Server    token=${TRUE}    server_name=${model_name}   service_account_name=${service_account_name}
        sleep    1m
        Deploy Model From Models Tab    project_name=${project_name}    model_name=${model_name}    framework=onnx
        ...    existing_data_connection=${TRUE}    data_connection_name=${dc_name}      model_server=${model_name}
        ...    model_path=mnist-8.onnx
        Wait Until Keyword Succeeds    5 min  10 sec  Verify Openvino Deployment    runtime_name=${model_name}
        ...    project_name=${project_name}
        Wait Until Keyword Succeeds    5 min  10 sec  Verify Serving Service    project_name=${project_name}
        Verify Model Status    model_name=${model_name}    expected_status=success
    END

Cross Auth Test Setup
    [Documentation]    Test setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup

    Set Library Search Order    SeleniumLibrary
    Skip If Component Is Not Enabled    ${serving_mode}
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Fetch Knative CA Certificate    filename=openshift_ca_istio_knative.crt
    Clean All Models Of Current User

Cross Auth Test Teardown
    [Documentation]    Test teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Run Keywords    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${MODEL_NAME}    project_title=${project_name}    AND    Clean All Models Of Current User

    # Even if kw fails, deleting the whole project will also delete the model
    # Failure will be shown in the logs of the run nonetheless
    IF    ${MODEL_CREATED}
        Clean All Models Of Current User
    ELSE
        Log    Model not deployed, skipping deletion step during teardown    console=true
    END
    ${projects}=    Create List    ${project_name}
    Delete List Of Projects Via CLI   ocp_projects=${projects}
    # Will only be present on SM cluster runs, but keyword passes
    # if file does not exist
    Remove File    openshift_ca_istio_knative.crt
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown
