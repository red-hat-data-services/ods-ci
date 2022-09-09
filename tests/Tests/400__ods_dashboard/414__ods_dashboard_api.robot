*** Settings ***
Library           RequestsLibrary
Library           OpenShiftLibrary
Library           SeleniumLibrary
Resource          ../../Resources/Common.robot
Suite Setup       Endpoint Testing Setup
Suite Teardown    Endpoint Testing Teardown


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

${NOTEBOOK_NS}=          rhods-notebooks
${NOTEBOOK_USERNAME}=    ""
${CM_ENDPOINT_PT1}=         api/configmaps/${NOTEBOOK_NS}/jupyterhub-singleuser-profile-
${CM_ENDPOINT_PT2}=         -envs

${CM_DASHBOARD_ENDPOINT}=         api/configmaps/redhat-ods-applications/odh-enabled-applications-config
${DUMMY_SECRET_NAME}=           test-dummy-secret
${SECRET_DASHBOARD_ENDPOINT}=         api/secrets/redhat-ods-applications/${DUMMY_SECRET_NAME}
${SECRET_ENDPOINT_PT1}=         api/secrets/${NOTEBOOK_NS}/jupyterhub-singleuser-profile-
${SECRET_ENDPOINT_PT2}=         -envs

${GROUPS_CONFIG_ENDPOINT}=        api/groups-config
${GROUPS_CONFIG_ENDPOINT_BODY}=   {"allowedGroups":[{"name":"system:authenticated","enabled":true}]}


*** Test Cases ***
Verify Access To cluster-settings API Endpoint
    [Documentation]     Verifies the endpoint "cluster-settings" works as expected
    ...                 based on the permissions of the user who query the endpoint
    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    Perform Dashboard API Endpoint GET Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Unauthorized
    Perform Dashboard API Endpoint GET Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint PUT Call   endpoint=${CLUSTER_SETTINGS_ENDPOINT}    token=${BASIC_USER_TOKEN}
    ...                                       json_body=${CLUSTER_SETTINGS_ENDPOINT_BODY}
    Operation Should Be Unauthorized
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
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${BUILDS_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed

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
    Operation Should Be Unauthorized
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

Verify Access To Notebook configmaps API Endpoint
    [Documentation]     Verifies the endpoint "configmaps" works as expected
    ...                 based on the permissions of the user who query the endpoint to get
    ...                 the user configmap map of a notebook server.
    ...                 The syntax to reach this endpoint is:
    ...                 `configmaps/<notebook_namespace>/jupyterhub-singleuser-profile-{username}-envs`

    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    ...       jupyter
    Spawn MinimalPython Notebook Server     username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    ${NOTEBOOK_BASIC_USER}=   Get Safe Username    ${TEST_USER_3.USERNAME}
    ${CM_ENDPOINT_BASIC_USER}=     Set Variable    ${CM_ENDPOINT_PT1}${NOTEBOOK_BASIC_USER}${CM_ENDPOINT_PT2}
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_ENDPOINT_BASIC_USER}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint DELETE Call   endpoint=${CM_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    # Not clear if it should be allowed or not for a basic user
    Operation Should Be Allowed
    Spawn MinimalPython Notebook Server     username=${TEST_USER_4.USERNAME}    password=${TEST_USER_4.PASSWORD}
    ${NOTEBOOK_BASIC_USER_2}=   Get Safe Username    ${TEST_USER_4.USERNAME}
    ${CM_ENDPOINT_BASIC_USER_2}=     Set Variable    ${CM_ENDPOINT_PT1}${NOTEBOOK_BASIC_USER_2}${CM_ENDPOINT_PT2}
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${CM_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    [Teardown]     Close All Notebooks

Verify Access To Notebook secrets API Endpoint
    [Documentation]     Verifies the endpoint "secrets" works as expected
    ...                 based on the permissions of the user who query the endpoint to get
    ...                 the user configmap map of a notebook server.
    ...                 The syntax to reach this endpoint is:
    ...                 `secrets/<notebook_namespace>/jupyterhub-singleuser-profile-{username}-envs`

    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    ...       jupyter
    Spawn MinimalPython Notebook Server     username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    ${NOTEBOOK_BASIC_USER}=   Get Safe Username    ${TEST_USER_3.USERNAME}
    ${SECRET_ENDPOINT_BASIC_USER}=     Set Variable    ${SECRET_ENDPOINT_PT1}${NOTEBOOK_BASIC_USER}${SECRET_ENDPOINT_PT2}
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_ENDPOINT_BASIC_USER}    token=${ADMIN_TOKEN}
    Operation Should Be Allowed
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_ENDPOINT_BASIC_USER}    token=${BASIC_USER_TOKEN}
    # Not clear if it should be allowed or not for a basic user
    Operation Should Be Allowed
    Spawn MinimalPython Notebook Server     username=${TEST_USER_4.USERNAME}    password=${TEST_USER_4.PASSWORD}
    ${NOTEBOOK_BASIC_USER_2}=   Get Safe Username    ${TEST_USER_4.USERNAME}
    ${SECRET_ENDPOINT_BASIC_USER_2}=     Set Variable    ${SECRET_ENDPOINT_PT1}${NOTEBOOK_BASIC_USER_2}${SECRET_ENDPOINT_PT2}
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_ENDPOINT_BASIC_USER_2}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    [Teardown]     Close All Notebooks

Verify Access To Dashboard configmaps and secrets API Endpoint
    [Documentation]     Verifies the endpoint "configmaps" works as expected
    ...                 based on the permissions of the user who query the endpoint
    ...                 to get a configmap from the Dashboard namespace.
    ...                 The syntax to reach this endpoint is:
    ...                 `configmaps/<dashboard_namespace>/<configmap_name>`
    [Tags]    ODS-XYZ
    ...       Tier1
    ...       Security
    ...       dash-cms
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${CM_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    # not clear if it should be Allowed or Forbidden..
    Operation Should Be Forbidden
    Create A Dummy Secret In Dashboard Namespace
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint GET Call   endpoint=${SECRET_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_DASHBOARD_ENDPOINT}    token=${BASIC_USER_TOKEN}
    Operation Should Be Forbidden
    Perform Dashboard API Endpoint DELETE Call   endpoint=${SECRET_DASHBOARD_ENDPOINT}    token=${ADMIN_TOKEN}
    Operation Should Be Forbidden
    [Teardown]      Delete Dummy Secret


*** Keywords ***
Log In As RHODS Admin
    [Documentation]     Perfom OC login using a RHODS admin user
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    ${oauth_proxy_cookie}=     Get OAuth Cookie
    Close Browser
    [Return]    ${oauth_proxy_cookie}

Log In As RHODS Basic User
    [Documentation]     Perfom OC login using a RHODS basic user
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    ${oauth_proxy_cookie}=     Get OAuth Cookie
    Close Browser
    [Return]    ${oauth_proxy_cookie}

Perform Dashboard API Endpoint GET Call
    [Documentation]     Runs a GET call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}
    ${response}=    RequestsLibrary.GET  ${ODH_DASHBOARD_URL}/${endpoint}   expected_status=any
    ...             headers=${headers}   timeout=5  verify=${False}

Perform Dashboard API Endpoint PUT Call
    [Documentation]     Runs a PUT call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}    ${json_body}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}   Content-type=application/json
    ${payload}=      Load Json String    json_string=${json_body}
    ${response}=    RequestsLibrary.Put  ${ODH_DASHBOARD_URL}/${endpoint}    expected_status=any
    ...             headers=${headers}    data=${json_body}   timeout=5  verify=${False}

Perform Dashboard API Endpoint PATCH Call
    [Documentation]     Runs a PATCH call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}    ${json_body}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}   Content-type=application/json
    ${payload}=     Load Json String    json_string=${json_body}
    ${response}=    RequestsLibrary.Patch  ${ODH_DASHBOARD_URL}/${endpoint}    expected_status=any
    ...             headers=${headers}    data=${json_body}   timeout=5  verify=${False}

Perform Dashboard API Endpoint DELETE Call
    [Documentation]     Runs a GET call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}
    ${response}=    RequestsLibrary.DELETE  ${ODH_DASHBOARD_URL}/${endpoint}   expected_status=any
    ...             headers=${headers}   timeout=5  verify=${False}

Endpoint Testing Setup
    [Documentation]     Fetches a bearer token for both a RHODS admin and basic user
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    ${ADMIN_TOKEN}=   Log In As RHODS Admin
    Set Suite Variable    ${ADMIN_TOKEN}
    ${BASIC_USER_TOKEN}=   Log In As RHODS Basic User
    Set Suite Variable    ${BASIC_USER_TOKEN}

Endpoint Testing Teardown
    [Documentation]     Switches to original OC context
    RHOSi Teardown

Operation Should Be Allowed
    [Documentation]     Checks if the API call returns an HTTP code 200 (SUCCESS)
    Run Keyword And Continue On Failure  Status Should Be  200

Operation Should Be Unauthorized
    [Documentation]     Checks if the API call returns an HTTP code 401 (Unauthorized)
    Run Keyword And Continue On Failure  Status Should Be  401

Operation Should Be Forbidden
    [Documentation]     Checks if the API call returns an HTTP code 403 (FORBIDDEN)
    Run Keyword And Continue On Failure  Status Should Be  403

Operation Should Be Unavailable
    [Documentation]     Checks if the API call returns an HTTP code 404 (NOT FOUND)
    Run Keyword And Continue On Failure  Status Should Be  404

Spawn MinimalPython Notebook Server
    [Documentation]    Suite Setup
    [Arguments]       ${username}    ${password}
    Launch Dashboard    ocp_user_name=${username}    ocp_user_pw=${password}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=s2i-minimal-notebook

Create A Dummy Secret In Dashboard Namespace
    [Documentation]     Creates a dummy secret to use in tests to avoid getting sensitive secrets
    # OpenshiftLibrary.Oc Create      kind=Secret    namespace=redhat-ods-applications   src={"data": {"secret_key": "super_dummy_secret"}}
    Run     oc create secret generic ${DUMMY_SECRET_NAME} --from-literal=super_key=super_dummy_secret -n redhat-ods-applications

Delete Dummy Secret
    [Documentation]     Deletes the dummy secret created during tests
    OpenshiftLibrary.Oc Delete    kind=secret  namespace=redhat-ods-applications  name=${DUMMY_SECRET_NAME}

Close All Notebooks
    [Documentation]     Stops all the notebook servers spanwed during a test.
    ...                 It assumes every server has been opened in a new browser
    ${browsers}=    Get Browser Ids
    FOR   ${browser_id}    IN   @{browsers}
        Switch Browser    ${browser_id}
        Stop JupyterLab Notebook Server
        Capture Page Screenshot     notebook-${browser_id}.png
    END
    Close All Browsers

