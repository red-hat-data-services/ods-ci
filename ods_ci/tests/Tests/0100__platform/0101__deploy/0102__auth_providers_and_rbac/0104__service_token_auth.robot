*** Settings ***
Documentation       Test Suite for Service Account Token Authentication
...                 Validates that service accounts can authenticate via bearer tokens
...                 through the gateway using Kubernetes TokenReview API

Resource            ../../../../Resources/CLI/EchoService.resource
Resource            ../../../../Resources/CLI/ServiceTokenAuth.resource
Resource            ../../../../Resources/Common.robot

Suite Setup         Service Token Auth Suite Setup
Suite Teardown      Service Token Auth Suite Teardown

Test Tags           ServiceTokenAuth


*** Variables ***
${TEST_NAMESPACE}=    opendatahub
${TEST_SA_NAME}=      test-svc-token-auth
${GATEWAY_NAMESPACE}=    openshift-ingress
${KUBE_AUTH_PROXY_NAME}=    kube-auth-proxy


*** Test Cases ***
Verify Service Token Auth Is Enabled On Gateway
    [Documentation]    Verifies that kube-auth-proxy deployment has service token validation enabled
    [Tags]    Smoke    Tier1    RHOAIENG-XXXXX
    ${args}=    Get Deployment Args    ${KUBE_AUTH_PROXY_NAME}    ${GATEWAY_NAMESPACE}
    Should Contain    ${args}    --enable-k8s-token-validation=true
    Log    message=Service token validation is enabled on kube-auth-proxy

Verify Dedicated ServiceAccount For Kube Auth Proxy
    [Documentation]    Verifies that kube-auth-proxy uses a dedicated ServiceAccount instead of default
    [Tags]    Security    Tier1    RHOAIENG-XXXXX
    ${sa_name}=    Get Deployment ServiceAccount    ${KUBE_AUTH_PROXY_NAME}    ${GATEWAY_NAMESPACE}
    Should Be Equal    ${sa_name}    ${KUBE_AUTH_PROXY_NAME}
    Log    message=kube-auth-proxy uses dedicated ServiceAccount: ${sa_name}

Verify ClusterRoleBinding For TokenReview
    [Documentation]    Verifies that the ClusterRoleBinding for TokenReview API exists and is correctly configured
    [Tags]    Tier1    RHOAIENG-XXXXX
    Verify ClusterRoleBinding Exists
    ...    ${KUBE_AUTH_PROXY_NAME}-tokenreview
    ...    ${KUBE_AUTH_PROXY_NAME}
    ...    ${GATEWAY_NAMESPACE}
    Verify ClusterRoleBinding Role
    ...    ${KUBE_AUTH_PROXY_NAME}-tokenreview
    ...    system:auth-delegator
    Log    message=ClusterRoleBinding correctly grants system:auth-delegator to kube-auth-proxy SA

Verify Service Account Can Authenticate Via Token
    [Documentation]    End-to-end test: service account authenticates through gateway using bearer token
    [Tags]    Tier1    E2E    RHOAIENG-XXXXX
    # Create service account token
    ${token}=    Create Service Account Token    ${TEST_SA_NAME}    ${TEST_NAMESPACE}    duration=10m

    # Call gateway with token
    ${response}=    Call Gateway With Token Via Curl    ${token}    path=/echo

    # Verify successful authentication
    Verify Response HTTP Code    ${response}    expected_code=200
    Verify Response Contains Auth Headers    ${response}
    ...    expected_user=system:serviceaccount:${TEST_NAMESPACE}:${TEST_SA_NAME}

    # Verify token was forwarded
    Should Contain    ${response}    x-auth-request-access-token
    Should Contain    ${response}    x-forwarded-access-token

    Log    message=Service account successfully authenticated via bearer token

Verify Service Account Token Has User Identity
    [Documentation]    Verifies that the authenticated token contains proper user identity information
    [Tags]    Tier1    RHOAIENG-XXXXX
    # Create service account token
    ${token}=    Create Service Account Token    ${TEST_SA_NAME}    ${TEST_NAMESPACE}    duration=10m

    # Call gateway with token
    ${response}=    Call Gateway With Token Via Curl    ${token}    path=/echo

    # Verify user identity headers
    Should Contain    ${response}    x-auth-request-user
    Should Contain    ${response}    system:serviceaccount:${TEST_NAMESPACE}:${TEST_SA_NAME}
    Should Contain    ${response}    x-auth-request-email
    Should Contain    ${response}    @cluster.local

    Log    message=Service account token contains proper user identity

Verify Invalid Token Is Rejected
    [Documentation]    Verifies that an invalid token is rejected by the gateway
    [Tags]    Negative    Tier2    RHOAIENG-XXXXX
    ${invalid_token}=    Set Variable    eyJhbGciOiJSUzI1NiIsImtpZCI6ImlOdmFsaWQifQ.invalid.token

    # Call gateway with invalid token
    ${response}=    Call Gateway With Token Via Curl    ${invalid_token}    path=/echo

    # Should get 403 Forbidden or redirect to login
    ${contains_forbidden}=    Run Keyword And Return Status
    ...    Should Contain    ${response}    HTTP_CODE:403
    ${contains_redirect}=    Run Keyword And Return Status
    ...    Should Contain    ${response}    HTTP_CODE:302

    ${is_rejected}=    Evaluate    ${contains_forbidden} or ${contains_redirect}
    Should Be True    ${is_rejected}    msg=Invalid token should be rejected

    Log    message=Invalid token was correctly rejected

Verify No Token Results In Auth Challenge
    [Documentation]    Verifies that requests without tokens are challenged for authentication
    [Tags]    Tier2    RHOAIENG-XXXXX
    ${gateway_url}=    Get Gateway URL From Route
    # Use -i to include headers, extract status from first line
    ${rc}    ${full_response}=    Run And Return Rc And Output
    ...    curl -k -s -i https://${gateway_url}/echo
    ${status_line}=    Get Line    ${full_response}    0
    @{status_parts}=    Split String    ${status_line}
    ${http_code}=    Set Variable    ${status_parts}[1]
    ${response}=    Set Variable    ${full_response}${\n}HTTP_CODE:${http_code}

    # Should get 403 Forbidden or 302 Redirect to login
    ${contains_forbidden}=    Run Keyword And Return Status
    ...    Should Contain    ${response}    HTTP_CODE:403
    ${contains_redirect}=    Run Keyword And Return Status
    ...    Should Contain    ${response}    HTTP_CODE:302

    ${is_challenged}=    Evaluate    ${contains_forbidden} or ${contains_redirect}
    Should Be True    ${is_challenged}    msg=Request without token should be challenged

    Log    message=Request without token was correctly challenged


*** Keywords ***
Service Token Auth Suite Setup
    [Documentation]    Suite setup - deploy echo service and create test service account
    Log    message=Setting up service token auth test infrastructure
    Deploy Echo Service    namespace=${TEST_NAMESPACE}
    Create Test Service Account    namespace=${TEST_NAMESPACE}
    Create HTTPRoute For Echo Service    namespace=${TEST_NAMESPACE}
    Sleep    5s    reason=Wait for Envoy configuration to propagate
    Log    message=Service token auth test infrastructure ready

Service Token Auth Suite Teardown
    [Documentation]    Suite teardown - remove echo service and test resources
    Log    message=Cleaning up service token auth test infrastructure
    Remove Echo Service    namespace=${TEST_NAMESPACE}
    Log    message=Service token auth test infrastructure cleaned up
