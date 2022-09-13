*** Settings ***
Library           SeleniumLibrary
Library           RequestsLibrary
Resource          ../../../Common.robot


*** Variables ***
${WARN_MSG_500}=    Accepting HTTP code 500 as "allowed". If the user wouldn't have permissions,
...                 the expected HTTP code is either 401 or 403. If users gets 500 it might mean
...                 something is wrong with the payload


*** Keywords ***
Perform Dashboard API Endpoint GET Call
    [Documentation]     Runs a GET call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}
    ${response}=    RequestsLibrary.GET  ${ODH_DASHBOARD_URL}/${endpoint}   expected_status=any
    ...             headers=${headers}   timeout=5  verify=${False}
    [Return]    ${response}

Perform Dashboard API Endpoint PUT Call
    [Documentation]     Runs a PUT call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}    ${body}     ${str_to_json}=${TRUE}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}   Content-type=application/json
    ${payload}=     Prepare Payload     body=${body}    str_to_json=${str_to_json}
    ${response}=    RequestsLibrary.Put  ${ODH_DASHBOARD_URL}/${endpoint}    expected_status=any
    ...             headers=${headers}    json=${payload}   timeout=5  verify=${False}

Perform Dashboard API Endpoint POST Call
    [Documentation]     Runs a PUT call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}    ${body}    ${str_to_json}=${TRUE}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}   Content-type=application/json
    ${payload}=     Prepare Payload     body=${body}    str_to_json=${str_to_json}
    ${response}=    RequestsLibrary.Post  ${ODH_DASHBOARD_URL}/${endpoint}    expected_status=any
    ...             headers=${headers}    json=${payload}   timeout=5  verify=${False}

Perform Dashboard API Endpoint PATCH Call
    [Documentation]     Runs a PATCH call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}    ${body}     ${str_to_json}=${TRUE}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}   Content-type=application/json
    ${payload}=     Prepare Payload     body=${body}    str_to_json=${str_to_json}
    ${response}=    RequestsLibrary.Patch  ${ODH_DASHBOARD_URL}/${endpoint}    expected_status=any
    ...             headers=${headers}    json=${payload}   timeout=5  verify=${False}

Perform Dashboard API Endpoint DELETE Call
    [Documentation]     Runs a GET call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}
    ${response}=    RequestsLibrary.DELETE  ${ODH_DASHBOARD_URL}/${endpoint}   expected_status=any
    ...             headers=${headers}   timeout=5  verify=${False}

Operation Should Be Allowed
    [Documentation]     Checks if the API call returns an HTTP code 200 (SUCCESS)
    [Arguments]     ${accept_code_500}=${FALSE}
    IF  "${accept_code_500}" == "${FALSE}"
        Run Keyword And Continue On Failure  Status Should Be  200
    ELSE
        Run Keyword And Ignore Error           Status Should Be  200
        Run Keyword And Continue On Failure    Status Should Be  500
        Log     message=${WARN_MSG_500}   level=WARN
    END

Operation Should Be Unauthorized
    [Documentation]     Checks if the API call returns an HTTP code 401 (Unauthorized)
    Run Keyword And Continue On Failure  Status Should Be  401

Operation Should Be Forbidden
    [Documentation]     Checks if the API call returns an HTTP code 403 (FORBIDDEN)
    Run Keyword And Continue On Failure  Status Should Be  403

Operation Should Be Unavailable
    [Documentation]     Checks if the API call returns an HTTP code 404 (NOT FOUND)
    Run Keyword And Continue On Failure  Status Should Be  404

Prepare Payload
    [Arguments]     ${body}     ${str_to_json}
    IF  "${str_to_json}" == "${TRUE}"
        ${payload}=     Load Json String    json_string=${body}
    ELSE
        ${payload}=     Set Variable    ${body}
    END
    [Return]    ${payload}
