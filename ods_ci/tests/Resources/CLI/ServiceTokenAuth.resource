*** Settings ***
Documentation       Keywords for Service Account Token Authentication testing
Library             OperatingSystem
Library             String
Resource            ../Common.robot


*** Keywords ***
Create Test Service Account For Token Auth
    [Documentation]    Ensures test ServiceAccount exists for token auth E2E tests
    [Arguments]    ${sa_name}=test-svc-token-auth    ${namespace}=opendatahub
    ${rc}    ${_}=    Run And Return Rc And Output
    ...    oc create serviceaccount ${sa_name} -n ${namespace} --dry-run=client -o yaml | oc apply -f -
    Should Be Equal As Integers    ${rc}    0
    Log    message=Test ServiceAccount ${sa_name} ready in ${namespace}

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
    [Arguments]    ${token}    ${path}=/    ${gateway_url}=${EMPTY}
    IF    "${gateway_url}" == "${EMPTY}"
        ${gateway_url}=    Get Gateway URL For Curl
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

Get Gateway URL For Curl
    [Documentation]    Gets gateway hostname for curl. Uses ODH_DASHBOARD_URL if set (works for all
    ...                ingress modes), otherwise Gateway resource.
    ${url}=    Get Variable Value    \${ODH_DASHBOARD_URL}    ${EMPTY}
    IF    "${url}" != "${EMPTY}"
        ${url}=    Remove String    ${url}    https://    http://
        ${host}=    Fetch From Left    ${url}    /
        RETURN    ${host}
    END
    ${rc}    ${url}=    Run And Return Rc And Output
    ...    oc get gateway data-science-gateway -n openshift-ingress -o jsonpath='{.status.addresses[0].value}'
    Should Be Equal As Integers    ${rc}    0
    Should Not Be Empty    ${url}
    Log    message=Gateway URL: ${url}
    RETURN    ${url}

Call Gateway Without Token
    [Documentation]    Makes curl request to gateway without authentication token
    [Arguments]    ${path}=/
    ${gateway_url}=    Get Gateway URL For Curl
    ${rc}    ${full_response}=    Run And Return Rc And Output
    ...    curl -k -s -i https://${gateway_url}${path}
    Should Be Equal As Integers    ${rc}    0
    ${status_line}=    Get Line    ${full_response}    0
    @{status_parts}=    Split String    ${status_line}
    ${http_code}=    Set Variable    ${status_parts}[1]
    ${response}=    Set Variable    ${full_response}${\n}HTTP_CODE:${http_code}
    RETURN    ${response}

Verify Response Is Auth Challenge
    [Documentation]    Verifies that response indicates auth challenge (403 or 302)
    [Arguments]    ${response}
    ${contains_forbidden}=    Run Keyword And Return Status
    ...    Should Contain    ${response}    HTTP_CODE:403
    ${contains_redirect}=    Run Keyword And Return Status
    ...    Should Contain    ${response}    HTTP_CODE:302
    ${is_challenged}=    Evaluate    ${contains_forbidden} or ${contains_redirect}
    Should Be True    ${is_challenged}    msg=Request without token should be challenged

Verify Response HTTP Code
    [Documentation]    Extracts and verifies HTTP response code from curl output
    [Arguments]    ${response}    ${expected_code}=200
    ${http_code}=    Get Regexp Matches    ${response}    HTTP_CODE:(\\d+)    1
    Should Not Be Empty    ${http_code}
    Should Be Equal As Strings    ${http_code}[0]    ${expected_code}
    Log    message=HTTP response code: ${http_code}[0]

Get Json Body From Curl Response
    [Documentation]    Extracts JSON body from curl -i response (body is after headers)
    [Arguments]    ${response}
    @{parts}=    Split String    ${response}    \n\n    1
    ${body_section}=    Set Variable    ${parts}[1]
    ${body}=    Fetch From Left    ${body_section}    ${\n}HTTP_CODE:
    ${body}=    Strip String    ${body}
    RETURN    ${body}

Verify API Status Returns User Name
    [Documentation]    Calls /api/status with token, verifies response contains expected userName
    [Arguments]    ${token}    ${expected_user}
    ${response}=    Call Gateway With Token Via Curl    ${token}    path=/api/status
    Verify Response HTTP Code    ${response}    expected_code=200
    ${body}=    Get Json Body From Curl Response    ${response}
    ${user_name}=    Evaluate    json.loads(r"""${body}""")["kube"]["userName"]    json
    Should Be Equal As Strings    ${user_name}    ${expected_user}
    Log    message=API status returned expected userName: ${user_name}

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
