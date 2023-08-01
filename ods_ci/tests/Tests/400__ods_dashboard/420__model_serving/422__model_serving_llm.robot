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



*** Test Cases ***
Verify External Dependency Operators Can Be Deployed
    [Tags]    ODS-2326
    Pass Execution    message=Installation done as part of Suite Setup.


*** Keywords ***
Install Model Serving Stack Dependencies
    Install Service Mesh Stack
    Deploy Service Mesh CRs
    Install Serverless Stack
    Deploy Serverless CRs 

Install Service Mesh Stack
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
    Wait For Pods To Be Ready    label_selector=name=istio-operator
    ...    namespace=${DEFAULT_OP_NS}
    Wait For Pods To Be Ready    label_selector=name=jaeger-operator
    ...    namespace=${DEFAULT_OP_NS}
    Wait For Pods To Be Ready    label_selector=name=kiali-operator
    ...    namespace=${DEFAULT_OP_NS}

Deploy Service Mesh CRs
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${SERVICEMESH_CR_NS}
    Copy File     ${SERVICEMESH_CONTROLPLANE_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
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
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/peer_auth_filled.yaml
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

Install Serverless Stack
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
    Wait For Pods To Be Ready    label_selector=name=knative-openshift
    ...    namespace=${SERVERLESS_NS}
    Wait For Pods To Be Ready    label_selector=name=knative-openshift-ingress
    ...    namespace=${SERVERLESS_NS}
    Wait For Pods To Be Ready    label_selector=knative-operator
    ...    namespace=${SERVERLESS_NS}

Deploy Serverless CRs 
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${SERVERLESS_CR_NS}
    Add Namespace To ServiceMeshMemberRoll    namespace=${SERVERLESS_CR_NS}
    Copy File     ${SERVERLESS_KNATIVECR_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/knativeserving_istio_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVERLESS_CR_NS}}/${SERVERLESS_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/knativeserving_istio_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/knativeserving_istio_filled.yaml
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
