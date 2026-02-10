*** Settings ***
Documentation       Keywords for Service Account Token Authentication testing
Library             OperatingSystem
Library             String
Resource            ../Common.robot


*** Keywords ***
Create Service Account Token
    [Documentation]    Creates a service account token via oc CLI
    [Arguments]    ${sa_name}    ${namespace}    ${duration}=1h
    ${rc}    ${token}=    Run And Return Rc And Output
    ...    oc create token ${sa_name} -n ${namespace} --duration=${duration}
    Should Be Equal As Integers    ${rc}    0
    Should Not Be Empty    ${token}
    Log    message=Created token for ${sa_name} in ${namespace} (duration: ${duration})
    RETURN    ${token}

Call Gateway With Token Via Curl
    [Documentation]    Makes curl request to gateway with service account token
    [Arguments]    ${token}    ${path}=/echo    ${gateway_url}=${EMPTY}
    IF    "${gateway_url}" == "${EMPTY}"
        ${gateway_url}=    Get Gateway URL From Route
    END
    # Use -i to include headers, then extract status code from first line
    ${rc}    ${full_response}=    Run And Return Rc And Output
    ...    curl -k -s -i -H "Authorization: Bearer ${token}" https://${gateway_url}${path}
    Should Be Equal As Integers    ${rc}    0
    # Extract HTTP status code from first line (e.g., "HTTP/1.1 200 OK")
    ${status_line}=    Get Line    ${full_response}    0
    @{status_parts}=    Split String    ${status_line}
    ${http_code}=    Set Variable    ${status_parts}[1]
    # Add HTTP_CODE to response for compatibility with existing tests
    ${response}=    Set Variable    ${full_response}${\n}HTTP_CODE:${http_code}
    Log    message=Gateway response (HTTP ${http_code}): ${response}
    RETURN    ${response}

Get Gateway URL From Route
    [Documentation]    Gets the gateway hostname from the ingress route
    ${rc}    ${url}=    Run And Return Rc And Output
    ...    oc get route data-science-gateway -n openshift-ingress -o jsonpath='{.spec.host}'
    Should Be Equal As Integers    ${rc}    0
    Should Not Be Empty    ${url}
    Log    message=Gateway URL: ${url}
    RETURN    ${url}

Verify Response Contains Auth Headers
    [Documentation]    Verifies that the response contains expected authentication headers
    [Arguments]    ${response}    ${expected_user}
    Should Contain    ${response}    x-auth-request-user
    Should Contain    ${response}    ${expected_user}
    Log    message=Response contains expected auth headers for ${expected_user}

Verify Response HTTP Code
    [Documentation]    Extracts and verifies HTTP response code from curl output
    [Arguments]    ${response}    ${expected_code}=200
    ${http_code}=    Get Regexp Matches    ${response}    HTTP_CODE:(\\d+)    1
    Should Not Be Empty    ${http_code}
    Should Be Equal As Strings    ${http_code}[0]    ${expected_code}
    Log    message=HTTP response code: ${http_code}[0]

Get Deployment Args
    [Documentation]    Gets container args from a deployment
    [Arguments]    ${deployment_name}    ${namespace}
    ${rc}    ${args}=    Run And Return Rc And Output
    ...    oc get deployment ${deployment_name} -n ${namespace} -o jsonpath='{.spec.template.spec.containers[0].args}'
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${args}

Get Deployment ServiceAccount
    [Documentation]    Gets the serviceAccountName from a deployment
    [Arguments]    ${deployment_name}    ${namespace}
    ${rc}    ${sa}=    Run And Return Rc And Output
    ...    oc get deployment ${deployment_name} -n ${namespace} -o jsonpath='{.spec.template.spec.serviceAccountName}'
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${sa}

Verify ClusterRoleBinding Exists
    [Documentation]    Verifies ClusterRoleBinding exists and references correct ServiceAccount
    [Arguments]    ${crb_name}    ${expected_sa_name}    ${expected_sa_namespace}=openshift-ingress
    ${rc}    ${sa_name}=    Run And Return Rc And Output
    ...    oc get clusterrolebinding ${crb_name} -o jsonpath='{.subjects[0].name}'
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal    ${sa_name}    ${expected_sa_name}
    ${rc}    ${sa_namespace}=    Run And Return Rc And Output
    ...    oc get clusterrolebinding ${crb_name} -o jsonpath='{.subjects[0].namespace}'
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal    ${sa_namespace}    ${expected_sa_namespace}
    Log    message=ClusterRoleBinding ${crb_name} references SA ${expected_sa_name} in ${expected_sa_namespace}

Verify ClusterRoleBinding Role
    [Documentation]    Verifies ClusterRoleBinding references the correct ClusterRole
    [Arguments]    ${crb_name}    ${expected_role}
    ${rc}    ${role}=    Run And Return Rc And Output
    ...    oc get clusterrolebinding ${crb_name} -o jsonpath='{.roleRef.name}'
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal    ${role}    ${expected_role}
    Log    message=ClusterRoleBinding ${crb_name} references ClusterRole ${expected_role}
