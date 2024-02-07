*** Settings ***
Documentation     Collection of keywords to interact with Model Serving feature for LLM (Kserve) via CLI
Resource          ../../../Resources/OCP.resource


*** Keywords ***
Verify Etcd Pod
    [Documentation]    Verifies the correct deployment of the etcd pod in the rhods namespace
    ${etcd_name} =    Run    oc get pod -l component=model-mesh-etcd -n ${APPLICATIONS_NAMESPACE} | grep etcd | awk '{split($0, a); print a[1]}'
    ${etcd_running} =    Run    oc get pod ${etcd_name} -n ${APPLICATIONS_NAMESPACE} | grep 1/1 -o
    Should Be Equal As Strings    ${etcd_running}    1/1

Verify Serving Service
    [Documentation]    Verifies the correct deployment of the serving service in the project namespace
    [Arguments]    ${project_name}=${PRJ_TITLE}
    ${service} =    Oc Get    kind=Service    namespace=${project_name}    label_selector=modelmesh-service=modelmesh-serving
    Should Not Be Equal As Strings    Error from server (NotFound): services "modelmesh-serving" not found    ${service}

Verify ModelMesh Deployment
    [Documentation]    Verifies the correct deployment of modelmesh in the rhods namespace
    @{modelmesh_controller} =  Oc Get    kind=Pod    namespace=${APPLICATIONS_NAMESPACE}    label_selector=control-plane=modelmesh-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${modelmesh_controller}  3  1  ${containerNames}

Verify odh-model-controller Deployment
    [Documentation]    Verifies the correct deployment of the model controller in the rhods namespace
    @{odh_model_controller} =  Oc Get    kind=Pod    namespace=${APPLICATIONS_NAMESPACE}    label_selector=control-plane=odh-model-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${odh_model_controller}  3  1  ${containerNames}

Verify Openvino Deployment
    [Documentation]    Verifies the correct deployment of the ovms server pod(s) in the rhods namespace
    [Arguments]    ${runtime_name}    ${project_name}=${PRJ_TITLE}    ${num_replicas}=1
    ${pod_selector}=    Set Variable    name=modelmesh-serving-${runtime_name}
    @{ovms} =  Oc Get    kind=Pod    namespace=${project_name}   label_selector=${pod_selector}
    ${containerNames} =  Create List  rest-proxy  oauth-proxy  ovms  ovms-adapter  mm
    ${pass}=    Run Keyword And Return Status    Verify Deployment    ${ovms}  ${num_replicas}  5  ${containerNames}
    IF    not ${pass}
        ${events}    ${podlogs}=    Get Events And Pod Logs    namespace=${project_name}
        ...    label_selector=${pod_selector}
        Fail    msg=Model Server deployment failed to get Running by timeout
    END
    ${all_ready} =    Run    oc get deployment -n ${project_name} -l ${pod_selector} | grep ${num_replicas}/${num_replicas} -o  # robocop:disable
    Should Be Equal As Strings    ${all_ready}    ${num_replicas}/${num_replicas}
