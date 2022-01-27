*** Settings ***
Library         SeleniumLibrary
Library         ../../../../libs/Helpers.py
Resource        ../JupyterHub/JupyterLabLauncher.robot
Resource        ../../Components/Components.resource


*** Keywords ***
Check Consumer and Producer Output Equality
  [Arguments]  ${producer_text}  ${consumer_text}
  ${producer_output_list}=  Text To List  text=${producer_text}
  ${consumer_output_list}=  Text To List  text=${consumer_text}
  Should Be Equal    ${producer_output_list}    ${consumer_output_list}[1:]

Open Producer Notebook
  [Arguments]  ${dir_path}  ${filename}
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  ${dir_path}/${filename}
  Click Element  xpath://div[.="Open"]
  Wait Until ${filename} JupyterLab Tab Is Selected

Open Consumer Notebook
  [Arguments]  ${dir_path}  ${filename}
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  ${dir_path}/${filename}
  Click Element  xpath://div[.="Open"]
  Wait Until ${filename} JupyterLab Tab Is Selected

Enable RHOSAK
  Menu.Navigate To Page    Applications    Explore
  Wait Until Page Contains    ${rhosak_displayed_appname}  timeout=30
  Click Element     xpath://*[@id='${rhosak_real_appname}']
  Wait Until Page Contains Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}   timeout=10   error=${rhosak_real_appname} does not have sidebar with information in the Explore page of ODS Dashboard
  Page Should Contain Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}   message=${rhosak_real_appname} does not have a "Enable" button in ODS Dashboard
  Click Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}
  Wait Until Page Contains Element    xpath://div[contains(@id, 'pf-modal-part')]
  Click Button    xpath://footer/button[text()='Enable']
  Wait Until Page Contains Element   xpath://div[@class='pf-c-alert pf-m-success']