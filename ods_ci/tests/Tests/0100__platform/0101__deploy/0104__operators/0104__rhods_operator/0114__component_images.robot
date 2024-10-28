*** Settings ***
Documentation       Test Suite to check for components

Resource            ../../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Variables ***
@{COMPONENTS} =
...                 codeflare
...                 modelregistry
...                 trustyai
...                 ray
...                 kueue
...                 workbenches
...                 dashboard
...                 modelmeshserving
...                 datasciencepipelines
...                 trainingoperator


*** Test Cases ***
Check For Correct Component Images
    [Documentation]    The purpose is to enforce the check of correct component images on their deployments.
    [Tags]                  Operator                RHOAIENG-12576          Smoke
    FOR    ${cmp}    IN    @{COMPONENTS}
        ${rc}    ${managementState}=    Run And Return Rc And Output
        ...    oc get DataScienceCluster default-dsc -o jsonpath="{.spec.components['${cmp}'].managementState}"
        IF    "${managementState}" == "Managed"
            IF    "${cmp}" == "codeflare"
                Check Image On Csv And Deployment
                ...    odh_codeflare_operator_image
                ...    codeflare-operator-manager
            ELSE IF    "${cmp}" == "modelregistry"
                Check Image On Csv And Deployment
                ...    odh_mlmd_grpc_server_image
                ...    model-registry-operator-controller-manager
                Check Image On Csv And Deployment
                ...    odh_model_registry_image
                ...    model-registry-operator-controller-manager
            ELSE IF    "${cmp}" == "trustyai"
                Check Image On Csv And Deployment
                ...    odh_trustyai_service_operator_image
                ...    trustyai-service-operator-controller-manager
            ELSE IF    "${cmp}" == "ray"
                Check Image On Csv And Deployment
                ...    odh_kuberay_operator_controller_image
                ...    kuberay-operator
            ELSE IF    "${cmp}" == "kueue"
                Check Image On Csv And Deployment
                ...    odh_kueue_controller_image
                ...    kueue-controller-manager
            ELSE IF    "${cmp}" == "workbenches"
                Check Image On Csv And Deployment
                ...    odh_notebook_controller_image
                ...    odh-notebook-controller-manager
                Check Image On Csv And Deployment
                ...    odh_kf_notebook_controller_image
                ...    notebook-controller-deployment
            ELSE IF    "${cmp}" == "dashboard"
                Check Image On Csv And Deployment               odh_dashboard_image     ${DASHBOARD_DEPLOYMENT_NAME}
            ELSE IF    "${cmp}" == "modelmeshserving"
                Check Image On Csv And Deployment
                ...    odh_modelmesh_controller_image
                ...    modelmesh-controller
            ELSE IF    "${cmp}" == "datasciencepipelines"
                Check Image On Csv And Deployment
                ...    odh_data_science_pipelines_operator_controller_image
                ...    data-science-pipelines-operator-controller-manager
            ELSE IF    "${cmp}" == "trainingoperator"
                Check Image On Csv And Deployment
                ...    odh_training_operator_image
                ...    kubeflow-training-operator
            END
        END
    END


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown

Check Image On Csv And Deployment
    [Documentation]    Check Image On Csv And Deployment
    [Arguments]    ${image}    ${deployment_name}

    ${rc}    ${csv_image}=    Run And Return Rc And Output
    ...    oc get ClusterServiceVersion -l ${OPERATOR_SUBSCRIPTION_LABEL} -n ${OPERATOR_NAMESPACE} -o jsonpath='{.items[?(@.kind=="ClusterServiceVersion")].spec.relatedImages[?(@.name=="${image}")].image}'
    Should Be Equal    "${rc}"    "0"    msg=${csv_image}
    Should Not Be Empty    ${csv_image}
    Log To Console    IMAGE ON CSV IS ${csv_image}

    # Check for regex to see whether it is pointing mistream or downstream
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get Deployment ${deployment_name} -n ${APPLICATIONS_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[?(@.images=="${csv_image}")]}'
    Should Be Equal    "${rc}"    "0"    msg=${csv_image} not found on ${deployment_name} deployment
    Log To Console    SUCCESS: Both CSV and Deployment ${image} images match
