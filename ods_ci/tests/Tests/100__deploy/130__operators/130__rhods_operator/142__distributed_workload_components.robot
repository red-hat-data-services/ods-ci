*** Settings ***
Documentation       Test Cases to verify DSC Distributed Workloads Components

Library             Collections
Resource            ../../../../Resources/OCP.resource
Resource            ../../../../Resources/ODS.robot
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
${IS_PRESENT}    0
${IS_NOT_PRESENT}    1


*** Test Cases ***
Validate Kueue Managed State
    [Documentation]    Validate that the DSC by default sets component 'kueue' to sate Managed,
    ...    check that kueue deployment and pod are created
    [Tags]    Operator    Tier1    RHOAIENG-5435    kueue-managed

    Check Component Resources In Managed State   kueue    ${KUEUE_DEPLOYMENT_NAME}    ${KUEUE_LABEL_SELECTOR}

Validate Kueue Removed State
    [Documentation]    Validate that Kueue management state Removed does remove relevant resources.
    [Tags]    Operator    Tier1    RHOAIENG-5435    kueue-removed

    Set DSC Component Removed State And Wait For Completion   kueue    ${KUEUE_DEPLOYMENT_NAME}    ${KUEUE_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component Managed State And Wait For Completion    kueue    ${KUEUE_DEPLOYMENT_NAME}    ${KUEUE_LABEL_SELECTOR}

Validate Codeflare Managed State
    [Documentation]    Validate that the DSC by default sets component 'Codeflare' to sate Managed,
    ...    check that kueue deployment and pod are created
    [Tags]    Operator    Tier1    RHOAIENG-5435    codeflare-managed

    Check Component Resources In Managed State    kueue    ${CODEFLARE_DEPLOYMENT_NAME}    ${CODEFLARE_LABEL_SELECTOR}

Validate Codeflare Removed State
    [Documentation]    Validate that Codeflare management state Removed does remove relevant resources.

    [Tags]    Operator    Tier1    RHOAIENG-5435    codeflare-removed

    Set DSC Component Removed State And Wait For Completion   codeflare    ${CODEFLARE_DEPLOYMENT_NAME}    ${CODEFLARE_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component Managed State And Wait For Completion    codeflare    ${CODEFLARE_DEPLOYMENT_NAME}    ${CODEFLARE_LABEL_SELECTOR}

Validate Ray Managed State
    [Documentation]    Validate that the DSC by default sets component 'Ray' to sate Managed,
    ...    check that Ray deployment and pod are created
    [Tags]    Operator    Tier1    RHOAIENG-5435    ray-managed

    Check Component Resources In Managed State   ray    ${RAY_DEPLOYMENT_NAME}    ${RAY_LABEL_SELECTOR}

Validate Ray Removed State
    [Documentation]    Validate that Ray management state Removed does remove relevant resources.

    [Tags]    Operator    Tier1    RHOAIENG-5435    ray-removed

    Set DSC Component Removed State And Wait For Completion   ray    ${RAY_DEPLOYMENT_NAME}    ${RAY_LABEL_SELECTOR}

    [Teardown]     Restore DSC Component Managed State And Wait For Completion    ray    ${RAY_DEPLOYMENT_NAME}    ${RAY_LABEL_SELECTOR}


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Wait For DSC Conditions Reconciled    ${OPERATOR_NS}     ${DSC_NAME}

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown

Check Component Resources In Managed State
    [Documentation]    Validate that component resources are created as expected
    [Arguments]    ${component}    ${deployment_name}    ${LABEL_SELECTOR}

    Check DSC Component Management State    ${DSC_NAME}    ${component}    Managed    ${OPERATOR_NS}
    Is Resource Present     Deployment    ${deployment_name}    ${APPLICATIONS_NS}    ${IS_PRESENT}
    Check If Pod Exists    ${APPLICATIONS_NS}    ${LABEL_SELECTOR}    ${FALSE}

Set DSC Component Removed State And Wait For Completion
    [Documentation]    Set component management state to 'Removed', and wait for resources deployment and pod to be removed.
    [Arguments]    ${component}    ${deployment_name}    ${label_selector}

    Set DSC Component Management State    ${DSC_NAME}    ${component}    Removed    ${OPERATOR_NS}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Deployment    ${deployment_name}    ${APPLICATIONS_NS}    ${IS_NOT_PRESENT}

    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Check If Pod Does Not Exist    ${label_selector}    ${APPLICATIONS_NS}

Restore DSC Component Managed State And Wait For Completion
    [Documentation]    Set component management state to 'Managed', wait for component resources deployment and pod to be present.
    [Arguments]    ${component}    ${deployment_name}    ${LABEL_SELECTOR}

    Set DSC Component Management State    ${DSC_NAME}    ${component}    Managed    ${OPERATOR_NS}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present     Deployment    ${deployment_name}    ${APPLICATIONS_NS}    ${IS_PRESENT}

    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Check If Pod Exists    ${APPLICATIONS_NS}    ${LABEL_SELECTOR}    ${FALSE}
