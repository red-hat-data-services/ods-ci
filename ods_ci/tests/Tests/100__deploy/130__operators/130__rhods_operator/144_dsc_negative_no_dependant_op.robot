*** Settings ***
Documentation       Test Cases to verify DSC/DSCi negative cases when dependant (servicemesh, serverless) operators are not installed

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
${IS_NOT_PRESENT}                           1


*** Test Cases ***
Validate DSC and DSCI Created Without Service Mesh And Serverless Operators     #robocop:disable
    [Documentation]    The purpose of this Test Case is to validate that DSC and DSCI are created
    ...                without dependant operators ((servicemesh, serverless) installed, but with errors
    [Tags]    Operator    Tier3    ODS-2527

    Log To Console    message=Creating DSCInitialization CR via CLI
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Sleep  30s     reason=wait for 1 minute until DSCI is created and reconciled

    Log To Console    message=Creating DataScienceCluster CR via CLI
    Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
    Wait Until Keyword Succeeds    6 min    0 sec
    ...    Check DataScienceCluster Conditions When Dependant Operators Are Not Installed

    [Teardown]    Reinstall Service Mesh And Serverless Operators And Recreate DSC And DSCI


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    Set Library Search Order    SeleniumLibrary
    Remove DSC And DSCI Resources
    Uninstall Service Mesh Operator CLI
    Uninstall Serverless Operator CLI

Suite Teardown
    [Documentation]    Suite Teardown
    Selenium Library.Close All Browsers
    RHOSi Teardown

Reinstall Service Mesh And Serverless Operators And Recreate DSC And DSCI
    [Documentation]    Reinstalls Dependant (service mesh, serverless) operators and waits for the Service Mesh Control plane to be created
    Remove DSC And DSCI Resources
    Install Serverless Operator Via Cli
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

Check DataScienceCluster Conditions When Dependant Operators Are Not Installed
    [Documentation]   Keyword to check the DSC conditions when dependant (servicemesh, serverless) operators are not installed
    Log To Console    message=Checking DataScienceCluster conditions
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster ${DSC_NAME} -n ${OPERATOR_NS} -o json | jq -r '.status.conditions | map(.message) | join(",")'    #robocop:disable
    Should Be Equal As Integers  ${return_code}   0   msg=Error retrieved DSC conditions
    Should Contain    ${output}    operator servicemeshoperator not found. Please install the operator before enabling kserve component    #robocop:disable
    Should Contain    ${output}    operator serverless-operator not found. Please install the operator before enabling kserve component    #robocop:disable
