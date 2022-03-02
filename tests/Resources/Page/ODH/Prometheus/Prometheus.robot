*** Settings ***
Documentation       Queries Prometheus using API calls

Library             Collections
Library             Process
Library             RequestsLibrary


*** Keywords ***
Run Query
    [Documentation]    Runs a Prometheus query using the API
    [Arguments]    ${pm_url}    ${pm_token}    ${pm_query}
    ${pm_headers}=    Create Dictionary    Authorization=Bearer ${pm_token}
    ${resp}=    RequestsLibrary.GET    url=${pm_url}/api/v1/query?query=${pm_query}
    ...    headers=${pm_headers}    verify=${False}
    Status Should Be    200    ${resp}
    # Log To Console    ${resp.json()}
    [Return]    ${resp}

Get Rules
    [Documentation]    Gets Prometheus rules
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_type}
    ${pm_headers}=    Create Dictionary    Authorization=Bearer ${pm_token}
    ${resp}=    RequestsLibrary.GET    url=${pm_url}/api/v1/rules?type=${rule_type}
    ...    headers=${pm_headers}    verify=${False}
    Status Should Be    200    ${resp}
    [Return]    ${resp.json()}

Verify Rule
    [Documentation]    Verifies that a Prometheus rule exist, failing if it doesn't
    [Arguments]    ${rule_group}    @{all_rules}

    FOR    ${rule}    IN    @{all_rules}
        ${rule_name}=    Get From Dictionary    ${rule}    name
        ${rules_list}=    Get From Dictionary    ${rule}    rules

        IF    '${rule_name}' == '${rule_group}'
            ${rules_list_len}=    Get Length    ${rules_list}
            Should Be True    ${rules_list_len} != 0
            Return From Keyword    ${TRUE}
        END
    END
    Fail    msg=${rule_group} was not found in Prometheus rules

Verify Rules
    [Documentation]    Verifies that a list of Prometheus rules exist, failing if one or more doesn't
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_type}    @{rule_groups}
    ${all_rules}=    Get Rules    ${pm_url}    ${pm_token}    ${rule_type}
    ${all_rules}=    Get From Dictionary    ${all_rules['data']}    groups

    FOR    ${rule_group}    IN    @{rule_groups}
        Prometheus.Verify Rule    ${rule_group}    @{all_rules}
    END

Alert Should Be Firing    # robocop: disable:too-many-calls-in-keyword
    [Documentation]    Fails if a Prometheus alert is not firing
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}=${EMPTY}
    ${all_rules}=    Get Rules    ${pm_url}    ${pm_token}    alert
    ${all_rules}=    Get From Dictionary    ${all_rules['data']}    groups
    ${alert_found}=    Set Variable    False

    FOR    ${rule}    IN    @{all_rules}
        ${rule_name}=    Get From Dictionary    ${rule}    name
        ${rules_list}=    Get From Dictionary    ${rule}    rules

        IF    '${rule_name}' == '${rule_group}'
            FOR    ${sub_rule}    IN    @{rules_list}
                ${state}=    Get From Dictionary    ${sub_rule}    state
                ${name}=    Get From Dictionary    ${sub_rule}    name
                ${duration}=    Get From Dictionary    ${sub_rule}    duration

                ${alert_found}=    Run Keyword And Return Status
                ...    Alerts Should Be Equal    ${alert}    ${alert-duration}    ${name}    ${duration}

                IF    ${alert_found}
                    IF    '${state}' == 'firing'
                        Return From Keyword    ${TRUE}
                    ELSE
                        Exit For Loop
                    END
                END
            END
        END
    END

    IF    ${alert_found} == True
        # Log To Console    msg=Alert "${alert} ${alert-duration}" was found in Prometheus but state != firing
        Fail    msg=Alert "${alert} ${alert-duration}" was found in Prometheus but state != firing
    ELSE
        Log To Console    msg=ERROR: Alert "${alert} ${alert-duration}" was not found in Prometheus firing rules
        Fail    msg=Alert "${alert} ${alert-duration}" was not found in Prometheus firing rules
    END

Alerts Should Be Equal
    [Documentation]    Compares two alerts names and fails if they are different.
    ...    If ${alert1-duration} is not empty, compare it also with ${alert2-duration}
    [Tags]    Private
    [Arguments]    ${alert1-name}    ${alert1-duration}    ${alert2-name}    ${alert2-duration}
    Should Be Equal    ${alert1-name}    ${alert2-name}
    IF    "${alert1-duration}" != "${EMPTY}"
        Should Be Equal As Strings    ${alert1-duration}    ${alert2-duration}
    END

Alert Should Not Be Firing
    [Documentation]    Fails if a Prometheus alert is firing
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}=${EMPTY}
    ${is_alert_firing}=    Run Keyword And Return Status
    ...    Alert Should Be Firing
    ...    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}
    Should Be True    not ${is_alert_firing}    msg=Alert ${alert} should not be firing

Wait Until Alert Is Firing    # robocop: disable:too-many-arguments
    [Documentation]    Waits until alert is firing or timeout is reached (failing in that case),
    ...    checking the alert state every minute
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}
    ...    ${alert}    ${alert-duration}=${EMPTY}    ${timeout}=10 min
    Wait Until Keyword Succeeds    ${timeout}    1 min
    ...    Alert Should Be Firing    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}

Wait Until Alert Is Not Firing    # robocop: disable:too-many-arguments
    [Documentation]    Waits until alert is not firing or timeout is reached (failing in that case),
    ...    checking the alert state every minute
    [Arguments]    ${pm_url}    ${pm_token}    ${rule_group}
    ...    ${alert}    ${alert-duration}=${EMPTY}    ${timeout}=5 min
    Wait Until Keyword Succeeds    ${timeout}    1 min
    ...    Alert Should Not Be Firing    ${pm_url}    ${pm_token}    ${rule_group}    ${alert}    ${alert-duration}
