*** Settings ***
Documentation       Test Cases to verify Service Mesh integration

Library             Collections
Resource            ../../../../../Resources/OCP.resource
Resource            ../../../../../Resources/ODS.robot
Resource            ../../../../../Resources/RHOSi.resource
Resource            ../../../../../Resources/ServiceMesh.resource
Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Variables ***
${OPERATOR_NS}                              ${OPERATOR_NAMESPACE}
${DSCI_NAME}                                default-dsci
${DSC_NAME}                                 default-dsc
${SERVICE_MESH_OPERATOR_NS}                 openshift-operators
${SERVICE_MESH_OPERATOR_DEPLOYMENT_NAME}    istio-operator
${SERVICE_MESH_CR_NS}                       istio-system
${SERVICE_MESH_CR_NAME}                     data-science-smcp
${INSTALL_TYPE}                             Cli
${TEST_ENV}                                 PSI
${IS_PRESENT}                               0
${IS_NOT_PRESENT}                           1


*** Test Cases ***
Validate Service Mesh State Managed
    [Documentation]    The purpose of this Test Case is to validate Service Mesh integration
    [Tags]    Operator    Tier1    ODS-2526    ServiceMesh-Managed

    Is Resource Present    ServiceMeshControlPlane    ${SERVICE_MESH_CR_NAME}    ${SERVICE_MESH_CR_NS}    ${IS_PRESENT}
    Check If Pod Exists    ${SERVICE_MESH_CR_NS}    app=istiod    ${FALSE}

    [Teardown]    Set Service Mesh State To Managed And Wait For CR Ready    ${SERVICE_MESH_CR_NAME}    ${SERVICE_MESH_CR_NS}    ${OPERATOR_NS}

Validate Service Mesh State Unmanaged
    [Documentation]    The purpose of this Test Case is to validate Service Mesh state 'Unmanaged'.
    ...                The operator will not recreate/update the Service Mesh CR if removed or changed.
    [Tags]    Operator    Tier1    ODS-2526    ServiceMesh-Unmanaged

    Set Service Mesh Management State    Unmanaged    ${OPERATOR_NS}
    Delete Service Mesh Control Plane    ${SERVICE_MESH_CR_NS}
    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present    ServiceMeshControlPlane    ${SERVICE_MESH_CR_NAME}     ${SERVICE_MESH_CR_NS}    ${IS_NOT_PRESENT}

    [Teardown]    Set Service Mesh State To Managed And Wait For CR Ready    ${SERVICE_MESH_CR_NAME}    ${SERVICE_MESH_CR_NS}    ${OPERATOR_NS}

Validate Service Mesh State Removed
    [Documentation]    The purpose of this Test Case is to validate Service Mesh state 'Removed'.
    ...                The operator will Delete the Service Mesh CR, when state is Removed.
    ...                Test will fail until RHOAIENG-2209 is fixed
    [Tags]    Operator    Tier1    ODS-2526     ServiceMesh-Removed     ProductBug

    Set Service Mesh Management State    Removed    ${OPERATOR_NS}
    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present    ServiceMeshControlPlane    ${SERVICE_MESH_CR_NAME}    ${SERVICE_MESH_CR_NS}    ${IS_NOT_PRESENT}

    [Teardown]    Set Service Mesh State To Managed And Wait For CR Ready
    ...           ${SERVICE_MESH_CR_NAME}    ${SERVICE_MESH_CR_NS}    ${OPERATOR_NS}


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Wait Until Operator Ready    ${SERVICE_MESH_OPERATOR_DEPLOYMENT_NAME}    ${SERVICE_MESH_OPERATOR_NS}
    Wait Until Operator Ready    ${OPERATOR_DEPLOYMENT_NAME}    ${OPERATOR_NAMESPACE}
    Wait For DSCI Ready State    ${DSCI_NAME}    ${OPERATOR_NAMESPACE}

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown
