*** Settings ***
Documentation       Test Cases to verify Service Mesh integration

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
${SERVICE_MESH_CR_NS}                       istio-system
${SERVICE_MESH_OPERATOR_DEPLOYMENT_NAME}    istio-operator

${IS_PRESENT}                           0
${IS_NOT_PRESENT}                       1


*** Test Cases ***
Validate Service Mesh State Managed
    [Documentation]    The purpose of this Test Case is to validate Service Mesh integration
    [Tags]    Operator    Smoke    ODS-2526    ServiceMesh-Managed

    Is Resource Present    ServiceMeshControlPlane    data-science-smcp    ${SERVICE_MESH_CR_NS}    ${IS_PRESENT}
    Check If Pod Exists    istiod    ${SERVICE_MESH_CR_NS}

Validate Service Mesh State Unmanaged
    [Documentation]    The purpose of this Test Case is to validate Service Mesh state 'Unmanaged'.
    ...                The operator will not recreate/update the Service Mesh CR if removed or changed.
    [Tags]    Operator    Smoke    ODS-2526    ServiceMesh-Unmanaged

    Set Service Mesh Management State    Unmanaged    ${OPERATOR_NS}
    Delete Service Mesh Control Plane    ${SERVICE_MESH_CR_NS}
    Wait Until Keyword Succeeds    2 min    0 sec
    ...    Is Resource Present    ServiceMeshControlPlane    data-science-smcp    ${SERVICE_MESH_CR_NS}    ${IS_NOT_PRESENT}

    [Teardown]    Set Service Mesh Management State    Managed    ${OPERATOR_NS}

Validate Service Mesh State Removed
    [Documentation]    The purpose of this Test Case is to validate Service Mesh state 'Removed'.
    ...                The operator will Delete the Service Mesh CR, when state is Removed.
    ...                Test will fail until RHOAIENG-2209 is fixed
    [Tags]    ServiceMesh-Removed

    Set Service Mesh Management State    Removed    ${OPERATOR_NS}
    Wait Until Keyword Succeeds    2 min    0 sec
    ...    Is Resource Present    ServiceMeshControlPlane    data-science-smcp    ${SERVICE_MESH_CR_NS}    ${IS_NOT_PRESENT}

    [Teardown]    Set Service Mesh Management State    Managed    ${OPERATOR_NS}


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    RHOSi Setup
    Wait Until Operator Ready    ${SERVICE_MESH_OPERATOR_DEPLOYMENT_NAME}    ${SERVICE_MESH_OPERATOR_NS}
    Wait Until Operator Ready    ${RHOAI_OPERATOR_DEPLOYMENT_NAME}    ${OPERATOR_NS}
    Wait For DSCI Ready State    ${DSCI_NAME}    ${OPERATOR_NS}

Suite Teardown
    [Documentation]    Suite Teardown
    RHOSi Teardown

Delete Service Mesh Control Plane
    [Documentation]    Delete Service Mesh Control Plane
    [Arguments]    ${namespace}        ${reconsile_wait_time}=15s
    ${rc}=    Run And Return RC
    ...    oc delete ServiceMeshControlPlane data-science-smcp -n ${namespace}
    Should Be Equal As Integers    ${rc}    ${0}    msg=Failed to delete SMCP
    # Allow operator time to reconsile
    Sleep    ${reconsile_wait_time}

Set Service Mesh Management State
    [Documentation]    Change DSCI Management State to one of Managed/Unmanaged/Removed
    [Arguments]    ${management_state}    ${namespace}
    ${rc}=     Run And Return Rc
    ...    oc patch DSCInitialization/default-dsci -n ${namespace} -p '{"spec":{"serviceMesh":{"managementState":"${management_state}"}}}' --type merge
    Should Be Equal    "${rc}"    "0"    msg=Failed update DSCI serviceMesh managementState to ${management_state}
