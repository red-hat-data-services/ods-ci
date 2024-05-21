*** Settings ***
Documentation       Test Cases to verify Serverless installation

Library             Collections
Library             SeleniumLibrary
Library             OpenShiftLibrary
Resource            ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../../Resources/OCP.resource
Resource            ../../../../Resources/RHOSi.resource

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Test Cases ***
Detect Pre-existing Install Of Argo Workflows And Block RHOAI Install
    [Documentation]    Detect Pre-existing Install Of Argo Workflows And Block RHOAI Install
    [Tags]                  Operator                ODS-2651                Tier1
    ${return_code}          ${output}               Run And Return Rc And Output
    ...                     oc apply -f ods_ci/tests/Resources/Files/argo/crd.workflows.yaml
    Log To Console          ${output}
    Should Be Equal As Integers
    ...                     ${return_code}
    ...                     0
    ...                     msg=Error while applying the provided file
    Open Installed Operators Page
    Navigate to Installed Operators
    ${is_operator_installed}                        Is Operator Installed                           ${OPERATOR_NAME}
    IF    ${is_operator_installed}    Uninstall ODH Operator
    ODH Operator Should Be Uninstalled
    Open OperatorHub
    Install ODH Operator
    Apply DataScienceCluster CustomResource         default-dsc
    Resource Status Should Be
    ...                     oc get DataScienceCluster default-dsc -o json | jq '.status.conditions[] | select(.type=="data-science-pipelines-operatorReady") | .status'
    ...                     CapabilityDSPv2Argo
    ...                     "False"
    Resource Status Should Be
    ...                     oc get DataScienceCluster default-dsc -o json | jq '.status.conditions[] | select(.type=="data-science-pipelines-operatorReady") | .status'
    ...                     data-science-pipelines-operatorReady
    ...                     "False"
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete crd -l app.kubernetes.io/part-of=data-science-pipelines-operator -l app.opendatahub.io/data-science-pipelines-operator=true --ignore-not-found
    Log To Console          ${output}
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting CRDs with DSP labels
    ${return_code}    ${output}               Run And Return Rc And Output
    ...                     oc delete DataScienceCluster default-dsc
    Log To Console          ${output}
    Should Be Equal As Integers  ${return_code}   0   msg=Error deleting DataScienceCluster CR
    Apply DataScienceCluster CustomResource         default-dsc


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Suite Teardown
    [Documentation]    Suite Teardown
    Close All Browsers
    RHOSi Teardown
