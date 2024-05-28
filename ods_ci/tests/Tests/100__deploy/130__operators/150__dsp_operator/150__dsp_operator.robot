*** Settings ***
Documentation       Test Cases with regards to the DSP Operator

Library             Collections
Library             SeleniumLibrary
Library             OpenShiftLibrary
Resource            ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../../Resources/OCP.resource
Resource            ../../../../Resources/RHOSi.resource
Resource            ../../tasks/Resources/RHODS_OLM/uninstall/uninstall.robot

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Test Cases ***
Detect Pre-existing Install Of Argo Workflows And Block RHOAI Install
    [Documentation]    Detect Pre-existing Install Of Argo Workflows And Block RHOAI Install
    [Tags]                  Operator                ODS-2651                Tier3
    Delete Argo Workflow Crd
    ${return_code}          ${output}               Run And Return Rc And Output
    ...                     oc apply -f ./ods_ci/tests/Resources/Files/argo/crd.workflows.yaml
    Should Be Equal As Integers
    ...                     ${return_code}
    ...                     0
    ...                     msg=${output}
    Uninstalling RHODS Operator
    Should Be Equal As Integers ${return_code}      0
    Open OperatorHub
    Install ODH Operator
    Apply DataScienceCluster CustomResource         default-dsc
    Wait Until Keyword Succeeds
    ...                     5 min
    ...                     30s
    ...                     Resource Status Should Be
    ...                     oc get DataScienceCluster default-dsc -o json | jq '.status.conditions[] | select(.type=="data-science-pipelines-operatorReady") | .status'
    ...                     CapabilityDSPv2Argo
    ...                     "False"
    Wait Until Keyword Succeeds
    ...                     5 min
    ...                     30s
    ...                     Resource Status Should Be
    ...                     oc get DataScienceCluster default-dsc -o json | jq '.status.conditions[] | select(.type=="data-science-pipelines-operatorReady") | .status'
    ...                     data-science-pipelines-operatorReady
    ...                     "False"
    Delete Argo Workflow Crd
    ${return_code}          ${output}               Run And Return Rc And Output
    ...                     oc delete DataScienceCluster default-dsc
    Log To Console          ${output}
    Should Be Equal As Integers
    ...                     ${return_code}
    ...                     0
    ...                     msg=Error deleting DataScienceCluster CR
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

Delete Argo Workflow Crd
    [Documentation]    Keyword for Argo Workflow CRD CleanUp
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete crd workflows.argoproj.io
    Log To Console    ${output}
