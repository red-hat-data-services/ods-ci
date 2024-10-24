*** Settings ***
Documentation       Test Cases to verify DSC/DSCi negative cases when dependant (servicemesh, serverless) operators are not installed

Library             Collections
Library             OperatingSystem
Resource            ../../Resources/OCP.resource
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/RHOSi.resource
Resource            ../../Resources/ServiceMesh.resource
Resource            ../../Resources/Page/OCPDashboard/InstalledOperators/InstalledOperators.robot
Resource            ../../Resources/Page/OCPDashboard/OperatorHub/InstallODH.robot
Resource            ../../../tasks/Resources/RHODS_OLM/uninstall/uninstall.robot
Resource            ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
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
Validate DSC and DSCI Created With Errors When Service Mesh Operator Is Not Installed    #robocop:disable
    [Documentation]    The purpose of this Test Case is to validate that DSC and DSCI are created
    ...                without Service Mesh Operator installed, but with errors
    [Tags]    Operator    Tier3    ODS-2584    RHOAIENG-2514

    Remove DSC And DSCI Resources
    Uninstall Service Mesh Operator CLI

    Log To Console    message=Creating DSCInitialization CR via CLI
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Log To Console    message=Checking DSCInitialization conditions
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    DSCInitialization Should Fail Because Service Mesh Operator Is Not Installed

    Log To Console    message=Creating DataScienceCluster CR via CLI
    Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
    Log To Console    message=Checking DataScienceCluster conditions
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    DataScienceCluster Should Fail Because Service Mesh Operator Is Not Installed

    [Teardown]    Reinstall Service Mesh Operator And Recreate DSC And DSCI

Validate DSC and DSCI Created With Errors When Serverless Operator Is Not Installed    #robocop:disable
    [Documentation]    The purpose of this Test Case is to validate that DSC and DSCI are created
    ...                without Serverless Operator installed, but with errors
    [Tags]    Operator    Tier3    ODS-2586    RHOAIENG-2512

    Remove DSC And DSCI Resources
    Uninstall Serverless Operator CLI

    Log To Console    message=Creating DSCInitialization CR via CLI
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Wait For DSCInitialization CustomResource To Be Ready    timeout=600

    Log To Console    message=Creating DataScienceCluster CR via CLI
    Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
    Log To Console    message=Checking DataScienceCluster conditions
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    DataScienceCluster Should Fail Because Serverless Operator Is Not Installed

    [Teardown]    Reinstall Serverless Operator And Recreate DSC And DSCI

Validate DSC and DSCI Created With Errors When Service Mesh And Serverless Operators Are Not Installed   #robocop:disable
    [Documentation]    The purpose of this Test Case is to validate that DSC and DSCI are created
    ...                without dependant operators ((servicemesh, serverless) installed, but with errors
    [Tags]    Operator    Tier3    ODS-2527     RHOAIENG-2518

    Remove DSC And DSCI Resources
    Uninstall Service Mesh Operator CLI
    Uninstall Serverless Operator CLI

    Log To Console    message=Creating DSCInitialization CR via CLI
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Log To Console    message=Checking DSCInitialization conditions
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    DSCInitialization Should Fail Because Service Mesh Operator Is Not Installed

    Log To Console    message=Creating DataScienceCluster CR via CLI
    Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
    Log To Console    message=Checking DataScienceCluster conditions
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    DataScienceCluster Should Fail Because Service Mesh Operator Is Not Installed
    Wait Until Keyword Succeeds    10 min    0 sec
    ...    DataScienceCluster Should Fail Because Serverless Operator Is Not Installed

    [Teardown]    Reinstall Service Mesh And Serverless Operators And Recreate DSC And DSCI

Validate DSC and DSCI Created With No Errors When Kserve Serving Is Unmanaged And Service Mesh And Serverless Operators Are Not Installed    #robocop:disable
    [Documentation]    The purpose of this Test Case is to validate that DSC and DSCI are created
    ...                without dependant operators ((servicemesh, serverless) installed and with no errors
    ...                because the Kserve component serving is unmanaged
    [Tags]    Operator    Tier3     RHOAIENG-3472

    Remove DSC And DSCI Resources
    Uninstall Service Mesh Operator CLI
    Uninstall Serverless Operator CLI

    Log To Console    message=Creating DSCInitialization CR via CLI
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Set Service Mesh Management State    Unmanaged    ${OPERATOR_NS}

    Wait For DSCInitialization CustomResource To Be Ready    timeout=600

    Log To Console    message=Creating DataScienceCluster CR via CLI
    Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}

    Set DataScienceCluster Kserve Serving Management State        ${DSC_NAME}      Unmanaged

    Wait For DataScienceCluster CustomResource To Be Ready    timeout=600

    [Teardown]    Reinstall Service Mesh And Serverless Operators And Recreate DSC And DSCI


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Suite Teardown
    [Documentation]    Suite Teardown
    Selenium Library.Close All Browsers
    RHOSi Teardown

Set DataScienceCluster Kserve Serving Management State
    [Documentation]    Sets DSC Kserve Serving mgmt state to a specific value
    [Arguments]      ${dsc_name}       ${status}
    ${result} =    Run Process    oc patch DataScienceCluster ${dsc_name} --type 'json' -p '[{"op" : "replace" ,"path" : "/spec/components/kserve/serving/managementState" ,"value" : "${status}"}]'      #robocop:disable
    ...    shell=true    stderr=STDOUT
    IF    $result.rc != 0
        FAIL    Can not patch serving.managementState field: ${result.stdout}
    END

Reinstall Service Mesh Operator And Recreate DSC And DSCI
    [Documentation]    Reinstalls Service Mesh operator and waits for the Service Mesh Control plane to be created
    Remove DSC And DSCI Resources
    Install Service Mesh Operator Via Cli
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Wait For DSCInitialization CustomResource To Be Ready    timeout=600
    Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
    Wait For DataScienceCluster CustomResource To Be Ready   timeout=600
    Set Service Mesh State To Managed And Wait For CR Ready
    ...           ${SERVICE_MESH_CR_NAME}    ${SERVICE_MESH_CR_NS}    ${SERVICE_MESH_OPERATOR_NS}

Reinstall Serverless Operator And Recreate DSC And DSCI
    [Documentation]    Reinstalls Service Mesh operator and waits for the Service Mesh Control plane to be created
    Remove DSC And DSCI Resources
    Install Serverless Operator Via Cli
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Wait For DSCInitialization CustomResource To Be Ready    timeout=600
    Apply DataScienceCluster CustomResource    dsc_name=${DSC_NAME}
    Wait For DataScienceCluster CustomResource To Be Ready   timeout=600
    Set Service Mesh State To Managed And Wait For CR Ready
    ...           ${SERVICE_MESH_CR_NAME}    ${SERVICE_MESH_CR_NS}    ${SERVICE_MESH_OPERATOR_NS}

Reinstall Service Mesh And Serverless Operators And Recreate DSC And DSCI
    [Documentation]    Reinstalls Dependant (service mesh, serverless) operators and waits for the Service Mesh Control plane to be created
    Remove DSC And DSCI Resources
    Install Serverless Operator Via Cli
    Install Service Mesh Operator Via Cli
    Apply DSCInitialization CustomResource    dsci_name=${DSCI_NAME}
    Wait For DSCInitialization CustomResource To Be Ready    timeout=600
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

DSCInitialization Should Fail Because Service Mesh Operator Is Not Installed
    [Documentation]   Keyword to check the DSCI conditions when service mesh operator is not installed.
    ...           One condition should appear saying this operator is needed to enable kserve component.
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc get DSCInitialization ${DSCI_NAME} -n ${OPERATOR_NS} -o json | jq -r '.status.conditions | map(.message) | join(",")'     #robocop:disable
    Should Be Equal As Integers  ${return_code}   0   msg=Error retrieved DSCI conditions
    Should Contain    ${output}    failed to find the pre-requisite Service Mesh Operator subscription, please ensure Service Mesh Operator is installed. failed to find the pre-requisite operator subscription \"servicemeshoperator\", please ensure operator is installed. missing operator \"servicemeshoperator\"    #robocop:disable

DataScienceCluster Should Fail Because Service Mesh Operator Is Not Installed
    [Documentation]   Keyword to check the DSC conditions when service mesh operator is not installed.
    ...           One condition should appear saying this operator is needed to enable kserve component.
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster ${DSC_NAME} -n ${OPERATOR_NS} -o json | jq -r '.status.conditions | map(.message) | join(",")'    #robocop:disable
    Should Be Equal As Integers  ${return_code}   0   msg=Error retrieved DSC conditions
    Should Contain    ${output}    operator servicemeshoperator not found. Please install the operator before enabling kserve component    #robocop:disable

    ${rc}    ${logs}=    Run And Return Rc And Output
    ...    oc logs -l ${OPERATOR_LABEL_SELECTOR} -c ${OPERATOR_POD_CONTAINER_NAME} -n ${OPERATOR_NS} --ignore-errors

    Should Contain    ${logs}    failed to find the pre-requisite Service Mesh Operator subscription, please ensure Service Mesh Operator is installed.    #robocop:disable

DataScienceCluster Should Fail Because Serverless Operator Is Not Installed
    [Documentation]   Keyword to check the DSC conditions when serverless operator is not installed.
    ...           One condition should appear saying this operator is needed to enable kserve component.
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc get DataScienceCluster ${DSC_NAME} -n ${OPERATOR_NS} -o json | jq -r '.status.conditions | map(.message) | join(",")'    #robocop:disable
    Should Be Equal As Integers  ${return_code}   0   msg=Error retrieved DSC conditions
    Should Contain    ${output}    operator serverless-operator not found. Please install the operator before enabling kserve component    #robocop:disable
