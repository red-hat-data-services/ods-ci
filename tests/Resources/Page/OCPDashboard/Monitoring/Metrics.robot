*** Settings ***
Library  SeleniumLibrary

*** Variables ***
${METRICS_QUERY_TEXTAREA}  xpath=/html/body/div[2]/div[1]/div/div/div/div/main/div/div/div/section/div/div[2]/div[2]/div[2]/div/div[3]/div/div[1]/textarea
${METRICS_QUERY_RESULTS_PARENT_ELEMENT}            xpath=/html/body/div[2]/div[1]/div/div/div/div/main/div/div/div/section/div/div[2]/div[2]/div[2]/div/div[3]/div[2]
${METRICS_QUERY_RESULTS_TABLE}                     xpath=/html/body/div[2]/div[1]/div/div/div/div/main/div/div/div/section/div/div[2]/div[2]/div[2]/div/div[3]/div[2]/table
${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}  xpath=/html/body/div[2]/div[1]/div/div/div/div/main/div/div/div/section/div/div[2]/div[2]/div[2]/div/div[3]/div[2]/table/tbody/tr/td[4]

*** Keywords ***
Verify Page Loaded
  Wait Until Page Contains    No query entered  timeout=20
  Wait Until Page Contains Element  ${METRICS_QUERY_TEXTAREA}  timeout=20

Verify Query Results Contain Data
  Wait Until Page Contains Element  ${METRICS_QUERY_RESULTS_PARENT_ELEMENT}
  Page Should Contain Element    ${METRICS_QUERY_RESULTS_TABLE}
  ${metrics_query_result_row1_value} =   Get Text  ${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}
  Should Be True    '${metrics_query_result_row1_value}' != ''
  Should Be True    '${metrics_query_result_row1_value}' != 'None'

Verify Query Results Dont Contain Data
  ${metrics_query_results_contain_data} =  Run Keyword And Return Status   Verify Query Results Contain Data
  Should Be True   not ${metrics_query_results_contain_data}

Run Query
  [Arguments]  ${query}
  Input Text    ${METRICS_QUERY_TEXTAREA}  ${query}
  Press Keys    ${METRICS_QUERY_TEXTAREA}    ENTER
  Wait Until Page Contains Element  ${METRICS_QUERY_RESULTS_PARENT_ELEMENT}


Get Query Results
  ${metrics_query_results_contain_data} =  Run Keyword and Return Status   Verify Query Results Contain Data
  IF  ${metrics_query_results_contain_data}
      ${metrics_query_result_row1_value} =   Get Text  ${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}
  ELSE
       ${metrics_query_result_row1_value} =   Set Variable  ${EMPTY}
  END
  [Return]  ${metrics_query_result_row1_value}
