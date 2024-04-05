*** Settings ***
Documentation       Test Cases to verify RHOAI operator integration with Authorino operator

Library             Collections
Resource            ../../../../Resources/OCP.resource
Resource            ../../../../Resources/ODS.robot
Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Variables ***
${OPERATOR_NS}                              ${OPERATOR_NAMESPACE}
${RHOAI_OPERATOR_DEPLOYMENT_NAME}           rhods-operator
${DSCI_NAME}                                default-dsci
${SERVICE_MESH_OPERATOR_NS}                 openshift-operators
${SERVICE_MESH_OPERATOR_DEPLOYMENT_NAME}    istio-operator
${AUTHORINO_OPERATOR_NS}                    openshift-operators
${AUTHORINO_OPERATOR_DEPLOYMENT_NAME}       authorino-operator
${AUTHORINO_CR_NS}                          redhat-ods-applications-auth-provider
${AUTHORINO_CR_NAME}                        authorino

${IS_PRESENT}                           0
${IS_NOT_PRESENT}                       1


*** Test Cases ***
Validate Authorino Resources
    [Documentation]    The purpose of this Test Case is to validate that Authorino resources have been created.
    [Tags]    Operator    Tier1    RHOAIENG-5092

    # Validate that Authorino CR has been created
    Wait Until Keyword Succeeds    2 min    0 sec
    ...    Is Resource Present    Authorino    ${AUTHORINO_CR_NAME}    ${AUTHORINO_CR_NS}    ${IS_PRESENT}

    Check If Pod Exists    ${AUTHORINO_CR_NS}    authorino-resource    ${FALSE}


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Wait Until Operator Ready    ${SERVICE_MESH_OPERATOR_DEPLOYMENT_NAME}    ${SERVICE_MESH_OPERATOR_NS}
    Wait Until Operator Ready    ${RHOAI_OPERATOR_DEPLOYMENT_NAME}    ${OPERATOR_NS}
    Wait Until Operator Ready    ${AUTHORINO_OPERATOR_DEPLOYMENT_NAME}    ${AUTHORINO_OPERATOR_NS}
    Wait For DSCI Ready State    ${DSCI_NAME}    ${OPERATOR_NS}

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown
