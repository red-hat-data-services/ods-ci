*** Settings ***
Library         RequestsLibrary
Library         OpenShiftLibrary
Resource        ../../Resources/Common.robot
Suite Setup     Endpoint Testing Setup


*** Variables ***
${CLUSTER_SETTINGS_ENDPOINT}=        api/cluster-settings
${CLUSTER_SETTINGS_ENDPOINT_BODY}=   {"userTrackingEnabled":true}

${BUILDS_ENDPOINT}=        api/builds
${BUILDS_ENDPOINT_BODY}=   {"name":"CUDA","status":"Running"}

${CONFIG_ENDPOINT}=        api/config
${CONFIG_ENDPOINT_BODY}=   {"spec":{"dashboardConfig":{"disableTracking":false}}}

${CONSOLE_LINKS_ENDPOINT}=        api/console-links
${DOCS_ENDPOINT}=        api/docs
${GETTING_STARTED_ENDPOINT}=        api/getting-started
${QUICKSTARTS_ENDPOINT}=        api/quickstarts
${SEGMENT_KEY_ENDPOINT}=        api/segment-key
${GPU_ENDPOINT}=        api/gpu


*** Test Cases ***
Verify Access To cluster-settings API Endpoint
    [Documentation]     Verifies the endpoint "cluster-settings" works as expected
    ...                 based on the permissions of the user who query the endpoint
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

Verify Access To builds API Endpoint
    [Documentation]     Verifies the endpoint "builds" works as expected
    ...                 based on the permissions of the user who query the endpoint

    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${BUILDS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${BUILDS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint PUT Call    endpoint=${BUILDS_ENDPOINT}    token=${ADMIN_TOKEN}
    ...                                        json_body=${BUILDS_ENDPOINT_BODY}
    Operation Should Be Unavailable

Verify Access To config API Endpoint
    [Documentation]     Verifies the endpoint "config" works as expected
    ...                 based on the permissions of the user who query the endpoint

    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${CONFIG_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${CONFIG_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint PATCH Call    endpoint=${CONFIG_ENDPOINT}    token=${BASIC_USER_TOKEN}
    ...                                          json_body=${CONFIG_ENDPOINT_BODY}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint PATCH Call    endpoint=${CONFIG_ENDPOINT}    token=${ADMIN_TOKEN}
    ...                                          json_body=${CONFIG_ENDPOINT_BODY}
    Operation Should Be Allowed

Verify Access To console-links API Endpoint
    [Documentation]     Verifies the endpoint "console-links" works as expected
    ...                 based on the permissions of the user who query the endpoint

    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${CONSOLE_LINKS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${CONSOLE_LINKS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    # Perform Dashboard API Endpoint PUT Call    endpoint=${CONSOLE_LINKS_ENDPOINT}    token=${ADMIN_TOKEN}
    # ...                                        json_body=${CONSOLE_LINKS_ENDPOINT_BODY}
    # Operation Should Be Unavailable

Verify Access To docs API Endpoint
    [Documentation]     Verifies the endpoint "docs" works as expected
    ...                 based on the permissions of the user who query the endpoint

    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${DOCS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${DOCS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To getting-started API Endpoint
    [Documentation]     Verifies the endpoint "getting_started" works as expected
    ...                 based on the permissions of the user who query the endpoint

    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${GETTING_STARTED_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${GETTING_STARTED_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To quickstarts API Endpoint
    [Documentation]     Verifies the endpoint "quickstarts" works as expected
    ...                 based on the permissions of the user who query the endpoint

    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${QUICKSTARTS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${QUICKSTARTS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To segment-key API Endpoint
    [Documentation]     Verifies the endpoint "segment-key" works as expected
    ...                 based on the permissions of the user who query the endpoint

    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${SEGMENT_KEY_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${SEGMENT_KEY_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

Verify Access To gpu API Endpoint
    [Documentation]     Verifies the endpoint "segment-key" works as expected
    ...                 based on the permissions of the user who query the endpoint

    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${GPU_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${GPU_ENDPOINT}    token=${ADMIN_TOKEN}
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

Perform Dashboard API Endpoint PATCH Call
    [Arguments]     ${endpoint}     ${token}    ${json_body}
    ${headers}=    Create Dictionary     Authorization=Bearer ${token}
    Load Json String    json_string=${json_body}
    ${response}=    RequestsLibrary.Patch  ${ODH_DASHBOARD_URL}/${endpoint}    expected_status=any
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
    [Documentation]     Checks if the API call returns an HTTP code 200 (SUCCESS)
    Run Keyword And Continue On Failure  Status Should Be  200

Operation Should Be Forbidden
    [Documentation]     Checks if the API call returns an HTTP code 403 (FORBIDDEN)
    Run Keyword And Continue On Failure  Status Should Be  403

Operation Should Be Unavailable
    [Documentation]     Checks if the API call returns an HTTP code 404 (NOT FOUND)
    Run Keyword And Continue On Failure  Status Should Be  404



