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
${OPERATOR_NS}                                              ${OPERATOR_NAMESPACE}
${APPLICATIONS_NS}                                          ${APPLICATIONS_NAMESPACE}
${KNATIVE_SERVING_NS}                                       knative-serving
${DSC_NAME}                                                 default-dsc
${KUEUE_LABEL_SELECTOR}                                     app.kubernetes.io/name=kueue
${KUEUE_DEPLOYMENT_NAME}                                    kueue-controller-manager
${RAY_LABEL_SELECTOR}                                       app.kubernetes.io/name=kuberay
${RAY_DEPLOYMENT_NAME}                                      kuberay-operator
${TRAINING_LABEL_SELECTOR}                                  app.kubernetes.io/name=training-operator
${TRAINING_DEPLOYMENT_NAME}                                 kubeflow-training-operator
${TRAINER_LABEL_SELECTOR}                                   app.kubernetes.io/name=trainer
${TRAINER_DEPLOYMENT_NAME}                                  kubeflow-trainer-controller-manager
${AIPIPELINES_LABEL_SELECTOR}                               app.kubernetes.io/name=data-science-pipelines-operator
${AIPIPELINES_DEPLOYMENT_NAME}                              data-science-pipelines-operator-controller-manager
${ODH_MODEL_CONTROLLER_LABEL_SELECTOR}                      app=odh-model-controller
${ODH_MODEL_CONTROLLER_DEPLOYMENT_NAME}                     odh-model-controller
${MODELREGISTRY_CONTROLLER_LABEL_SELECTOR}                  control-plane=model-registry-operator
${MODELREGISTRY_CONTROLLER_DEPLOYMENT_NAME}                 model-registry-operator-controller-manager
${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}                 control-plane=kserve-controller-manager
${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}                kserve-controller-manager
${TRUSTYAI_CONTROLLER_MANAGER_LABEL_SELECTOR}               app.kubernetes.io/part-of=trustyai
${TRUSTYAI_CONTROLLER_MANAGER_DEPLOYMENT_NAME}              trustyai-service-operator-controller-manager
${FEASTOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}          app.kubernetes.io/part-of=feastoperator
${FEASTOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}         feast-operator-controller-manager
${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}     app.kubernetes.io/part-of=llamastackoperator
${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}    llama-stack-k8s-operator-controller-manager
${MLFLOWOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}         app.kubernetes.io/name=mlflow-operator
${MLFLOWOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}        mlflow-operator-controller-manager
${MODELSASSERVICE_CONTROLLER_MANAGER_LABEL_SELECTOR}        app.kubernetes.io/part-of=models-as-a-service
${MODELSASSERVICE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}       maas-api
${NOTEBOOK_CONTROLLER_DEPLOYMENT_LABEL_SELECTOR}            component.opendatahub.io/name=kf-notebook-controller
${NOTEBOOK_CONTROLLER_MANAGER_LABEL_SELECTOR}               component.opendatahub.io/name=odh-notebook-controller
${NOTEBOOK_DEPLOYMENT_NAME}                                 notebook-controller-deployment
${IS_NOT_PRESENT}                                           1
&{SAVED_MANAGEMENT_STATES}
...                                                         RAY=${EMPTY}
...                                                         KUEUE=${EMPTY}
...                                                         TRAINING=${EMPTY}
...                                                         TRAINER=${EMPTY}
...                                                         DASHBOARD=${EMPTY}
...                                                         AIPIPELINES=${EMPTY}
...                                                         MODELREGISTRY=${EMPTY}
...                                                         KSERVE=${EMPTY}
...                                                         TRUSTYAI=${EMPTY}
...                                                         WORKBENCHES=${EMPTY}
...                                                         FEASTOPERATOR=${EMPTY}
...                                                         LLAMASTACKOPERATOR=${EMPTY}
...                                                         MLFLOWOPERATOR=${EMPTY}
...                                                         MODELSASSERVICE=${EMPTY}

@{CONTROLLERS_LIST}                                     # dashboard added in Suite Setup, since it's different in RHOAI vs ODH
...                                                     data-science-pipelines-operator-controller-manager
...                                                     kuberay-operator
#...                                                     kueue-controller-manager   # RHOAIENG-34529
...                                                     notebook-controller-deployment
...                                                     odh-model-controller
...                                                     odh-notebook-controller-manager
...                                                     trustyai-service-operator-controller-manager
#...                                                     kserve-controller-manager  # RHOAIENG-27943
#...                                                     kubeflow-training-operator # RHOAIENG-27944


*** Test Cases ***
Validate Kueue Removed To Unmanaged State Transition
    [Documentation]    Validate that the DSC Kueue component Unmanaged state creates the expected resources,
    ...    check that kueue deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    kueue-unmanaged-from-removed
    ...    Integration
    ...    Smoke
    Set DSC Component Removed State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    ...    wait_for_completion=False
    Set DSC Component Unmanaged State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}

    [Teardown]      Restore Kueue Initial State

Validate Kueue Unmanaged To Removed State Transition
    [Documentation]    Validate that Kueue management state Removed does remove relevant resources when coming from
    ...                Unmanaged state.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    kueue-removed-from-unmanaged
    ...    Integration
    ...    Sanity

    Set DSC Component Unmanaged State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    Set DSC Component Removed State And Wait For Completion
    ...    kueue
    ...    ${KUEUE_DEPLOYMENT_NAME}
    ...    ${KUEUE_LABEL_SELECTOR}
    ...    namespace=${KUEUE_NS}
    ...    wait_for_completion=False

    [Teardown]      Restore Kueue Initial State

Validate Ray Managed State
    [Documentation]    Validate that the DSC Ray component Managed state creates the expected resources,
    ...    check that Ray deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-5435
    ...    ray-managed
    ...    Integration
    ...    Smoke

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
    ...    Sanity

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
    ...    Smoke

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
    ...    Sanity

    Set DSC Component Removed State And Wait For Completion
    ...    trainingoperator
    ...    ${TRAINING_DEPLOYMENT_NAME}
    ...    ${TRAINING_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     trainingoperator        ${TRAINING_DEPLOYMENT_NAME}     ${TRAINING_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.TRAINING}

Validate Trainer Managed State
    [Documentation]    Validate that the DSC Trainer component Managed state creates the expected resources,
    ...    check that Training deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    trainer-managed
    ...    Integration
    ...    ExcludeOnODH
    ...    Smoke

    Set DSC Component Managed State And Wait For Completion
    ...    trainer
    ...    ${TRAINER_DEPLOYMENT_NAME}
    ...    ${TRAINER_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct       ${TRAINER_DEPLOYMENT_NAME}     ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     trainer        ${TRAINER_DEPLOYMENT_NAME}     ${TRAINER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.TRAINER}

Validate Trainer Removed State
    [Documentation]    Validate that Trainer management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    trainer-removed
    ...    Integration
    ...    ExcludeOnODH
    ...    Sanity

    Set DSC Component Removed State And Wait For Completion
    ...    trainer
    ...    ${TRAINER_DEPLOYMENT_NAME}
    ...    ${TRAINER_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     trainer      ${TRAINER_DEPLOYMENT_NAME}     ${TRAINER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.TRAINER}

Validate Dashboard Managed State
    [Documentation]    Validate that the DSC Dashboard component Managed state creates the expected resources,
    ...    check that Dashboard deployment is created and all pods are in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-7298
    ...    dashboard-managed
    ...    Integration
    ...    Smoke

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
    ...    Sanity

    Set DSC Component Removed State And Wait For Completion
    ...    dashboard
    ...    ${DASHBOARD_DEPLOYMENT_NAME}
    ...    ${DASHBOARD_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     dashboard       ${DASHBOARD_DEPLOYMENT_NAME}        ${DASHBOARD_LABEL_SELECTOR}     ${SAVED_MANAGEMENT_STATES.DASHBOARD}

Validate Aipipelines Managed State
    [Documentation]    Validate that the DSC Aipipelines component Managed state creates the expected resources,
    ...    check that Datasciencepipelines deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-7298
    ...    operator-aipipelines-managed
    ...    Integration
    ...    Smoke

    Set DSC Component Managed State And Wait For Completion
    ...    aipipelines
    ...    ${AIPIPELINES_DEPLOYMENT_NAME}
    ...    ${AIPIPELINES_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct       ${AIPIPELINES_DEPLOYMENT_NAME}     ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     aipipelines        ${AIPIPELINES_DEPLOYMENT_NAME}     ${AIPIPELINES_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.AIPIPELINES}

Validate Aipipelines Removed State
    [Documentation]    Validate that Aipipelines management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-7298
    ...    operator-aipipelines-removed
    ...    Integration
    ...    Sanity

    Set DSC Component Removed State And Wait For Completion
    ...    aipipelines
    ...    ${AIPIPELINES_DEPLOYMENT_NAME}
    ...    ${AIPIPELINES_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     aipipelines        ${AIPIPELINES_DEPLOYMENT_NAME}     ${AIPIPELINES_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.AIPIPELINES}

Validate TrustyAi Managed State
    [Documentation]    Validate that the DSC TrustyAi component Managed state creates the expected resources,
    ...    check that TrustyAi deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-14018
    ...    trustyai-managed
    ...    Integration
    ...    Smoke

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
    ...    Sanity

    Set DSC Component Removed State And Wait For Completion
    ...    trustyai
    ...    ${TRUSTYAI_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${TRUSTYAI_CONTROLLER_MANAGER_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     trustyai        ${TRUSTYAI_CONTROLLER_MANAGER_DEPLOYMENT_NAME}      ${TRUSTYAI_CONTROLLER_MANAGER_LABEL_SELECTOR}       ${SAVED_MANAGEMENT_STATES.TRUSTYAI}

Validate ModelRegistry Managed State
    [Documentation]    Validate that the DSC ModelRegistry component Managed state creates the expected resources,
    ...    check that ModelRegistry deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    RHOAIENG-10404
    ...    modelregistry-managed
    ...    Integration
    ...    Smoke

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
    ...    Sanity

    # Properly validate Removed state by first setting to Managed, which will ensure that namspace
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
    ...    Smoke

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
    ...    Sanity

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
    [Tags]
    ...    Operator
    ...    Tier1
    ...    workbenches-managed
    ...    Integration
    ...    Smoke

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
    [Tags]
    ...    Operator
    ...    Tier1
    ...    workbenches-removed
    ...    Integration
    ...    Sanity

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
    ...    Smoke

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
    ...    Sanity

    Set DSC Component Removed State And Wait For Completion
    ...    feastoperator
    ...    ${FEASTOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${FEASTOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     feastoperator       ${FEASTOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}     ${FEASTOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.FEASTOPERATOR}

Validate Llamastackoperator Managed State
    [Documentation]    Validate that the DSC Llamastackoperator component Managed state creates the expected resources,
    ...    check that LlamastackOperator deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    llamastackoperator-managed
    ...    Integration
    ...    ExcludeOnODH
    ...    Smoke

    Set DSC Component Managed State And Wait For Completion
    ...    llamastackoperator
    ...    ${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct
    ...    ${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     llamastackoperator       ${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}     ${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.LLAMASTACKOPERATOR}

Validate Llamastackoperator Removed State
    [Documentation]    Validate that LlamastackOperator management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    llamastackoperator-removed
    ...    Integration
    ...    ExcludeOnODH
    ...    Sanity

    Set DSC Component Removed State And Wait For Completion
    ...    llamastackoperator
    ...    ${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     llamastackoperator       ${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}     ${LLAMASTACKOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.LLAMASTACKOPERATOR}

Validate Mlflowoperator Managed State
    [Documentation]    Validate that the DSC Mlflowoperator component Managed state creates the expected resources,
    ...    check that MlflowOperator deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    mlflowoperator-managed
    ...    Integration
    ...    ExcludeOnODH
    ...    Smoke

    Set DSC Component Managed State And Wait For Completion
    ...    mlflowoperator
    ...    ${MLFLOWOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${MLFLOWOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct
    ...    ${MLFLOWOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${IMAGE_PULL_PATH}

    [Teardown]      Restore DSC Component State     mlflowoperator       ${MLFLOWOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}     ${MLFLOWOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.MLFLOWOPERATOR}

Validate Mlflowoperator Removed State
    [Documentation]    Validate that MlflowOperator management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    mlflowoperator-removed
    ...    Integration
    ...    ExcludeOnODH
    ...    Sanity

    Set DSC Component Removed State And Wait For Completion
    ...    mlflowoperator
    ...    ${MLFLOWOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${MLFLOWOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}

    [Teardown]      Restore DSC Component State     mlflowoperator       ${MLFLOWOPERATOR_CONTROLLER_MANAGER_DEPLOYMENT_NAME}     ${MLFLOWOPERATOR_CONTROLLER_MANAGER_LABEL_SELECTOR}      ${SAVED_MANAGEMENT_STATES.MLFLOWOPERATOR}

Validate Modelsasservice Managed State
    [Documentation]    Validate that the DSC Modelsasservice component Managed state creates the expected resources,
    ...    check that ModelsAsService deployment is created and pod is in Ready state
    [Tags]
    ...    Operator
    ...    Tier1
    ...    modelsasservice-managed
    ...    Integration
    ...    ExcludeOnODH
    ...    Smoke

    Set DSC Nested Component Managed State And Wait For Completion
    ...    kserve
    ...    modelsAsService
    ...    ${MODELSASSERVICE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${MODELSASSERVICE_CONTROLLER_MANAGER_LABEL_SELECTOR}
    Check That Image Pull Path Is Correct
    ...    ${MODELSASSERVICE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${IMAGE_PULL_PATH}

    [Teardown]      Restore Nested Component And Parent State
    ...    kserve    modelsAsService
    ...    ${MODELSASSERVICE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}    ${MODELSASSERVICE_CONTROLLER_MANAGER_LABEL_SELECTOR}
    ...    ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}    ${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}
    ...    ${SAVED_MANAGEMENT_STATES.MODELSASSERVICE}    ${SAVED_MANAGEMENT_STATES.KSERVE}

Validate Modelsasservice Removed State
    [Documentation]    Validate that ModelsAsService management state Removed does remove relevant resources.
    [Tags]
    ...    Operator
    ...    Tier1
    ...    modelsasservice-removed
    ...    Integration
    ...    ExcludeOnODH
    ...    Sanity

    Set DSC Nested Component Removed State And Wait For Completion
    ...    kserve
    ...    modelsAsService
    ...    ${MODELSASSERVICE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}
    ...    ${MODELSASSERVICE_CONTROLLER_MANAGER_LABEL_SELECTOR}

    [Teardown]      Restore Nested Component And Parent State
    ...    kserve    modelsAsService
    ...    ${MODELSASSERVICE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}    ${MODELSASSERVICE_CONTROLLER_MANAGER_LABEL_SELECTOR}
    ...    ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}    ${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}
    ...    ${SAVED_MANAGEMENT_STATES.MODELSASSERVICE}    ${SAVED_MANAGEMENT_STATES.KSERVE}

Validate Support For Configuration Of Controller Resources
    [Documentation]    Validate support for configuration of controller resources in component deployments
    [Tags]    Operator    Sanity    ODS-2664      Integration  RHOAIENG-12811
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

        Sleep    45s  Give time for operator to potentially reconcile our changes

        # verify the allowlisted values are kept, non-allowlisted are reverted
        Verify Deployment Patch Was Not Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.cpu  ${new_cpu_limit}
        Verify Deployment Patch Was Not Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.memory  ${new_memory_limit}
        Verify Deployment Patch Was Not Reverted      ${controller}  .spec.replicas  ${new_replicas}
        Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].image  ${new_image}

        # annotate the deployment so that the operator ignores the allowlist
        Run  oc annotate deployment -n ${APPLICATIONS_NAMESPACE} ${controller} opendatahub.io/managed=true

        # verify that all values get reverted
        Wait Until Keyword Succeeds    3 min  10 s
        ...     Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.cpu  ${new_cpu_limit}
        Wait Until Keyword Succeeds    3 min  10 s
        ...     Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.memory  ${new_memory_limit}
        Wait Until Keyword Succeeds    3 min  10 s
        ...     Verify Deployment Patch Was Reverted  ${controller}  .spec.replicas  ${new_replicas}

        # patch again and verify that values get reverted immediately when the annotation is already in place
        Patch Controller Deployment  ${controller}  /spec/template/spec/containers/0/resources/limits/cpu  '${new_cpu_limit}'
        Patch Controller Deployment  ${controller}  /spec/template/spec/containers/0/resources/limits/memory  '${new_memory_limit}'
        Patch Controller Deployment  ${controller}  /spec/template/spec/containers/0/image  '${new_image}'
        Patch Controller Deployment  ${controller}  /spec/replicas  ${new_replicas}

        Wait Until Keyword Succeeds    3 min  10 s
        ...     Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.cpu  ${new_cpu_limit}
        Wait Until Keyword Succeeds    3 min  10 s
        ...     Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].resources.limits.memory  ${new_memory_limit}
        Wait Until Keyword Succeeds    3 min  10 s
        ...     Verify Deployment Patch Was Reverted  ${controller}  .spec.template.spec.containers[0].image  ${new_image}
        Wait Until Keyword Succeeds    3 min  10 s
        ...     Verify Deployment Patch Was Reverted  ${controller}  .spec.replicas  ${new_replicas}
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
    ${SAVED_MANAGEMENT_STATES.TRAINING}=     Get DSC Component State    ${DSC_NAME}    trainingoperator    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.TRAINER}=     Get DSC Component State     ${DSC_NAME}     trainer    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.DASHBOARD}=     Get DSC Component State    ${DSC_NAME}    dashboard    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.AIPIPELINES}=     Get DSC Component State    ${DSC_NAME}    aipipelines    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.MODELREGISTRY}=     Get DSC Component State    ${DSC_NAME}    modelregistry    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.KSERVE}=     Get DSC Component State    ${DSC_NAME}    kserve    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.TRUSTYAI}=     Get DSC Component State    ${DSC_NAME}    trustyai    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.WORKBENCHES}=    Get DSC Component State    ${DSC_NAME}    workbenches    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.FEASTOPERATOR}=    Get DSC Component State    ${DSC_NAME}    feastoperator    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.LLAMASTACKOPERATOR}=    Get DSC Component State    ${DSC_NAME}    llamastackoperator    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.MLFLOWOPERATOR}=    Get DSC Component State    ${DSC_NAME}    mlflowoperator    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.MODELSASSERVICE}=    Get DSC Nested Component State    ${DSC_NAME}    kserve    modelsAsService    ${OPERATOR_NS}
    Set Suite Variable    ${SAVED_MANAGEMENT_STATES}
    Append To List  ${CONTROLLERS_LIST}    ${DASHBOARD_DEPLOYMENT_NAME}

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown

Restore Kueue Initial State
    [Documentation]    Keyword to restore the initial state of the Kueue component. If the restored state is Unmanaged
    ...                we need to ensure the Kueue Operator is installed, if not, we need to make sure is not installed.
    ${kueue_installed} =   Check If Operator Is Installed Via CLI      ${KUEUE_OP_NAME}
    IF    not ${kueue_installed}
          Install Kueue Dependencies
    END
    Set Component State    kueue    ${SAVED_MANAGEMENT_STATES.KUEUE}

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
    ${rc}   ${out}=    Run And Return Rc And Output
    ...    oc patch Deployment ${controller} -n ${APPLICATIONS_NAMESPACE} --type=json -p="[{'op': 'replace', 'path': '${patch_path}', 'value': ${patch_value}}]"    # robocop: disable
    Log To Console    ${out}
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

Restore Nested Component And Parent State
    [Documentation]    Restore both a nested component and its parent component to their original states.
    ...                Restores nested component first, then parent component to handle dependencies correctly.
    [Arguments]    ${parent_component}    ${nested_component}    ${nested_deployment_name}    ${nested_label_selector}
    ...            ${parent_deployment_name}    ${parent_label_selector}    ${nested_saved_state}    ${parent_saved_state}

    # First restore the nested component
    Restore DSC Nested Component State
    ...    ${parent_component}
    ...    ${nested_component}
    ...    ${nested_deployment_name}
    ...    ${nested_label_selector}
    ...    ${nested_saved_state}

    # Then restore the parent component to its original state
    # This ensures parent is in the correct state after the test
    Restore DSC Component State
    ...    ${parent_component}
    ...    ${parent_deployment_name}
    ...    ${parent_label_selector}
    ...    ${parent_saved_state}
