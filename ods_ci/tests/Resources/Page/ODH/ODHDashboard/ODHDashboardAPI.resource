*** Settings ***
Library           SeleniumLibrary
Library           RequestsLibrary
Resource          ../../../Common.robot


*** Variables ***
${WARN_MSG_500}=    Accepting HTTP code 500 as "allowed". If the user wouldn't have permissions,
...                 the expected HTTP code is either 401 or 403. If users gets 500 it might mean
...                 something is wrong with the payload


*** Keywords ***
Perform Request
    [Documentation]    Generic keyword to perform API call. It implements the log security by
    ...                hiding the oauth proxy data from logs and producing a custom log string.
    [Arguments]     ${request_type}    ${skip_res_json}=${FALSE}   &{request_args}
    &{LOG_DICT}=    Create Dictionary   url=${EMPTY}   headers=${EMPTY}
    ...                                 body=${EMPTY}    status_code=${EMPTY}
    &{LOG_RESP_DICT}=    Create Dictionary   url=${EMPTY}   headers=${EMPTY}   body=${EMPTY}
    ...                                      status_code=${EMPTY}   reason=${EMPTY}
    ${response}=   Run Keyword And Continue On Failure     RequestsLibrary.${request_type}   &{request_args}
    Remove OAuth Token From Header   headers=${response.request.headers}    token=${request_args}[headers][Cookie]
    Remove OAuth Token From Header   headers=${response.headers}    token=${request_args}[headers][Cookie]
    Set Log Level    INFO
    Set To Dictionary    ${LOG_DICT}     url=${response.request.url}   headers=${response.request.headers}
    ...                                 body=${response.request.headers}    status_code=${response.status_code}
    Log     ${request_type} Request: ${LOG_DICT}
    Set To Dictionary    ${LOG_RESP_DICT}      url=${response.url}   headers=${response.headers}   body=${response.text}
    ...                                      status_code=${response.status_code}   reason=${response.reason}
    Log     ${request_type} Response: ${LOG_RESP_DICT}
    IF    ${skip_res_json} == ${TRUE}
        RETURN    ${response.text}
    ELSE
        RETURN    ${response.json()}
    END

Perform Dashboard API Endpoint GET Call
    [Documentation]     Runs a GET call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}
    &{args}=       Create Dictionary     url=${ODH_DASHBOARD_URL}/${endpoint}   expected_status=any
    ...             headers=${headers}   timeout=5  verify=${False}
    ${response}=    Run Keyword And Continue On Failure     Perform Request     GET     &{args}
    IF    ${response} == ${NONE}
        Log    msg=HTTP response is empty. The request may have failed to be performed  level=ERROR
    END
    RETURN    ${response}

Perform Dashboard API Endpoint PUT Call
    [Documentation]     Runs a PUT call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}    ${body}     ${str_to_json}=${TRUE}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}   Content-type=application/json
    ${payload}=     Prepare Payload     body=${body}    str_to_json=${str_to_json}
    &{args}=       Create Dictionary     url=${ODH_DASHBOARD_URL}/${endpoint}   expected_status=any
    ...             headers=${headers}   json=${payload}    timeout=5  verify=${False}
    ${response}=    Run Keyword And Continue On Failure     Perform Request     PUT     &{args}
    IF    ${response} == ${NONE}
        Log    msg=HTTP response is empty. The request may have failed to be performed  level=ERROR
    END

Perform Dashboard API Endpoint POST Call
    [Documentation]     Runs a PUT call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}    ${body}    ${str_to_json}=${TRUE}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}   Content-type=application/json
    ${payload}=     Prepare Payload     body=${body}    str_to_json=${str_to_json}
    &{args}=       Create Dictionary     url=${ODH_DASHBOARD_URL}/${endpoint}   expected_status=any
    ...             headers=${headers}   json=${payload}    timeout=5  verify=${False}
    ${response}=    Run Keyword And Continue On Failure     Perform Request     POST     &{args}
    IF    ${response} == ${NONE}
        Log    msg=HTTP response is empty. The request may have failed to be performed  level=ERROR
    END

Perform Dashboard API Endpoint PATCH Call
    [Documentation]     Runs a PATCH call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}    ${body}     ${str_to_json}=${TRUE}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}   Content-type=application/json
    ${payload}=     Prepare Payload     body=${body}    str_to_json=${str_to_json}
    &{args}=       Create Dictionary     url=${ODH_DASHBOARD_URL}/${endpoint}   expected_status=any
    ...             headers=${headers}   json=${payload}    timeout=5  verify=${False}
    ${response}=    Run Keyword And Continue On Failure     Perform Request     PATCH     &{args}
    IF    ${response} == ${NONE}
        Log    msg=HTTP response is empty. The request may have failed to be performed  level=ERROR
    END

Perform Dashboard API Endpoint DELETE Call
    [Documentation]     Runs a GET call to the given API endpoint. Result may change based
    ...                 on the given token (i.e., user)
    [Arguments]     ${endpoint}     ${token}
    ${headers}=    Create Dictionary     Cookie=_oauth_proxy=${token}
    &{args}=       Create Dictionary     url=${ODH_DASHBOARD_URL}/${endpoint}   expected_status=any
    ...             headers=${headers}   timeout=5  verify=${False}
    ${response}=    Run Keyword And Continue On Failure     Perform Request     DELETE     &{args}
    IF    ${response} == ${NONE}
        Log    msg=HTTP response is empty. The request may have failed to be performed  level=ERROR
    END

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
    RETURN    ${payload}

Remove OAuth Token From Header
    [Documentation]     Hides oauth proxy from header
    [Arguments]     ${headers}   ${token}
    ${oauth_present}=       Run Keyword And Return Status    Dictionary Should Contain Key
    ...                                                      dictionary=${headers}    key=Cookie
    ${token}=    Replace String    string=${token}    search_for=_oauth_proxy=    replace_with=${EMPTY}
    IF    ${oauth_present} == ${TRUE}
         ${cookies}=    Replace String    string=${headers}[Cookie]     search_for=${token}     replace_with=***hidden***
         Set To Dictionary    dictionary=${headers}   Cookie=${cookies}
    END
