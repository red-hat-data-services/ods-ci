*** Settings ***
Documentation       Main Service Mesh Resource file, to manage the operator and its resources

Resource            OCP.resource
Resource            ODS.robot

Library             OpenShiftLibrary


*** Variables ***
${SERVICE_MESH_OPERATOR_NS}                 openshift-operators
${SERVICE_MESH_OPERATOR_DEPLOYMENT_NAME}    istio-operator
${SERVICE_MESH_CR_NS}                       istio-system

${IS_PRESENT}                           0
${IS_NOT_PRESENT}                       1


*** Keywords ***
Delete Service Mesh Control Plane
    [Documentation]    Delete Service Mesh Control Plane
    [Arguments]    ${namespace}        ${reconsile_wait_time}=15s
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc delete ServiceMeshControlPlane data-science-smcp -n ${namespace}
    Should Be Equal    "${rc}"    "0"   msg=${output}
    # Allow operator time to reconsile
    Sleep    ${reconsile_wait_time}

Set Service Mesh Management State
    [Documentation]    Change DSCI Management State to one of Managed/Unmanaged/Removed
    [Arguments]    ${management_state}    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...         oc patch DSCInitialization/default-dsci -n ${namespace} -p '{"spec":{"serviceMesh":{"managementState":"${management_state}"}}}' --type merge    #robocop:disable
    Should Be Equal    "${rc}"    "0"   msg=${output}

Set Service Mesh State To Managed And Wait For CR Ready
    [Documentation]    Restore Service Mesh State and Wait for Service Mesh CR to be Ready
    [Arguments]    ${smcp_name}    ${smcp_ns}    ${dsci_ns}    ${timeout}=2m

    Set Service Mesh Management State    Managed    ${dsci_ns}

    Wait Until Keyword Succeeds    5 min    0 sec
    ...    Is Resource Present    ServiceMeshControlPlane    ${smcp_name}     ${smcp_ns}    ${IS_PRESENT}

    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc wait ServiceMeshControlPlane/${smcp_name} --for condition=Ready -n ${smcp_ns} --timeout ${timeout}
    Should Be Equal    "${rc}"    "0"   msg=${output}

Delete Mesh Service CRs
    [Documentation]    Deletes the mesh service CRs using OpenshiftLibrary.
    ...                Temporarily, it deletes all the CRs it finds, but
    ...                this going to change when installation will be replaces with CLI:
    ...                at that point the kw will delete a specific CR by name
    [Arguments]    ${cr_kind}    ${cr_ns}
    ${servicemeshs}=    Oc Get    api_version=maistra.io/v2    kind=${cr_kind}   namespace=${cr_ns}
    ...            fields=['metadata.name']
    ${n_servicemeshs}=    Get Length    ${servicemeshs}
    IF    "${n_servicemeshs}" > "${1}"
        Log    message=There are more than once instance of Mesh Service..deleting all of them!
        ...    level=WARN
    END
    FOR    ${instance}    IN    @{servicemeshs}
        Oc Delete    api_version=maistra.io/v2
        ...    kind=${cr_kind}  name=${instance}[metadata.name]  namespace=${cr_ns}
    END
