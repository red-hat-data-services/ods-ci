*** Settings ***
Documentation    Collection of tests to validate the model serving stack for Large Language Models (LLM)
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
${KSERVE_NS}=    kserve    # will be replaced by redhat-ods-applications
${CAIKIT_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/caikit_servingruntime.yaml
${TEST_NS}=    watsonx


*** Test Cases ***
Verify External Dependency Operators Can Be Deployed
    [Tags]    ODS-2326    WatsonX
    Pass Execution    message=Installation done as part of Suite Setup.


*** Keywords ***
Install Model Serving Stack Dependencies
    [Documentation]    Instaling And Configuring dependency operators: Service Mesh and Serverless.
    ...                This is likely going to change in the future and it will include a way to skip installation.
    ...                Caikit runtime will be shipped Out-of-the-box and will be removed from here.
    Install Service Mesh Stack
    Deploy Service Mesh CRs
    Install Serverless Stack
    Deploy Serverless CRs
    Configure KNative Gateways
    Set Up Test OpenShift Project    namespace=${TEST_NS}
    # temporary step - caikit will be shipped OOTB
    Deploy Caikit Serving Runtime    namespace=${TEST_NS}

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
    Sleep    30s
    Wait For Pods To Be Ready    label_selector=name=istio-operator
    ...    namespace=${DEFAULT_OP_NS}
    Wait For Pods To Be Ready    label_selector=name=jaeger-operator
    ...    namespace=${DEFAULT_OP_NS}
    Wait For Pods To Be Ready    label_selector=name=kiali-operator
    ...    namespace=${DEFAULT_OP_NS}

Deploy Service Mesh CRs
    [Documentation]    Deploys CustomResources for ServiceMesh operator
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${SERVICEMESH_CR_NS}
    Copy File     ${SERVICEMESH_CONTROLPLANE_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    Copy File     ${SERVICEMESH_ROLL_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    Add Peer Authentication    namespace=${SERVICEMESH_CR_NS}
    Add Peer Authentication    namespace=${SERVERLESS_CR_NS}
    Add Peer Authentication    namespace=${KSERVE_NS}
    Sleep    30s
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

Add Peer Authentication
    [Documentation]    Add a service to the service-to-service auth system of ServiceMesh
    [Arguments]    ${namespace}
    Copy File     ${SERVICEMESH_PEERAUTH_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/peer_auth_${namespace}.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{NAMESPACE}}/${namespace}/g" ${LLM_RESOURCES_DIRPATH}/peer_auth_${namespace}.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/peer_auth_${namespace}.yaml

Install Serverless Stack
    [Documentation]    Install the operators needed for Serverless operator purposes
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${SERVERLESS_NS}
    Install ISV Operator From OperatorHub Via CLI    operator_name=${SERVERLESS_OP_NAME}
    ...    subscription_name=${SERVERLESS_SUB_NAME}
    ...    catalog_source_name=redhat-operators
    ...    operator_group_name=serverless-operators
    ...    operator_group_ns=${SERVERLESS_NS}
    ...    operator_group_target_ns=''
    Wait Until Operator Subscription Last Condition Is
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${SERVERLESS_SUB_NAME}
    Sleep    30s
    Wait For Pods To Be Ready    label_selector=name=knative-openshift
    ...    namespace=${SERVERLESS_NS}
    Wait For Pods To Be Ready    label_selector=name=knative-openshift-ingress
    ...    namespace=${SERVERLESS_NS}
    Wait For Pods To Be Ready    label_selector=knative-operator
    ...    namespace=${SERVERLESS_NS}

Deploy Serverless CRs 
    [Documentation]    Deploys the CustomResources for Serverless operator
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${SERVERLESS_CR_NS}
    Add Namespace To ServiceMeshMemberRoll    namespace=${SERVERLESS_CR_NS}
    Copy File     ${SERVERLESS_KNATIVECR_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/knativeserving_istio_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVERLESS_CR_NS}}/${SERVERLESS_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/knativeserving_istio_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/knativeserving_istio_filled.yaml
    Sleep    15s
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
    ${rc}    ${common_name}=    Run And Return Rc And Output
    ...    oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}'|sed 's/apps.//'
    ${rc}    ${out}=    Run And Return Rc And Output    ./${WILDCARD_GEN_SCRIPT_FILEPATH} ${base_dir} ${domain_name} ${common_name}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc create secret tls wildcard-certs --cert=${base_dir}/wildcard.crt --key=${base_dir}/wildcard.key -n ${SERVICEMESH_CR_NS}
    Copy File     ${SERVERLESS_GATEWAYS_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVERLESS_CR_NS}}/${SERVERLESS_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/gateways_filled.yaml

Set Up Test OpenShift Project
    [Documentation]    Creates a test namespace and track it under ServiceMesh
    [Arguments]    ${test_ns}
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${test_ns}
    Add Peer Authentication    namespace=${test_ns}
    Add Namespace To ServiceMeshMemberRoll    namespace=${test_ns}

Deploy Caikit Serving Runtime
    [Documentation]    Create the ServingRuntime CustomResource in the test ${namespace}.
    ...                This must be done before deploying a model which needs Caikit.
    [Arguments]    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${CAIKIT_FILEPATH} -n ${namespace}
