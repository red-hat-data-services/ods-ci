*** Settings ***
Documentation       Test Suite for Auth CRD functionality verification

Resource            ../../../../Resources/ODS.robot
Resource            ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../../Resources/RHOSi.resource

Suite Setup         Auth Crd Suite Setup
Suite Teardown      Auth Crd Suite Teardown


*** Test Cases ***
Verify Auth Crd
    [Documentation]    Happy path to cover the functionality of the Auth CRD
    [Tags]      Smoke
    ...         Operator
    ...         RHOAIENG-18846
    Get User Groups From Auth Cr And Check Rolebinding Exists       adminGroups     rolebinding     admingroup-rolebinding
    Get User Groups From Auth Cr And Check Rolebinding Exists       adminGroups     clusterrolebinding     admingroupcluster-rolebinding
    Get User Groups From Auth Cr And Check Rolebinding Exists       allowedGroups   rolebinding     allowedgroup-rolebinding


*** Keywords ***
Auth Crd Suite Setup
    [Documentation]    Suite setup
    RHOSi Setup

Auth Crd Suite Teardown
    [Documentation]    Suite teardown
    RHOSi Teardown

Get User Groups From Auth Cr And Check Rolebinding Exists
    [Documentation]    Get User Groups From Auth CR And Check Rolebinding Exists
    [Arguments]    ${group}     ${role_type}    ${rolebinding_name}
    ${rc}    ${out}=    Run And Return Rc And Output        oc get auth auth -o jsonpath='{.spec.${group}}'
    Should Be Equal As Integers    ${rc}    0
    ${groups_str}=    Remove String    ${out}    [    ]
    @{groups_list}=    Split String    ${groups_str}    ,
    FOR    ${user}    IN    @{groups_list}
        Log To Console    ${user}
        ${rc}=    Run And Return Rc
        ...    oc get ${role_type} ${rolebinding_name} -n ${APPLICATIONS_NAMESPACE} -o jsonpath='{.subjects[?(@.name==${user})]}'   #robocop: disable:line-too-long
        Should Be Equal As Integers    ${rc}    0
    END
