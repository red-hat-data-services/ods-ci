*** Settings ***
Documentation       TestSuite testing Bias metrics for Deployed Models
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/OCP.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/Operators/ISVs.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/ModelServer.resource
Resource            ../../../Resources/Page/OCPDashboard/Monitoring/Metrics.robot
Library             OpenShiftLibrary
Suite Setup         Bias Metrics Suite Setup
Suite Teardown      RHOSi Teardown

*** Variables ***
${DEFAULT_MONITORING_NS}=            openshift-user-workload-monitoring
${SETUP_MONITORING}=                 ${TRUE}
${PRJ_TITLE}=                        model-serving-project
${MODEL_ALPHA}=                      demo-loan-nn-onnx-alpha
${MODEL_PATH_ALPHA}=                 trusty/loan_model_alpha.onnx
${MODEL_BETA}=                       demo-loan-nn-onnx-beta
${MODEL_PATH_BETA}=                  trusty/loan_model_beta.onnx
${TRUSTYAI_RESOURCEPATH}=            ods_ci/tests/Resources/Files/TrustyAI
${TRUSTYAI_CR_FILEPATH}=             ${TRUSTYAI_RESOURCEPATH}/trustyai_crd.yaml
${MONITORING_CONFIG_FILEPATH}=       ods_ci/tests/Resources/Files/cluster-monitoring-config.yaml
${UWM_CONFIG_FILEPATH}=              ods_ci/tests/Resources/Files/user-workload-monitoring-config.yaml
${aws_bucket}=                       rhods-public
${RUNTIME_NAME}=                     Model Bias Serving Test
${PRJ_DESCRIPTION}=                  Model Bias Project Description
${framework_onnx}=                   onnx - 1

*** Test Cases ***

Verify TrustyAI Operator Installation
    [Documentation]    Verifies that the TrustyAI operator has been
    ...    deployed in the ${APPLICATIONS_NAMESPACE} namespace
    [Tags]    Smoke
    ...       Tier1    ODS-2481
    ...       OpenDataHub
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  1 min  10 sec  Verify trustyai-service-operator-controller-manager Deployment

Verify Bias Metrics are available in CLI for models deployed prior to enabling Trusty service
    [Documentation]    Verifies that the Bias metrics are available in the Prometheus for a model which was
    ...                 deployed prior to enabling the TrustyAI service
    [Tags]    Smoke
    ...       Tier1   ODS-2482    ODS-2479
    ...       OpenDataHub
    [Teardown]    Delete Data Science Project From CLI   ${PRJ_TITLE}
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=${MODEL_ALPHA}    framework=${framework_onnx}    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=${MODEL_PATH_ALPHA}    model_server=${RUNTIME_NAME}
    ${runtime_pod_name} =    Replace String Using Regexp    string=${RUNTIME_NAME}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Sleep    45s
    ${return_code}    ${output}    Run And Return Rc And Output   oc get pod -n ${PRJ_TITLE} | grep "5/5" -o
    Should Be Equal    ${output}   5/5
    Should Be Equal As Integers    ${return_code}	 0
    Verify Model Status    ${MODEL_ALPHA}    success
    Install And Verify TrustyAI Service
    Sleep    30s  msg=Give time for Trusty to see the deployment and register the pods
    Verify Model Is Registered with TrustyAI Service
    Send Batch Inference Data to Model     model_name=${MODEL_ALPHA}     project_name=${PRJ_TITLE}
    ${modelId}=   Get ModelId For A Deployed Model    modelId=${MODEL_ALPHA}
    ${modelId}    Replace String    ${modelId}    "    ${EMPTY}
    Create Metrics request via CLI     metrics_type=dir   modelId=${modelId}    protectedAttribute="customer_data_input-3"
    ...       favorableOutcome=0   outcomeName="predict"    privilegedAttribute=1.0    unprivilegedAttribute=0.0
    Verify TrustyAI Metrics Exists In Observe Metrics    trustyai_dir    retry_attempts=2

*** Keywords ***
Bias Metrics Suite Setup
    [Documentation]    Setup to configure TrustyAI metrics
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    IF    ${SETUP_MONITORING} == ${TRUE}
        Log    Enabling and Configuring User Workload Monitoring
        Enable User Workload Monitoring
        Configure User Workload Monitoring
        Verify User Workload Monitoring Configuration
    END
    Launch Data Science Project Main Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=${aws_bucket}
    Create Model Server    token=${FALSE}    server_name=${RUNTIME_NAME}


Enable User Workload Monitoring
    [Documentation]    Enable User Workload Monitoring for the cluster for user-defined-projects
    RHOSi Setup
    ${return_code}    ${output}    Run And Return Rc And Output   oc apply -f ${MONITORING_CONFIG_FILEPATH}
    Log To Console    ${output}
    Should Be Equal As Integers    ${return_code}     0   msg=Error while applying the provided file

Configure User Workload Monitoring
    [Documentation]    Configure the retention period in User Workload Monitoring for the cluster.
    ...                This period can be configured for the component as and when needed.
    ${return_code}    ${output}    Run And Return Rc And Output   oc apply -f ${UWM_CONFIG_FILEPATH}
    Log To Console    ${output}
    Should Be Equal As Integers    ${return_code}     0   msg=Error while applying the provided file

Verify User Workload Monitoring Configuration
    [Documentation]    Verifies that the ALL monitoring components for user-defined-projects
    ...    are READY in the ${DEFAULT_MONITORING_NS} namespace
    [Tags]    Smoke
    ...       Tier1
    ...       OpenDataHub
    Wait For Pods Status  namespace=${DEFAULT_MONITORING_NS}  timeout=60
    Log  Verified Applications NS: ${DEFAULT_MONITORING_NS}  console=yes

Verify trustyai-service-operator-controller-manager Deployment
    [Documentation]    Verifies the correct deployment of the model controller in the namespace
    [Arguments]    ${num_replicas}=1
    ${all_ready} =    Run    oc get deployment -n ${APPLICATIONS_NAMESPACE} trustyai-service-operator-controller-manager | grep ${num_replicas}/${num_replicas} -o  # robocop:disable
    Should Be Equal As Strings    ${all_ready}    ${num_replicas}/${num_replicas}

Install And Verify TrustyAI Service
    [Documentation]    Install TrustyAI service CRD and verify that TrustyAI resources have spun up
    Deploy Custom Resource    kind=TrustyAIService    namespace=${PRJ_TITLE}
    ...    filepath=${TRUSTYAI_CR_FILEPATH}
    Sleep   15s
    ${return_code}    ${output}    Run And Return Rc And Output   oc get route trustyai-service -n ${PRJ_TITLE} --template={{.spec.host}}
    Should Be Equal As Integers    ${return_code}	 0
    Set Suite Variable    ${TRUSTY_ROUTE}    https://${output}

Delete TrustyAI Service
    [Documentation]    Delete TrustyAI service CRD
    OpenshiftLibrary.Oc Delete    kind=TrustyAIService    namespace=${PRJ_TITLE}    name=trustyai-service

Verify Model Is Registered with TrustyAI Service
    [Documentation]    Verify the deployed model is registered with TrustyAI Service by verifying MM_PAYLOAD_PROCESSORS
    ...                value is the TrustyAI service route
    ${MM_PAYLOAD_PROCESSORS_Expected}=    Set Variable    http://trustyai-service.${PRJ_TITLE}.svc.cluster.local/consumer/kserve/v2
    Wait Until Keyword Succeeds  3 min  20 sec  Verify One Model Serving Pod Exists   ${PRJ_TITLE}    label_selector=modelmesh-service=modelmesh-serving
    ${return_code}    ${podname}    Run And Return Rc And Output  oc get pods -n ${PRJ_TITLE} -o json | jq '.items[].metadata.name' | grep 'modelmesh-serving'
    Log    Serving Runtime Podname: ${podname}
    ${MM_PAYLOAD_PROCESSORS_Actual} =  Run  oc get pod ${podname} -n ${PRJ_TITLE} -o json | jq '.spec.containers[0].env[] | select(.name=="MM_PAYLOAD_PROCESSORS") | .value'
    ${MM_PAYLOAD_PROCESSORS_Actual} =    Strip String    ${MM_PAYLOAD_PROCESSORS_Actual}    characters="
    Should Be Equal  ${MM_PAYLOAD_PROCESSORS_Actual.strip()}  ${MM_PAYLOAD_PROCESSORS_Expected.strip()}

Verify One Model Serving Pod Exists
    [Documentation]    Verifies that serving runtime pods have been stabilized and only 1 pod exists
    [Arguments]    ${PRJ_TITLE}     ${label_selector}
    ${return_code}    ${pod_number}    Run And Return Rc And Output   oc get pod -n ${PRJ_TITLE} -l ${label_selector} | tail -n +2 | wc -l
    ${pod_numbers}    Split String     ${pod_number}
    Should Be Equal    ${pod_numbers}[0]   1

#Verify MM_PAYLOAD_PROCESSORS Environment Variable Is Removed
#    [Documentation]    Verify that the MM_PAYLOAD_PROCESSORS is deleted when TrustyAI service is removed
#    ${podname} =  Run  oc get pods -n ${PRJ_TITLE} -o json | jq '.items[].metadata.name' | grep 'modelmesh-serving'
#

Send Batch Inference Data to Model
    [Documentation]    Send Batch Inference data to the already deployed model using Curl commands
    [Arguments]        ${model_name}   ${project_name}
    ${url}=    Get Model Route via CLI    ${model_name}   ${project_name}
    #To be removed PWD Command
    ${rc}    ${pwd}=    Run And Return Rc And Output    echo $PWD
    FOR    ${counter}    IN RANGE    1    5
        ${inference}=  Set Variable   ${pwd}/ods_ci/tests/Resources/Files/TrustyAI/loan_default_batched/batch_0${counter}.json
        ${curl_cmd}=     Set Variable    curl -sk ${url} -d @${inference}
        ${rc}  ${inference_output}=    Run And Return Rc And Output    ${curl_cmd}
        Should Contain    ${inference_output}    model_name
        Should Be Equal As Integers	${rc}	 0
    END

Get ModelId For A Deployed Model
    [Documentation]   Curl command to get modelid of the model. The sufffix gets changed by modelmesh
    ...               https://github.com/trustyai-explainability/trustyai-explainability/issues/395
    [Arguments]       ${model_name}
    #To Be removed later once modelid doesn't get modified
    ${curl_cmd}=     Set Variable    curl -sk --location ${TRUSTY_ROUTE}/info | jq '.[0].data.modelId'
    ${rc}  ${output}=     Run And Return Rc And Output    ${curl_cmd}
    ${model_id}=    Set Variable If    '${output}'=='${EMPTY}'    ${model_name}    ${output}
    RETURN    ${model_id}

Create Metrics request via CLI
    [Documentation]    Create an SPD or DIR metrics via CLI
    [Arguments]        ${metrics_type}   ${modelId}    ${protectedAttribute}   ${favorableOutcome}    ${outcomeName}
    ...                ${privilegedAttribute}    ${unprivilegedAttribute}
    ${curl_cmd}=     Set Variable    curl -sk --location ${TRUSTY_ROUTE}/metrics/${metrics_type}/request --header
    ${curl_cmd}=     Catenate    ${curl_cmd}    'Content-Type: application/json'
    ${curl_cmd}=     Catenate    ${curl_cmd}    --data '{"modelId":"${modelId}","protectedAttribute": ${protectedAttribute},"favorableOutcome":  ${favorableOutcome},"outcomeName": ${outcomeName},"privilegedAttribute": ${privilegedAttribute},"unprivilegedAttribute": ${unprivilegedAttribute}}'
    Log to Console    ${curl_cmd}
    Log to Console    Run Curl
    ${rc}  ${output}=     Run And Return Rc And Output    ${curl_cmd}
    Should Contain    ${output}    requestId
    Log to Console    ${output}

Verify TrustyAI Metrics Exists In Observe Metrics
    [Documentation]    Verify that Verify TrustyAI Metrics
    [Arguments]        ${model_query}    ${retry_attempts}
    ${metrics_value} =    Run OpenShift Metrics Query    ${model_query}    ${retry_attempts}
    ${metrics_query_results_contain_data} =    Run Keyword And Return Status    Metrics.Verify Query Results Contain Data
    IF    ${metrics_query_results_contain_data}
        Log To Console    Current Fairness Value: ${metrics_value}
    END

#Create Metrics Request via UI
