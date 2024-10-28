*** Settings ***
Documentation       Test Suite to check for components

Resource            ../../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Test Cases ***
Check For Correct Component Images
    [Documentation]    The purpose is to enforce the check of correct component images on their deployments.
    [Tags]                  Operator                RHOAIENG-12576          Smoke
    [Template]          Check Image On Csv And Deployment
    codeflare               codeflare-operator-manager                              odh_codeflare_operator_image    
    modelregistry           model-registry-operator-controller-manager              odh_mlmd_grpc_server_image      
    modelregistry           model-registry-operator-controller-manager              odh_model_registry_image        
    trustyai                trustyai-service-operator-controller-manager            odh_trustyai_service_operator_image
    ray                     kuberay-operator                                        odh_kuberay_operator_controller_image
    kueue                   kueue-controller-manager                                odh_kueue_controller_image
    workbenches             odh-notebook-controller-manager                         odh_notebook_controller_image
    workbenches             notebook-controller-deployment                          odh_kf_notebook_controller_image
    dashboard               ${DASHBOARD_DEPLOYMENT_NAME}                            odh_dashboard_image     
    modelmeshserving        modelmesh-controller                                    odh_modelmesh_controller_image
    datasciencepipelines    data-science-pipelines-operator-controller-manager      odh_data_science_pipelines_operator_controller_image
    trainingoperator        kubeflow-training-operator                              odh_training_operator_image


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown

Check Image On Csv And Deployment
    [Documentation]    Check Image On Csv And Deployment
    [Arguments]    ${component}     ${deployment_name}      ${image}

    ${rc}    ${managementState}=    Run And Return Rc And Output
        ...    oc get DataScienceCluster default-dsc -o jsonpath="{.spec.components['${component}'].managementState}"
    IF    "${managementState}" == "Managed"

        ${rc}    ${csv_image}=    Run And Return Rc And Output
        ...    oc get ClusterServiceVersion -l ${OPERATOR_SUBSCRIPTION_LABEL} -n ${OPERATOR_NAMESPACE} -o jsonpath='{.items[?(@.kind=="ClusterServiceVersion")].spec.relatedImages[?(@.name=="${image}")].image}'
        Should Be Equal    "${rc}"    "0"    msg=${csv_image}
        Should Not Be Empty    ${csv_image}
        Log To Console    IMAGE ON CSV IS ${csv_image}

        ${rc}    ${out}=    Run And Return Rc And Output
        ...    oc get Deployment ${deployment_name} -n ${APPLICATIONS_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[?(@.images=="${csv_image}")]}'
        Should Be Equal    "${rc}"    "0"    msg=${csv_image} not found on ${deployment_name} deployment
        Log To Console    SUCCESS: Both CSV and Deployment ${image} images match

    END
