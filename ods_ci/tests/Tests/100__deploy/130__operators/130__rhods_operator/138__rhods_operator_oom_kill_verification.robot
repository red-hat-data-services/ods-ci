*** Settings ***
Documentation       RHODS_OPERATOR_OOM_KILL_VERIFICATION
...                 Verify rhods operator running without any issue
...                 after createing multiple dummy namespace in openshift
...
...                 = Variables =
...                 | Namespace    | Required |    RHODS operator namespace|
...                 | Number    | Required |    Number of namespace to be created |

Library             OperatingSystem
Library             SeleniumLibrary
Resource            ../../../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource            ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../../Resources/Common.robot

Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown


*** Variables ***
${NAMESPACE}    ${OPERATOR_NAMESPACE}
${NUMBER}       1500


*** Test Cases ***
Verify RHODS Operator OOM Kill Behaviour
    [Documentation]    Create multiple namespace and verify
    ...    if the rhods operator pod is running without any
    ...    issue and perfrom some basic validation with RHODS
    [Tags]    ODS-1091    Tier3
    ${dfeault_np_count}    Run    oc get namespace | wc -l
    Create Namespace In Openshift
    Verify Operator Pod Status    ${NAMESPACE}    name=rhods-operator
    Verify Pods Status
    Basic Dashboard Test Verification
    Delete Namespace From Openshift
    ${new__np_count}    Run    oc get namespace | wc -l
    Should Be True    ${dfeault_np_count} == ${new__np_count}    All the dummy namespace created is not deleted


*** Keywords ***
Create Namespace In Openshift
    [Documentation]    Create dummy namespace based on number
    [Arguments]    ${number}=${NUMBER}
    FOR    ${counter}    IN RANGE    1    ${number}+1
        ${create_namespace}    Run    oc create namespace testuser'${counter}'
        ${label_namespace}    Run    oc label namespace testuser'${counter}' testuser=testuser
    END
    ${temp_count}    Run    oc get namespace | wc -l
    Log    ${temp_count}

Delete Namespace From Openshift
    [Documentation]    Delete dummy namespace from opneshift
    [Arguments]    ${number}=${NUMBER}
    ${delete_namespace}    Run    oc delete namespace --selector testuser=testuser
    ${temp_count}    Run    oc get namespace | wc -l
    Log    ${temp_count}

Basic Dashboard Test Verification
    [Documentation]    Basic verification of RHODS feature
    Begin Web Test
    Wait For RHODS Dashboard To Load
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments
    Fix Spawner Status
    Close Browser

Verify Pods Status
    [Documentation]    Verify each pod status in the rhods namespace
    Wait For Pods Status  namespace=${APPLICATIONS_NAMESPACE}  timeout=60
    Wait For Pods Status  namespace=${OPERATOR_NAMESPACE}  timeout=60
    Wait For Pods Status  namespace=${MONITORING_NAMESPACE}  timeout=60
