*** Settings ***
Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot
Library         ../../../../libs/Helpers.py

*** Keywords ***
Get Pod Logs
  [Arguments]  ${namespace}  ${pod_search_term}
  Navigate To Page    Workloads    Pods
  Search Last Item Instance By Title in OpenShift Table  search_term=${pod_search_term}  namespace=${namespace}
  Click Link    xpath://tr[@data-id='0-0']/td[@id='name']/*/a
  Click Link    Logs
  Sleep  2
  Capture Page Screenshot  logs_page.png
  ${logs_text}=  Get Text    xpath://div[@class='log-window__lines']
  ${log_rows}=  Text To List  ${logs_text}
  [Return]  ${log_rows}