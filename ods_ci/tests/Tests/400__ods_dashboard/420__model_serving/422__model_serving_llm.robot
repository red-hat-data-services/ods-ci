*** Settings ***
Documentation    Collection of tests to validate the model serving stack for Large Language Models (LLM)
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/Page/Operators/ISVs.resource
Resource    ../../100__deploy/130__operators/130__rhods_operator/138__rhods_operator_oom_kill_verification.robot
Suite Setup       Install Model Serving Stack Dependencies
# Suite Teardown


*** Variables ***
${LLM_RESOURCES_DIRPATH}=    ods_ci/tests/Resources/Files/llm
${SERVERLESS_OP_NAME}=     serverless-operator
${SERVERLESS_SUB_NAME}=    serverless-operator
${SERVERLESS_NS}=    openshift-serverless    
${SERVERLESS_CR_NS}=    knative
${SERVICEMESH_OP_NAME}=     servicemeshoperator
${SERVICEMESH_SUB_NAME}=    servicemeshoperator
${SERVICEMESH_CONTROLPLANE_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/smcp.yaml
${SERVICEMESH_ROLL_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/smmr.yaml
${SERVICEMESH_CR_NS}=    istio-system
${KIALI_OP_NAME}=     kiali-ossm
${KIALI_SUB_NAME}=    kiali-ossm
${JAEGER_OP_NAME}=     jaeger-product
${JAEGER_SUB_NAME}=    jaeger-product



*** Test Cases ***
Verify External Dependency Operators Can Be Deployed
    [Tags]    ODS-2326
    Pass Execution    message=Installation done as part of Suite Setup.


*** Keywords ***
Install Model Serving Stack Dependencies
    Install Service Mesh Stack
    Install Serverless Stack
    Deploy Service Mesh CRs And Wait For Pods
    Deploy Serverless CRs And Wait For Pods

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

Deploy Service Mesh CRs And Wait For Pods
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${SERVICEMESH_CR_NS}
    Copy File     ${SERVICEMESH_CONTROLPLANE_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/smcp_filled.yaml
    Copy File     ${SERVICEMESH_ROLL_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i "s/{{SERVICEMESH_CR_NS}}/${SERVICEMESH_CR_NS}/g" ${LLM_RESOURCES_DIRPATH}/smmr_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f smcp_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f smmr_filled.yaml
    # add peer auth - replace namespaces with a sed
    # Wait Until Operator Pods Are Running

Deploy Serverless CRs And Wait For Pods
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${SERVERLESS_CR_NS}
    Add Namespace To ServiceMeshMemberRoll    namespace=${SERVERLESS_CR_NS}
    # Wait Until Operator Pods Are Running

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