*** Settings ***
Library           SeleniumLibrary
Library           RequestsLibrary
Resource          ../../../Common.robot


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
    [Arguments]     ${endpoint}     ${token}    ${json_body}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}   Content-type=application/json
    ${payload}=      Load Json String    json_string=${json_body}
    ${response}=    RequestsLibrary.Put  ${ODH_DASHBOARD_URL}/${endpoint}    expected_status=any
    ...             headers=${headers}    data=${json_body}   timeout=5  verify=${False}

Perform Dashboard API Endpoint POST Call
    [Documentation]     Runs a PUT call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}    ${json_body}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}   Content-type=application/json
    ${payload}=      Load Json String    json_string=${json_body}
    ${response}=    RequestsLibrary.Post  ${ODH_DASHBOARD_URL}/${endpoint}    expected_status=any
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
