*** Settings ***
Resource  ../../Common.robot
Library  JupyterLibrary
Library  String
Library  OpenShiftLibrary

*** Variables ***
${APP_LAUNCHER_ELEMENT}                 xpath://button[@aria-label="Application launcher"]
${PERSPECTIVE_SWITCHER_BUTTON_ELEMENT}  xpath=//*[@data-test-id="perspective-switcher-toggle"]
${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  xpath=//*[@data-test-id="perspective-switcher-toggle"]/span/h2
${PERSPECTIVE_ADMINISTRATOR_BUTTON}  xpath=//*[@data-test-id="perspective-switcher-menu-option"][starts-with(., "Administrator")]
${PERSPECTIVE_DEVELOPER_BUTTON}      xpath=//*[@data-test-id="perspective-switcher-menu-option"][starts-with(., "Developer")]
${LOADING_INDICATOR_ELEMENT}         xpath=//*[@data-test="loading-indicator"]

*** Keywords ***
Wait Until OpenShift Console Is Loaded
  ${expected_text_list}=    Create List    Administrator    Developer
  Wait Until Page Contains A String In List    ${expected_text_list}
  Wait Until Element Is Enabled    ${APP_LAUNCHER_ELEMENT}  timeout=60

Switch To Administrator Perspective
  Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  timeout=30
  Maybe Skip Tour
  ${current_perspective}=   Get Text  ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}
  IF  '${current_perspective}' != 'Administrator'
      Click Button    ${PERSPECTIVE_SWITCHER_BUTTON_ELEMENT}
      Wait Until Page Does Not Contain Element   ${LOADING_INDICATOR_ELEMENT}  timeout=30
      Wait Until Element Is Visible    ${PERSPECTIVE_ADMINISTRATOR_BUTTON}  timeout=30
      Sleep  1
      Click Element   ${PERSPECTIVE_ADMINISTRATOR_BUTTON}
      Wait Until Page Does Not Contain Element   ${LOADING_INDICATOR_ELEMENT}  timeout=30
      Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  timeout=30
  END

Switch To Developer Perspective
  Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}   timeout=30
  Maybe Skip Tour
  ${current_perspective}=   Get Text  ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}
  IF  '${current_perspective}' != 'Developer'
      Click Button    ${PERSPECTIVE_SWITCHER_BUTTON_ELEMENT}
      Wait Until Page Does Not Contain Element   ${LOADING_INDICATOR_ELEMENT}  timeout=30
      Wait Until Element Is Visible    ${PERSPECTIVE_DEVELOPER_BUTTON}  timeout=30
      Sleep  1
      Click Element   ${PERSPECTIVE_DEVELOPER_BUTTON}
      Wait Until Page Does Not Contain Element   ${LOADING_INDICATOR_ELEMENT}  timeout=30
      Wait Until Page Contains Element     ${PERSPECTIVE_SWITCHER_TEXT_ELEMENT}  timeout=30
  END

Maybe Skip Tour
    [Documentation]    If we are in the openshift web console, maybe skip the first time
    ...    tour popup given to users, otherwise RETURN.
    ${should_cont} =    Does Current Sub Domain Start With    https://console-openshift-console
    IF  ${should_cont}==False
        RETURN
    END
    ${MODAL_GUIDED_TOUR_XPATH} =  Set Variable  xpath=//div[@id='guided-tour-modal']

    ${tour_modal} =  Run Keyword And Return Status  Wait Until Page Contains Element  ${MODAL_GUIDED_TOUR_XPATH}  timeout=5s
    IF  ${tour_modal}
        # This xpath is for OCP 4.18 and older
        ${MODAL_BUTTON_OLDER_XPATH} =  Set Variable  ${MODAL_GUIDED_TOUR_XPATH}/button
        # This xpath is for OCP 4.19+
        ${MODAL_BUTTON_NEWER_XPATH} =  Set Variable  ${MODAL_GUIDED_TOUR_XPATH}//button[@aria-label="Close"]

        ${modal_older} =  Run Keyword And Return Status  Page Should Contain Element    ${MODAL_BUTTON_OLDER_XPATH}
        ${modal_newer} =  Run Keyword And Return Status  Page Should Contain Element    ${MODAL_BUTTON_NEWER_XPATH}
        IF  ${modal_older}
            Click Element  ${MODAL_BUTTON_OLDER_XPATH}
        ELSE IF  ${modal_newer}
            Click Element  ${MODAL_BUTTON_NEWER_XPATH}
        ELSE
            Fail  Unexpected Guided tour modal window, please check and update the implementation.
        END
    END

Get OpenShift Version
    [Documentation]   Get the installed openshitf version on the cluster.
    ${data}=   Oc Get    kind=ClusterVersion
    ${version}=   Split String From Right    ${data[0]['status']['desired']['version']}      .    1
    RETURN     ${version[0]}
