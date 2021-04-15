*** Settings ***
Library  JupyterLibrary
Library  String

*** Variables ***

*** Keywords ***
Navigate Home In JupyterLab Sidebar
  Click Element  xpath://span[contains(@class,"jp-BreadCrumbs-home")]

Navigate To ${dir_path} In JupyterLab Sidebar
  @{path_list} =  Split String  ${dir_path}  /
  FOR  ${var}  IN  @{path_list}
    ${var} Is Visible In JupyterLab Sidebar
    Double Click Element  xpath://span[@class="jp-DirListing-itemText"][.="${var}"]
  END

${file_obj} Is Visible In JupyterLab Sidebar
  Wait Until Element Is Visible  xpath://span[@class="jp-DirListing-itemText"][.="${file_obj}"]
