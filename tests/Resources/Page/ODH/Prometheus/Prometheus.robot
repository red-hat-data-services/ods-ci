*** Settings ***
Library        RequestsLibrary
Library        Collections

*** Keywords ***
Run Query
  [Arguments]  ${pm_url}  ${pm_token}  ${pm_query}
  ${pm_headers}=       Create Dictionary  Authorization=Bearer ${pm_token}
  ${resp}=       GET   url=${pm_url}/api/v1/query?query=${pm_query}   headers=${pm_headers}   verify=${False}
  Status Should Be    200    ${resp}
  Log To Console    ${resp.json()}
  [Return]   ${resp}
