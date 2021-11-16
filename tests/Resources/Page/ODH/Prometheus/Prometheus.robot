*** Settings ***
Library        Collections
Library        Process
Library        RequestsLibrary

*** Keywords ***
Run Query
  [Arguments]  ${pm_url}  ${pm_token}  ${pm_query}
  ${pm_headers}=       Create Dictionary  Authorization=Bearer ${pm_token}
  ${resp}=       GET   url=${pm_url}/api/v1/query?query=${pm_query}   headers=${pm_headers}   verify=${False}
  Status Should Be    200    ${resp}
  Log To Console    ${resp.json()}
  [Return]   ${resp}

Get Rules
  [Arguments]  ${pm_url}  ${pm_token}  ${rule_type}
  ${pm_headers}=       Create Dictionary  Authorization=Bearer ${pm_token}
  ${resp}=       GET   url=${pm_url}/api/v1/rules?type=${rule_type}   headers=${pm_headers}   verify=${False}
  Status Should Be    200    ${resp}
  [Return]  ${resp.json()}

Verify Rule
  [Arguments]  ${rule_group}  @{all_rules}

  FOR    ${rule}    IN    @{all_rules}
    ${rule_name}=  Get From Dictionary  ${rule}  name
    ${rules_list}=  Get From Dictionary  ${rule}  rules

    IF  '${rule_name}' == '${rule_group}'
      ${rules_list_len}=  Get Length  ${rules_list}
      Should Be True  ${rules_list_len} != 0
      Return from keyword  ${TRUE}
    END
  END
  Log To Console  ${rule_group} was not found in Prometheus rules
  Fail

Verify Rules
  [Arguments]  ${pm_url}  ${pm_token}  ${rule_type}  @{rule_groups}
  ${all_rules}=  Get Rules   ${pm_url}  ${pm_token}  ${rule_type}
  ${all_rules}=  Get From Dictionary    ${all_rules['data']}  groups

  FOR  ${rule_group}  IN  @{rule_groups}
    Prometheus.Verify Rule  ${rule_group}  @{all_rules}
  END

Alert Should Be Firing
  [Arguments]  ${pm_url}  ${pm_token}  ${rule_group}  ${alert}
  ${all_rules}=  Get Rules   ${pm_url}  ${pm_token}  alert
  ${all_rules}=  Get From Dictionary    ${all_rules['data']}  groups
  ${alert_found}=   Set Variable  False

  FOR  ${rule}  IN  @{all_rules}
    ${rule_name}=  Get From Dictionary  ${rule}  name
    ${rules_list}=  Get From Dictionary  ${rule}  rules

    IF  '${rule_name}' == '${rule_group}'
      FOR  ${sub_rule}  IN  @{rules_list}
        ${state}=  Get From Dictionary  ${sub_rule}  state
        ${name}=  Get From Dictionary  ${sub_rule}  name
        ${duration}=  Get From Dictionary  ${sub_rule}  duration
        IF  '${name}' == '${alert}'
          ${alert_found}=   Set Variable  True
          Log   Alert "${name}" (duration=${duration}): state=${state}
          IF    '${state}' == 'firing'
              Return from keyword  ${TRUE}
          END
        END
      END
    END
  END

  IF    ${alert_found} == True
      Fail  msg=Alert "${alert}" was found in Prometheus but it wasn't firing
  ELSE
      Fail  msg=Alert "${alert}" was not found in Prometheus firing rules
  END


Wait Until Alert Is Firing
   [Documentation]  Waits until alert is firing or timeout is reached (failing in that case), checking the alert state every minute
   [Arguments]    ${pm_url}  ${pm_token}  ${rule_group}  ${alert}  ${timeout}=10 min
   Log To Console    Waiting for alert "${alert}" to be firing (timeout = ${timeout})
   Wait Until Keyword Succeeds  ${timeout}  1 min  Alert Should Be Firing  ${pm_url}  ${pm_token}  ${rule_group}  ${alert}


