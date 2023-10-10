*** Settings ***
Documentation     Collection of tests to validate the model serving stack for Large Language Models (LLM)
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettingsRuntimes.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Suite Setup       Custom Serving Runtime Suite Setup
Suite Teardown    Custom Serving Runtime Suite Teardown


*** Variables ***
${RESOURCES_DIRPATH}=        ods_ci/tests/Resources/Files
${OVMS_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/ovms_servingruntime.yaml
${UPLOADED_OVMS_DISPLAYED_NAME}=    ODS-CI Custom OpenVINO Model Server
${PRJ_TITLE}=    CustomServingRuntimesProject
${PRJ_DESCRIPTION}=    ODS-CI DS Project for testing of Custom Serving Runtimes
${MODEL_SERVER_NAME}=    ODS-CI CustomServingRuntime Server


*** Test Cases ***
Verify RHODS Admins Can Import A Custom Serving Runtime Template By Uploading A YAML file
    [Tags]    Smoke    ODS-2276
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${OVMS_RUNTIME_FILEPATH}
    Serving Runtime Template Should Be Listed    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}

Verify RHODS Admins Can Delete A Custom Serving Runtime Template
    [Tags]    Smoke    ODS-2279
    [Setup]    Create Test Serving Runtime Template If Not Exists
    Open Dashboard Settings    settings_page=Serving runtimes
    Delete Serving Runtime Template    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}
    ...    press_cancel=${TRUE}
    Delete Serving Runtime Template    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}

Verify RHODS Users Can Deploy A Model Using A Custom Serving Runtime
    [Documentation]    Verifies that a model can be deployed using only the UI.
    ...    At the end of the process, verifies the correct resources have been deployed.
    [Tags]    Sanity    ODS-2281
    [Setup]    Run Keywords
    ...    Create Test Serving Runtime Template If Not Exists
    ...    AND
    ...    Create Data Science Project If Not Exists    project_title=${PRJ_TITLE}    username=${TEST_USER_3.USERNAME}
    ...    description=${PRJ_DESCRIPTION}
    ${model_name}=    Set Variable    test-model-csr
    ${inference_input}=    Set Variable    @ods_ci/tests/Resources/Files/modelmesh-mnist-input.json
    ${exp_inference_output}=    Set Variable    {"model_name":"test-model-csr__isvc-85fe09502b","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}
    Open Data Science Project Details Page    project_title=${PRJ_TITLE}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server    server_name=${MODEL_SERVER_NAME}    runtime=${UPLOADED_OVMS_DISPLAYED_NAME}
    Serve Model    project_name=${PRJ_TITLE}    model_name=${model_name}    framework=onnx    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=mnist-8.onnx
    Wait Until Runtime Pod Is Running    server_name=${MODEL_SERVER_NAME}
    ...    project_title=${PRJ_TITLE}
    Verify Model Status    ${model_name}    success
    Verify Model Inference    ${model_name}    ${inference_input}    ${exp_inference_output}    token_auth=${TRUE}
    ...    project_title=${PRJ_TITLE}


*** Keywords ***
Custom Serving Runtime Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    Launch Data Science Project Main Page    username=${TEST_USER_3.USERNAME}
    RHOSi Setup
    Fetch CA Certificate If RHODS Is Self-Managed

Custom Serving Runtime Suite Teardown
    Delete Data Science Project From CLI    displayed_name=${PRJ_TITLE}
    Delete Serving Runtime Template From CLI    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown

Create Test Serving Runtime Template If Not Exists
    ${resource_name}=    Get OpenShift Template Resource Name By Displayed Name    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}
    IF    "${resource_name}" == "${EMPTY}"
        Log    message=Creating the necessary Serving Runtime as part of Test Setup.
        Open Dashboard Settings    settings_page=Serving runtimes
        Upload Serving Runtime Template    runtime_filepath=${OVMS_RUNTIME_FILEPATH}
        Serving Runtime Template Should Be Listed    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}        
    END
