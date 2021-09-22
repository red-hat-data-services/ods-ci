*** Settings ***
Library  JupyterLibrary
Library  String

*** Variables ***
${APP_LAUNCHER_ELEMENT}                 xpath=//*[@aria-label='Application launcher']/button
${PERSPECTIVE_SWITCHER_BUTTON_ELEMENT}  xpath=//*[@data-test-id="perspective-switcher-toggle"]
${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  xpath=//*[@data-test-id="perspective-switcher-toggle"]/span/h2
${PERSPECTIVE_ADMINISTRATOR_BUTTON}  xpath=//*[@id="page-sidebar"]/div/nav/div/div/ul/li[1]/*[contains(@class, 'pf-c-dropdown__menu-item')]/h2
${PERSPECTIVE_DEVELOPER_BUTTON}      xpath=//*[@id="page-sidebar"]/div/nav/div/div/ul/li[2]/*[contains(@class, 'pf-c-dropdown__menu-item')]/h2


*** Keywords ***
Wait Until OpenShift Console Is Loaded
  Wait Until Element Is Enabled    ${APP_LAUNCHER_ELEMENT}  timeout=60

Switch To Administrator Perspective
  Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  timeout=30
  Maybe Skip Tour
  ${current_perspective}=   Get Text  ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}
  IF  '${current_perspective}' != 'Administrator'
      Click Button    ${PERSPECTIVE_SWITCHER_BUTTON_ELEMENT}
      Wait Until Page Contains Element    ${PERSPECTIVE_ADMINISTRATOR_BUTTON}
      Click Element   ${PERSPECTIVE_ADMINISTRATOR_BUTTON}
      Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  timeout=30
  END

Switch To Developer Perspective
  Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}   timeout=30
  Maybe Skip Tour
  ${current_perspective}=   Get Text  ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}
  IF  '${current_perspective}' != 'Developer'
      Click Button    ${PERSPECTIVE_SWITCHER_BUTTON_ELEMENT}
      Wait Until Page Contains Element    ${PERSPECTIVE_DEVELOPER_BUTTON}
      Click Element   ${PERSPECTIVE_DEVELOPER_BUTTON}
      Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  timeout=30
  END

Maybe Skip Tour
   ${tour_modal} =  Run Keyword And Return Status  Page Should Contain Element  xpath=//div[@id='guided-tour-modal']
   Run Keyword If  ${tour_modal}  Click Element  xpath=//div[@id='guided-tour-modal']/
  
Create Secret
  [Arguments]  ${name}  ${key}  ${value}
  Menu.Navigate To Page   Workloads  Secrets
  Wait Until Page Contains  Create  timeout=30
  Click Button  Create
  Click Element  xpath://*[@id="generic-link"]
  Wait Until Page Contains  Secret name  timeout=30
  Input Text  xpath://*[@id="secret-name"]  ${name}
  Input Text  xpath://*[@id="0-key"]  ${Key}
  Input Text  xpath://*[@id="content-scrollable"]/div/form/div[1]/div/div[2]/div/div/div/div/textarea  ${Value}
  Click Button  Create

