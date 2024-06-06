*** Settings ***
Documentation       Test Cases to verify DSC Distributed Workloads Components

Library             Collections
Resource            ../../../../Resources/OCP.resource
Resource            ../../../../Resources/ODS.robot
Resource            ../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Variables ***
${OPERATOR_NS}                  ${OPERATOR_NAMESPACE}
${APPLICATIONS_NS}              ${APPLICATIONS_NAMESPACE}
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
${IS_PRESENT}        0
${IS_NOT_PRESENT}    1
&{SAVED_MANAGEMENT_STATES}
...  RAY=${EMPTY}
...  KUEUE=${EMPTY}
...  CODEFLARE=${EMPTY}
...  TRAINING=${EMPTY}
...  DASHBOARD=${EMPTY}
...  DATASCIENCEPIPELINES=${EMPTY}


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
    [Tags]    Operator    Tier1    RHOAIENG-7298    datasciencepipelines-managed

    Set DSC Component Managed State And Wait For Completion   datasciencepipelines    ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}    ${DATASCIENCEPIPELINES_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    datasciencepipelines    ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}    ${DATASCIENCEPIPELINES_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.DATASCIENCEPIPELINES}

Validate Datasciencepipelines Removed State
    [Documentation]    Validate that Datasciencepipelines management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1    RHOAIENG-7298    datasciencepipelines-removed

    Set DSC Component Removed State And Wait For Completion   datasciencepipelines    ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}    ${DATASCIENCEPIPELINES_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component State    datasciencepipelines    ${DATASCIENCEPIPELINES_DEPLOYMENT_NAME}    ${DATASCIENCEPIPELINES_LABEL_SELECTOR}    ${SAVED_MANAGEMENT_STATES.DATASCIENCEPIPELINES}


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Wait For DSC Conditions Reconciled    ${OPERATOR_NS}     ${DSC_NAME}
    ${SAVED_MANAGEMENT_STATES.RAY}=     Get DSC Component State    ${DSC_NAME}    ray    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.KUEUE}=     Get DSC Component State    ${DSC_NAME}    kueue    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.CODEFLARE}=     Get DSC Component State    ${DSC_NAME}    codeflare    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.TRAINING}=     Get DSC Component State    ${DSC_NAME}    trainingoperator    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.DASHBOARD}=     Get DSC Component State    ${DSC_NAME}    dashboard    ${OPERATOR_NS}
    ${SAVED_MANAGEMENT_STATES.DATASCIENCEPIPELINES}=     Get DSC Component State    ${DSC_NAME}    datasciencepipelines    ${OPERATOR_NS}
    Set Suite Variable    ${SAVED_MANAGEMENT_STATES}

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown

Set DSC Component Removed State And Wait For Completion
    [Documentation]    Set component management state to 'Removed', and wait for deployment and pod to be removed.
    [Arguments]    ${component}    ${deployment_name}    ${label_selector}

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    ${component}    ${OPERATOR_NS}
    IF    "${management_state}" != "Removed"
            Set Component State    ${component}    Removed
    END

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Deployment    ${deployment_name}    ${APPLICATIONS_NS}    ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Check If Pod Does Not Exist    ${label_selector}    ${APPLICATIONS_NS}

Set DSC Component Managed State And Wait For Completion
    [Documentation]    Set component management state to 'Managed', and wait for deployment and pod to be available.
    [Arguments]    ${component}    ${deployment_name}    ${label_selector}

    ${management_state}=    Get DSC Component State    ${DSC_NAME}    ${component}    ${OPERATOR_NS}
    IF    "${management_state}" != "Managed"
            Set Component State    ${component}    Managed
    END

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Deployment    ${deployment_name}    ${APPLICATIONS_NS}    ${IS_PRESENT}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Check If Pod Exists    ${APPLICATIONS_NS}    ${label_selector}    ${FALSE}

    Wait Until Keyword Succeeds    8 min    0 sec
    ...    Is Pod Ready    ${label_selector}

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
