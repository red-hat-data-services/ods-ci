*** Settings ***
Documentation     Collection of tests to validate the model serving stack for Large Language Models (LLM)
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/Page/Operators/ISVs.resource
Suite Setup       Install Model Serving Stack Dependencies
# Suite Teardown


*** Variables ***
${DEFAULT_OP_NS}=    openshift-operators
${LLM_RESOURCES_DIRPATH}=    ods_ci/tests/Resources/Files/llm
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
${SERVICEMESH_CR_NS}=    istio-system
${KIALI_OP_NAME}=     kiali-ossm
${KIALI_SUB_NAME}=    kiali-ossm
${JAEGER_OP_NAME}=     jaeger-product
${JAEGER_SUB_NAME}=    jaeger-product
${KSERVE_NS}=    redhat-ods-operator    # NS is "kserve" for ODH
${CAIKIT_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/caikit_servingruntime.yaml
${TEST_NS}=    watsonx
${BUCKET_SECRET_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/bucket_secret.yaml
${BUCKET_SA_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/bucket_sa.yaml
${USE_BUCKET_HTTPS}=    "1"
${INFERENCESERVICE_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/caikit_isvc.yaml
${DEFAULT_BUCKET_SECRET_NAME}=    models-bucket-secret
${DEFAULT_BUCKET_SA_NAME}=        models-bucket-sa
${EXP_RESPONSES_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/model_expected_responses.json
${SKIP_PREREQS_INSTALL}=    ${FALSE}
${MODELS_BUCKET}=    ${S3.BUCKET_3}
${FLAN_MODEL_S3_DIR}=    flan-t5-small
${BLOOM_MODEL_S3_DIR}=    bloom-560m
${FLAN_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${FLAN_MODEL_S3_DIR}/
${BLOOM_STORAGE_URI}=    s3://${S3.BUCKET_3.NAME}/${BLOOM_MODEL_S3_DIR}/


*** Test Cases ***
Verify External Dependency Operators Can Be Deployed
    [Tags]    ODS-2326    WatsonX
    Pass Execution    message=Installation done as part of Suite Setup.

Verify User Can Serve And Query A Model
    [Tags]    ODS-2341    WatsonX
    [Setup]    Set Project And Runtime    namespace=${TEST_NS}
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ...    namespace=${TEST_NS}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=${TEST_NS}
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${flan_model_name}   namespace=${TEST_NS}
    ${body}=    Set Variable    '{"text": "${EXP_RESPONSES}[queries][0][query_text]"}'
    ${header}=    Set Variable    'mm-model-id: ${flan_model_name}'
    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict"
    ...    json_body=${body}    json_header=${header}
    ...    insecure=${TRUE}
    Query Models And Check Responses Multiple Times    models_names=${models_names}    n_times=1
    [Teardown]    Clean Up Test Project    test_ns=${TEST_NS}
    ...    isvc_names=${models_names}

Verify User Can Deploy Multiple Models In The Same Namespace
    [Tags]    ODS-2371    WatsonX
    [Setup]    Set Project And Runtime    namespace=${TEST_NS}
    ${model_one_name}=    Set Variable    bloom-560m-caikit
    ${model_two_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_one_name}    ${model_two_name}
    Compile Inference Service YAML    isvc_name=${model_one_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ...    namespace=${TEST_NS}
    Compile Inference Service YAML    isvc_name=${model_two_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ...    namespace=${TEST_NS}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_one_name}
    ...    namespace=${TEST_NS}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_two_name}
    ...    namespace=${TEST_NS}
    Query Models And Check Responses Multiple Times    models_names=${models_names}    n_times=10
    [Teardown]    Clean Up Test Project    test_ns=${TEST_NS}
    ...    isvc_names=${models_names}

Verify Model Upgrade Using Canaray Rollout
    [Tags]    ODS-2372    WatsonX
    [Setup]    Set Project And Runtime    namespace=canary-model-upgrade
    ${flan_isvc_name}=    Set Variable    flan-t5-small-caikit
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    Compile And Query LLM model   isvc_name=${flan_isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_name=${model_name}
    ...    namespace=canary-model-upgrade
    Log To Console    Applying Canary Tarffic for Model Upgrade
    Compile And Query LLM Model   isvc_name=${flan_isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    ...    model_name=${model_name}
    ...    canaryTrafficPercent=20
    ...    namespace=canary-model-upgrade
#    ...    multiple_query=YES
    Log To Console    Remove Canary Tarffic For Model Upgrade
    Compile And Query LLM Model    isvc_name=${flan_isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_name=${model_name}
    ...    model_storage_uri=${BLOOM_STORAGE_URI}
    ...    namespace=canary-model-upgrade
    [Teardown]   Clean Up Test Project    test_ns=canary-model-upgrade
    ...    isvc_names=${models_names}

Verify Model Pods Are Deleted When No Inference Service Is Present
    [Tags]    ODS-2373    WatsonX
    [Setup]    Set Project And Runtime    namespace=no-infer-kserve
    ${flan_isvc_name}=    Set Variable    flan-t5-small-caikit
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    Compile And Query LLM Model   isvc_name=${flan_isvc_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    model_name=${model_name}
    ...    namespace=no-infer-kserve
    Delete InfereceService    isvc_name=${flan_isvc_name}    namespace=no-infer-kserve
    ${rc}    ${out}=    Run And Return Rc And Output    oc wait pod -l serving.kserve.io/inferenceservice=${flan_isvc_name} -n no-infer-kserve --for=delete --timeout=200s
    Should Be Equal As Integers    ${rc}    ${0}
    [Teardown]   Clean Up Test Project    test_ns=no-infer-kserve
    ...    isvc_names=${models_names}   isvc_delete=${FALSE}

Verify User Can Change The Minimum Number Of Replicas For A Model
    [Tags]    ODS-2376    WatsonX
    [Setup]    Set Project And Runtime    namespace=${TEST_NS}
    ${model_name}=    Set Variable    flan-t5-small-caikit
    ${models_names}=    Create List    ${model_name}
    Compile Inference Service YAML    isvc_name=${model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    ...    min_replicas=2
    Deploy Model Via CLI    isvc_filepath=${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ...    namespace=${TEST_NS}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${TEST_NS}    exp_replicas=2
    Query Models And Check Responses Multiple Times    models_names=${models_names}    n_times=3
    ${rev_id}=    Scale Number Of Replicas    n_replicas=3    model_name=${model_name}
    ...    namespace=${TEST_NS}
    Wait For Pods To Be Terminated    label_selector=serving.knative.dev/revisionUID=${rev_id}
    ...    namespace=${TEST_NS}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${TEST_NS}    exp_replicas=3
    Query Models And Check Responses Multiple Times    models_names=${models_names}    n_times=3
    ${rev_id}=    Scale Number Of Replicas    n_replicas=1    model_name=${model_name}
    ...    namespace=${TEST_NS}
    Wait For Pods To Be Terminated    label_selector=serving.knative.dev/revisionUID=${rev_id}
    ...    namespace=${TEST_NS}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${TEST_NS}    exp_replicas=1
    Query Models And Check Responses Multiple Times    models_names=${models_names}    n_times=3
    [Teardown]   Clean Up Test Project    test_ns=${TEST_NS}
    ...    isvc_names=${models_names}

Verify User Can Autoscale Using Concurrency
    [Tags]    ODS-2377    WatsonX
    [Setup]    Set Project And Runtime    namespace=autoscale-con
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${model_name}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=s3://ods-ci-wisdom/flan-t5-small/
    ...    auto_scale=True
    Deploy Model Via CLI    isvc_filepath=${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ...    namespace=autoscale-con
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=autoscale-con
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${flan_model_name}   namespace=autoscale-con
    ${body}=    Set Variable    '{"text": "At what temperature does liquid Nitrogen boil?"}'
    ${header}=    Set Variable    'mm-model-id: ${flan_model_name}'

    FOR    ${index}    IN RANGE    30
           Query Model With GRPCURL   host=${host}    port=443
           ...    endpoint="caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict"
           ...    json_body=${body}    json_header=${header}
           ...    insecure=${TRUE}     background=${TRUE}
    END
    @{pod_lists}=    Oc Get    kind=Pod    namespace=autoscale-con
    ...    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ${count}=    Get Length   ${pod_lists}
    IF   ${count} > ${1}
         Log      Autoscale Using Concurrency is completed.Model Pod has been scaled up from 1 to $count
    ELSE
         FAIL     msg= Autoscale Using Concurrency has failed and Model pod has not been scaled up
    END
    [Teardown]   Clean Up Test Project    test_ns=autoscale-con
    ...    isvc_names=${model_name}

Verify User Can Validate Scale To Zero
    [Tags]    ODS-2379    WatsonX
    [Setup]    Set Project And Runtime    namespace=autoscale-zero
    ${flan_model_name}=    Set Variable    flan-t5-small-caikit
    ${model_name}=    Create List    ${flan_model_name}
    Compile Inference Service YAML    isvc_name=${flan_model_name}
    ...    sa_name=${DEFAULT_BUCKET_SA_NAME}
    ...    model_storage_uri=${FLAN_STORAGE_URI}
    Deploy Model Via CLI    isvc_filepath=${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ...    namespace=autoscale-zero
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=autoscale-zero
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${flan_model_name}   namespace=autoscale-zero
    ${body}=    Set Variable    '{"text": "At what temperature does liquid Nitrogen boil?"}'
    ${header}=    Set Variable    'mm-model-id: ${flan_model_name}'
    Query Model With GRPCURL   host=${host}    port=443
    ...    endpoint="caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict"
    ...    json_body=${body}    json_header=${header}
    ...    insecure=${TRUE}
    Update Scale To Zero For Knative Serving   serving_name=knative-serving
    ...    namespace=knative-serving   status=true
    ${revision_id}=    Scale Number Of Replicas    n_replicas=0    model_name=${flan_model_name}
    ...    namespace=autoscale-zero
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=autoscale-zero
    Wait For Pods To Be Terminated    label_selector=serving.kserve.io/inferenceservice=${flan_model_name}
    ...    namespace=autoscale-zero
    [Teardown]   Clean Up Test Project    test_ns=autoscale-zero
    ...    isvc_names=${model_name}

*** Keywords ***
Install Model Serving Stack Dependencies
    [Documentation]    Instaling And Configuring dependency operators: Service Mesh and Serverless.
    ...                This is likely going to change in the future and it will include a way to skip installation.
    ...                Caikit runtime will be shipped Out-of-the-box and will be removed from here.
    RHOSi Setup
    IF    ${SKIP_PREREQS_INSTALL} == ${FALSE}
        Install Service Mesh Stack
        Deploy Service Mesh CRs
        Install Serverless Stack
        Deploy Serverless CRs
        Configure KNative Gateways
    END
    Load Expected Responses

Clean Up Test Project
    [Arguments]    ${test_ns}    ${isvc_names}    ${isvc_delete}=${TRUE}
    IF    ${isvc_delete} == ${TRUE}
        FOR    ${index}    ${isvc_name}    IN ENUMERATE    @{isvc_names}
              Log    Deleting ${isvc_name}
              Delete InfereceService    isvc_name=${isvc_name}    namespace=${test_ns}
        END
    ELSE
        Log To Console     InferenceService Delete option not provided by user
    END
    Remove Namespace From ServiceMeshMemberRoll    namespace=${test_ns}
    ...    servicemesh_ns=${SERVICEMESH_CR_NS}
    ${rc}    ${out}=    Run And Return Rc And Output    oc delete project ${test_ns}
    Should Be Equal As Integers    ${rc}    ${0}


Load Expected Responses
    [Documentation]    Loads the json file containing the expected answer for each
    ...                query and model
    ${exp_responses}=    Load Json File    ${EXP_RESPONSES_FILEPATH}
    Set Suite Variable    ${EXP_RESPONSES}    ${exp_responses}

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
    ...    sed -i 's/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g' ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    Copy File     ${SERVICEMESH_ROLL_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    Copy File     ${SERVICEMESH_PEERAUTH_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/peer_auth_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/peer_auth_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVERLESS_CR_NS}}/${SERVERLESS_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/peer_auth_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{KSERVE_NS}}/${KSERVE_NS}/g" ${LLM_RESOURCES_DIRPATH}/peer_auth_filled.yaml
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
    ...    sed -i 's/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g' ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{KSERVE_NS}}/${KSERVE_NS}/g' ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
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
    ...    sed -i 's/{{NAMESPACE}}/${namespace}/g' ${LLM_RESOURCES_DIRPATH}/peer_auth_${namespace}.yaml
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
    ...    sed -i 's/{{SERVERLESS_CR_NS}}/${SERVERLESS_CR_NS}/g' ${LLM_RESOURCES_DIRPATH}/knativeserving_istio_filled.yaml
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
    ...    sed -i 's/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g' ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{SERVERLESS_CR_NS}}/${SERVERLESS_CR_NS}/g' ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}


Set Up Test OpenShift Project
    [Documentation]    Creates a test namespace and track it under ServiceMesh
    [Arguments]    ${test_ns}
    ${rc}    ${out}=    Run And Return Rc And Output    oc get project ${test_ns}
    IF    "${rc}" == "${0}"
        Log    message=OpenShift Project ${test_ns} already present. Skipping project setup...
        ...    level=WARN
        RETURN
    END
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${test_ns}
    Should Be Equal As Numbers    ${rc}    ${0}
    Add Peer Authentication    namespace=${test_ns}
    Add Namespace To ServiceMeshMemberRoll    namespace=${test_ns}

Deploy Caikit Serving Runtime
    [Documentation]    Create the ServingRuntime CustomResource in the test ${namespace}.
    ...                This must be done before deploying a model which needs Caikit.
    [Arguments]    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output    oc get ServingRuntime caikit-runtime -n ${namespace}
    IF    "${rc}" == "${0}"
        Log    message=ServingRuntime caikit-runtime in ${namespace} NS already present. Skipping runtime setup...
        ...    level=WARN
        RETURN
    END
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${CAIKIT_FILEPATH} -n ${namespace}

Set Project And Runtime
    [Arguments]    ${namespace}
    Set Up Test OpenShift Project    test_ns=${namespace}
    Create Secret For S3-Like Buckets    endpoint=${MODELS_BUCKET.ENDPOINT}
    ...    region=${MODELS_BUCKET.REGION}    namespace=${namespace}
    # temporary step - caikit will be shipped OOTB
    Deploy Caikit Serving Runtime    namespace=${namespace}

Create Secret For S3-Like Buckets
    [Documentation]    Configures the cluster to fetch models from a S3-like bucket
    [Arguments]    ${name}=${DEFAULT_BUCKET_SECRET_NAME}    ${sa_name}=${DEFAULT_BUCKET_SA_NAME}
    ...            ${namespace}=${TEST_NS}    ${endpoint}=${S3.AWS_DEFAULT_ENDPOINT}
    ...            ${region}=${S3.AWS_DEFAULT_REGION}    ${access_key_id}=${S3.AWS_ACCESS_KEY_ID}
    ...            ${access_key}=${S3.AWS_SECRET_ACCESS_KEY}    ${use_https}=${USE_BUCKET_HTTPS}
    ${rc}    ${out}=    Run And Return Rc And Output    oc get secret ${name} -n ${namespace}
    IF    "${rc}" == "${0}"
        Log    message=Secret ${name} in ${namespace} NS already present. Skipping secret setup...
        ...    level=WARN
        RETURN
    END
    Copy File     ${BUCKET_SECRET_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    Copy File     ${BUCKET_SA_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/bucket_sa_filled.yaml
    ${endpoint}=    Replace String   ${endpoint}    https://    ${EMPTY}
    ${endpoint_escaped}=    Escape String Chars    str=${endpoint}
    ${accesskey_escaped}=    Escape String Chars    str=${access_key}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{ENDPOINT}}/${endpoint_escaped}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{USE_HTTPS}}/${use_https}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{REGION}}/${region}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{ACCESS_KEY_ID}}/${access_key_id}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{SECRET_ACCESS_KEY}}/${accesskey_escaped}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
        ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{NAME}}/${name}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{NAME}}/${sa_name}/g' ${LLM_RESOURCES_DIRPATH}/bucket_sa_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml -n ${namespace}
    Should Be Equal As Integers    ${rc}    ${0}
    Run Keyword And Ignore Error    Run    oc create -f ${LLM_RESOURCES_DIRPATH}/bucket_sa_filled.yaml -n ${namespace}
    Add Secret To Service Account    sa_name=${sa_name}    secret_name=${name}    namespace=${namespace}

Compile Inference Service YAML
    [Documentation]    Prepare the Inference Service YAML file in order to deploy a model
    [Arguments]    ${isvc_name}    ${sa_name}    ${model_storage_uri}    ${canaryTrafficPercent}=${EMPTY}
    ...            ${min_replicas}=1   ${scaleTarget}=1   ${scaleMetric}=concurrency  ${auto_scale}=${NONE}
    Copy File     ${INFERENCESERVICE_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ${model_storage_uri}=    Escape String Chars    str=${model_storage_uri}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{INFERENCE_SERVICE_NAME}}/${isvc_name}/g' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{MIN_REPLICAS}}/${min_replicas}/g' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{SA_NAME}}/${sa_name}/g' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{STORAGE_URI}}/${model_storage_uri}/g' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i 's/{{MIN_REPLICAS}}/${min_replicas}/g' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    IF   '${auto_scale}' == '${NONE}'
          ${rc}    ${out}=    Run And Return Rc And Output
          ...    sed -i '/scaleMetric/d' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
          ${rc}    ${out}=    Run And Return Rc And Output
          ...    sed -i '/scaleTarget/d' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ELSE
          ${rc}    ${out}=    Run And Return Rc And Output
          ...    sed -i 's/{{SCALE_TARGET}}/${scaleTarget}/g' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
          ${rc}    ${out}=    Run And Return Rc And Output
          ...    sed -i 's/{{SCALE_METRIC}}/${scaleMetric}/g' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    END
    IF   '${canaryTrafficPercent}' == '${EMPTY}'
        ${rc}    ${out}=    Run And Return Rc And Output
        ...    sed -i '/canaryTrafficPercent/d' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ELSE
        ${rc}    ${out}=    Run And Return Rc And Output
        ...    sed -i 's/{{CanaryTrafficPercent}}/${canaryTrafficPercent}/g' ${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    END

Model Response Should Match The Expectation
    [Documentation]    Checks that the actual model response matches the expected answer.
    ...                The goals are:
    ...                   - to ensure we are getting an answer from the model (e.g., not an empty text)
    ...                   - to check that we receive the answer from the right model
    ...                when multiple ones are deployed
    [Arguments]    ${model_response}    ${model_name}    ${query_idx}
    Should Be Equal As Integers    ${model_response}[generated_tokens]    ${EXP_RESPONSES}[queries][${query_idx}][models][${model_name}][generatedTokenCount]
    ${cleaned_response_text}=    Replace String Using Regexp    ${model_response}[generated_text]    \\s+    ${SPACE}
    ${cleaned_exp_response_text}=    Replace String Using Regexp    ${EXP_RESPONSES}[queries][${query_idx}][models][${model_name}][response_text]    \\s+    ${SPACE}
    ${cleaned_response_text}=    Strip String    ${cleaned_response_text}
    ${cleaned_exp_response_text}=    Strip String    ${cleaned_exp_response_text}
    Should Be Equal    ${cleaned_response_text}    ${cleaned_exp_response_text}

Query Models And Check Responses Multiple Times
    [Documentation]    Queries and checks the responses of the given models in a loop
    ...                running ${n_times}. For each loop run it queries all the model in sequence
    [Arguments]    ${models_names}    ${n_times}=10
    FOR    ${counter}    IN RANGE    0    ${n_times}    1
        Log    ${counter}
        FOR    ${index}    ${model_name}    IN ENUMERATE    @{models_names}
            Log    ${index}: ${model_name}
            ${host}=    Get KServe Inference Host Via CLI    isvc_name=${model_name}   namespace=${TEST_NS}
            ${body}=    Set Variable    '{"text": "${EXP_RESPONSES}[queries][0][query_text]"}'
            ${header}=    Set Variable    'mm-model-id: ${model_name}'
            ${res}=    Query Model With GRPCURL   host=${host}    port=443
            ...    endpoint="caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict"
            ...    json_body=${body}    json_header=${header}
            ...    insecure=${TRUE}
            Run Keyword And Continue On Failure
            ...    Model Response Should Match The Expectation    model_response=${res}    model_name=${model_name}
            ...    query_idx=0
        END
    END

Compile And Query LLM model
    [Arguments]    ${isvc_name}     ${model_storage_uri}    ${model_name}
    ...            ${canaryTrafficPercent}=${EMPTY}   ${namespace}=${TEST_NS}  ${sa_name}=${DEFAULT_BUCKET_SA_NAME}
    ...            ${multiple_query}=${EMPTY}
    Compile Inference Service YAML    isvc_name=${isvc_name}
    ...    sa_name=${sa_name}
    ...    model_storage_uri=${model_storage_uri}
    ...    canaryTrafficPercent=${canaryTrafficPercent}
    Deploy Model Via CLI    isvc_filepath=${LLM_RESOURCES_DIRPATH}/caikit_isvc_filled.yaml
    ...    namespace=${namespace}
    Wait For Pods To Be Ready    label_selector=serving.kserve.io/inferenceservice=${isvc_name}
    ...    namespace=${namespace}
    ${host}=    Get KServe Inference Host Via CLI    isvc_name=${isvc_name}   namespace=${namespace}
    ${body}=    Set Variable    '{"text": "At what temperature does liquid Nitrogen boil?"}'
    ${header}=    Set Variable    'mm-model-id: ${model_name}'
    IF   '${multiple_query}' != '${EMPTY}'
          Query Models And Check Responses Multiple Times    models_names=${models_name}    n_times=10
    ELSE
          ${res}=      Query Model With GRPCURL   host=${host}    port=443
          ...    endpoint="caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict"
          ...    json_body=${body}    json_header=${header}
          ...    insecure=${TRUE}
    END
