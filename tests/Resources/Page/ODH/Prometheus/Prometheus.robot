*** Settings ***
Library        Collections
Library        Process
Library        RequestsLibrary

*** Keywords ***
Run Query
  [Arguments]  ${pm_url}  ${pm_token}  ${pm_query}
  ${pm_headers}=       Create Dictionary  Authorization=Bearer ${pm_token}
  ${resp}=       RequestsLibrary.GET   url=${pm_url}/api/v1/query?query=${pm_query}   headers=${pm_headers}   verify=${False}
  Status Should Be    200    ${resp}
  Log To Console    ${resp.json()}
  [Return]   ${resp}

Get Rules
  [Arguments]  ${pm_url}  ${pm_token}  ${rule_type}
  ${pm_headers}=       Create Dictionary  Authorization=Bearer ${pm_token}
  ${resp}=       RequestsLibrary.GET   url=${pm_url}/api/v1/rules?type=${rule_type}   headers=${pm_headers}   verify=${False}
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

  FOR  ${rule}  IN  @{all_rules}
    ${rule_name}=  Get From Dictionary  ${rule}  name
    ${rules_list}=  Get From Dictionary  ${rule}  rules

    IF  '${rule_name}' == '${rule_group}'
      FOR  ${sub_rule}  IN  @{rules_list}
        ${state}=  Get From Dictionary  ${sub_rule}  state
        ${name}=  Get From Dictionary  ${sub_rule}  name
        IF  '${name}' == '${alert}'
          Should Be Equal As Strings  ${state}  firing  msg=Alert ${alert} should be firing but state = ${state}
          Return from keyword  ${TRUE}
        END
      END
    END
  END
  Fail  msg=${alert} was not found in Prometheus firing rules
