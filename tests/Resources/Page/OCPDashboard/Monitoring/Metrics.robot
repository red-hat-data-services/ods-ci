*** Settings ***
Library  SeleniumLibrary


*** Variables ***
${METRICS_QUERY_TEXTAREA}                           xpath=//*[@aria-label='Expression (press Shift+Enter for newlines)']
${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}   xpath=//td[@data-label='Value']


*** Keywords ***
Verify Page Loaded
  Wait Until Page Contains    No query entered  timeout=45
  Wait Until Page Contains Element  ${METRICS_QUERY_TEXTAREA}  timeout=45

Verify Query Results Contain Data
  Wait Until Page Contains Element  ${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}  timeout=20  error="Query results don't contain data"
  ${metrics_query_result_row1_value} =   Get Text  ${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}
  Should Be True    '${metrics_query_result_row1_value}' != ''   "Query results don't contain data"
  Should Be True    '${metrics_query_result_row1_value}' != 'None'   "Query results don't contain data"

Verify Query Results Dont Contain Data
  ${metrics_query_results_contain_data} =  Run Keyword And Return Status   Verify Query Results Contain Data
  Should Be True   not ${metrics_query_results_contain_data}

Run Query
  [Arguments]  ${query}  ${retry_attempts}=10
  Wait Until Page Contains Element    ${METRICS_QUERY_TEXTAREA}  timeout=30
  Input Text   ${METRICS_QUERY_TEXTAREA}  ${query}

  ${end-range}=   Evaluate    ${retry_attempts} + 1
  FOR    ${counter}    IN RANGE    1    ${end-range}
      Press Keys   ${METRICS_QUERY_TEXTAREA}    ENTER
      Sleep  5  reason=Wait for query results
      ${metrics_query_results_contain_data} =  Run Keyword and Return Status   Verify Query Results Contain Data
      Capture Page Screenshot
      Exit For Loop If   ${metrics_query_results_contain_data}
      Exit For Loop If   ${counter} == ${retry_attempts}
      Sleep  60  reason=Wait until metrics are available
  END

Get Query Results
    [Documentation]    After having run a query in OpenShift Console > Observe > Metrics, returns the obtained value.
    ...    If ${return_zero_if_result_empty} is True, returns a zero when the result is empty
    [Arguments]    ${return_zero_if_result_empty}=False

    ${metrics_query_results_contain_data} =  Run Keyword And Return Status   Verify Query Results Contain Data
    IF  ${metrics_query_results_contain_data}
      ${metrics_query_result_row1_value} =   Get Text  ${METRICS_QUERY_RESULTS_TABLE_ROW1_VALUE_ELEMENT}
    ELSE
        IF  ${return_zero_if_result_empty}==True
            ${metrics_query_result_row1_value} =   Set Variable  0
        ELSE
            ${metrics_query_result_row1_value} =   Set Variable  ${EMPTY}
        END
    END
    RETURN  ${metrics_query_result_row1_value}
