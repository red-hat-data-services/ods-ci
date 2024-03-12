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
    ...    serving_platform=multi
    Serving Runtime Template Should Be Listed    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}
    ...    serving_platform=multi

Verify RHODS Admins Can Delete A Custom Serving Runtime Template
    [Tags]    Smoke    ODS-2279
    [Setup]    Create Test Serving Runtime Template If Not Exists
    Open Dashboard Settings    settings_page=Serving runtimes
    Delete Serving Runtime Template    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}
    ...    press_cancel=${TRUE}
    Delete Serving Runtime Template    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}

Verify RHODS Admins Can Import A Custom Serving Runtime Template For Each Serving Platform
    [Documentation]    Imports a Custom Serving Runtime for each supported serving platform
    [Tags]    Sanity    ODS-2542    Tier1
    [Setup]    Generate Runtime YAMLs
    Open Dashboard Settings    settings_page=Serving runtimes
    ${RUNTIME_SINGLE_FILEPATH}=    Set Variable    ${RESOURCES_DIRPATH}/csr_single_model.yaml
    ${RUNTIME_MULTI_FILEPATH}=    Set Variable    ${RESOURCES_DIRPATH}/csr_multi_model.yaml
    Upload Serving Runtime Template    runtime_filepath=${RUNTIME_SINGLE_FILEPATH}
    ...    serving_platform=single
    Serving Runtime Template Should Be Listed    displayed_name=${RUNTIME_SINGLE_DISPLAYED_NAME}
    ...    serving_platform=single
    Upload Serving Runtime Template    runtime_filepath=${RUNTIME_MULTI_FILEPATH}
    ...    serving_platform=multi
    Serving Runtime Template Should Be Listed    displayed_name=${RUNTIME_MULTI_DISPLAYED_NAME}
    ...    serving_platform=multi
    [Teardown]    Run Keywords
    ...    Delete Serving Runtime Template From CLI    displayed_name=${RUNTIME_SINGLE_DISPLAYED_NAME}
    ...    AND
    ...    Delete Serving Runtime Template From CLI    displayed_name=${RUNTIME_MULTI_DISPLAYED_NAME}

Verify RHODS Users Can Deploy A Model Using A Custom Serving Runtime
    [Documentation]    Verifies that a model can be deployed using only the UI.
    ...    At the end of the process, verifies the correct resources have been deployed.
    [Tags]    Sanity    Tier1    ODS-2281    ModelMesh
    [Setup]    Run Keywords
    ...    Skip If Component Is Not Enabled    modelmeshserving
    ...    AND
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
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE}
    Create Model Server    server_name=${MODEL_SERVER_NAME}    runtime=${UPLOADED_OVMS_DISPLAYED_NAME}
    Serve Model    project_name=${PRJ_TITLE}    model_name=${model_name}    framework=onnx
    ...    existing_data_connection=${TRUE}    model_server=${MODEL_SERVER_NAME}
    ...    data_connection_name=model-serving-connection    model_path=mnist-8.onnx
    Wait Until Runtime Pod Is Running    server_name=${MODEL_SERVER_NAME}
    ...    project_title=${PRJ_TITLE}    timeout=5m
    Verify Model Status    ${model_name}    success
    Verify Model Inference With Retries    ${model_name}    ${inference_input}    ${exp_inference_output}
    ...    token_auth=${TRUE}
    ...    project_title=${PRJ_TITLE}
    [Teardown]    Run Keyword If Test Failed    Get Events And Pod Logs    namespace=${ns_name}
    ...    label_selector=name=modelmesh-serving-${RUNTIME_POD_NAME}


*** Keywords ***
Custom Serving Runtime Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    ${runtime_pod_name} =    Replace String Using Regexp    string=${MODEL_SERVER_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Set Suite Variable    ${RUNTIME_POD_NAME}    ${runtime_pod_name}
    Fetch CA Certificate If RHODS Is Self-Managed

Custom Serving Runtime Suite Teardown
    Delete Data Science Project From CLI    displayed_name=${PRJ_TITLE}
    Delete Serving Runtime Template From CLI    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}
    SeleniumLibrary.Close All Browsers
    Remove File    openshift_ca.crt
    RHOSi Teardown

Create Test Serving Runtime Template If Not Exists
    ${resource_name}=    Get OpenShift Template Resource Name By Displayed Name    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}
    IF    "${resource_name}" == "${EMPTY}"
        Log    message=Creating the necessary Serving Runtime as part of Test Setup.
        Open Dashboard Settings    settings_page=Serving runtimes
        Upload Serving Runtime Template    runtime_filepath=${OVMS_RUNTIME_FILEPATH}
        ...    serving_platform=multi
        Serving Runtime Template Should Be Listed    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}
        ...    serving_platform=multi
    END

Generate Runtime YAMLs
    [Documentation]    Generates three different Custom Serving Runtime YAML files
    ...                starting from OVMS one. Each YAML will be used for a different
    ...                supported serving platform (single model, multi model)
    Set Suite Variable    ${RUNTIME_SINGLE_FILEPATH}    ${RESOURCES_DIRPATH}/csr_single_model.yaml
    Set Suite Variable    ${RUNTIME_MULTI_FILEPATH}    ${RESOURCES_DIRPATH}/csr_multi_model.yaml
    Set Suite Variable    ${RUNTIME_SINGLE_DISPLAYED_NAME}    ODS-CI CSR - Single model Platform
    Set Suite Variable    ${RUNTIME_MULTI_DISPLAYED_NAME}    ODS-CI CSR - Multi models Platform
    Copy File    ${OVMS_RUNTIME_FILEPATH}    ${RUNTIME_SINGLE_FILEPATH}
    Copy File    ${OVMS_RUNTIME_FILEPATH}    ${RUNTIME_MULTI_FILEPATH}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    yq -i '.metadata.annotations."openshift.io/display-name" = "${RUNTIME_SINGLE_DISPLAYED_NAME}"' ${RUNTIME_SINGLE_FILEPATH}
    Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    yq -i '.metadata.name = "ods-ci-single"' ${RUNTIME_SINGLE_FILEPATH}
        ${rc}    ${out}=    Run And Return Rc And Output
    ...    yq -i '.metadata.annotations."openshift.io/display-name" = "${RUNTIME_MULTI_DISPLAYED_NAME}"' ${RUNTIME_MULTI_FILEPATH}
    Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    yq -i '.metadata.name = "ods-ci-multi"' ${RUNTIME_MULTI_FILEPATH}
    Should Be Equal As Integers    ${rc}    ${0}    msg=${out}

