*** Settings ***
Documentation       Service Account Token Authentication through the OpenShift AI Gateway
...                 Validates bearer token auth using the dashboard (already deployed)

Resource            ../../../../Resources/CLI/ServiceTokenAuth.resource
Resource            ../../../../Resources/Common.robot

Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown

Test Tags           ServiceTokenAuth


*** Variables ***
${TEST_SA_NAME}=    test-svc-token-auth
${GATEWAY_NAMESPACE}=    openshift-ingress
${KUBE_AUTH_PROXY_NAME}=    kube-auth-proxy
${DASHBOARD_PATH}=    /


*** Test Cases ***
Verify Service Token Auth Is Enabled On Gateway
    [Documentation]    Verifies that kube-auth-proxy deployment has service token validation enabled
    [Tags]    Operator    Tier1    RHOAIENG-47496
    ${args}=    Get Deployment Args    ${KUBE_AUTH_PROXY_NAME}    ${GATEWAY_NAMESPACE}
    Should Contain    ${args}    --enable-k8s-token-validation=true
    Log    message=Service token validation is enabled on kube-auth-proxy

Verify Dedicated ServiceAccount For Kube Auth Proxy
    [Documentation]    Verifies that kube-auth-proxy uses a dedicated ServiceAccount
    [Tags]    Operator    Security    Tier1    RHOAIENG-47496
    ${sa_name}=    Get Deployment ServiceAccount    ${KUBE_AUTH_PROXY_NAME}    ${GATEWAY_NAMESPACE}
    Should Be Equal    ${sa_name}    ${KUBE_AUTH_PROXY_NAME}
    Log    message=kube-auth-proxy uses dedicated ServiceAccount: ${sa_name}

Verify ClusterRoleBinding For TokenReview
    [Documentation]    Verifies ClusterRoleBinding for TokenReview API exists
    [Tags]    Operator    Tier1    RHOAIENG-47496
    Verify ClusterRoleBinding Exists
    ...    ${KUBE_AUTH_PROXY_NAME}-tokenreview
    ...    ${KUBE_AUTH_PROXY_NAME}
    ...    ${GATEWAY_NAMESPACE}
    Verify ClusterRoleBinding Role
    ...    ${KUBE_AUTH_PROXY_NAME}-tokenreview
    ...    system:auth-delegator
    Log    message=ClusterRoleBinding correctly grants system:auth-delegator to kube-auth-proxy SA

Verify Service Account Can Authenticate Via Token
    [Documentation]    E2E: service account authenticates through gateway to dashboard
    [Tags]    Operator    Tier1    E2E    RHOAIENG-47496
    Create Test Service Account For Token Auth    sa_name=${TEST_SA_NAME}    namespace=${APPLICATIONS_NAMESPACE}
    ${token}=    Create Service Account Token    ${TEST_SA_NAME}    ${APPLICATIONS_NAMESPACE}
    ...    duration=10m
    ${response}=    Call Gateway With Token Via Curl    ${token}    path=${DASHBOARD_PATH}
    Verify Response HTTP Code    ${response}    expected_code=200
    Log    message=Service account successfully authenticated via bearer token to dashboard

Verify User Can Authenticate Via Opaque Token
    [Documentation]    E2E: user authenticates through gateway to dashboard using oc token
    [Tags]    Operator    Tier1    E2E    RHOAIENG-47496
    ${cluster_auth_value}=    Get Variable Value    ${CLUSTER_AUTH}    ${EMPTY}
    IF  "${cluster_auth_value}" == "oidc"
        Skip  "Not supported with BYOIDC"
    END
    ${rc}    ${token}=    Run And Return Rc And Output
    ...    oc whoami --show-token
    Should Be Equal As Integers    ${rc}    0
    Should Not Be Empty    ${token}
    ${response}=    Call Gateway With Token Via Curl    ${token}    path=${DASHBOARD_PATH}
    Verify Response HTTP Code    ${response}    expected_code=200
    Log    message=User successfully authenticated via opaque token to dashboard

Verify User Can Authenticate Via OIDC JWT
    [Documentation]    E2E: user authenticates through gateway to dashboard using JWT token
    [Tags]    Operator    Tier1    E2E    RHOAIENG-47496
    ${cluster_auth_value}=    Get Variable Value    ${CLUSTER_AUTH}    ${EMPTY}
    IF  "${cluster_auth_value}" != "oidc"
        Skip  "Only applicable with BYOIDC"
    END
    ${token}=    Get Oidc Token
    ...      ${CLUSTER_OIDC_ISSUER}
    ...      ${TEST_USER.USERNAME}
    ...      ${TEST_USER.PASSWORD}
    ...      token_endpoint=${OIDC_TOKEN_ENDPOINT}
    ...      client_id=${CLIENT_ID_OC_CLI}
    ...      scope=${OIDC_LOGIN_SCOPE}
    Should Not Be Empty    ${token}
    ${response}=    Call Gateway With Token Via Curl    ${token}    path=${DASHBOARD_PATH}
    Verify Response HTTP Code    ${response}    expected_code=200
    Log    message=User successfully authenticated via opaque token to dashboard

# /api/status is served by the ODH Dashboard backend (opendatahub-io/odh-dashboard).
# When authenticated via Bearer token, it returns kube.userName as the service account identity.
# Example response for service account token auth:
# {"kube":{"currentContext":"inClusterContext","currentUser":{"name":"inClusterUser","authProvider":{"name":"tokenFile","config":{"tokenFile":"/var/run/secrets/kubernetes.io/serviceaccount/token"}}},"namespace":"redhat-ods-applications","userName":"system:serviceaccount:redhat-ods-applications:test-svc-token-auth","userID":"ee53c854ec67aa5dfef1afbf6fb7d9b3dc2156ab0268656e1abfd77115a068e3","clusterID":"36e8547a-97af-453a-8d47-dd08c2a8d423","clusterBranding":"rosa","isAdmin":false,"isAllowed":true,"serverURL":"https://172.30.0.1:443"}}

Verify API Status Returns Service Account Identity
    [Documentation]    E2E: /api/status returns userName when authenticated via Bearer token
    [Tags]    Operator    Tier1    E2E    RHOAIENG-47496
    Create Test Service Account For Token Auth    sa_name=${TEST_SA_NAME}    namespace=${APPLICATIONS_NAMESPACE}
    ${token}=    Create Service Account Token    ${TEST_SA_NAME}    ${APPLICATIONS_NAMESPACE}
    ...    duration=10m
    ${expected_user}=    Set Variable    system:serviceaccount:${APPLICATIONS_NAMESPACE}:${TEST_SA_NAME}
    Verify API Status Returns User Name    ${token}    ${expected_user}
    Log    message=API status correctly returned service account identity

Verify API Status Returns User Identity With Opaque Token
    [Documentation]    E2E: /api/status returns userName when authenticated via Bearer token
    [Tags]    Operator    Tier1    E2E    RHOAIENG-47496
    ${cluster_auth_value}=    Get Variable Value    ${CLUSTER_AUTH}    ${EMPTY}
    IF  "${cluster_auth_value}" == "oidc"
        Skip  "Not supported with BYOIDC"
    END
    ${rc}    ${token}=    Run And Return Rc And Output
    ...    oc whoami --show-token
    Should Be Equal As Integers    ${rc}    0
    Should Not Be Empty    ${token}
    ${_}    ${expected_user}=    Run And Return Rc And Output
    ...    oc whoami
    Verify API Status Returns User Name    ${token}    ${expected_user}
    Log    message=API status correctly returned user identity

Verify API Status Returns User Identity With OIDC JWT
    [Documentation]    E2E: /api/status returns userName when authenticated via Bearer token
    [Tags]    Operator    Tier1    E2E    RHOAIENG-47496
    ${cluster_auth_value}=    Get Variable Value    ${CLUSTER_AUTH}    ${EMPTY}
    IF  "${cluster_auth_value}" != "oidc"
        Skip  "Only applicable with BYOIDC"
    END
    ${token}=    Get Oidc Token
    ...      ${CLUSTER_OIDC_ISSUER}
    ...      ${TEST_USER.USERNAME}
    ...      ${TEST_USER.PASSWORD}
    ...      token_endpoint=${OIDC_TOKEN_ENDPOINT}
    ...      client_id=${CLIENT_ID_OC_CLI}
    ...      scope=${OIDC_LOGIN_SCOPE}
    Should Not Be Empty    ${token}
    Verify API Status Returns User Name    ${token}    ${TEST_USER.USERNAME}
    Log    message=API status correctly returned user identity

Verify Invalid Token Is Rejected
    [Documentation]    Verifies that an invalid token is rejected by the gateway
    [Tags]    Operator    Negative    Tier2    RHOAIENG-47496
    ${invalid_token}=    Set Variable    eyJhbGciOiJSUzI1NiIsImtpZCI6ImlOdmFsaWQifQ.invalid.token
    ${response}=    Call Gateway With Token Via Curl    ${invalid_token}    path=${DASHBOARD_PATH}
    ${contains_forbidden}=    Run Keyword And Return Status
    ...    Should Contain    ${response}    HTTP_CODE:403
    ${contains_redirect}=    Run Keyword And Return Status
    ...    Should Contain    ${response}    HTTP_CODE:302
    ${is_rejected}=    Evaluate    ${contains_forbidden} or ${contains_redirect}
    Should Be True    ${is_rejected}    msg=Invalid token should be rejected
    Log    message=Invalid token was correctly rejected

Verify No Token Results In Auth Challenge
    [Documentation]    Verifies that requests without tokens are challenged
    [Tags]    Operator    Tier2    RHOAIENG-47496
    ${response}=    Call Gateway Without Token    path=${DASHBOARD_PATH}
    Verify Response Is Auth Challenge    ${response}
    Log    message=Request without token was correctly challenged
