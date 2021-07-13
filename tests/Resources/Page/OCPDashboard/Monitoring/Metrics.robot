*** Settings ***
Library  SeleniumLibrary

*** Variables ***
${METRICS_QUERY_TEXTAREA}                           xpath=//*[@aria-label='Expression (press Shift+Enter for newlines)']
${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}   xpath=//td[@data-label='Value']

*** Keywords ***
Verify Page Loaded
  Wait Until Page Contains    No query entered  timeout=20
  Wait Until Page Contains Element  ${METRICS_QUERY_TEXTAREA}  timeout=20

Verify Query Results Contain Data
  Page Should Not Contain   No datapoints found.
  Wait Until Page Contains Element  ${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}  timeout=20
  Page Should Contain Element    ${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}   "Query results don't contain data"
  ${metrics_query_result_row1_value} =   Get Text  ${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}
  Should Be True    '${metrics_query_result_row1_value}' != ''   "Query results don't contain data"
  Should Be True    '${metrics_query_result_row1_value}' != 'None'   "Query results don't contain data"

Verify Query Results Dont Contain Data
  ${metrics_query_results_contain_data} =  Run Keyword And Return Status   Verify Query Results Contain Data
  Should Be True   not ${metrics_query_results_contain_data}

Run Query
  [Arguments]  ${query}
  Input Text   ${METRICS_QUERY_TEXTAREA}  ${query}
  Press Keys   ${METRICS_QUERY_TEXTAREA}    ENTER
  Wait Until Page Does Not Contain    No query entered  timeout=20

Get Query Results
  ${metrics_query_results_contain_data} =  Run Keyword and Return Status   Verify Query Results Contain Data
  IF  ${metrics_query_results_contain_data}
      ${metrics_query_result_row1_value} =   Get Text  ${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}
  ELSE
       ${metrics_query_result_row1_value} =   Set Variable  ${EMPTY}
  END
  [Return]  ${metrics_query_result_row1_value}
