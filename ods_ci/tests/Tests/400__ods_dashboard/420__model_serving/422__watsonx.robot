*** Settings ***
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/Page/Operators/ISVs.resource
Resource    ../../100__deploy/130__operators/130__rhods_operator/138__rhods_operator_oom_kill_verification.robot
Suite Setup       Install Model Serving Stack Dependencies
# Suite Teardown    


*** Variables ***
${SERVERLESS_OP_NAME}=     serverless-operator
${SERVERLESS_SUB_NAME}=    serverless-operator-sub
${SERVERLESS_NS}=    openshift-serverless    
${SERVICEMESH_OP_NAME}=     servicemeshoperator
${SERVICEMESH_SUB_NAME}=    servicemeshoperator-sub
${KIALI_OP_NAME}=     kiali-ossm
${KIALI_SUB_NAME}=    kiali-ossm-sub
${JAEGER_OP_NAME}=     jaeger-product
${JAEGER_SUB_NAME}=    jaeger-product-sub



*** Test Cases ***
Verify External Dependency Operators Can Be Deployed
    [Tags]    ODS-2326
    Pass Execution    message=Installation done as part of Suite Setup.


*** Keywords ***
Install Model Serving Stack Dependencies
    Install Service Mesh Stack
    Install Serverless Stack
    # deploy CRs and configure


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
    
Install Serverless Stack
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${SERVERLESS_NS}
    Install ISV Operator From OperatorHub Via CLI    operator_name=${SERVERLESS_OP_NAME}
    ...    subscription_name=${SERVERLESS_SUB_NAME}
    ...    catalog_source_name=redhat-operators
    ...    operator_group_target_ns=${SERVERLESS_NS}
    Wait Until Operator Subscription Last Condition Is
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${SERVERLESS_SUB_NAME}