*** Settings ***
Documentation       Test Suite to check for components

Resource            ../../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource            ../../../../../../tests/Resources/Page/Components/Components.resource
Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Variables ***
${APPLICATIONS_NS}                              ${APPLICATIONS_NAMESPACE}
${KUEUE_LABEL_SELECTOR}                         app.kubernetes.io/name=kueue
${CODEFLARE_LABEL_SELECTOR}                     app.kubernetes.io/name=codeflare-operator
${RAY_LABEL_SELECTOR}                           app.kubernetes.io/name=kuberay
${TRAINING_LABEL_SELECTOR}                      app.kubernetes.io/name=training-operator
${DATASCIENCEPIPELINES_LABEL_SELECTOR}          app.kubernetes.io/name=data-science-pipelines-operator
${MODELMESH_CONTROLLER_LABEL_SELECTOR}          app.kubernetes.io/instance=modelmesh-controller
${ODH_MODEL_CONTROLLER_LABEL_SELECTOR}          app=odh-model-controller
${MODELREGISTRY_CONTROLLER_LABEL_SELECTOR}      control-plane=model-registry-operator
${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}     control-plane=kserve-controller-manager
${TRUSTYAI_CONTROLLER_MANAGER_LABEL_SELECTOR}   app.kubernetes.io/part-of=trustyai
${WORKBENCHES_LABEL_SELECTOR}                   app.kubernetes.io/part-of=workbenches


*** Test Cases ***
Check For Correct Component Images
    [Documentation]    The purpose is to enforce the check of correct component images on their deployments.
    [Tags]                  Operator                RHOAIENG-12576          Smoke
    [Template]          Check Image On Csv And Deployment
    codeflare               codeflare-operator-manager                              ${CODEFLARE_LABEL_SELECTOR}                     odh_codeflare_operator_image    
    modelregistry           model-registry-operator-controller-manager              ${MODELREGISTRY_CONTROLLER_LABEL_SELECTOR}      odh_mlmd_grpc_server_image      
    modelregistry           model-registry-operator-controller-manager              ${MODELREGISTRY_CONTROLLER_LABEL_SELECTOR}      odh_model_registry_image        
    trustyai                trustyai-service-operator-controller-manager            ${TRUSTYAI_CONTROLLER_MANAGER_LABEL_SELECTOR}   odh_trustyai_service_operator_image
    ray                     kuberay-operator                                        ${RAY_LABEL_SELECTOR}                           odh_kuberay_operator_controller_image
    kueue                   kueue-controller-manager                                ${KUEUE_LABEL_SELECTOR}                         odh_kueue_controller_image
    workbenches             odh-notebook-controller-manager                         ${WORKBENCHES_LABEL_SELECTOR}                   odh_notebook_controller_image
    workbenches             notebook-controller-deployment                          ${WORKBENCHES_LABEL_SELECTOR}                   odh_kf_notebook_controller_image
    dashboard               ${DASHBOARD_DEPLOYMENT_NAME}                            ${DASHBOARD_LABEL_SELECTOR}                     odh_dashboard_image     
    modelmeshserving        modelmesh-controller                                    ${MODELMESH_CONTROLLER_LABEL_SELECTOR}          odh_modelmesh_controller_image
    datasciencepipelines    data-science-pipelines-operator-controller-manager      ${DATASCIENCEPIPELINES_LABEL_SELECTOR}          odh_data_science_pipelines_operator_controller_image
    trainingoperator        kubeflow-training-operator                              ${TRAINING_LABEL_SELECTOR}                      odh_training_operator_image


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown

Check Image On Csv And Deployment
    [Documentation]    Check Image On Csv And Deployment
    [Arguments]    ${component}     ${deployment_name}      ${label_selector}      ${image}
    ${rc}    ${managementState}=    Run And Return Rc And Output
        ...    oc get DataScienceCluster default-dsc -o jsonpath="{.spec.components['${component}'].managementState}"
    IF    "${managementState}" == "Managed"

        ${rc}    ${csv_image}=    Run And Return Rc And Output
        ...    oc get ClusterServiceVersion -l ${OPERATOR_SUBSCRIPTION_LABEL} -n ${OPERATOR_NAMESPACE} -o jsonpath='{.items[?(@.kind=="ClusterServiceVersion")].spec.relatedImages[?(@.name=="${image}")].image}'
        Should Be Equal    "${rc}"    "0"    msg=${csv_image}
        Should Not Be Empty    ${csv_image}
        Log To Console    IMAGE ON CSV IS ${csv_image}

        Wait For Resources To Be Available    ${deployment_name}    ${label_selector}

        ${rc}    ${out}=    Run And Return Rc And Output
        ...    oc get Deployment ${deployment_name} -n ${APPLICATIONS_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[?(@.images=="${csv_image}")]}'
        Should Be Equal    "${rc}"    "0"    msg=${csv_image} not found on ${deployment_name} deployment
        Log To Console    SUCCESS: Both CSV and Deployment ${image} images match

    END
