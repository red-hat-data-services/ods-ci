*** Settings ***
Documentation       Test Cases to verify DSC Distributed Workloads Components

Library             Collections
Resource            ../../../../../Resources/OCP.resource
Resource            ../../../../../Resources/ODS.robot
Resource            ../../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource            ../../../../../Resources/Page/Components/Components.resource

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Variables ***
${OPERATOR_NS}                                          ${OPERATOR_NAMESPACE}
${APPLICATIONS_NS}                                      ${APPLICATIONS_NAMESPACE}
${KNATIVE_SERVING_NS}                                   knative-serving
${DSC_NAME}                                             default-dsc
${KUEUE_NS}                                             openshift-kueue-operator
${KUEUE_OP_NAME}                                        kueue-operator
${CERT_MANAGER_OP_NAME}                                 openshift-cert-manager-operator
${KUEUE_LABEL_SELECTOR}                                 app.kubernetes.io/name=kueue
${KUEUE_DEPLOYMENT_NAME}                                kueue-controller-manager
${CODEFLARE_LABEL_SELECTOR}                             app.kubernetes.io/name=codeflare-operator
${CODEFLARE_DEPLOYMENT_NAME}                            codeflare-operator-manager
${RAY_LABEL_SELECTOR}                                   app.kubernetes.io/name=kuberay
${RAY_DEPLOYMENT_NAME}                                  kuberay-operator
${TRAINING_LABEL_SELECTOR}                              app.kubernetes.io/name=training-operator
${TRAINING_DEPLOYMENT_NAME}                             kubeflow-training-operator
${DATASCIENCEPIPELINES_LABEL_SELECTOR}                  app.kubernetes.io/name=data-science-pipelines-operator
${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}                 data-science-pipelines-operator-controller-manager
${MODELMESH_CONTROLLER_LABEL_SELECTOR}                  app.kubernetes.io/instance=modelmesh-controller
${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}                 modelmesh-controller
${ETCD_LABEL_SELECTOR}                                  component=model-mesh-etcd
${ETCD_DEPLOYMENT_NAME}                                 etcd
${ODH_MODEL_CONTROLLER_LABEL_SELECTOR}                  app=odh-model-controller
${ODH_MODEL_CONTROLLER_DEPLOYMENT_NAME}                 odh-model-controller
${MODELREGISTRY_CONTROLLER_LABEL_SELECTOR}              control-plane=model-registry-operator
${MODELREGISTRY_CONTROLLER_DEPLOYMENT_NAME}             model-registry-operator-controller-manager
${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}             control-plane=kserve-controller-manager
${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}            kserve-controller-manager
${TRUSTYAI_CONTROLLER_MANAGER_LABEL_SELECTOR}           app.kubernetes.io/part-of=trustyai
${TRUSTYAI_CONTROLLER_MANAGER_DEPLOYMENT_NAME}          trustyai-service-operator-controller-manager
${FEASTOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}      app.kubernetes.io/part-of=feastoperator
${FEASTOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}     feast-operator-controller-manager
${NOTEBOOK_CONTROLLER_DEPLOYMENT_LABEL_SELECTOR}        component.opendatahub.io/name=kf-notebook-controller
${NOTEBOOK_CONTROLLER_MANAGER_LABEL_SELECTOR}           component.opendatahub.io/name=odh-notebook-controller
${NOTEBOOK_DEPLOYMENT_NAME}                             notebook-controller-deployment
${IS_NOT_PRESENT}                                       1
&{SAVED_MANAGEMENT_STATES}
...                                                     RAY=${EMPTY}
...                                                     KUEUE=${EMPTY}
...                                                     CODEFLARE=${EMPTY}
...                                                     TRAINING=${EMPTY}
...                                                     DASHBOARD=${EMPTY}
...                                                     DATASCIENCEPIPELINES=${EMPTY}
...                                                     MODELMESHERVING=${EMPTY}
...                                                     MODELREGISTRY=${EMPTY}
...                                                     KSERVE=${EMPTY}
...                                                     TRUSTYAI=${EMPTY}
...                                                     WORKBENCHES=${EMPTY}
...                                                     FEASTOPERATOR=${EMPTY}

@{CONTROLLERS_LIST}                                     # dashboard added in Suite Setup, since it's different in RHOAI vs ODH
...                                                     codeflare-operator-manager
...                                                     data-science-pipelines-operator-controller-manager
...                                                     kuberay-operator
...                                                     kueue-controller-manager
...                                                     modelmesh-controller
...                                                     notebook-controller-deployment
...                                                     odh-model-controller
...                                                     odh-notebook-controller-manager
...                                                     trustyai-service-operator-controller-manager
#...                                                     kserve-controller-manager  # RHOAIENG-27943
#...                                                     kubeflow-training-operator # RHOAIENG-27944


*** Test Cases ***
Validate Kueue Removed To Managed State Transition
    [Documentation]    Validate that the DSC Kueue component Managed state creates the expected resources,
    ...    check that kueue deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-5435
    ...    kueue-managed-from-removed
    ...    Integration

    ${initial_state}=    Get DSC Component State    ${DSC_NAME}    kueue    ${OPERATOR_NS}
    ${ocp_version}=     Get Ocp Cluster Version
    ${install_kueue_by_ocp_version}=    GTE    ${ocp_version}    4.18.0
    IF    "${initial_state}" == "Unmanaged"
            ${namespace_to_check}=    Set Variable    ${KUEUE_NS}
    ELSE
            ${namespace_to_check}=    Set Variable    ${APPLICATIONS_NAMESPACE}
    END

    IF    ${install_kueue_by_ocp_version}
            ${kueue_installed} =   Check If Operator Is Installed Via CLI    ${KUEUE_OP_NAME}
            IF    ${kueue_installed}
                    Uninstall Kueue Operator CLI
            END
    END

    Set DSC Component Removed State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${namespace_to_check}
    ${kueue_installed} =   Check If Operator Is Installed Via CLI      ${KUEUE_OP_NAME}
    IF    ${kueue_installed}
            Uninstall Kueue Operator CLI
    END
    Set DSC Component Managed State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${IMAGE_PULL_PATH}

    [Teardown]      Restore Kueue Initial State

Validate Kueue Removed To Unmanaged State Transition
    [Documentation]    Validate that the DSC Kueue component Unmanaged state creates the expected resources,
    ...    check that kueue deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    kueue-unmanaged-from-removed
    ...    Integration

    ${initial_state}=    Get DSC Component State    ${DSC_NAME}    kueue    ${OPERATOR_NS}
    ${ocp_version}=     Get Ocp Cluster Version
    ${install_kueue_by_ocp_version}=    GTE    ${ocp_version}    4.18.0
    IF    "${initial_state}" == "Unmanaged"
            ${namespace_to_check}=    Set Variable    ${KUEUE_NS}
    ELSE
            ${namespace_to_check}=    Set Variable    ${APPLICATIONS_NAMESPACE}
    END

    IF    ${install_kueue_by_ocp_version}
            ${kueue_installed} =   Check If Operator Is Installed Via CLI      ${KUEUE_OP_NAME}
            IF    ${kueue_installed}
                    Uninstall Kueue Operator CLI
            END
    END

    Skip If    condition=${install_kueue_by_ocp_version}==False   msg="Unmanaged Kueue status is not supported in OCP ${ocp_version}. It needs to be 4.18+"
    Set DSC Component Removed State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${namespace_to_check}
    Set DSC Component Unmanaged State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    ...    wait_for_completion=False
    Install Kueue Dependencies
    Wait For Resources To Be Available
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    Check That Image Pull Path Is Correct
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${IMAGE_PULL_PATH}
    ...    namespace=${KUEUE_NS}

    [Teardown]      Restore Kueue Initial State

Validate Kueue Managed To Removed State Transition
    [Documentation]    Validate that Kueue management state Removed does remove relevant resources when coming from
    ...                Managed state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-5435
    ...    kueue-removed-from-managed
    ...    Integration

    ${ocp_version}=     Get Ocp Cluster Version
    ${install_kueue_by_ocp_version}=    GTE    ${ocp_version}    4.18.0
    IF    ${install_kueue_by_ocp_version}
            ${kueue_installed} =   Check If Operator Is Installed Via CLI      ${KUEUE_OP_NAME}
            IF    ${kueue_installed}
                    Uninstall Kueue Operator CLI
            END
    END
    Set DSC Component Managed State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    Set DSC Component Removed State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}

    [Teardown]      Restore Kueue Initial State

Validate Kueue Unmanaged To Removed State Transition
    [Documentation]    Validate that Kueue management state Removed does remove relevant resources when coming from
    ...                Unmanaged state.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    kueue-removed-from-unmanaged
    ...    Integration

    ${initial_state}=    Get DSC Component State    ${DSC_NAME}    kueue    ${OPERATOR_NS}
    ${ocp_version}=     Get Ocp Cluster Version
    ${install_kueue_by_ocp_version}=    GTE    ${ocp_version}    4.18.0
    IF    "${initial_state}" == "Unmanaged"
            ${namespace_to_check}=    Set Variable    ${KUEUE_NS}
    ELSE
            ${namespace_to_check}=    Set Variable    ${APPLICATIONS_NAMESPACE}
    END

    Skip If    condition=${install_kueue_by_ocp_version}==False   msg="Unmanaged Kueue status is not supported in OCP ${ocp_version}. It needs to be 4.18+"
    Set DSC Component Unmanaged State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    ...    wait_for_completion=False
    Install Kueue Dependencies
    Wait For Resources To Be Available
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    Uninstall Kueue Operator CLI
    Set DSC Component Removed State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}

    [Teardown]      Restore Kueue Initial State

Validate Kueue Unmanaged To Managed State Transition
    [Documentation]    Validate that Kueue management state Managed does create relevant resources when coming from
    ...                Unmanaged state. The kueue resources need to be removed from the kueue namespace and being
    ...                present in the apps namespace.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    kueue-managed-from-unmanaged
    ...    Integration

    ${ocp_version}=     Get Ocp Cluster Version
    ${install_kueue_by_ocp_version}=    GTE    ${ocp_version}    4.18.0

    Skip If    condition=${install_kueue_by_ocp_version}==False   msg="Unmanaged Kueue status is not supported in OCP ${ocp_version}. It needs to be 4.18+"
    Set DSC Component Unmanaged State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    ...    wait_for_completion=False
    Install Kueue Dependencies
    Wait For Resources To Be Available
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    Set DSC Component Managed State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${APPLICATIONS_NAMESPACE}
    ...    wait_for_completion=False
    Uninstall Kueue Operator CLI
    Wait For Resources To Be Available
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${APPLICATIONS_NAMESPACE}
    Wait For Resources To Be Removed
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}

    [Teardown]      Restore Kueue Initial State

Validate Kueue Managed To Unmanaged State Transition
    [Documentation]    Validate that Kueue management state Unmanaged does create relevant resources when coming from
    ...                Managed state. The kueue resources need to be removed from the apps namespace and being
    ...                present in the kueue namespace.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    kueue-unmanaged-from-managed
    ...    Integration

    ${ocp_version}=     Get Ocp Cluster Version
    ${install_kueue_by_ocp_version}=    GTE    ${ocp_version}    4.18.0

    Skip If    condition=${install_kueue_by_ocp_version}==False   msg="Unmanaged Kueue status is not supported in OCP ${ocp_version}. It needs to be 4.18+"
    Set DSC Component Managed State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${APPLICATIONS_NAMESPACE}
    ...    wait_for_completion=False
    ${kueue_installed} =   Check If Operator Is Installed Via CLI      ${KUEUE_OP_NAME}
    IF    ${kueue_installed}
            Uninstall Kueue Operator CLI
    END
    Wait For Resources To Be Available
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${APPLICATIONS_NAMESPACE}
    Set DSC Component Unmanaged State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    ...    wait_for_completion=False
    Install Kueue Dependencies
    Wait For Resources To Be Available
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    Wait For Resources To Be Removed
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${APPLICATIONS_NAMESPACE}

    [Teardown]      Restore Kueue Initial State

Validate Codeflare Managed State
    [Documentation]    Validate that the DSC Codeflare component Managed state creates the expected resources,
    ...    check that Codeflare deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-5435
    ...    codeflare-managed
    ...    Integration
    ...    RHOAIENG-24666
    Set DSC Component Managed State And Wait For Completion
    ...    codeflare
    ...    ${CODEFLARE_DEPLOYMENT_NAME}
    ...    ${CODEFLARE_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct       ${CODEFLARE_DEPLOYMENT_NAME}        ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     codeflare       ${CODEFLARE_DEPLOYMENT_NAME}        ${CODEFLARE_LABEL_SELECTOR}     ${SAVED_MANAGEMENT_STATES.CODEFLARE}

Validate Codeflare Removed State
    [Documentation]    Validate that Codeflare management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-5435
    ...    codeflare-removed
    ...    Integration

    Set DSC Component Removed State And Wait For Completion
    ...    codeflare
    ...    ${CODEFLARE_DEPLOYMENT_NAME}
    ...    ${CODEFLARE_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     codeflare       ${CODEFLARE_DEPLOYMENT_NAME}        ${CODEFLARE_LABEL_SELECTOR}     ${SAVED_MANAGEMENT_STATES.CODEFLARE}

Validate Ray Managed State
    [Documentation]    Validate that the DSC Ray component Managed state creates the expected resources,
    ...    check that Ray deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-5435
    ...    ray-managed
    ...    Integration
    Set DSC Component Managed State And Wait For Completion
    ...    ray
    ...    ${RAY_DEPLOYMENT_NAME}
    ...    ${RAY_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct       ${RAY_DEPLOYMENT_NAME}      ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     ray     ${RAY_DEPLOYMENT_NAME}      ${RAY_LABEL_SELECTOR}       ${SAVED_MANAGEMENT_STATES.RAY}

Validate Ray Removed State
    [Documentation]    Validate that Ray management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-5435
    ...    ray-removed
    ...    Integration

    Set DSC Component Removed State And Wait For Completion
    ...    ray
    ...    ${RAY_DEPLOYMENT_NAME}
    ...    ${RAY_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     ray     ${RAY_DEPLOYMENT_NAME}      ${RAY_LABEL_SELECTOR}       ${SAVED_MANAGEMENT_STATES.RAY}

Validate Training Operator Managed State
    [Documentation]    Validate that the DSC Training Operator component Managed state creates the expected resources,
    ...    check that Training deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-6627
    ...    training-managed
    ...    Integration
    Set DSC Component Managed State And Wait For Completion
    ...    trainingoperator
    ...    ${TRAINING_DEPLOYMENT_NAME}
    ...    ${TRAINING_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct       ${TRAINING_DEPLOYMENT_NAME}     ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     trainingoperator        ${TRAINING_DEPLOYMENT_NAME}     ${TRAINING_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.TRAINING}

Validate Training Operator Removed State
    [Documentation]    Validate that Training Operator management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-6627
    ...    training-removed
    ...    Integration

    Set DSC Component Removed State And Wait For Completion
    ...    trainingoperator
    ...    ${TRAINING_DEPLOYMENT_NAME}
    ...    ${TRAINING_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     trainingoperator        ${TRAINING_DEPLOYMENT_NAME}     ${TRAINING_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.TRAINING}

Validate Dashboard Managed State
    [Documentation]    Validate that the DSC Dashboard component Managed state creates the expected resources,
    ...    check that Dashboard deployment is created and all pods are in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-7298
    ...    dashboard-managed
    ...    Integration
    Set DSC Component Managed State And Wait For Completion
    ...    dashboard
    ...    ${DASHBOARD_DEPLOYMENT_NAME}
    ...    ${DASHBOARD_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct       ${DASHBOARD_DEPLOYMENT_NAME}        ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     dashboard       ${DASHBOARD_DEPLOYMENT_NAME}        ${DASHBOARD_LABEL_SELECTOR}     ${SAVED_MANAGEMENT_STATES.DASHBOARD}

Validate Dashboard Removed State
    [Documentation]    Validate that Dashboard management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-7298
    ...    dashboard-removed
    ...    Integration

    Set DSC Component Removed State And Wait For Completion
    ...    dashboard
    ...    ${DASHBOARD_DEPLOYMENT_NAME}
    ...    ${DASHBOARD_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     dashboard       ${DASHBOARD_DEPLOYMENT_NAME}        ${DASHBOARD_LABEL_SELECTOR}     ${SAVED_MANAGEMENT_STATES.DASHBOARD}

Validate Datasciencepipelines Managed State
    [Documentation]    Validate that the DSC Datasciencepipelines component Managed state creates the expected resources,
    ...    check that Datasciencepipelines deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-7298
    ...    operator-datasciencepipelines-managed
    ...    Integration
    Set DSC Component Managed State And Wait For Completion
    ...    datasciencepipelines
    ...    ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}
    ...    ${DATASCIENCEPIPELINES_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct       ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}     ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     datasciencepipelines        ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}     ${DATASCIENCEPIPELINES_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.DATASCIENCEPIPELINES}

Validate Datasciencepipelines Removed State
    [Documentation]    Validate that Datasciencepipelines management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-7298
    ...    operator-datasciencepipelines-removed
    ...    Integration

    Set DSC Component Removed State And Wait For Completion
    ...    datasciencepipelines
    ...    ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}
    ...    ${DATASCIENCEPIPELINES_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     datasciencepipelines        ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}     ${DATASCIENCEPIPELINES_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.DATASCIENCEPIPELINES}

Validate TrustyAi Managed State
    [Documentation]    Validate that the DSC TrustyAi component Managed state creates the expected resources,
    ...    check that TrustyAi deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-14018
    ...    trustyai-managed
    ...    Integration
    Set DSC Component Managed State And Wait For Completion
    ...    trustyai
    ...    ${TRUSTYAI_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${TRUSTYAI_CONTROLLER_MANAGER_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct
    ...    ${TRUSTYAI_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     trustyai        ${TRUSTYAI_CONTROLLER_MANAGER_DEPLOYMENT_NAME}      ${TRUSTYAI_CONTROLLER_MANAGER_LABEL_SELECTOR}       ${SAVED_MANAGEMENT_STATES.TRUSTYAI}

Validate TrustyAi Removed State
    [Documentation]    Validate that TrustyAi management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-14018
    ...    trustyai-removed
    ...    Integration

    Set DSC Component Removed State And Wait For Completion
    ...    trustyai
    ...    ${TRUSTYAI_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${TRUSTYAI_CONTROLLER_MANAGER_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     trustyai        ${TRUSTYAI_CONTROLLER_MANAGER_DEPLOYMENT_NAME}      ${TRUSTYAI_CONTROLLER_MANAGER_LABEL_SELECTOR}       ${SAVED_MANAGEMENT_STATES.TRUSTYAI}

Validate Modelmeshserving Managed State
    [Documentation]    Validate that the DSC Modelmeshserving component Managed state creates the expected resources,
    ...    check that Modelmeshserving deployment is created and pods are in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-8546
    ...    modelmeshserving-managed
    ...    Integration
    Set DSC Component Managed State And Wait For Completion
    ...    modelmeshserving
    ...    ${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}
    ...    ${MODELMESH_CONTROLLER_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct       ${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}     ${IMAGE_PULL_PATH}

    # Check that ETC resources are ready
    Wait For Resources To Be Available
    ...    ${ETCD_DEPLOYMENT_NAME}
    ...    ${ETCD_LABEL_SELECTOR}

    # Check that ODH Model Controller resources are ready
    Wait For Resources To Be Available
    ...    ${ODH_MODEL_CONTROLLER_DEPLOYMENT_NAME}
    ...    ${ODH_MODEL_CONTROLLER_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     modelmeshserving        ${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}     ${MODELMESH_CONTROLLER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.MODELMESHERVING}

Validate Modelmeshserving Removed State
    [Documentation]    Validate that Modelmeshserving management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-8546
    ...    modelmeshserving-removed
    ...    Integration

    Set DSC Component Removed State And Wait For Completion
    ...    modelmeshserving
    ...    ${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}
    ...    ${MODELMESH_CONTROLLER_LABEL_SELECTOR}

    # Check that ETC resources are removed
    Wait For Resources To Be Removed
    ...    ${ETCD_DEPLOYMENT_NAME}
    ...    ${ETCD_LABEL_SELECTOR}

    # Check that ODH Model Controller resources are removed, if KServe managementState is Removed
    ${state}=    Get DSC Component State
    ...    ${DSC_NAME}
    ...    kserve
    ...    ${OPERATOR_NS}
    IF    "${state}" == "Removed"
        Wait For Resources To Be Removed
        ...    ${ODH_MODEL_CONTROLLER_DEPLOYMENT_NAME}
        ...    ${ODH_MODEL_CONTROLLER_LABEL_SELECTOR}
    END

    [Teardown]      Restore DSC Component State     modelmeshserving        ${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}     ${MODELMESH_CONTROLLER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.MODELMESHERVING}

Validate ModelRegistry Managed State
    [Documentation]    Validate that the DSC ModelRegistry component Managed state creates the expected resources,
    ...    check that ModelRegistry deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-10404
    ...    modelregistry-managed
    ...    Integration
    Set DSC Component Managed State And Wait For Completion
    ...    modelregistry
    ...    ${MODELREGISTRY_CONTROLLER__DEPLOYMENT_NAME}
    ...    ${MODELREGISTRY_CONTROLLER__LABEL_SELECTOR}
    Check That Image Pull Path Is Correct           ${MODELREGISTRY_CONTROLLER__DEPLOYMENT_NAME}    ${IMAGE_PULL_PATH}

    Check Model Registry Namespace

    [Teardown]      Restore DSC Component State     modelregistry       ${MODELREGISTRY_CONTROLLER__DEPLOYMENT_NAME}        ${MODELREGISTRY_CONTROLLER__LABEL_SELECTOR}     ${SAVED_MANAGEMENT_STATES.MODELREGISTRY}

Validate ModelRegistry Removed State
    [Documentation]    Validate that ModelRegistry management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-10404
    ...    modelregistry-removed
    ...    Integration
    # Properly validate Removed state by first setting to Manged, which will ensure that namspace
    # was created as needed for later validating that namespace persisted when component is Removed
    [Setup]     Set DSC Component Managed State And Wait For Completion     modelregistry       ${MODELREGISTRY_CONTROLLER__DEPLOYMENT_NAME}        ${MODELREGISTRY_CONTROLLER__LABEL_SELECTOR}

    Set DSC Component Removed State And Wait For Completion
    ...    modelregistry
    ...    ${MODELREGISTRY_CONTROLLER__DEPLOYMENT_NAME}
    ...    ${MODELREGISTRY_CONTROLLER__LABEL_SELECTOR}

    # Note: Model Registry namespace will not be deleted when component state changed from Manged to Removed
    Check Model Registry Namespace

    [Teardown]      Restore DSC Component State     modelregistry       ${MODELREGISTRY_CONTROLLER__DEPLOYMENT_NAME}        ${MODELREGISTRY_CONTROLLER__LABEL_SELECTOR}     ${SAVED_MANAGEMENT_STATES.MODELREGISTRY}

Validate KServe Controller Manager Managed State
    [Documentation]    Validate that the DSC KServe Controller Manager component Managed state creates the expected resources,
    ...    check that KServe Controller Manager deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-7217
    ...    kserve-controller-manager-managed
    ...    Integration
    ...    ExcludeOnODH
    ...    ExcludeOnRHOAI
    Set DSC Component Managed State And Wait For Completion
    ...    kserve
    ...    ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct           ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}    ${KSERVE_IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     kserve      ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}        ${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}     ${SAVED_MANAGEMENT_STATES.KSERVE}

Validate KServe Controller Manager Removed State
    [Documentation]    Validate that KServe Controller Manager management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-7217
    ...    kserve-controller-manager-removed
    ...    Integration

    Set DSC Component Removed State And Wait For Completion
    ...    kserve
    ...    ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}

    # With KServe Removed, KNative-Serving CR will not exist regardless of the kserve.serving management state
    Wait Until Keyword Succeeds
    ...    5 min
    ...    0 sec
    ...    Is Resource Present
    ...    KnativeServing
    ...    knative-serving
    ...    ${KNATIVE_SERVING_NS}
    ...    ${IS_NOT_PRESENT}

    [Teardown]      Restore DSC Component State     kserve      ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}        ${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}     ${SAVED_MANAGEMENT_STATES.KSERVE}

Validate Workbenches Managed State
    [Documentation]    Validate that the DSC Workbenches component Managed state creates the expected resources,
    ...    check that Workbenches deployment is created and pods are in Ready state
    [Tags]      Operator        Tier1       workbenches-managed     Integration

    Set DSC Component Managed State And Wait For Completion
    ...    workbenches
    ...    ${NOTEBOOK_DEPLOYMENT_NAME}
    ...    ${NOTEBOOK_CONTROLLER_MANAGER_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct           ${NOTEBOOK_DEPLOYMENT_NAME}                     ${IMAGE_PULL_PATH}

    Wait For Resources To Be Available
    ...    ${NOTEBOOK_DEPLOYMENT_NAME}
    ...    ${NOTEBOOK_CONTROLLER_DEPLOYMENT_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     workbenches     ${NOTEBOOK_DEPLOYMENT_NAME}     ${NOTEBOOK_CONTROLLER_DEPLOYMENT_LABEL_SELECTOR}        ${SAVED_MANAGEMENT_STATES.WORKBENCHES}

Validate Workbenches Removed State
    [Documentation]    Validate that Workbenches component management state Removed does remove relevant resources.
    [Tags]                  Operator                Tier1                   workbenches-removed     Integration

    Set DSC Component Removed State And Wait For Completion
    ...    workbenches
    ...    ${NOTEBOOK_DEPLOYMENT_NAME}
    ...    ${NOTEBOOK_CONTROLLER_MANAGER_LABEL_SELECTOR}

    Wait For Resources To Be Removed
    ...    ${NOTEBOOK_DEPLOYMENT_NAME}
    ...    ${NOTEBOOK_CONTROLLER_DEPLOYMENT_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     workbenches     ${NOTEBOOK_DEPLOYMENT_NAME}     ${NOTEBOOK_CONTROLLER_MANAGER_LABEL_SELECTOR}       ${SAVED_MANAGEMENT_STATES.WORKBENCHES}

Validate Feastoperator Managed State
    [Documentation]    Validate that the DSC Feastoperator component Managed state creates the expected resources,
    ...    check that FeastOperator deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    feastoperator-managed
    ...    Integration
    ...    ExcludeOnODH
    Set DSC Component Managed State And Wait For Completion
    ...    feastoperator
    ...    ${FEASTOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${FEASTOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct
    ...    ${FEASTOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     feastoperator       ${FEASTOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}     ${FEASTOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.FEASTOPERATOR}

Validate Feastoperator Removed State
    [Documentation]    Validate that FeastOperator management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    feastoperator-removed
    ...    Integration
    ...    ExcludeOnODH

    Set DSC Component Removed State And Wait For Completion
    ...    feastoperator
    ...    ${FEASTOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${FEASTOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     feastoperator       ${FEASTOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}     ${FEASTOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.FEASTOPERATOR}

Validate Support For Configuration Of Controller Resources
    [Documentation]    Validate support for configuration of controller resources in component deployments
    [Tags]    Operator    Tier1    ODS-2664      Integration  RHOAIENG-12811
    FOR   ${controller}    IN    @{CONTROLLERS_LIST}
        ${new_cpu_limit}=  Set Variable  1001m
        ${new_memory_limit}=  Set Variable  4001Mi
        ${new_image}=  Set Variable  registry.invalid/test:latest
        ${new_replicas}  Set Variable  0

        # overwrite some fields
        Patch Controller Deployment  ${controller}  /spec/template/spec/containers/0/resources/limits/cpu  '${new_cpu_limit}'
        Patch Controller Deployment  ${controller}  /spec/template/spec/containers/0/resources/limits/memory  '${new_memory_limit}'
        Patch Controller Deployment  ${controller}  /spec/template/spec/containers/0/image  '${new_image}'
        Patch Controller Deployment  ${controller}  /spec/replicas  ${new_replicas}

        Sleep    10s  Give time for operator to potentially reconcile our changes

        # verify the allowlisted values are kept, non-allowlisted are reverted
        Verify Deployment Patch Was Not Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.cpu  ${new_cpu_limit}
        Verify Deployment Patch Was Not Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.memory  ${new_memory_limit}
        Verify Deployment Patch Was Not Reverted      ${controller}  .spec.replicas  ${new_replicas}
        Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].image  ${new_image}

        # annotate the deployment so that the operator ignores the allowlist
        Run  oc annotate deployment -n ${APPLICATIONS_NAMESPACE} ${controller} opendatahub.io/managed=true

        # verify that all values get reverted
        Wait Until Keyword Succeeds    1 min  10 s
        ...     Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.cpu  ${new_cpu_limit}
        Wait Until Keyword Succeeds    1 min  10 s
        ...     Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.memory  ${new_memory_limit}
        Wait Until Keyword Succeeds    1 min  10 s
        ...     Verify Deployment Patch Was Reverted  ${controller}  .spec.replicas  ${new_replicas}

        # patch again and verify that values get reverted immediately when the annotation is already in place
        Patch Controller Deployment  ${controller}  /spec/template/spec/containers/0/resources/limits/cpu  '${new_cpu_limit}'
        Patch Controller Deployment  ${controller}  /spec/template/spec/containers/0/resources/limits/memory  '${new_memory_limit}'
        Patch Controller Deployment  ${controller}  /spec/template/spec/containers/0/image  '${new_image}'
        Patch Controller Deployment  ${controller}  /spec/replicas  ${new_replicas}

        Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.cpu  ${new_cpu_limit}
        Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.memory  ${new_memory_limit}
        Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].image  ${new_image}
        Verify Deployment Patch Was Reverted  ${controller}  .spec.replicas  ${new_replicas}
    END

    [Teardown]   Restore Component Deployments


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    ${DSC_SPEC}=    Get DataScienceCluster Spec    ${DSC_NAME}
    Log To Console    DSC Spec: ${DSC_SPEC}
    Wait For DSC Ready State    ${OPERATOR_NS}     ${DSC_NAME}
    ${SAVED_MANAGEMENT_STATES.RAY}=     Get DSC Component State    ${DSC_NAME}    ray    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.KUEUE}=     Get DSC Component State    ${DSC_NAME}    kueue    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.CODEFLARE}=     Get DSC Component State    ${DSC_NAME}    codeflare    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.TRAINING}=     Get DSC Component State    ${DSC_NAME}    trainingoperator    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.DASHBOARD}=     Get DSC Component State    ${DSC_NAME}    dashboard    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.DATASCIENCEPIPELINES}=     Get DSC Component State    ${DSC_NAME}    datasciencepipelines    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.MODELMESHERVING}=     Get DSC Component State    ${DSC_NAME}    modelmeshserving    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.MODELREGISTRY}=     Get DSC Component State    ${DSC_NAME}    modelregistry    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.KSERVE}=     Get DSC Component State    ${DSC_NAME}    kserve    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.TRUSTYAI}=     Get DSC Component State    ${DSC_NAME}    trustyai    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.WORKBENCHES}=    Get DSC Component State    ${DSC_NAME}    workbenches    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.FEASTOPERATOR}=    Get DSC Component State    ${DSC_NAME}    feastoperator    ${OPERATOR_NS}
    Set Suite Variable    ${SAVED_MANAGEMENT_STATES}
    Append To List  ${CONTROLLERS_LIST}    ${DASHBOARD_DEPLOYMENT_NAME}

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown

Restore Kueue Initial State
    [Documentation]    Keyword to restore the initial state of the Kueue component. If the restored state is Unmanaged
    ...                we need to ensure the Kueue Operator is installed, if not, we need to make sure is not installed.
    ${current_state}=    Get DSC Component State    ${DSC_NAME}    kueue    ${OPERATOR_NS}
    ${ocp_version}=     Get Ocp Cluster Version
    ${install_kueue_by_ocp_version}=    GTE    ${ocp_version}    4.18.0
    ${kueue_installed} =   Check If Operator Is Installed Via CLI      ${KUEUE_OP_NAME}
    IF    "${SAVED_MANAGEMENT_STATES.KUEUE}" == "Managed"
            IF    ${install_kueue_by_ocp_version}
                    IF    ${kueue_installed}
                            Uninstall Kueue Operator CLI
                    END
            END
            ${namespace}=    Set Variable    ${APPLICATIONS_NAMESPACE}
    ELSE IF    "${SAVED_MANAGEMENT_STATES.KUEUE}" == "Unmanaged"
            IF    not ${kueue_installed}
                    Install Kueue Dependencies
            END
            ${namespace}=    Set Variable    ${KUEUE_NS}
    ELSE
            IF    ${install_kueue_by_ocp_version}
                    IF    ${kueue_installed}
                            Uninstall Kueue Operator CLI
                    END
            END
            IF       "${current_state}" == "Managed"
                      ${namespace}=    Set Variable    ${APPLICATIONS_NAMESPACE}
            ELSE IF        "${current_state}" == "Unmanaged"
                      ${namespace}=    Set Variable    ${KUEUE_NS}
            ELSE
                      ${namespace}=    Set Variable    ${APPLICATIONS_NAMESPACE}
            END
    END
    Restore DSC Component State     kueue       ${KUEUE_DEPLOYMENT_NAME}        ${KUEUE_LABEL_SELECTOR}     ${SAVED_MANAGEMENT_STATES.KUEUE}     ${namespace}

Check Controller Conditions Are Accomplished
    [Documentation]    Wait for the conditions related to a specific controller are accomplished
    [Arguments]    ${controller}

    @{d_obj}=    OpenShiftLibrary.Oc Get
    ...    kind=Deployment
    ...    name=${controller}
    ...    namespace=${APPLICATIONS_NAMESPACE}
    &{d_obj_dictionary}=    Set Variable    ${d_obj}[0]
    ${cpu_limit}=    Set Variable    ${d_obj_dictionary.spec.template.spec.containers[0].resources.limits.cpu}
    ${memory_limit}=    Set Variable    ${d_obj_dictionary.spec.template.spec.containers[0].resources.limits.memory}
    Should Match    ${d_obj_dictionary.spec.template.spec.containers[0].resources.limits.cpu}    ${cpu_limit}
    Should Match    ${d_obj_dictionary.spec.template.spec.containers[0].resources.limits.memory}    ${memory_limit}
    Should Not Match    ${d_obj_dictionary.spec.template.spec.serviceAccountName}    random-sa-name

Patch Controller Deployment
    [Arguments]    ${controller}  ${patch_path}  ${patch_value}
    ${rc}=    Run And Return Rc
    ...    oc patch Deployment ${controller} -n ${APPLICATIONS_NAMESPACE} --type=json -p="[{'op': 'replace', 'path': '${patch_path}', 'value': ${patch_value}}]"    # robocop: disable
    Should Be Equal As Integers    ${rc}    ${0}


Verify Deployment Patch Was Not Reverted
    [Arguments]    ${controller}  ${json_path}  ${expected}
    ${rc}  ${actual}=  Run And Return Rc And Output    oc get deployment -n ${APPLICATIONS_NAMESPACE} ${controller} -o jsonpath='{${json_path}}'
    Should Be Equal    ${actual}  ${expected}

Verify Deployment Patch Was Reverted
    [Arguments]    ${controller}  ${json_path}  ${expected}
    ${rc}  ${actual}=  Run And Return Rc And Output    oc get deployment -n ${APPLICATIONS_NAMESPACE} ${controller} -o jsonpath='{${json_path}}'
    Should Not Be Equal    ${actual}  ${expected}

Restore Component Deployments
    FOR   ${controller}    IN    @{CONTROLLERS_LIST}
        # delete the Deployment resource for operator to recreate
        Run  oc delete Deployment ${controller} -n ${APPLICATIONS_NAMESPACE}
    END
