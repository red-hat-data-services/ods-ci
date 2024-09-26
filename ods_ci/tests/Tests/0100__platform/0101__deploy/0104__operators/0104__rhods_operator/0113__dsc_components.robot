*** Settings ***
Documentation       Test Cases to verify DSC Distributed Workloads Components

Library             Collections
Resource            ../../../../../Resources/OCP.resource
Resource            ../../../../../Resources/ODS.robot
Resource            ../../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Variables ***
${OPERATOR_NS}                  ${OPERATOR_NAMESPACE}
${APPLICATIONS_NS}              ${APPLICATIONS_NAMESPACE}
${KNATIVE_SERVING_NS}           knative-serving
${DSC_NAME}                     default-dsc
${KUEUE_LABEL_SELECTOR}         app.kubernetes.io/name=kueue
${KUEUE_DEPLOYMENT_NAME}        kueue-controller-manager
${CODEFLARE_LABEL_SELECTOR}     app.kubernetes.io/name=codeflare-operator
${CODEFLARE_DEPLOYMENT_NAME}    codeflare-operator-manager
${RAY_LABEL_SELECTOR}           app.kubernetes.io/name=kuberay
${RAY_DEPLOYMENT_NAME}          kuberay-operator
${TRAINING_LABEL_SELECTOR}      app.kubernetes.io/name=training-operator
${TRAINING_DEPLOYMENT_NAME}     kubeflow-training-operator
${DATASCIENCEPIPELINES_LABEL_SELECTOR}     app.kubernetes.io/name=data-science-pipelines-operator
${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}    data-science-pipelines-operator-controller-manager
${MODELMESH_CONTROLLER_LABEL_SELECTOR}     app.kubernetes.io/instance=modelmesh-controller
${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}    modelmesh-controller
${ETCD_LABEL_SELECTOR}                     component=model-mesh-etcd
${ETCD_DEPLOYMENT_NAME}                    etcd
${ODH_MODEL_CONTROLLER_LABEL_SELECTOR}     app=odh-model-controller
${ODH_MODEL_CONTROLLER_DEPLOYMENT_NAME}    odh-model-controller
${MODELREGISTRY_CONTROLLER_LABEL_SELECTOR}     control-plane=model-registry-operator
${MODELREGISTRY_CONTROLLER_DEPLOYMENT_NAME}    model-registry-operator-controller-manager
${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}    control-plane=kserve-controller-manager
${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}   kserve-controller-manager
${IS_PRESENT}        0
${IS_NOT_PRESENT}    1
&{SAVED_MANAGEMENT_STATES}
...  RAY=${EMPTY}
...  KUEUE=${EMPTY}
...  CODEFLARE=${EMPTY}
...  TRAINING=${EMPTY}
...  DASHBOARD=${EMPTY}
...  DATASCIENCEPIPELINES=${EMPTY}
...  MODELMESHERVING=${EMPTY}
...  MODELREGISTRY=${EMPTY}
...  KSERVE=${EMPTY}

@{CONTROLLERS_LIST}    kserve-controller-manager    odh-model-controller    modelmesh-controller
@{REDHATIO_PATH_CHECK_EXCLUSTION_LIST}    kserve-controller-manager


*** Test Cases ***
Validate Kueue Managed State
    [Documentation]    Validate that the DSC Kueue component Managed state creates the expected resources,
    ...    check that kueue deployment is created and pod is in Ready state
    [Tags]    Operator    Tier1    RHOAIENG-5435    kueue-managed

    Set DSC Component Managed State And Wait For Completion   kueue    ${KUEUE_DEPLOYMENT_NAME}    ${KUEUE_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    kueue    ${KUEUE_DEPLOYMENT_NAME}    ${KUEUE_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.KUEUE}

Validate Kueue Removed State
    [Documentation]    Validate that Kueue management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1    RHOAIENG-5435    kueue-removed

    Set DSC Component Removed State And Wait For Completion   kueue    ${KUEUE_DEPLOYMENT_NAME}    ${KUEUE_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    kueue    ${KUEUE_DEPLOYMENT_NAME}    ${KUEUE_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.KUEUE}

 Validate Codeflare Managed State
    [Documentation]    Validate that the DSC Codeflare component Managed state creates the expected resources,
    ...    check that Codeflare deployment is created and pod is in Ready state
    [Tags]    Operator    Tier1    RHOAIENG-5435    codeflare-managed

    Set DSC Component Managed State And Wait For Completion   codeflare    ${CODEFLARE_DEPLOYMENT_NAME}    ${CODEFLARE_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    codeflare    ${CODEFLARE_DEPLOYMENT_NAME}    ${CODEFLARE_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.CODEFLARE}

Validate Codeflare Removed State
    [Documentation]    Validate that Codeflare management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1    RHOAIENG-5435    codeflare-removed

    Set DSC Component Removed State And Wait For Completion   codeflare    ${CODEFLARE_DEPLOYMENT_NAME}    ${CODEFLARE_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    codeflare    ${CODEFLARE_DEPLOYMENT_NAME}    ${CODEFLARE_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.CODEFLARE}

Validate Ray Managed State
    [Documentation]    Validate that the DSC Ray component Managed state creates the expected resources,
    ...    check that Ray deployment is created and pod is in Ready state
    [Tags]    Operator    Tier1    RHOAIENG-5435    ray-managed

    Set DSC Component Managed State And Wait For Completion   ray    ${RAY_DEPLOYMENT_NAME}    ${RAY_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    ray    ${RAY_DEPLOYMENT_NAME}    ${RAY_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.RAY}

Validate Ray Removed State
    [Documentation]    Validate that Ray management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1    RHOAIENG-5435    ray-removed

    Set DSC Component Removed State And Wait For Completion   ray    ${RAY_DEPLOYMENT_NAME}    ${RAY_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    ray    ${RAY_DEPLOYMENT_NAME}    ${RAY_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.RAY}

Validate Training Operator Managed State
    [Documentation]    Validate that the DSC Training Operator component Managed state creates the expected resources,
    ...    check that Training deployment is created and pod is in Ready state
    [Tags]    Operator    Tier1    RHOAIENG-6627    training-managed

    Set DSC Component Managed State And Wait For Completion   trainingoperator    ${TRAINING_DEPLOYMENT_NAME}    ${TRAINING_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    trainingoperator    ${TRAINING_DEPLOYMENT_NAME}    ${TRAINING_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.TRAINING}

Validate Training Operator Removed State
    [Documentation]    Validate that Training Operator management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1    RHOAIENG-6627    training-removed

    Set DSC Component Removed State And Wait For Completion   trainingoperator    ${TRAINING_DEPLOYMENT_NAME}    ${TRAINING_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    trainingoperator    ${TRAINING_DEPLOYMENT_NAME}    ${TRAINING_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.TRAINING}

Validate Dashboard Managed State
    [Documentation]    Validate that the DSC Dashboard component Managed state creates the expected resources,
    ...    check that Dashboard deployment is created and all pods are in Ready state
    [Tags]    Operator    Tier1    RHOAIENG-7298    dashboard-managed

    Set DSC Component Managed State And Wait For Completion   dashboard    ${DASHBOARD_DEPLOYMENT_NAME}    ${DASHBOARD_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    dashboard    ${DASHBOARD_DEPLOYMENT_NAME}    ${DASHBOARD_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.DASHBOARD}

Validate Dashboard Removed State
    [Documentation]    Validate that Dashboard management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1    RHOAIENG-7298    dashboard-removed

    Set DSC Component Removed State And Wait For Completion   dashboard    ${DASHBOARD_DEPLOYMENT_NAME}    ${DASHBOARD_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    dashboard    ${DASHBOARD_DEPLOYMENT_NAME}    ${DASHBOARD_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.DASHBOARD}

Validate Datasciencepipelines Managed State
    [Documentation]    Validate that the DSC Datasciencepipelines component Managed state creates the expected resources,
    ...    check that Datasciencepipelines deployment is created and pod is in Ready state
    [Tags]    Operator    Tier1    RHOAIENG-7298    operator-datasciencepipelines-managed

    Set DSC Component Managed State And Wait For Completion   datasciencepipelines    ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}    ${DATASCIENCEPIPELINES_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    datasciencepipelines    ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}    ${DATASCIENCEPIPELINES_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.DATASCIENCEPIPELINES}

Validate Datasciencepipelines Removed State
    [Documentation]    Validate that Datasciencepipelines management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1    RHOAIENG-7298    operator-datasciencepipelines-removed

    Set DSC Component Removed State And Wait For Completion   datasciencepipelines    ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}    ${DATASCIENCEPIPELINES_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    datasciencepipelines    ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}    ${DATASCIENCEPIPELINES_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.DATASCIENCEPIPELINES}

Validate Modelmeshserving Managed State
    [Documentation]    Validate that the DSC Modelmeshserving component Managed state creates the expected resources,
    ...    check that Modelmeshserving deployment is created and pods are in Ready state
    [Tags]    Operator    Tier1    RHOAIENG-8546    modelmeshserving-managed

    Set DSC Component Managed State And Wait For Completion   modelmeshserving    ${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}    ${MODELMESH_CONTROLLER_LABEL_SELECTOR}

    # Check that ETC resources are ready
    Wait For Resources To Be Available    ${ETCD_DEPLOYMENT_NAME}    ${ETCD_LABEL_SELECTOR}

    # Check that ODH Model Controller resources are ready
    Wait For Resources To Be Available    ${ODH_MODEL_CONTROLLER_DEPLOYMENT_NAME}    ${ODH_MODEL_CONTROLLER_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    modelmeshserving    ${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}    ${MODELMESH_CONTROLLER_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.MODELMESHERVING}

Validate Modelmeshserving Removed State
    [Documentation]    Validate that Modelmeshserving management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1    RHOAIENG-8546    modelmeshserving-removed

    Set DSC Component Removed State And Wait For Completion   modelmeshserving    ${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}    ${MODELMESH_CONTROLLER_LABEL_SELECTOR}

    # Check that ETC resources are removed
    Wait For Resources To Be Removed    ${ETCD_DEPLOYMENT_NAME}    ${ETCD_LABEL_SELECTOR}

    # Check that ODH Model Controller resources are removed, if KServe managementState is Removed
    ${state}=    Get DSC Component State    ${DSC_NAME}    kserve    ${OPERATOR_NS}
    IF    "${state}" == "Removed"
        Wait For Resources To Be Removed    ${ODH_MODEL_CONTROLLER_DEPLOYMENT_NAME}    ${ODH_MODEL_CONTROLLER_LABEL_SELECTOR}
    END

    [Teardown]     Restore DSC Component State    modelmeshserving    ${MODELMESH_CONTROLLER_DEPLOYMENT_NAME}    ${MODELMESH_CONTROLLER_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.MODELMESHERVING}

Validate ModelRegistry Managed State
    [Documentation]    Validate that the DSC ModelRegistry component Managed state creates the expected resources,
    ...    check that ModelRegistry deployment is created and pod is in Ready state
    [Tags]    Operator    Tier1    RHOAIENG-10404    modelregistry-managed    ExcludeOnRHOAI

    Set DSC Component Managed State And Wait For Completion   modelregistry    ${MODELREGISTRY_CONTROLLER__DEPLOYMENT_NAME}    ${MODELREGISTRY_CONTROLLER__LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    modelregistry    ${MODELREGISTRY_CONTROLLER__DEPLOYMENT_NAME}    ${MODELREGISTRY_CONTROLLER__LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.MODELREGISTRY}

Validate ModelRegistry Removed State
    [Documentation]    Validate that ModelRegistry management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1    RHOAIENG-10404    modelregistry-removed    ExcludeOnRHOAI

    Set DSC Component Removed State And Wait For Completion   modelregistry    ${MODELREGISTRY_CONTROLLER__DEPLOYMENT_NAME}    ${MODELREGISTRY_CONTROLLER__LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    modelregistry    ${MODELREGISTRY_CONTROLLER__DEPLOYMENT_NAME}    ${MODELREGISTRY_CONTROLLER__LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.MODELREGISTRY}

Validate KServe Controller Manager Managed State
    [Documentation]    Validate that the DSC KServe Controller Manager component Managed state creates the expected resources,
    ...    check that KServe Controller Manager deployment is created and pod is in Ready state
    [Tags]    Operator    Tier1    RHOAIENG-7217    kserve-controller-manager-managed

    Set DSC Component Managed State And Wait For Completion   kserve    ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}    ${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    kserve    ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}    ${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.KSERVE}

Validate KServe Controller Manager Removed State
    [Documentation]    Validate that KServe Controller Manager management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1   RHOAIENG-7217    kserve-controller-manager-removed

    Set DSC Component Removed State And Wait For Completion   kserve    ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}    ${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}

    # With KServe Removed, KNative-Serving CR will not exist regardless of the kserve.serving management state
    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     KnativeServing    knative-serving    ${KNATIVE_SERVING_NS}   ${IS_NOT_PRESENT}

    [Teardown]     Restore DSC Component State    kserve    ${KSERVE_CONTROLLER_MANAGER_DEPLOYMENT_NAME}    ${KSERVE_CONTROLLER_MANAGER_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.KSERVE}

Validate Support For Configuration Of Controller Resources
    [Documentation]    Validate support for configuration of controller resources in component deployments
    [Tags]    Operator    Tier1    ODS-2664
    FOR   ${controller}    IN    @{CONTROLLERS_LIST}
        ${rc}=    Run And Return Rc
        ...    oc patch Deployment ${controller} -n ${APPLICATIONS_NAMESPACE} --type=json -p="[{'op': 'replace', 'path': '/spec/template/spec/containers/0/resources/limits/cpu', 'value': '600m'}]"    # robocop: disable
        Should Be Equal As Integers    ${rc}    ${0}
        ${rc}=    Run And Return Rc
        ...    oc patch Deployment ${controller} -n ${APPLICATIONS_NAMESPACE} --type=json -p="[{'op': 'replace', 'path': '/spec/template/spec/containers/0/resources/limits/memory', 'value': '6Gi'}]"    # robocop: disable
        Should Be Equal As Integers    ${rc}    ${0}
        ${rc}=    Run And Return Rc
        ...    oc patch Deployment ${controller} -n ${APPLICATIONS_NAMESPACE} --type=json -p="[{'op': 'replace', 'path': '/spec/template/spec/serviceAccountName', 'value': 'random-sa-name'}]"    # robocop: disable
        Should Be Equal As Integers    ${rc}    ${0}

        Wait Until Keyword Succeeds    3 min    0 sec
        ...    Check Controller Conditions Are Accomplished      ${controller}

        # Restore old values
        # delete the Deployment resource for operator to recreate
        ${rc}=    Run And Return Rc
        ...    oc delete Deployment ${controller} -n ${APPLICATIONS_NAMESPACE}
        Should Be Equal As Integers    ${rc}    ${0}
    END


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    ${DSC_SPEC}=    Get DataScienceCluster Spec    ${DSC_NAME}
    Log To Console    DSC Spec: ${DSC_SPEC}
    Wait For DSC Conditions Reconciled    ${OPERATOR_NS}     ${DSC_NAME}
    ${SAVED_MANAGEMENT_STATES.RAY}=     Get DSC Component State    ${DSC_NAME}    ray    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.KUEUE}=     Get DSC Component State    ${DSC_NAME}    kueue    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.CODEFLARE}=     Get DSC Component State    ${DSC_NAME}    codeflare    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.TRAINING}=     Get DSC Component State    ${DSC_NAME}    trainingoperator    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.DASHBOARD}=     Get DSC Component State    ${DSC_NAME}    dashboard    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.DATASCIENCEPIPELINES}=     Get DSC Component State    ${DSC_NAME}    datasciencepipelines    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.MODELMESHERVING}=     Get DSC Component State    ${DSC_NAME}    modelmeshserving    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.MODELREGISTRY}=     Get DSC Component State    ${DSC_NAME}    modelregistry    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.KSERVE}=     Get DSC Component State    ${DSC_NAME}    kserve    ${OPERATOR_NS}
    Set Suite Variable    ${SAVED_MANAGEMENT_STATES}

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown

Check Controller Conditions Are Accomplished
    [Documentation]    Wait for the conditions related to a specific controller are accomplished
    [Arguments]    ${controller}

    @{d_obj}=  OpenShiftLibrary.Oc Get  kind=Deployment  name=${controller}    namespace=${APPLICATIONS_NAMESPACE}
    &{d_obj_dictionary}=  Set Variable  ${d_obj}[0]
    ${cpu_limit}=    Set Variable    ${d_obj_dictionary.spec.template.spec.containers[0].resources.limits.cpu}
    ${memory_limit}=    Set Variable    ${d_obj_dictionary.spec.template.spec.containers[0].resources.limits.memory}
    Should Match    ${d_obj_dictionary.spec.template.spec.containers[0].resources.limits.cpu}    ${cpu_limit}
    Should Match    ${d_obj_dictionary.spec.template.spec.containers[0].resources.limits.memory}    ${memory_limit}
    Should Not Match    ${d_obj_dictionary.spec.template.spec.serviceAccountName}    random-sa-name

Set DSC Component Removed State And Wait For Completion
    [Documentation]    Set component management state to 'Removed', and wait for deployment and pod to be removed.
    [Arguments]    ${component}    ${deployment_name}    ${label_selector}

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    ${component}    ${OPERATOR_NS}
    IF    "${management_state}" != "Removed"
            Set Component State    ${component}    Removed
    END

    Wait For Resources To Be Removed    ${deployment_name}    ${label_selector}

Set DSC Component Managed State And Wait For Completion
    [Documentation]    Set component management state to 'Managed', and wait for deployment and pod to be available.
    [Arguments]    ${component}    ${deployment_name}    ${label_selector}

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    ${component}    ${OPERATOR_NS}
    IF    "${management_state}" != "Managed"
            Set Component State    ${component}    Managed
    END

    Wait For Resources To Be Available    ${deployment_name}    ${label_selector}

    Check Image Pull Path Is Redhatio    ${deployment_name}

Wait For Resources To Be Available
    [Documentation]    Wait until Deployment and Pod(s) are Available
    [Arguments]    ${deployment_name}    ${label_selector}
    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Deployment    ${deployment_name}    ${APPLICATIONS_NS}    ${IS_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Check If Pod Exists    ${APPLICATIONS_NS}    ${label_selector}    ${FALSE}

    Wait Until Keyword Succeeds    8 min    0 sec
    ...    Is Pod Ready    ${label_selector}

Wait For Resources To Be Removed
    [Documentation]    Wait until Deployment and Pod(s) to Removed
    [Arguments]    ${deployment_name}    ${label_selector}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Deployment    ${deployment_name}    ${APPLICATIONS_NS}    ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Check If Pod Does Not Exist    ${label_selector}    ${APPLICATIONS_NS}

Restore DSC Component State
    [Documentation]    Set component management state to original state, wait for component resources to be available.
    [Arguments]    ${component}    ${deployment_name}    ${LABEL_SELECTOR}    ${saved_state}

    ${current_state}=    Get DSC Component State    ${DSC_NAME}    ${component}    ${OPERATOR_NS}
    IF    "${current_state}" != "${saved_state}"
        IF    "${saved_state}" == "Managed"
            Set DSC Component Managed State And Wait For Completion    ${component}    ${deployment_name}    ${LABEL_SELECTOR}
        ELSE IF    "${saved_state}" == "Removed"
            Set DSC Component Removed State And Wait For Completion    ${component}    ${deployment_name}    ${LABEL_SELECTOR}
        ELSE
            FAIL    Component ${component} state "${saved_state}" not supported at this time
        END
    END

Is Pod Ready
    [Documentation]    Check If Pod Is In Ready State.
    ...    Note: Will check that all pods with given label-selector are in Ready state.
    [Arguments]    ${label_selector}
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    oc get pod -A -l ${label_selector} -o jsonpath='{..status.conditions[?(@.type=="Ready")].status}'
    # Log To Console    "Pod Ready Status: ${output}"
    Should Be Equal As Integers    ${rc}    0
    Should Not Contain    ${output}    False

Get DataScienceCluster Spec
    [Documentation]    Return the DSC Spec
    [Arguments]    ${DSC_NAME}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster/${DSC_NAME} -n ${OPERATOR_NS} -o "jsonpath={".spec"}"
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${output}

Check Image Pull Path Is Redhatio
    [Documentation]    Check that the Deployment Image Pull Path is registry.redhat.io
    [Arguments]    ${deployment_name}

    # Skip pull path check if Deployment is in exclusion list
    IF    $deployment_name in @{REDHATIO_PATH_CHECK_EXCLUSTION_LIST}
        Log To Console    Skip image pull path check for Deployment ${deployment_name}
        RETURN
    END

    ${rc}   ${image}=    Run And Return Rc And Output
    ...    oc get deployment/${deployment_name} -n ${APPLICATIONS_NAMESPACE} -o jsonpath="{..image}"
    Should Be Equal As Integers    ${rc}    0    msg=${image}

    Log To Console    Check deployment ${deployment_name} pull path for image ${image}
    IF  "registry.redhat.io" in $image
        Log To Console    Deployment ${deployment_name} image contains pull path registry.redhat.io
    ELSE
        Fail    Deployment image  ${deployment_name} does not contain pull path registry.redhat.io
    END
