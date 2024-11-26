# robocop: off=too-long-test-case,too-many-calls-in-test-case,wrong-case-in-keyword-name
*** Settings ***
Documentation     Suite of test cases for OVMS in Kserve
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
Suite Setup       Cross Auth On Kserve Suite Setup
Suite Teardown    Cross Auth On Kserve Suite Teardown
Test Tags         Kserve    Modelmesh


*** Variables ***
${INFERENCE_INPUT}=    @tests/Resources/Files/modelmesh-mnist-input.json
${PRJ_TITLE}=    cross-auth-prj
${PRJ_DESCRIPTION}=    project used for validating cross-auth CVE
${MODEL_CREATED}=    ${FALSE}
${MODEL_NAME}=    test-model
${SECOND_MODEL_NAME}=    test-model-second
${RUNTIME_NAME}=    Model Serving Test
${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"${MODEL_NAME}__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}  #robocop: disable
${SECOND_EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"${SECOND_MODEL_NAME}__isvc-83d6fab7bd","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}  #robocop: disable


*** Test Cases ***
Test Cross Model Authentication On Kserve
    [Documentation]    Tests for the presence of CVE-2024-7557 when using Kserve
    [Tags]    Sanity    ProductBug
    ...       RHOAIENG-11007    RHOAIENG-12048
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    existing_project=${FALSE}
    Recreate S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Deploy Kserve Model Via UI    model_name=${MODEL_NAME}    serving_runtime=OpenVINO Model Server
    ...    data_connection=model-serving-connection    path=test-dir    model_framework=onnx
    ...    service_account_name=first_account    token=${TRUE}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${MODEL_NAME}
    ...    namespace=${PRJ_TITLE}
    ${first_token}=  Get Model Serving Access Token via UI    service_account_name=first_account    single_model=${TRUE}
    ...    model_name=${MODEL_NAME}
    Deploy Kserve Model Via UI    model_name=${SECOND_MODEL_NAME}    serving_runtime=OpenVINO Model Server
    ...    data_connection=model-serving-connection    path=test-dir    model_framework=onnx
    ...    service_account_name=second_account    token=${TRUE}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${SECOND_MODEL_NAME}
    ...    namespace=${PRJ_TITLE}
    ${second_token}=  Get Model Serving Access Token via UI    service_account_name=second_account
    ...    single_model=${TRUE}    model_name=${SECOND_MODEL_NAME}
    Verify Model Inference    model_name=${MODEL_NAME}    inference_input=${INFERENCE_INPUT}
    ...    expected_inference_output=${EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}    token=${first_token}
    ...    project_title=${PRJ_TITLE}
    Verify Model Inference    model_name=${SECOND_MODEL_NAME}    inference_input=${INFERENCE_INPUT}
    ...    expected_inference_output=${SECOND_EXPECTED_INFERENCE_OUTPUT}    token_auth=${TRUE}    token=${second_token}
    ...    project_title=${PRJ_TITLE}
    # Should not be able to query first model with second token
    # Will fail at this step until CVE is fixed from dashboard side
    ${inf_out}=  Get Model Inference    model_name=${MODEL_NAME}    inference_input=${INFERENCE_INPUT}
    ...    token_auth=${TRUE}    token=${second_token}
    Run Keyword And Warn On Failure    Should Contain    ${inf_out}    Log in with OpenShift
    ${inf_out}=  Get Model Inference    model_name=${SECOND_MODEL_NAME}    inference_input=${INFERENCE_INPUT}
    ...    token_auth=${TRUE}    token=${first_token}
    Run Keyword And Warn On Failure    Should Contain    ${inf_out}    Log in with OpenShift
    [Teardown]    Run Keywords    Run Keyword If Test Failed    Get Kserve Events And Logs
    ...    model_name=${MODEL_NAME}    project_title=${PRJ_TITLE}    AND    model_name=${SECOND_MODEL_NAME}    project_title=${PRJ_TITLE}


*** Keywords ***
Cross Auth On Kserve Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Fetch Knative CA Certificate    filename=openshift_ca_istio_knative.crt
    Delete Project Via CLI By Display Name    displayed_name=ALL

Cross Auth On Kserve Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    # Even if kw fails, deleting the whole project will also delete the model
    # Failure will be shown in the logs of the run nonetheless
    IF    ${MODEL_CREATED}
        Delete Project Via CLI By Display Name    displayed_name=ALL
    ELSE
        Log    Model not deployed, skipping deletion step during teardown    console=true
    END
    ${projects}=    Create List    ${PRJ_TITLE}
    Delete List Of Projects Via CLI   ocp_projects=${projects}
    # Will only be present on SM cluster runs, but keyword passes
    # if file does not exist
    Remove File    openshift_ca_istio_knative.crt
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown
