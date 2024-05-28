*** Settings ***
Documentation       Test Cases to verify DSC/DSCi negative cases when Service Mesh operator is not installed

Library             Collections
Library             OperatingSystem
Resource            ../../../../Resources/OCP.resource
Resource            ../../../../Resources/ODS.robot
Resource            ../../../../Resources/RHOSi.resource
Resource            ../../../../Resources/ServiceMesh.resource
Resource            ../../../../Resources/Page/OCPDashboard/InstalledOperators/InstalledOperators.robot
Resource            ../../../../Resources/Page/OCPDashboard/OperatorHub/InstallODH.robot
Resource            ../../../../../tasks/Resources/RHODS_OLM/uninstall/uninstall.robot
Resource            ../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Variables ***
${OPERATOR_NS}                              ${OPERATOR_NAMESPACE}
${DSCI_NAME}                                default-dsci
${SERVICE_MESH_OPERATOR_NS}                 openshift-operators
${SERVICE_MESH_CR_NS}                       istio-system
${SERVICE_MESH_CR_NAME}                     data-science-smcp
${IS_NOT_PRESENT}                       1


*** Test Cases ***
Validate DSC and DSCI Created Without Service Mesh Operator     #robocop:disable
    [Documentation]    The purpose of this Test Case is to validate that DSC and DSCI are created
    ...                without Service Mesh Operator installer, but with errors
    [Tags]    Operator    Sanity    Tier1    ODS-2584

    Log To Console    message=Creating DSCInitialization CR via CLI
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Wait Until Keyword Succeeds    6 min    0 sec
    ...    Check DSCInitialization Conditions When Service Mesh Operator Is Not Installed

    Log To Console    message=Creating DataScienceCluster CR via CLI
    Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
    Wait Until Keyword Succeeds    6 min    0 sec
    ...    Check DataScienceCluster Conditions When Service Mesh Operator Is Not Installed

    [Teardown]    Reinstall Service Mesh Operator And Recreate DSC And DSCI


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    Set Library Search Order    SeleniumLibrary
    Remove DSC And DSCI Resources
    Uninstall Service Mesh Operator CLI

Suite Teardown
    [Documentation]    Suite Teardown
    Selenium Library.Close All Browsers
    RHOSi Teardown

Reinstall Service Mesh Operator And Recreate DSC And DSCI
    [Documentation]    Reinstalls Service Mesh operator and waits for the Service Mesh Control plane to be created
    Remove DSC And DSCI Resources
    Install Service Mesh Operator Via Cli
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Wait For DSCInitialization CustomResource To Be Ready    timeout=180
    Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
    Wait For DataScienceCluster CustomResource To Be Ready   timeout=600
    Set Service Mesh State To Managed And Wait For CR Ready
    ...           ${SERVICE_MESH_CR_NAME}    ${SERVICE_MESH_CR_NS}    ${SERVICE_MESH_OPERATOR_NS}

Remove DSC And DSCI Resources
    [Documentation]   Removed DSC and DSCI CRs resources from the cluster
    Log To Console    message=Deleting DataScienceCluster CR From Cluster
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc delete DataScienceCluster --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting DataScienceCluster CR

    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Is Resource Present    DataScienceCluster    ${DSC_NAME}
    ...    ${OPERATOR_NS}      ${IS_NOT_PRESENT}

    Log To Console    message=Deleting DSCInitialization CR From Cluster
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc delete DSCInitialization --all --ignore-not-found
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting DSCInitialization CR

    Wait Until Keyword Succeeds    3 min    0 sec
    ...    Is Resource Present    DSCInitialization    ${DSCI_NAME}
    ...    ${OPERATOR_NS}      ${IS_NOT_PRESENT}

Check DSCInitialization Conditions When Service Mesh Operator Is Not Installed
    [Documentation]   Keyword to check the DSCI conditions when service mesh operator is not installed
    Log To Console    message=Checking DSCInitialization conditions
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc get DSCInitialization ${DSCI_NAME} -n ${OPERATOR_NS} -o json | jq -r '.status.conditions | map(.message) | join(",")'     #robocop:disable
    Should Be Equal As Integers  ${return_code}   0   msg=Error retrieved DSCI conditions
    Should Contain    ${output}    failed to find the pre-requisite Service Mesh Operator subscription, please ensure Service Mesh Operator is installed. failed to find the pre-requisite operator subscription \"servicemeshoperator\", please ensure operator is installed. missing operator \"servicemeshoperator\"    #robocop:disable

Check DataScienceCluster Conditions When Service Mesh Operator Is Not Installed
    [Documentation]   Keyword to check the DSC conditions when service mesh operator is not installed
    Log To Console    message=Checking DataScienceCluster conditions
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster ${DSC_NAME} -n ${OPERATOR_NS} -o json | jq -r '.status.conditions | map(.message) | join(",")'    #robocop:disable
    Should Be Equal As Integers  ${return_code}   0   msg=Error retrieved DSC conditions
    Should Contain    ${output}    Component reconciliation failed: 1 error occurred:\n\t* operator servicemeshoperator not found. Please install the operator before enabling kserve component    #robocop:disable

    @{pod}=    Oc Get    kind=Pod    namespace=${OPERATOR_NS}  label_selector=name=rhods-operator
    ${logs}=    Oc Get Pod Logs    name=${pod[0]['metadata']['name']}   namespace=${OPERATOR_NS}   container=rhods-operator      #robocop:disable

    Should Contain    ${logs}    failed to find the pre-requisite Service Mesh Operator subscription, please ensure Service Mesh Operator is installed.    #robocop:disable
