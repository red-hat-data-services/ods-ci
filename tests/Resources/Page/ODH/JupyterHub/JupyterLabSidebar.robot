*** Settings ***
Library  JupyterLibrary
Library  String
Library  RequestsLibrary
*** Variables ***

*** Keywords ***
Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  [Documentation]  Opens the JupyterLab Sidebar, clicks on "File Browser" and clicks on the Root folder (/opt/app-root/src)
  Maybe Open JupyterLab Sidebar   File Browser
  Click Element  xpath://span[contains(@class,"jp-BreadCrumbs-home")]

Navigate To ${dir_path} In JupyterLab Sidebar
  @{path_list} =  Split String  ${dir_path}  /
  FOR  ${var}  IN  @{path_list}
    ${var} Is Visible In JupyterLab Sidebar
    Double Click Element  xpath://span[@class="jp-DirListing-itemText"][.="${var}"]
  END

${file_obj} Is Visible In JupyterLab Sidebar
  Wait Until Element Is Visible  xpath://span[@class="jp-DirListing-itemText"][.="${file_obj}"]

Get Install Plugin list from JupyterLab
  ${plugin_names}    Create List
  Maybe Open JupyterLab Sidebar      Extension Manager
  Run Keyword And Return Status   Wait Until Page Contains Element       xpath://*[@class="jp-extensionmanager-disclaimer"]//*[contains(text(), "Enable")]    timeout=10
  Run Keyword And Return Status         Click Button    Enable
  Run Keyword And Return Status      Wait Until Page Contains Element     xpath://*[@class="jp-extensionmanager-disclaimer"]//*[contains(text(), "Disable")]     timeout=10
  ${link_elements}=  Get WebElements  xpath://ul[@class="jp-extensionmanager-listview"]//li[contains(@class,"jp-extensionmanager-entry-ok")]//a
  FOR  ${idx}  ${ext_link}  IN ENUMERATE  @{link_elements}  start=1
        ${plugin_name}=  Get Element Attribute    ${ext_link}    text
        ${href}=  Get Element Attribute    ${ext_link}    href
        Append To List    ${plugin_names}    ${plugin_name}
        ${status}=  Get HTTP Status Code   ${href}
        Log To Console    ${idx}. ${href} gets status code ${status}
  END
  [Return]   ${plugin_names}


Get HTTP Status Code
    [Arguments]  ${link_to_check}
    ${response}=    RequestsLibrary.GET  ${link_to_check}   expected_status=any
    Run Keyword And Continue On Failure  Status Should Be  200
    #Run Keyword And Warn On Failure  Status Should Be  200
    [Return]  ${response.status_code}
