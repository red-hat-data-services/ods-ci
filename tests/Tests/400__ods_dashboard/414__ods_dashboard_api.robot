*** Settings ***
Library         RequestsLibrary
Library         OpenShiftLibrary
Resource        ../../Resources/Common.robot
Suite Setup     Endpoint Testing Setup


*** Variables ***
${CLUSTER_SETTINGS_ENDPOINT}=        api/cluster-settings
${CLUSTER_SETTINGS_ENDPOINT_BODY}=   {"userTrackingEnabled":false}


*** Test Cases ***
Verify Access To cluster-settings API Endpoint
    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint PUT Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    ...                                       json_body=${CLUSTER_SETTINGS_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PUT Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${ADMIN_TOKEN}
    ...                                       json_body=${CLUSTER_SETTINGS_ENDPOINT_BODY}
    Operation Should Be Allowed


*** Keywords ***
Log In As RHODS Admin
    [Documentation]     Perfom OC login using a RHODS admin user
    OpenshiftLibrary.Oc Login    ${OCP_API_URL}    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}

Log In As RHODS Basic User
    [Documentation]     Perfom OC login using a RHODS basic user
    OpenshiftLibrary.Oc Login    ${OCP_API_URL}    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}

Perform Dashboard API Endpoint GET Call
    [Arguments]     ${endpoint}     ${token}
    ${headers}=    Create Dictionary     Authorization=Bearer ${token}
    ${response}=    RequestsLibrary.GET  ${ODH_DASHBOARD_URL}/${endpoint}    expected_status=any
    ...             headers=${headers}   timeout=5  verify=${False}

Perform Dashboard API Endpoint PUT Call
    [Arguments]     ${endpoint}     ${token}    ${json_body}
    ${headers}=    Create Dictionary     Authorization=Bearer ${token}
    Load Json String    json_string=${json_body}
    ${response}=    RequestsLibrary.Put  ${ODH_DASHBOARD_URL}/${endpoint}    expected_status=any
    ...             headers=${headers}   timeout=5  verify=${False}

Endpoint Testing Setup
    [Documentation]     Fetch a bearer token for both a RHODS admin and basic user
    Log In As RHODS Admin
    ${ADMIN_TOKEN}=      Get Bearer Token
    Set Suite Variable    ${ADMIN_TOKEN}
    Log In As RHODS Basic User
    ${BASIC_USER_TOKEN}=      Get Bearer Token
    Set Suite Variable    ${BASIC_USER_TOKEN}

Operation Should Be Allowed
    Run Keyword And Continue On Failure  Status Should Be  200

Operation Should Be Forbidden
    Run Keyword And Continue On Failure  Status Should Be  403



