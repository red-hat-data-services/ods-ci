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

Disable Guided Tour Via CLI
    [Documentation]    Disables the OpenShift Console guided tour for the current user using oc commands.
    ...                This is more reliable than UI-based modal detection and clicking.
    ...                Only updates existing user settings configmap, does not create new ones.
    [Arguments]    ${username}

    # Get the current user's UID
    ${rc}    ${user_uid}=    Run And Return Rc And Output    oc get user ${username} -o jsonpath='{.metadata.uid}'
    IF    ${rc} != 0
        Log    Failed to get user UID for ${username}, guided tour may still appear: ${user_uid}    level=WARN
        RETURN
    END

    Log    Found user UID for ${username}: ${user_uid}

    # Check if the user settings configmap exists
    ${rc}    ${output}=    Run And Return Rc And Output    oc get cm user-settings-${user_uid} -n openshift-console-user-settings -o name

    IF    ${rc} != 0
        Log    User settings configmap does not exist yet, skipping CLI method    level=INFO
        RETURN
    ELSE
        Log    User settings configmap exists, updating guided tour settings...
        # Patch the existing configmap to disable guided tour
        ${rc}    ${output}=    Run And Return Rc And Output    oc patch configmap user-settings-${user_uid} -n openshift-console-user-settings --patch='{"data":{"console.guidedTour":"{\\"admin\\":{\\"completed\\":true},\\"developer\\":{\\"completed\\":true}}"}}'
        IF    ${rc} != 0
            Log    Failed to patch user settings configmap: ${output}    level=WARN
            RETURN
        END
        Log    Successfully updated user settings configmap to disable guided tour
    END

Maybe Skip Tour
    [Documentation]    If we are in the openshift web console, maybe skip the first time
    ...    tour popup given to users, otherwise RETURN.
    ...    This function now uses CLI commands to disable the tour proactively if username is provided.
    [Arguments]    ${username}=${EMPTY}

    ${should_cont} =    Does Current Sub Domain Start With    https://console-openshift-console
    IF  ${should_cont}==False
        RETURN
    END

    # Try to disable the tour via CLI first (more reliable) if username is provided
    IF    "${username}" != "${EMPTY}"
        Log    Attempting to disable guided tour via CLI for user: ${username}
        Disable Guided Tour Via CLI    ${username}
        # Give the console a moment to pick up the configuration change and reload page
        Sleep    3s
        Reload Page
        Wait Until OpenShift Console Is Loaded
    ELSE
        Log    No username provided, skipping CLI method and using UI fallback only
    END

    # Fallback: still check for modal in case CLI approach didn't work or username not provided
    ${MODAL_GUIDED_TOUR_XPATH} =  Set Variable  xpath=//div[@id='guided-tour-modal']
    ${tour_modal} =  Run Keyword And Return Status  Wait Until Page Contains Element  ${MODAL_GUIDED_TOUR_XPATH}  timeout=5s
    IF  ${tour_modal}
        Log    Guided tour modal still appeared, attempting to close via UI
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
            Capture Page Screenshot
            Fail  Unexpected Guided tour modal window, please check and update the implementation.
        END
    ELSE
        Log    No guided tour modal detected, CLI disabling was successful or not needed
    END

Get OpenShift Version
    [Documentation]   Get the installed openshitf version on the cluster.
    ${data}=   Oc Get    kind=ClusterVersion
    ${version}=   Split String From Right    ${data[0]['status']['desired']['version']}      .    1
    RETURN     ${version[0]}
