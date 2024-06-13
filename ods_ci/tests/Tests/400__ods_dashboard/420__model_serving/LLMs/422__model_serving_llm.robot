*** Settings ***
Documentation     Collection of CLI tests to validate the model serving stack for Large Language Models (LLM).
...               These tests leverage on Caikit+TGIS combined Serving Runtime
Resource          ../../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../../Resources/OCP.resource
Resource          ../../../../Resources/Page/Operators/ISVs.resource
Resource          ../../../../Resources/CLI/ModelServing/llm.resource
Library            OpenShiftLibrary
Suite Setup       Install Model Serving Stack Dependencies
Suite Teardown    RHOSi Teardown
Test Tags         KServe


*** Variables ***
${DEFAULT_OP_NS}=    openshift-operators
${SERVERLESS_OP_NAME}=     serverless-operator
${SERVERLESS_SUB_NAME}=    serverless-operator
${SERVERLESS_NS}=    openshift-serverless
${SERVERLESS_CR_NS}=    knative-serving
${SERVERLESS_KNATIVECR_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/knativeserving_istio.yaml
${SERVERLESS_GATEWAYS_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/gateways.yaml
${WILDCARD_GEN_SCRIPT_FILEPATH}=    ods_ci/utils/scripts/generate-wildcard-certs.sh
${SERVICEMESH_OP_NAME}=     servicemeshoperator
${SERVICEMESH_SUB_NAME}=    servicemeshoperator
${SERVICEMESH_CONTROLPLANE_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/smcp.yaml
${SERVICEMESH_ROLL_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/smmr.yaml
${SERVICEMESH_PEERAUTH_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/peer_auth.yaml
${KIALI_OP_NAME}=     kiali-ossm
${KIALI_SUB_NAME}=    kiali-ossm
${JAEGER_OP_NAME}=     jaeger-product
${JAEGER_SUB_NAME}=    jaeger-product
${KSERVE_NS}=    ${APPLICATIONS_NAMESPACE}    # NS is "kserve" for ODH
${TEST_NS}=    singlemodel
${SKIP_PREREQS_INSTALL}=    ${TRUE}
${SCRIPT_BASED_INSTALL}=    ${TRUE}
${FLAN_MODEL_S3_DIR}=    flan-t5-small/flan-t5-small-caikit
${FLAN_GRAMMAR_MODEL_S3_DIR}=    flan-t5-large-grammar-synthesis-caikit/flan-t5-large-grammar-synthesis-caikit
${FLAN_LARGE_MODEL_S3_DIR}=    flan-t5-large/flan-t5-large
${BLOOM_MODEL_S3_DIR}=    bloom-560m/bloom-560m-caikit
${FLAN_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_MODEL_S3_DIR}/
${FLAN_GRAMMAR_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_GRAMMAR_MODEL_S3_DIR}/
${FLAN_LARGE_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_LARGE_MODEL_S3_DIR}/
${BLOOM_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${BLOOM_MODEL_S3_DIR}/
${SCRIPT_TARGET_OPERATOR}=    rhods    # rhods or brew
${SCRIPT_BREW_TAG}=    ${EMPTY}    # ^[0-9]+$
${CAIKIT_TGIS_RUNTIME_NAME}=    caikit-tgis-runtime


*** Test Cases ***
Verify External Dependency Operators Can Be Deployed
    [Documentation]    Checks the pre-required Operators can be installed
    ...                and configured
    [Tags]    ODS-2326
    Pass Execution    message=Installation done as part of Suite Setup.

Verify User Can Serve And Query A Model
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Sanity    Tier1    ODS-2341
    [Setup]    Set Project And Runtime    namespace=${TEST_NS}-cli
    ${test_namespace}=    Set Variable     ${TEST_NS}-cli
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Deploy Multiple Models In The Same Namespace
    [Documentation]    Checks if user can deploy and query multiple models in the same namespace
    [Tags]    Sanity    Tier1    ODS-2371
    [Setup]    Set Project And Runtime    namespace=${TEST_NS}-multisame
    ${test_namespace}=    Set Variable     ${TEST_NS}-multisame
    ${model_one_name}=    Set Variable    bloom-560m-caikit
    ${model_two_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_one_name}    ${model_two_name}
    Compile Inference Service YAML    isvc_name=${model_one_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Compile Inference Service YAML    isvc_name=${model_two_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_one_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_two_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Query Model Multiple Times    model_name=${model_one_name}
    ...    n_times=5    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_two_name}
    ...    n_times=10    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_one_name}
    ...    n_times=5    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_two_name}
    ...    n_times=10    namespace=${test_namespace}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Deploy Multiple Models In Different Namespaces
    [Documentation]    Checks if user can deploy and query multiple models in the different namespaces
    [Tags]    Sanity    Tier1    ODS-2378
    [Setup]    Run Keywords    Set Project And Runtime    namespace=singlemodel-multi1
    ...        AND
    ...        Set Project And Runtime    namespace=singlemodel-multi2
    ${model_one_name}=    Set Variable    bloom-560m-caikit
    ${model_two_name}=    Set Variable    flan-t5-small-caikit
    ${models_names_ns_1}=    Create List    ${model_one_name}
    ${models_names_ns_2}=    Create List    ${model_two_name}
    Compile Inference Service YAML    isvc_name=${model_one_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=singlemodel-multi1
    Compile Inference Service YAML    isvc_name=${model_two_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=singlemodel-multi2
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_one_name}
    ...    namespace=singlemodel-multi1    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_two_name}
    ...    namespace=singlemodel-multi2    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Query Model Multiple Times    model_name=${model_one_name}    n_times=2
    ...    namespace=singlemodel-multi1
    Query Model Multiple Times    model_name=${model_two_name}    n_times=2
    ...    namespace=singlemodel-multi2
    [Teardown]    Run Keywords    Clean Up Test Project    test_ns=singlemodel-multi1    isvc_names=${models_names_ns_1}
    ...           wait_prj_deletion=${FALSE}
    ...           AND
    ...           Clean Up Test Project    test_ns=singlemodel-multi2    isvc_names=${models_names_ns_2}
    ...           wait_prj_deletion=${FALSE}

Verify Model Upgrade Using Canaray Rollout
    [Documentation]    Checks if user can apply Canary Rollout as deployment strategy
    [Tags]    Sanity    Tier1    ODS-2372
    [Setup]    Set Project And Runtime    namespace=canary-model-upgrade
    ${test_namespace}=    Set Variable    canary-model-upgrade
    ${isvc_name}=    Set Variable    canary-caikit
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${isvcs_names}=    Create List    ${isvc_name}
    ${canary_percentage}=    Set Variable    ${30}
    Compile Deploy And Query LLM model   isvc_name=${isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_name=${model_name}
    ...    namespace=${test_namespace}
    ...    validate_response=${FALSE}
    Log To Console    Applying Canary Tarffic for Model Upgrade
    ${model_name}=    Set Variable    bloom-560m-caikit
    Compile Deploy And Query LLM model   isvc_name=${isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    ...    model_name=${model_name}
    ...    canaryTrafficPercent=${canary_percentage}
    ...    namespace=${test_namespace}
    ...    validate_response=${FALSE}
    ...    n_queries=${0}
    Traffic Should Be Redirected Based On Canary Percentage    exp_percentage=${canary_percentage}
    ...    isvc_name=${isvc_name}    model_name=${model_name}    namespace=${test_namespace}
    ...    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Log To Console    Remove Canary Tarffic For Model Upgrade
    Compile Deploy And Query LLM model    isvc_name=${isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_name=${model_name}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    ...    namespace=${test_namespace}
    Traffic Should Be Redirected Based On Canary Percentage    exp_percentage=${100}
    ...    isvc_name=${isvc_name}    model_name=${model_name}    namespace=${test_namespace}
    ...    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${isvcs_names}    wait_prj_deletion=${FALSE}

Verify Model Pods Are Deleted When No Inference Service Is Present
    [Documentation]    Checks if model pods gets successfully deleted after
    ...                deleting the KServe InferenceService object
    [Tags]    Tier2    ODS-2373
    [Setup]    Set Project And Runtime    namespace=no-infer-kserve
    ${flan_isvc_name}=    Set Variable    flan-t5-small-caikit
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    Compile Deploy And Query LLM model   isvc_name=${flan_isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_name=${model_name}
    ...    namespace=no-infer-kserve
    Delete InfereceService    isvc_name=${flan_isvc_name}    namespace=no-infer-kserve
    ${rc}    ${out}=    Run And Return Rc And Output    oc wait pod -l serving.kserve.io/inferenceservice=${flan_isvc_name} -n no-infer-kserve --for=delete --timeout=200s
    Should Be Equal As Integers    ${rc}    ${0}
    [Teardown]   Clean Up Test Project    test_ns=no-infer-kserve
    ...    isvc_names=${models_names}   isvc_delete=${FALSE}
    ...    wait_prj_deletion=${FALSE}

Verify User Can Change The Minimum Number Of Replicas For A Model
    [Documentation]    Checks if user can change the minimum number of replicas
    ...                of a deployed model.
    ...                Affected by:  https://issues.redhat.com/browse/SRVKS-1175
    [Tags]    Sanity    Tier1    ODS-2376
    [Setup]    Set Project And Runtime    namespace=${TEST_NS}-reps
    ${test_namespace}=    Set Variable     ${TEST_NS}-reps
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    min_replicas=1
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}    exp_replicas=${1}
    Query Model Multiple Times    model_name=${model_name}    n_times=3
    ...    namespace=${test_namespace}
    ${rev_id}=    Set Minimum Replicas Number    n_replicas=3    model_name=${model_name}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Terminated    label_selector=serving.knative.dev/revisionUID=${rev_id}
    ...    namespace=${test_namespace}    timeout=360s
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}    exp_replicas=${3}
    Query Model Multiple Times    model_name=${model_name}    n_times=3
    ...    namespace=${test_namespace}
    ${rev_id}=    Set Minimum Replicas Number    n_replicas=1    model_name=${model_name}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Terminated    label_selector=serving.knative.dev/revisionUID=${rev_id}
    ...    namespace=${test_namespace}    timeout=360s
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}    exp_replicas=${1}
    Query Model Multiple Times    model_name=${model_name}    n_times=3
    ...    namespace=${test_namespace}
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Autoscale Using Concurrency
    [Documentation]    Checks if model successfully scale up based on concurrency metrics (KPA)
    [Tags]    Sanity    Tier1    ODS-2377
    [Setup]    Set Project And Runtime    namespace=autoscale-con
    ${test_namespace}=    Set Variable    autoscale-con
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    auto_scale=True
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Query Model Multiple Times    model_name=${flan_model_name}    n_times=10
    ...    namespace=${test_namespace}    validate_response=${FALSE}    background=${TRUE}
    Wait For Pods Number    number=1    comparison=GREATER THAN
    ...    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Validate Scale To Zero
    [Documentation]    Checks if model successfully scale down to 0 if there's no traffic
    [Tags]    Sanity    Tier1    ODS-2379
    [Setup]    Set Project And Runtime    namespace=autoscale-zero
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    ${test_namespace}=    Set Variable    autoscale-zero
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${flan_model_name}   namespace=${test_namespace}
    ${body}=    Set Variable    '{"text": "At what temperature does liquid Nitrogen boil?"}'
    ${header}=    Set Variable    'mm-model-id: ${flan_model_name}'
    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict"
    ...    json_body=${body}    json_header=${header}
    ...    insecure=${TRUE}
    Set Minimum Replicas Number    n_replicas=0    model_name=${flan_model_name}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}    exp_replicas=${2}
    Wait For Pods To Be Terminated    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict"
    ...    json_body=${body}    json_header=${header}
    ...    insecure=${TRUE}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Wait For Pods To Be Terminated    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Set Requests And Limits For A Model
    [Documentation]    Checks if user can set HW request and limits on their inference service object
    [Tags]    Sanity    Tier1    ODS-2380
    [Setup]    Set Project And Runtime    namespace=hw-res
    ${test_namespace}=    Set Variable    hw-res
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    ${requests}=    Create Dictionary    cpu=1    memory=2Gi
    ${limits}=    Create Dictionary    cpu=2    memory=4Gi
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    requests_dict=${requests}    limits_dict=${limits}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    ${rev_id}=    Get Current Revision ID    model_name=${flan_model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}    n_times=1
    ...    namespace=${test_namespace}
    Container Hardware Resources Should Match Expected    container_name=kserve-container
    ...    pod_label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    exp_requests=${requests}    exp_limits=${limits}
    ${new_requests}=    Create Dictionary    cpu=2    memory=3Gi
    Set Model Hardware Resources    model_name=${flan_model_name}    namespace=hw-res
    ...    requests=${new_requests}    limits=${NONE}
    Wait For Pods To Be Terminated    label_selector=serving.knative.dev/revisionUID=${rev_id}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Container Hardware Resources Should Match Expected    container_name=kserve-container
    ...    pod_label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    exp_requests=${new_requests}    exp_limits=${NONE}
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify Model Can Be Served And Query On A GPU Node
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model on GPU node
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Sanity    Tier1    ODS-2381    Resources-GPU
    [Setup]    Set Project And Runtime    namespace=singlemodel-gpu
    ${test_namespace}=    Set Variable    singlemodel-gpu
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    ${requests}=    Create Dictionary    nvidia.com/gpu=1
    ${limits}=    Create Dictionary    nvidia.com/gpu=1
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    requests_dict=${requests}    limits_dict=${limits}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Container Hardware Resources Should Match Expected    container_name=kserve-container
    ...    pod_label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    exp_requests=${requests}    exp_limits=${limits}
    Model Pod Should Be Scheduled On A GPU Node    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}    n_times=10
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${model_name}    n_times=5
    ...    namespace=${test_namespace}    inference_type=streaming
    [Teardown]   Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${model_name}    wait_prj_deletion=${FALSE}

Verify Non Admin Can Serve And Query A Model
    [Documentation]    Basic tests leveraging on a non-admin user for preparing, deploying and querying a LLM model
    ...                using Kserve and Caikit+TGIS runtime
    [Tags]    Sanity    Tier1    ODS-2326
    [Setup]    Run Keywords   Login To OCP Using API    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}  AND
    ...        Set Project And Runtime    namespace=non-admin-test
    ${test_namespace}=    Set Variable     non-admin-test
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    kserve_mode=${DSC_KSERVE_MODE}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${flan_model_name}   namespace=${test_namespace}
    ${body}=    Set Variable    '{"text": "${EXP_RESPONSES}[queries][0][query_text]"}'
    ${header}=    Set Variable    'mm-model-id: ${flan_model_name}'
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}
    [Teardown]  Run Keywords   Login To OCP Using API    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}   AND
    ...        Clean Up Test Project    test_ns=${test_namespace}   isvc_names=${models_names}
    ...        wait_prj_deletion=${FALSE}    kserve_mode=${DSC_KSERVE_MODE}

Verify User Can Serve And Query Flan-t5 Grammar Syntax Corrector
    [Documentation]    Deploys and queries flan-t5-large-grammar-synthesis model
    [Tags]    Tier2    ODS-2441
    [Setup]    Set Project And Runtime    namespace=grammar-model
    ${test_namespace}=    Set Variable     grammar-model
    ${flan_model_name}=    Set Variable    flan-t5-large-grammar-synthesis-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_GRAMMAR_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    query_idx=1
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    query_idx=${1}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Serve And Query Flan-t5 Large
    [Documentation]    Deploys and queries flan-t5-large model
    [Tags]    Tier2    ODS-2434
    [Setup]    Set Project And Runtime    namespace=flan-t5-large3
    ${test_namespace}=    Set Variable     flan-t5-large3
    ${flan_model_name}=    Set Variable    flan-t5-large
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_LARGE_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify Runtime Upgrade Does Not Affect Deployed Models
    [Documentation]    Upgrades the caikit runtime inthe same NS where a model
    ...                is already deployed. The expecation is that the current model
    ...                must remain unchanged after the runtime upgrade.
    ...                ATTENTION: this is an approximation of the runtime upgrade scenario, however
    ...                the real case scenario will be defined once RHODS actually ships the Caikit runtime.
    [Tags]    Sanity    Tier1    ODS-2404
    [Setup]    Set Project And Runtime    namespace=${TEST_NS}-up
    ${test_namespace}=    Set Variable     ${TEST_NS}-up
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}
    ${created_at}    ${caikitsha}=    Get Model Pods Creation Date And Image URL    model_name=${flan_model_name}
    ...    namespace=${test_namespace}    container=transformer-container
    Upgrade Runtime Image    new_image_url=quay.io/opendatahub/caikit-tgis-serving:stable
    ...    namespace=${test_namespace}    container=transformer-container    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Sleep    5s    reason=Sleep, in case the runtime upgrade takes some time to start performing actions on the pods...
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    ${created_at_after}    ${caikitsha_after}=    Get Model Pods Creation Date And Image URL    model_name=${flan_model_name}
    ...    namespace=${test_namespace}    container=transformer-container
    Should Be Equal    ${created_at}    ${created_at_after}
    Should Be Equal As Strings    ${caikitsha}    ${caikitsha_after}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Access Model Metrics From UWM
    [Documentation]    Verifies that model metrics are available for users in the
    ...                OpenShift monitoring system (UserWorkloadMonitoring)
    ...                PARTIALLY DONE: it is checking number of requests, number of successful requests
    ...                and model pod cpu usage. Waiting for a complete list of expected metrics and
    ...                derived metrics.
    [Tags]    Sanity    Tier1    ODS-2401
    [Setup]    Set Project And Runtime    namespace=singlemodel-metrics    enable_metrics=${TRUE}
    ${test_namespace}=    Set Variable     singlemodel-metrics
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    ${thanos_url}=    Get OpenShift Thanos URL
    ${token}=    Generate Thanos Token
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Wait Until Keyword Succeeds    30 times    4s
    ...    TGI Caikit And Istio Metrics Should Exist    thanos_url=${thanos_url}    thanos_token=${token}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=3
    ...    namespace=${test_namespace}
    Wait Until Keyword Succeeds    50 times    5s
    ...    User Can Fetch Number Of Requests Over Defined Time    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    query_kind=single    namespace=${test_namespace}    period=5m    exp_value=3
    Wait Until Keyword Succeeds    20 times    5s
    ...    User Can Fetch Number Of Successful Requests Over Defined Time    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    namespace=${test_namespace}    period=5m    exp_value=3
    Wait Until Keyword Succeeds    20 times    5s
    ...    User Can Fetch CPU Utilization    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    namespace=${test_namespace}    period=5m
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}
    Wait Until Keyword Succeeds    30 times    5s
    ...    User Can Fetch Number Of Requests Over Defined Time    thanos_url=${thanos_url}    thanos_token=${token}
    ...    model_name=${flan_model_name}    query_kind=stream    namespace=${test_namespace}    period=5m    exp_value=1
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Query A Model Using HTTP Calls
    [Documentation]    From RHOAI 2.5 HTTP is allowed and default querying protocol.
    ...                This tests deploys the runtime enabling HTTP port and send queries to the model
    [Tags]    ODS-2501    Sanity    Tier1
    [Setup]    Set Project And Runtime    namespace=kserve-http    protocol=http
    ${test_namespace}=    Set Variable     kserve-http
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${test_namespace}    runtime=${CAIKIT_TGIS_RUNTIME_NAME}
    Query Model Multiple Times    model_name=${model_name}    protocol=http
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}
    # temporarily disabling stream response validation. Need to re-design the expected response json file
    # because format of streamed response with http is slightly different from grpc
    Query Model Multiple Times    model_name=${model_name}    protocol=http
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}    query_idx=${0}    validate_response=${FALSE}
    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

Verify User Can Serve And Query A Model With Token
    [Documentation]    Basic tests for preparing, deploying and querying a LLM model
    ...                With Token using Kserve and Caikit+TGIS runtime
    [Tags]    RHOAIENG-6333
    ...       Tier1
    [Setup]    Set Project And Runtime    namespace=${TEST_NS}-cli
    ${test_namespace}=    Set Variable     ${TEST_NS}-cli
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    ${overlays}=    Create List    authorino
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    overlays=${overlays}

    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${test_namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${test_namespace}
   Create Role Binding For Authorino   name=${DEFAULT_BUCKET_PREFIX}   namespace=${test_namespace}
   ${inf_token}     Create Inference Access Token   ${test_namespace}    ${DEFAULT_BUCKET_SA_NAME}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=all-tokens    n_times=1
    ...    namespace=${test_namespace}   token=${inf_token}
    Query Model Multiple Times    model_name=${flan_model_name}
    ...    inference_type=streaming    n_times=1
    ...    namespace=${test_namespace}   token=${inf_token}

    [Teardown]    Clean Up Test Project    test_ns=${test_namespace}
    ...    isvc_names=${models_names}    wait_prj_deletion=${FALSE}

*** Keywords ***
Install Model Serving Stack Dependencies
    [Documentation]    Instaling And Configuring dependency operators: Service Mesh and Serverless.
    ...                This is likely going to change in the future and it will include a way to skip installation.
    ...                Caikit runtime will be shipped Out-of-the-box and will be removed from here.
    Skip If Component Is Not Enabled    kserve
    RHOSi Setup
    IF    ${SKIP_PREREQS_INSTALL} == ${FALSE}
        IF    ${SCRIPT_BASED_INSTALL} == ${FALSE}
            Install Service Mesh Stack
            Deploy Service Mesh CRs
            Install Serverless Stack
            Deploy Serverless CRs
            Configure KNative Gateways
        ELSE
            Run Install Script
        END
    END
    Load Expected Responses
    ${dsc_kserve_mode}=    Get KServe Default Deployment Mode From DSC
    Set Suite Variable    ${DSC_KSERVE_MODE}    ${dsc_kserve_mode}
    IF    "${dsc_kserve_mode}" == "RawDeployment"
        Set Suite Variable    ${IS_KSERVE_RAW}    ${TRUE}
    ELSE
        Set Suite Variable    ${IS_KSERVE_RAW}    ${FALSE}
    END

Install Service Mesh Stack
    [Documentation]    Installs the operators needed for Service Mesh operator purposes
    Install ISV Operator From OperatorHub Via CLI    operator_name=${SERVICEMESH_OP_NAME}
    ...    subscription_name=${SERVICEMESH_SUB_NAME}
    ...    catalog_source_name=redhat-operators
    Install ISV Operator From OperatorHub Via CLI    operator_name=${KIALI_OP_NAME}
    ...    subscription_name=${KIALI_SUB_NAME}
    ...    catalog_source_name=redhat-operators
    Install ISV Operator From OperatorHub Via CLI    operator_name=${JAEGER_OP_NAME}
    ...    subscription_name=${JAEGER_SUB_NAME}
    ...    catalog_source_name=redhat-operators
    Wait Until Operator Subscription Last Condition Is
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${SERVICEMESH_SUB_NAME}
    Wait Until Operator Subscription Last Condition Is
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${KIALI_SUB_NAME}
    Wait Until Operator Subscription Last Condition Is
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${JAEGER_SUB_NAME}
    # Sleep   30s
    Wait For Pods To Be Ready    label_selector=name=istio-operator
    ...    namespace=${DEFAULT_OP_NS}
    Wait For Pods To Be Ready    label_selector=name=jaeger-operator
    ...    namespace=${DEFAULT_OP_NS}
    Wait For Pods To Be Ready    label_selector=name=kiali-operator
    ...    namespace=${DEFAULT_OP_NS}

Deploy Service Mesh CRs
    [Documentation]    Deploys CustomResources for ServiceMesh operator
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${SERVICEMESH_CR_NS}
    # Should Be Equal As Integers    ${rc}    ${0}
    Copy File     ${SERVICEMESH_CONTROLPLANE_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g' ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    Copy File     ${SERVICEMESH_ROLL_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e "s/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    Copy File     ${SERVICEMESH_PEERAUTH_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/peer_auth_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e "s/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/peer_auth_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e "s/{{SERVERLESS_CR_NS}}/${SERVERLESS_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/peer_auth_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e "s/{{KSERVE_NS}}/${KSERVE_NS}/g" ${LLM_RESOURCES_DIRPATH}/peer_auth_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    Wait For Pods To Be Ready    label_selector=app=istiod
    ...    namespace=${SERVICEMESH_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=prometheus
    ...    namespace=${SERVICEMESH_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=istio-ingressgateway
    ...    namespace=${SERVICEMESH_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=istio-egressgateway
    ...    namespace=${SERVICEMESH_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=jaeger
    ...    namespace=${SERVICEMESH_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=kiali
    ...    namespace=${SERVICEMESH_CR_NS}
    Copy File     ${SERVICEMESH_ROLL_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g' ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{KSERVE_NS}}/${KSERVE_NS}/g' ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    # Add Namespace To ServiceMeshMemberRoll    namespace=${KSERVE_NS}
    Add Peer Authentication    namespace=${SERVICEMESH_CR_NS}
    Add Peer Authentication    namespace=${KSERVE_NS}

Add Peer Authentication
    [Documentation]    Add a service to the service-to-service auth system of ServiceMesh
    [Arguments]    ${namespace}
    Copy File     ${SERVICEMESH_PEERAUTH_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/peer_auth_${namespace}.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{NAMESPACE}}/${namespace}/g' ${LLM_RESOURCES_DIRPATH}/peer_auth_${namespace}.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/peer_auth_${namespace}.yaml
    Should Be Equal As Integers    ${rc}    ${0}

Install Serverless Stack
    [Documentation]    Install the operators needed for Serverless operator purposes
    ${rc}    ${out}=    Run And Return Rc And Output    oc create namespace ${SERVERLESS_NS}
    Install ISV Operator From OperatorHub Via CLI    operator_name=${SERVERLESS_OP_NAME}
    ...    namespace=${SERVERLESS_NS}
    ...    subscription_name=${SERVERLESS_SUB_NAME}
    ...    catalog_source_name=redhat-operators
    ...    operator_group_name=serverless-operators
    ...    operator_group_ns=${SERVERLESS_NS}
    ...    operator_group_target_ns=${NONE}
    Wait Until Operator Subscription Last Condition Is
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${SERVERLESS_SUB_NAME}
    ...    namespace=${SERVERLESS_NS}
    # Sleep   30s
    Wait For Pods To Be Ready    label_selector=name=knative-openshift
    ...    namespace=${SERVERLESS_NS}
    Wait For Pods To Be Ready    label_selector=name=knative-openshift-ingress
    ...    namespace=${SERVERLESS_NS}
    Wait For Pods To Be Ready    label_selector=name=knative-operator
    ...    namespace=${SERVERLESS_NS}

Deploy Serverless CRs
    [Documentation]    Deploys the CustomResources for Serverless operator
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${SERVERLESS_CR_NS}
    Add Peer Authentication    namespace=${SERVERLESS_CR_NS}
    Add Namespace To ServiceMeshMemberRoll    namespace=${SERVERLESS_CR_NS}
    Copy File     ${SERVERLESS_KNATIVECR_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/knativeserving_istio_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{SERVERLESS_CR_NS}}/${SERVERLESS_CR_NS}/g' ${LLM_RESOURCES_DIRPATH}/knativeserving_istio_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/knativeserving_istio_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    Sleep   15s
    Wait For Pods To Be Ready    label_selector=app=controller
    ...    namespace=${SERVERLESS_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=net-istio-controller
    ...    namespace=${SERVERLESS_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=net-istio-webhook
    ...    namespace=${SERVERLESS_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=autoscaler-hpa
    ...    namespace=${SERVERLESS_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=domain-mapping
    ...    namespace=${SERVERLESS_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=webhook
    ...    namespace=${SERVERLESS_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=activator
    ...    namespace=${SERVERLESS_CR_NS}
    Wait For Pods To Be Ready    label_selector=app=autoscaler
    ...    namespace=${SERVERLESS_CR_NS}
    Enable Toleration Feature In KNativeServing    knative_serving_ns=${SERVERLESS_CR_NS}

Configure KNative Gateways
    [Documentation]    Sets up the KNative (Serverless) Gateways
    ${base_dir}=    Set Variable    ods_ci/tmp/certs
    ${exists}=    Run Keyword And Return Status
    ...    Directory Should Exist    ${base_dir}
    IF    ${exists} == ${FALSE}
        Create Directory    ${base_dir}
    END
    ${rc}    ${domain_name}=    Run And Return Rc And Output
    ...    oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}' | awk -F'.' '{print $(NF-1)"."$NF}'
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${common_name}=    Run And Return Rc And Output
    ...    oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}'|sed 's/apps.//'
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output    ./${WILDCARD_GEN_SCRIPT_FILEPATH} ${base_dir} ${domain_name} ${common_name}
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc create secret tls wildcard-certs --cert=${base_dir}/wildcard.crt --key=${base_dir}/wildcard.key -n ${SERVICEMESH_CR_NS}
    Copy File     ${SERVERLESS_GATEWAYS_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g' ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{SERVERLESS_CR_NS}}/${SERVERLESS_CR_NS}/g' ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}

Run Install Script
    [Documentation]    Install KServe serving stack using
    ...                https://github.com/opendatahub-io/caikit-tgis-serving/blob/main/demo/kserve/scripts/README.md
    ${rc}=    Run And Return Rc    git clone https://github.com/opendatahub-io/caikit-tgis-serving
    Should Be Equal As Integers    ${rc}    ${0}
    IF    "${SCRIPT_TARGET_OPERATOR}" == "brew"
        ${rc}=    Run And Watch Command    TARGET_OPERATOR=${SCRIPT_TARGET_OPERATOR} BREW_TAG=${SCRIPT_BREW_TAG} CHECK_UWM=false ./scripts/install/kserve-install.sh
        ...    cwd=caikit-tgis-serving/demo/kserve
    ELSE
        ${rc}=    Run And Watch Command    DEPLOY_ODH_OPERATOR=false TARGET_OPERATOR=${SCRIPT_TARGET_OPERATOR} CHECK_UWM=false ./scripts/install/kserve-install.sh
        ...    cwd=caikit-tgis-serving/demo/kserve
    END
    Should Be Equal As Integers    ${rc}    ${0}
