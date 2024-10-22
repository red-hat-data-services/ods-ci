*** Settings ***
Documentation    Test Suite that checks the deployment, pods and containers of the notebook controllers for workbench
...              component.
Resource         ../../Resources/OCP.resource
Resource         ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Test Tags        IDE    Smoke
Suite Setup      Suite Setup
Suite Teardown   Suite Teardown


*** Variables ***
${KF_NTB_CTRL_LABEL_SELECTOR} =    app=notebook-controller
${KF_NTB_POD_REPLICAS} =    1
${KF_NTB_CONTAINERS} =    1
${KF_NTB_CONTAINER_LIMITS_CPU} =    500m
${KF_NTB_CONTAINER_LIMITS_MEMORY} =    4Gi
${KF_NTB_CONTAINER_REQUESTS_CPU} =    500m
${KF_NTB_CONTAINER_REQUESTS_MEMORY} =    256Mi
${ODH_NTB_CTRL_LABEL_SELECTOR} =    app=odh-notebook-controller
${ODH_NTB_POD_REPLICAS} =    1
${ODH_NTB_CONTAINERS} =    1
${ODH_NTB_CONTAINER_LIMITS_CPU} =    500m
${ODH_NTB_CONTAINER_LIMITS_MEMORY} =    4Gi
${ODH_NTB_CONTAINER_REQUESTS_CPU} =    500m
${ODH_NTB_CONTAINER_REQUESTS_MEMORY} =    256Mi


*** Test Cases ***
Verify Odh Notebook Controller Deployment Pods Replicas
    [Documentation]    Check the Deployment pods replicas for ODH ntb controller and compares it with the expected
    ...                number.
    # The timeout is low as all resources should be up and running by this time already.
    Wait For Deployment Replica To Be Ready
    ...    label_selector=${ODH_NTB_CTRL_LABEL_SELECTOR}
    ...    namespace=${APPLICATIONS_NAMESPACE}
    ...    timeout=10s
    ...    exp_replicas=${ODH_NTB_POD_REPLICAS}

Verify Odh Notebook Controller Containers
    [Documentation]    Check the containers of the ODH ntb controller and their resources and compares it with the
    ...                expected number.
    Run And Verify Command
    ...    oc get pods -n ${APPLICATIONS_NAMESPACE} -l ${ODH_NTB_CTRL_LABEL_SELECTOR} -ojson | jq -e '.items[].spec.containers | length == ${ODH_NTB_CONTAINERS}'  #robocop: disable:line-too-long

    ${limits} =    Create Dictionary
    ...    cpu=${ODH_NTB_CONTAINER_LIMITS_CPU}    memory=${ODH_NTB_CONTAINER_LIMITS_MEMORY}
    ${requests} =    Create Dictionary
    ...    cpu=${ODH_NTB_CONTAINER_REQUESTS_CPU}    memory=${ODH_NTB_CONTAINER_REQUESTS_MEMORY}
    Container Hardware Resources Should Match Expected
    ...    container_name=manager
    ...    pod_label_selector=${ODH_NTB_CTRL_LABEL_SELECTOR}
    ...    namespace=${APPLICATIONS_NAMESPACE}
    ...    exp_limits=${limits}
    ...    exp_requests=${requests}

Verify Kf Notebook Controller Deployment Pods Replicas
    [Documentation]    Check the Deployment pods replicas for Kf ntb controller and compares it with expected number
    # The timeout is low as all resources should be up and running by this time already.
    Wait For Deployment Replica To Be Ready
    ...    label_selector=${KF_NTB_CTRL_LABEL_SELECTOR}
    ...    namespace=${APPLICATIONS_NAMESPACE}
    ...    timeout=10s
    ...    exp_replicas=${KF_NTB_POD_REPLICAS}

Verify Kf Notebook Controller Containers
    [Documentation]    Check the containers of the Kf ntb controller and their resources and compares it with the
    ...                expected number.
    Run And Verify Command
    ...    oc get pods -n ${APPLICATIONS_NAMESPACE} -l ${KF_NTB_CTRL_LABEL_SELECTOR} -ojson | jq -e '.items[].spec.containers | length == ${KF_NTB_CONTAINERS}'  #robocop: disable:line-too-long

    ${limits} =    Create Dictionary
    ...    cpu=${KF_NTB_CONTAINER_LIMITS_CPU}    memory=${KF_NTB_CONTAINER_LIMITS_MEMORY}
    ${requests} =    Create Dictionary
    ...    cpu=${KF_NTB_CONTAINER_REQUESTS_CPU}    memory=${KF_NTB_CONTAINER_REQUESTS_MEMORY}
    Container Hardware Resources Should Match Expected
    ...    container_name=manager
    ...    pod_label_selector=${KF_NTB_CTRL_LABEL_SELECTOR}
    ...    namespace=${APPLICATIONS_NAMESPACE}
    ...    exp_limits=${limits}
    ...    exp_requests=${requests}


*** Keywords ***
Suite Setup
    [Documentation]    Suite setup
    RHOSi Setup
    ${workbenches} =    Is Component Enabled    workbenches    ${DSC_NAME}
    IF    "${workbenches}" != "true"
        Fail    The workbench component isn't enabled!
    END

Suite Teardown
    [Documentation]    Suite teardown
    RHOSi Teardown
