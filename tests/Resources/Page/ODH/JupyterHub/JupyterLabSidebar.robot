*** Settings ***
Library  JupyterLibrary
Library  String

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
