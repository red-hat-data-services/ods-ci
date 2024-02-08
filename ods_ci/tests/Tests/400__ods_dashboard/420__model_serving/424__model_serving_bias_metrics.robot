*** Settings ***
Documentation       TestSuite testing Bias metrics for Deployed Models
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/OCP.resource
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource            ../../../Resources/Page/Operators/ISVs.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource            ../../../Resources/Page/OCPDashboard/Monitoring/Metrics.robot
Library             OpenShiftLibrary
Suite Setup         Bias Metrics Suite Setup
Suite Teardown      Bias Metrics Suite Teardown

*** Variables ***
${DEFAULT_MONITORING_NS}=            openshift-user-workload-monitoring
${PRJ_TITLE}=                        model-serving-project
${PRJ_TITLE1}=                       model-project-test
${MODEL_ALPHA}=                      demo-loan-nn-onnx-alpha
${MODEL_PATH_ALPHA}=                 trusty/loan_model_alpha.onnx
${MODEL_BETA}=                       demo-loan-nn-onnx-beta
${MODEL_PATH_BETA}=                  trusty/loan_model_beta.onnx
${TRUSTYAI_RESOURCEPATH}=            ods_ci/tests/Resources/Files/TrustyAI
${TRUSTYAI_CR_FILEPATH}=             ${TRUSTYAI_RESOURCEPATH}/trustyai_cr.yaml
${aws_bucket}=                       ${S3.BUCKET_1.NAME}
${RUNTIME_NAME}=                     Model Bias Serving Test
${PRJ_DESCRIPTION}=                  Model Bias Project Description
${PRJ_DESCRIPTION1}=                 Model Bias Project Description 1
${framework_onnx}=                   onnx - 1

*** Test Cases ***
Verify DIR Bias Metrics Available In CLI For Models Deployed Prior To Enabling Trusty Service For Admin User
    [Documentation]    Verifies that the Bias metrics are available in Metrics Console for a model which was
    ...                 deployed prior to enabling the TrustyAI service
    [Tags]    Smoke
    ...       Tier1   ODS-2482    ODS-2479
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=${aws_bucket}
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_ALPHA}    framework=${framework_onnx}    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=${MODEL_PATH_ALPHA}    model_server=${RUNTIME_NAME}
    ${runtime_name}=    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_name}=    Convert To Lower Case    ${runtime_name}
    Wait For Pods To Be Ready    label_selector=name=modelmesh-serving-${runtime_name}    namespace=${PRJ_TITLE}
    Verify Model Status    ${MODEL_ALPHA}    success
    Install And Verify TrustyAI Service     ${PRJ_TITLE}
    Wait Until Keyword Succeeds  5 min  10 sec  Verify Model Is Registered with TrustyAI Service     namespace=${PRJ_TITLE}
    Send Batch Inference Data to Model     model_name=${MODEL_ALPHA}     project_name=${PRJ_TITLE}
    ${token}=    Generate Thanos Token
    ${modelId}=   Get ModelId For A Deployed Model    modelId=${MODEL_ALPHA}     token=${token}
    ${modelId}    Replace String    ${modelId}    "    ${EMPTY}
    Schedule Bias Metrics request via CLI     metricsType=dir   modelId=${modelId}  token=${token}  protectedAttribute="customer_data_input-3"
    ...       favorableOutcome=0   outcomeName="predict"    privilegedAttribute=1.0    unprivilegedAttribute=0.0
    Sleep    60s    msg=Wait for Trusty Metrics to be calculated and prometheus scraping to be done
    Verify TrustyAI Metrics Exists In Observe Metrics    trustyai_dir    retry_attempts=2   username=${OCP_ADMIN_USER.USERNAME}
    ...    password=${OCP_ADMIN_USER.PASSWORD}    auth_type=${OCP_ADMIN_USER.AUTH_TYPE}


Verify SPD Metrics Available In CLI For Models Deployed After Enabling Trusty Service For Basic User
    [Documentation]    Verifies that the Bias metrics are available in Metrics Console for a model
    ...                 deployed after enabling the TrustyAI service
    [Tags]    Sanity
    ...       Tier1   ODS-2482    ODS-2476
    Launch Data Science Project Main Page
    Create Data Science Project    title=${PRJ_TITLE1}    description=${PRJ_DESCRIPTION1}
    Append To List    ${PROJECTS_TO_DELETE}    ${PRJ_TITLE1}
    Install And Verify TrustyAI Service      ${PRJ_TITLE1}
    Create S3 Data Connection    project_title=${PRJ_TITLE1}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=${aws_bucket}
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}
    Serve Model    project_name=${PRJ_TITLE1}    model_name=${MODEL_BETA}    framework=${framework_onnx}    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=${MODEL_PATH_BETA}    model_server=${RUNTIME_NAME}
    ${runtime_name}=    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_name}=    Convert To Lower Case    ${runtime_name}
    Wait For Pods To Be Ready    label_selector=name=modelmesh-serving-${runtime_name}    namespace=${PRJ_TITLE1}
    Verify Model Status    ${MODEL_BETA}    success
    Wait Until Keyword Succeeds  5 min  10 sec  Verify Model Is Registered with TrustyAI Service     namespace=${PRJ_TITLE1}
    Send Batch Inference Data to Model     lower_range=6   upper_range=11    model_name=${MODEL_BETA}     project_name=${PRJ_TITLE1}
    ${token}=    Generate Thanos Token
    ${modelId}=   Get ModelId For A Deployed Model    modelId=${MODEL_BETA}    ${token}
    ${modelId}    Replace String    ${modelId}    "    ${EMPTY}
    Schedule Bias Metrics request via CLI     metricsType=spd   modelId=${modelId}   token=${token}  protectedAttribute="customer_data_input-3"
    ...       favorableOutcome=0   outcomeName="predict"    privilegedAttribute=1.0    unprivilegedAttribute=0.0
    Verify TrustyAI Metrics Exists In Observe Metrics    trustyai_spd    retry_attempts=2    username=${TEST_USER.USERNAME}
    ...    password=${TEST_USER.PASSWORD}   auth_type=${TEST_USER.AUTH_TYPE}

*** Keywords ***
Bias Metrics Suite Setup
    [Documentation]    Setup to configure TrustyAI metrics
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup
    Enable User Workload Monitoring
    Configure User Workload Monitoring
    Verify User Workload Monitoring Configuration
    Launch Data Science Project Main Page

Bias Metrics Suite Teardown
    [Documentation]     Bias Metrics Suite Teardown
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown

Verify User Workload Monitoring Configuration
    [Documentation]    Verifies that the ALL monitoring components for user-defined-projects
    ...    are READY in the ${DEFAULT_MONITORING_NS} namespace
    Wait For Pods Status  namespace=${DEFAULT_MONITORING_NS}  timeout=60
    Log  Verified Applications NS: ${DEFAULT_MONITORING_NS}  console=yes

Install And Verify TrustyAI Service
    [Documentation]    Install TrustyAI service CRD and verify that TrustyAI resources have spun up
    [Arguments]        ${namespace}=${PRJ_TITLE}
    ${return_code}    ${output}=    Run And Return Rc And Output    oc apply -f ${TRUSTYAI_CR_FILEPATH} -n ${namespace}
    Sleep    60s    msg=Wait for Trusty Route to be created
    ${return_code}    ${output}    Run And Return Rc And Output   oc get route trustyai-service -n ${namespace} --template={{.spec.host}}
    Should Be Equal As Integers    ${return_code}	 0
    Set Suite Variable    ${TRUSTY_ROUTE}    https://${output}

Remove TrustyAI Service
    [Documentation]    Remove TrustyAI service CRD
    [Arguments]        ${namespace}=${PRJ_TITLE}
    OpenshiftLibrary.Oc Delete    kind=TrustyAIService    namespace=${namespace}    name=trustyai-service

Verify Model Is Registered with TrustyAI Service
    [Documentation]    Verify the deployed model is registered with TrustyAI Service by verifying MM_PAYLOAD_PROCESSORS
    ...                value is the TrustyAI service route
    [Arguments]        ${namespace}=${PRJ_TITLE}
    ${MM_PAYLOAD_PROCESSORS_Expected}=    Set Variable    http://trustyai-service.${namespace}.svc.cluster.local/consumer/kserve/v2
    Wait Until Keyword Succeeds  3 min  20 sec  Verify One Model Serving Pod Exists   ${namespace}    label_selector=modelmesh-service=modelmesh-serving
    ${podname}=    Get Pod Name   ${namespace}    label_selector=modelmesh-service=modelmesh-serving
    Log    Serving Runtime Podname: ${podname}
    ${MM_PAYLOAD_PROCESSORS_Actual}=  Run  oc get pod ${podname} -n ${namespace} -o json | jq '.spec.containers[0].env[] | select(.name=="MM_PAYLOAD_PROCESSORS") | .value'
    ${MM_PAYLOAD_PROCESSORS_Actual}=    Strip String    ${MM_PAYLOAD_PROCESSORS_Actual}    characters="
    Should Be Equal  ${MM_PAYLOAD_PROCESSORS_Actual.strip()}  ${MM_PAYLOAD_PROCESSORS_Expected.strip()}

Verify One Model Serving Pod Exists
    [Documentation]    Verifies that serving runtime pods have been stabilized and only 1 pod exists
    [Arguments]    ${PRJ_TITLE}     ${label_selector}
    ${return_code}    ${pod_number}    Run And Return Rc And Output   oc get pod -n ${PRJ_TITLE} -l ${label_selector} | tail -n +2 | wc -l
    ${pod_numbers}    Split String     ${pod_number}
    Should Be Equal    ${pod_numbers}[0]   1

Send Batch Inference Data to Model
    [Documentation]    Send Batch Inference data to the already deployed model using Curl commands
    [Arguments]        ${model_name}   ${project_name}    ${lower_range}=1     ${upper_range}=5
    FOR    ${counter}    IN RANGE    ${lower_range}    ${upper_range}
        ${inference_input}=  Set Variable   @ods_ci/tests/Resources/Files/TrustyAI/loan_default_batched/batch_${counter}.json
        ${inference_output}=    Get Model Inference    ${model_name}    ${inference_input}    token_auth=${FALSE}
        ...    project_title=${project_name}
        Should Contain    ${inference_output}    model_name
    END

Get ModelId For A Deployed Model
    [Documentation]   Curl command to get modelid of the model. The sufffix gets changed by modelmesh
    ...               https://github.com/trustyai-explainability/trustyai-explainability/issues/395
    [Arguments]       ${model_name}    ${token}
    ${curl_cmd}=     Set Variable    curl -H "Authorization: Bearer ${token}" -sk --location ${TRUSTY_ROUTE}/info | jq '.[0].data.modelId'
    ${rc}  ${output}=     Run And Return Rc And Output    ${curl_cmd}
    ${model_id}=    Set Variable If    '${output}'=='${EMPTY}'    ${model_name}    ${output}
    RETURN    ${model_id}

Schedule Bias Metrics request via CLI
    [Documentation]    Schedule a SPD or DIR metrics via CLI
    [Arguments]        ${metricsType}   ${modelId}    ${protectedAttribute}   ${favorableOutcome}    ${outcomeName}
    ...                ${privilegedAttribute}    ${unprivilegedAttribute}    ${token}
    ${curl_cmd}=     Set Variable    curl -k -H "Authorization: Bearer ${token}" ${TRUSTY_ROUTE}/metrics/${metricsType}/request --header
    ${curl_cmd}=     Catenate    ${curl_cmd}    'Content-Type: application/json'
    ${curl_cmd}=     Catenate    ${curl_cmd}    --data '{"modelId":"${modelId}","protectedAttribute": ${protectedAttribute},"favorableOutcome":  ${favorableOutcome},"outcomeName": ${outcomeName},"privilegedAttribute": ${privilegedAttribute},"unprivilegedAttribute": ${unprivilegedAttribute}}'
    ${rc}  ${output}=     Run And Return Rc And Output    ${curl_cmd}
    Should Contain    ${output}    requestId
    Log to Console    ${output}

Verify TrustyAI Metrics Exists In Observe Metrics
    [Documentation]    Verify that TrustyAI Metrics exist in the Observe -> Metrics in OCP
    [Arguments]        ${model_query}    ${retry_attempts}   ${username}  ${password}  ${auth_type}
    ${metrics_value}=    Run OpenShift Metrics Query    query=${model_query}    retry_attempts=${retry_attempts}   username=${username}
    ...   password=${password}   auth_type=${auth_type}
    ${metrics_query_results_contain_data}=    Run Keyword And Return Status    Metrics.Verify Query Results Contain Data
    IF    ${metrics_query_results_contain_data}
        Log To Console    Current Fairness Value: ${metrics_value}
    END

