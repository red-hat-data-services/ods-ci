*** Settings ***
Documentation       TestSuite testing Bias metrics for Deployed Models
Library             OpenShiftLibrary
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/CLI/TrustyAI/trustyai_service.resource
Resource            ../../Resources/OCP.resource
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Suite Setup         TLS Suite Setup
Suite Teardown      TLS Suite Teardown

*** Variables ***
${DEFAULT_MONITORING_NS}=            openshift-user-workload-monitoring
${PRJ_TITLE1}=                       model-tls-test
${MODEL_BETA}=                       demo-loan-nn-onnx-beta
${MODEL_PATH_BETA}=                  trusty/loan_model_beta.onnx
${framework_onnx}=                   onnx - 1
${aws_bucket}=                       ${S3.BUCKET_1.NAME}
${RUNTIME_NAME}=                     Model TLS Test
${PRJ_DESCRIPTION1}=                 Model TLS Project Description


*** Test Cases ***
Verify SPD Metrics Available In CLI For Models Deployed After Enabling Trusty Service For Basic User
    [Documentation]    Verifies that the Bias metrics are available in Metrics Console for a model
    ...                 deployed after enabling the TrustyAI service
    [Tags]    ODS-2482    ODS-2476     OpenDataHub    ExcludeOnRHOAI    tls
    Create Data Science Project    title=${PRJ_TITLE1}    description=${PRJ_DESCRIPTION1}
    Append To List    ${PROJECTS_TO_DELETE}    ${PRJ_TITLE1}
#    ${return_code}    ${output} =    Run And Return Rc And Output    oc apply -f tests/Resources/Files/TrustyAI/model-serving-config.yaml -n ${PRJ_TITLE1}
#    Log To Console    ${output}
    ${TRUSTY_ROUTE}=   Install And Verify TrustyAI Service      ${PRJ_TITLE1}
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
    Wait Until Keyword Succeeds  5 min  10 sec  Verify Model Is Registered With TrustyAI Service     namespace=${PRJ_TITLE1}

*** Keywords ***
TLS Suite Setup
    [Documentation]    Setup to configure TLS
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE1}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup
#    Enable User Workload Monitoring
#    Configure User Workload Monitoring
    Launch Data Science Project Main Page

TLS Suite Teardown
    [Documentation]     TLS Suite Teardown
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown
