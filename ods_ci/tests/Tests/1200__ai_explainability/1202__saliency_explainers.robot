*** Settings ***
Documentation       TestSuite testing Explainer for Deployed Models
Library             OpenShiftLibrary
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource            ../../Resources/CLI/ModelServing/llm.resource
Resource            ../../Resources/CLI/TrustyAI/trustyai_service.resource
Suite Setup         Explainers Suite Setup
Suite Teardown      Explainers Suite Teardown
Test Tags           ExplainersSuite


*** Variables ***
${TEST_NS}=                          explain
${LIME_EXPLAINER}=                   lime
${SHAP_EXPLAINER}=                   shap
${MODEL_NAME}=                       housing
${EXPLAINERS_PATH}=                  tests/Resources/Files/TrustyAI/Explainers
${INFERENCE_INPUT_2}=                ${EXPLAINERS_PATH}/example-input.json
${INFERENCE_INPUT_1}=                ${EXPLAINERS_PATH}/explainer-data-housing.json
${PRJ_TITLE1}=                       explainer-project
${MODEL_ALPHA}=                      demo-loan-nn-onnx-alpha
${MODEL_PATH_ALPHA}=                 trusty/loan_model_alpha.onnx
${AWS_BUCKET}=                       ${S3.BUCKET_1.NAME}
${PRJ_DESCRIPTION1}=                 Explainer Project Description 1
${RUNTIME_NAME}=                     Explainer Test
${FRAMEWORK_ONNX}=                   onnx - 1


*** Test Cases ***
Verify Lime And SHAP Explainers Are Availble For A Model Deployed Via CLI
    [Documentation]    Verifies that the Lime and shap Explainers are available on sending a request
    [Tags]    OpenDataHub     Smoke    RHOAIENG-9628     ExcludeOnRHOAI    test
    Set Project And Serving Runtime    namespace=${TEST_NS}    runtime_path=${EXPLAINERS_PATH}/odh-mlserver-1.x.yaml
    Oc Apply    kind=Secret    src=${EXPLAINERS_PATH}/storage-config.yaml     namespace=${TEST_NS}
    Deploy Model Via CLI    isvc_filepath=${EXPLAINERS_PATH}/housing.yaml
    ...    namespace=${TEST_NS}
    ${TRUSTY_ROUTE}=    Install And Verify TrustyAI Service     ${TEST_NS}
    Wait Until Keyword Succeeds  3 min  30 sec  Verify Model Is Registered With TrustyAI Service     namespace=${TEST_NS}
    ${TOKEN}=   Generate Thanos Token
    Send Model Inference Request    ${TEST_NS}    ${MODEL_NAME}     ${INFERENCE_INPUT_1}  ${TOKEN}
    ${INFERENCE_ID}=     Get Latest Inference Id    ${MODEL_NAME}     trusty_route=${TRUSTY_ROUTE}     token=${TOKEN}
    Request Explanation    ${INFERENCE_ID}   ${TOKEN}   ${TRUSTY_ROUTE}   ${MODEL_NAME}  explainer_type=${SHAP_EXPLAINER}
    Request Explanation    ${INFERENCE_ID}   ${TOKEN}   ${TRUSTY_ROUTE}   ${MODEL_NAME}  explainer_type=${LIME_EXPLAINER}

Verify Lime And SHAP Explainers Are Availble For A Model Deployed Via UI
    [Documentation]    Verifies that the lime and shap Explainers are available on sending a request
    [Tags]    OpenDataHub     Sanity    RHOAIENG-9628     ExcludeOnRHOAI       test2
    Launch Data Science Project Main Page
    Create Data Science Project    title=${PRJ_TITLE1}    description=${PRJ_DESCRIPTION1}
    Create S3 Data Connection    project_title=${PRJ_TITLE1}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=${AWS_BUCKET}
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}
    Serve Model    project_name=${PRJ_TITLE1}    model_name=${MODEL_ALPHA}    framework=${FRAMEWORK_ONNX}
    ...    existing_data_connection=${TRUE}    data_connection_name=model-serving-connection
    ...    model_path=${MODEL_PATH_ALPHA}    model_server=${RUNTIME_NAME}
    ${runtime_name}=    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_name}=    Convert To Lower Case    ${runtime_name}
    Wait For Pods To Be Ready    label_selector=name=modelmesh-serving-${runtime_name}    namespace=${PRJ_TITLE1}
    ${TRUSTY_ROUTE}=    Install And Verify TrustyAI Service     ${PRJ_TITLE1}
    ${TOKEN}=   Generate Thanos Token
    Send Model Inference Request    ${PRJ_TITLE1}    ${MODEL_ALPHA}     ${INFERENCE_INPUT_2}  ${TOKEN}
    ${INFERENCE_ID}=     Get Latest Inference Id    ${MODEL_ALPHA}     trusty_route=${TRUSTY_ROUTE}     token=${TOKEN}
    Request Explanation    ${INFERENCE_ID}   ${TOKEN}   ${TRUSTY_ROUTE}   ${MODEL_ALPHA}
    ...    explainer_type=${SHAP_EXPLAINER}
    Request Explanation    ${INFERENCE_ID}   ${TOKEN}   ${TRUSTY_ROUTE}   ${MODEL_ALPHA}
    ...    explainer_type=${LIME_EXPLAINER}


*** Keywords ***
Explainers Suite Setup
    [Documentation]    Setup to configure Explainers
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE1}     ${TEST_NS}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup

Explainers Suite Teardown
    [Documentation]     Explainers Suite Teardown
    Set Library Search Order    SeleniumLibrary
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown

Set Project And Serving Runtime
    [Documentation]    Creates the DS Project (if not exists),
    ...                creates runtime. This can be used as test setup
    [Arguments]    ${namespace}    ${runtime_path}
    Set Up Test OpenShift Project    test_ns=${namespace}
    Enable Modelmesh    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${runtime_path} -n ${namespace}
    Should Be Equal As Integers    ${rc}    ${0}    ${out}

Enable Modelmesh
    [Documentation]    Label namespace to enable ModelMesh.
    [Arguments]    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc label namespace ${namespace} modelmesh-enabled=true --overwrite
    Should Be Equal As Integers    ${rc}    ${0}    ${out}

Send Model Inference Request
    [Documentation]    Send Inference to the model
    [Arguments]    ${namespace}   ${model_name}  ${inference_input}   ${token}
    ${url}=    Get Model Route Via CLI    ${model_name}    ${namespace}
    ${token}=   Generate Thanos Token
    ${curl_cmd}=    Set Variable    curl -sk ${url} -d @${inference_input}
    ${curl_cmd}=    Catenate    ${curl_cmd}    -H "Authorization: Bearer ${token}"
    ${rc}  ${output}=     Run And Return Rc And Output    ${curl_cmd}
    Should Contain    ${output}    ${model_name}
    Should Be Equal As Integers    ${rc}    ${0}    ${output}

Get Latest Inference Id
    [Documentation]    Get all stored inference ids through TrustyAI Service endpoints
    [Arguments]    ${model_name}   ${trusty_route}  ${token}
    ${url}=   Set Variable     ${trusty_route}/info/inference/ids/${model_name}?type=organic
    ${curl_cmd}=     Set Variable    curl -sk "${url}"
    ${curl_cmd}=     Catenate    ${curl_cmd}    -H "Authorization: Bearer ${token}"
    ${rc}  ${output}=     Run And Return Rc And Output    ${curl_cmd} | jq -r '.[-1].id'
    Should Be Equal As Integers    ${rc}    ${0}    ${output}
    RETURN    ${output}

Request Explanation
    [Documentation]    Request a LIME/SHAP explanation for the selected inference ID
    [Arguments]    ${inference_id}    ${token}    ${trusty_route}   ${model_name}  ${explainer_type}
    ${curl_cmd}=     Set Variable    curl -sk -X POST -H "Authorization: Bearer ${token}"
    ${curl_cmd}=     Catenate    ${curl_cmd}    -H 'Content-Type: application/json'
    ${curl_cmd}=     Catenate    ${curl_cmd}    -d "{ \\"predictionId\\": \\"${inference_id}\\", \\"config\\": {\\"model\\": { \\"target\\": \\"modelmesh-serving:8033\\", \\"name\\":\\"${model_name}\\", \\"version\\": \\"v1\\"}}}"       # robocop: disable
    ${curl_cmd}=     Catenate    ${curl_cmd}    ${trusty_route}/explainers/local/${explainer_type}
    ${rc}  ${output}=     Run And Return Rc And Output    ${curl_cmd}
    Should Be Equal As Integers    ${rc}    ${0}    ${output}
    Should Contain    ${output}    score
    Should Contain    ${output}    confidence

