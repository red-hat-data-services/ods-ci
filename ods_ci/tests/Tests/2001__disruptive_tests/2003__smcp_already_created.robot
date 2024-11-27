*** Settings ***
Documentation       Test Cases to verify Service Mesh disruptive tests

Library             Collections
Resource            ../../Resources/OCP.resource
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/ServiceMesh.resource
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
${OLM_DIR}                                  olm
${INSTALL_TYPE}                             CLi
${TEST_ENV}                                 PSI
${IS_PRESENT}                               0
${IS_NOT_PRESENT}                           1
${MSG_REGEX}                                denied the request: only one service mesh may be installed per project/namespace


*** Test Cases ***
Validate Service Mesh Control Plane Already Created
    [Documentation]    This Test Case validates that only one ServiceMeshControlPlane is allowed to be installed per project/namespace
    [Tags]      RHOAIENG-2517       Operator    OperatorExclude
    Fetch Image Url And Update Channel
    Check Whether DSC Exists And Save Component Statuses
    Fetch Cluster Type By Domain
    IF    "${CLUSTER_TYPE}" == "selfmanaged"
        Uninstall RHODS In Self Managed Cluster
        Create Smcp From Template
        Install RHODS In Self Managed Cluster Using CLI     ${CLUSTER_TYPE}     ${IMAGE_URL}
    ELSE IF    "${CLUSTER_TYPE}" == "managed"
        Uninstall RHODS In OSD
        Create Smcp From Template
        Install RHODS In Managed Cluster Using CLI      ${CLUSTER_TYPE}     ${IMAGE_URL}
    END
    Operator Deployment Should Be Ready
    # Go check the Operator logs for the error message: denied the request: only one service mesh may be installed per project/namespace
    Verify Pod Logs Contain Error
    [Teardown]      Teardown Service Mesh Control Plane Already Created

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

Teardown Service Mesh Control Plane Already Created
    # Cleanup the SMCP
    Delete Smcp
    # Cleanup Olminstall dir
    Cleanup Olm Install Dir
    IF      ${DSC_EXISTS} == True
        Apply DataScienceCluster CustomResource     ${DSC_NAME}     True    ${custom_cmp}
    END
    Wait Until Keyword Succeeds    2 min    0 sec
    ...    Is Resource Present    ServiceMeshControlPlane    ${SERVICE_MESH_CR_NAME}    ${SERVICE_MESH_CR_NS}    ${IS_PRESENT}

Check Whether DSC Exists And Save Component Statuses
    ${rc}=    Run And Return Rc
    ...    oc get datasciencecluster ${DSC_NAME}
    IF  ${rc} == 0
        Set Global Variable    ${DSC_EXISTS}    True
        &{custom_cmp} =       Create Dictionary
        ${rc}    ${out}=    Run And Return Rc And Output
        ...    oc get datasciencecluster ${DSC_NAME} -o jsonpath='{.spec.components}'
        ${custom_cmp}=    Load Json String    ${out}
        Set Test Variable    ${custom_cmp}    ${custom_cmp}
    ELSE
        Set Global Variable    ${DSC_EXISTS}    False
    END

Fetch Image Url And Update Channel
    [Documentation]    Fetch url for image and Update Channel
    # Fetch subscription first
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get subscription ${OPERATOR_SUBSCRIPTION_NAME} -n ${OPERATOR_NAMESPACE} -o jsonpath='{.spec.source}'
    Should Be Equal As Integers    ${rc}    0
    Set Global Variable    ${CS_NAME}    ${out}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get subscription ${OPERATOR_SUBSCRIPTION_NAME} -n ${OPERATOR_NAMESPACE} -o jsonpath='{.spec.sourceNamespace}'
    Should Be Equal As Integers    ${rc}    0
    Set Global Variable    ${CS_NAMESPACE}    ${out}
    # Get CatalogSource
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get catalogsource ${CS_NAME} --namespace ${CS_NAMESPACE} -o jsonpath='{.spec.image}'
    Should Be Equal As Integers    ${rc}    0
    Set Global Variable    ${IMAGE_URL}    ${out}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get subscription ${OPERATOR_SUBSCRIPTION_NAME} --namespace ${OPERATOR_NS} -o jsonpath='{.spec.channel}'
    Should Be Equal As Integers    ${rc}    0
    Set Global Variable    ${UPDATE_CHANNEL}    ${out}

Fetch Cluster Type By Domain
    [Documentation]    This Keyword outputs the kind of cluster depending on the console URL domain
    ${matches}=    Get Regexp Matches    ${OCP_CONSOLE_URL}    rh-ods
    ${domain}=    Get From List    ${matches}    0
    IF    "${domain}" == "rh-ods"
        Set Global Variable    ${CLUSTER_TYPE}    selfmanaged
    ELSE
        Set Global Variable    ${CLUSTER_TYPE}    managed
    END

Create Smcp From Template
    [Documentation]    Create a default ServiceMeshControlPlane from a template
    ${file_path}=    Set Variable    ./tasks/Resources/Files/
    ${return_code}=    Run And Return Rc    oc apply -f ${file_path}smcp_template.yml
    Should Be Equal As Integers    ${return_code}    0

Delete Smcp
    [Documentation]    Delete the ServiceMeshControlPlane already created
    Run and Watch Command
    ...    oc delete ServiceMeshControlPlane basic --namespace ${SERVICE_MESH_CR_NS} --force --grace-period=0

Operator Deployment Should Be Ready
    [Documentation]    Loop until the Operator deployment is ready
    ${rc}=    Set Variable    1
    TRY
        WHILE    ${rc} != 0    limit=10m
            Sleep    5s
            ${rc}    ${output}=    Run And Return Rc And Output
            ...    oc wait --for condition=available -n ${OPERATOR_NAMESPACE} deploy/${OPERATOR_DEPLOYMENT_NAME}
        END
    EXCEPT    WHILE loop was aborted    type=start
        Fail    msg=Operator deployment did not get ready
    END

Verify Pod Logs Contain Error
    [Documentation]    Checks whether there is a SMCP related error on the Pod Logs
    ${pod_name}=    Get Pod Name    ${OPERATOR_NAMESPACE}    ${OPERATOR_LABEL_SELECTOR}
    ${length}=    Set Variable    0
    TRY
        WHILE       ${length} == 0        limit=5m
            ${pod_logs}=    Oc Get Pod Logs
            ...    name=${pod_name}
            ...    namespace=${OPERATOR_NAMESPACE}
            ...    container=${OPERATOR_POD_CONTAINER_NAME}
            ${match_list}=    Get Regexp Matches    ${pod_logs}    ${MSG_REGEX}
            ${entry_msg}=    Remove Duplicates    ${match_list}
            ${length}=    Get Length    ${entry_msg}
            Sleep    10s
        END
    EXCEPT
        Fail    msg=Pod ${pod_name} logs should contain message '${MSG_REGEX}'
    END

Cleanup Olm Install Dir
    [Documentation]    Clean up olm install repo
    ${return_code}=    Run and Watch Command    rm -vRf ${EXECDIR}/${OLM_DIR}    timeout=10 min
    Should Be Equal As Integers    ${return_code}    0    msg=Error while cleaning up olminstall directory
