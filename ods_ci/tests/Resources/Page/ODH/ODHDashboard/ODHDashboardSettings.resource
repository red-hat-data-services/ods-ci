*** Settings ***
Library         OpenShiftLibrary
Resource        ../../LoginPage.robot
Resource        ../../ODH/JupyterHub/LoginJupyterHub.robot


*** Variables ***
${TOLERATION_CHECKBOX}=    //input[@id="tolerations-enabled-checkbox"]
${GROUP_BTN_XP}=    (//*[@class="pf-c-chip-group"])//*[@class="pf-c-chip__text" ]//following-sibling::button[1]


*** Keywords ***
Add OpenShift Groups To Data Science Administrators
    [Documentation]  Add OpenShift Groups to Data Science administrators From RHODS Dashboard
    [Arguments]     @{admin_groups}
    Click Button   (//button[@class="pf-c-button pf-c-select__toggle-button pf-m-plain"])[${1}]
    FOR    ${admin_group}    IN    @{admin_groups}
             ${present}=  Run Keyword And Return Status    Element Should Be Visible   //*[@class="pf-c-select__menu-item pf-m-selected" and contains(text(), "${admin_group}")]
            IF  ${present} != True
                Click Button    //*[@class="pf-c-select__menu-item"and contains(text(), "${admin_group}")]
            END
    END
    Press Keys    None    ESC

Add OpenShift Groups To Data Science User Groups
    [Documentation]  Add OpenShift Groups to Data Science User From RHODS Dashboard
    [Arguments]     @{user_groups}
    Click Button    (//button[@class="pf-c-button pf-c-select__toggle-button pf-m-plain"])[${2}]

    FOR    ${user_group}    IN    @{user_groups}
            ${present}=  Run Keyword And Return Status
               ...  Element Should Be Visible   //*[@class="pf-c-select__menu-item pf-m-selected" and contains(text(), "${user_group}")]
             IF  ${present} != True
                Click Element    //*[@class="pf-c-select__menu-item"and contains(text(), "${user_group}")]
             END
    END
    Press Keys    None    ESC

Launch Dashboard And Check User Management Option Is Available For The User
    [Documentation]  Launch Dashboard And Check User Management Option Is
     ...    Available For The User logged in
    [Arguments]   ${username}  ${password}  ${auth_type}
    Launch Dashboard  ocp_user_name=${username}  ocp_user_pw=${password}  ocp_user_auth_type=${auth_type}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    ${authorization_required} =  Is Service Account Authorization Required
    IF  ${authorization_required}  Authorize jupyterhub service account
    Menu.Navigate To Page    Settings    User management
    Wait Until Element Is Visible   //*[@class="pf-c-button pf-c-select__toggle-button pf-m-plain"]  timeout=20

Remove OpenShift Groups From Data Science User Groups
    [Documentation]   Remove OpenShift Groups From Data Science User Groups From Dashboard
    [Arguments]   @{user_groups}
    FOR    ${user_group}    IN    @{user_groups}
            Click Element     (//*[@class="pf-c-chip-group"])[${2}]//*[@class="pf-c-chip__text" and contains(text(),"${user_groups}")]//following-sibling::button[${1}]
    END
    Press Keys    None    ESC

Remove OpenShift Groups From Data Science Administrator Groups
    [Documentation]  Remove OpenShift Groups From Data Science Administrator Groups From Dashboard
    [Arguments]     @{admin_groups}
    FOR    ${admin_group}    IN    @{admin_groups}
            Click Button    (//*[@class="pf-c-chip-group"])[${1}]//*[@class="pf-c-chip__text" and contains(text(),"${admin_group}")]//following-sibling::button[${1}]
    END
    Press Keys    None    ESC

Save Changes In User Management Setting
    [Documentation]  Save User Management Settings In Dashboard
    Press Keys    None    ESC
    Click Button    Save changes
    Sleep  60s

AdminGroups In OdhDashboardConfig CRD Should Be
    [Documentation]  Verify Expect Changes Are Present In CRD
    [Arguments]  @{UIadminGroupsList}
    ${dashnoardConfig}   Oc Get   kind=OdhDashboardConfig   namespace=${APPLICATIONS_NAMESPACE}  field_selector=metadata.name=odh-dashboard-config
    ${adminGroups}  Set Variable  ${dashnoardConfig[0]["spec"]["groupsConfig"]["adminGroups"]}
    @{adminGroupsList}  Split String  ${adminGroups}  ,
    Lists Should Be Equal      ${UIadminGroupsList}  ${adminGroupsList}

AllowedGroups In OdhDashboardConfig CRD Should Be
    [Documentation]  Verify Expect Changes Are Present In CRD
    [Arguments]   @{UIallowedGroupList}
    ${dashnoardConfig}   Oc Get   kind=OdhDashboardConfig   namespace=${APPLICATIONS_NAMESPACE}  field_selector=metadata.name=odh-dashboard-config
    ${allowedGroups}  Set Variable  ${dashnoardConfig[0]["spec"]["groupsConfig"]["allowedGroups"]}
    @{allowedGroupsList}  Split String  ${allowedGroups}  ,
    Lists Should Be Equal      ${UIallowedGroupList}  ${allowedGroupsList}

Clear User Management Settings
    [Documentation]  Clear all groups from User Management Settings
    @{remove_users_list}  Get Webelements  ${GROUP_BTN_XP}
    FOR  ${user}   IN   @{remove_users_list}
        Click Button  ${GROUP_BTN_XP}
    END

Set Pod Toleration Via UI
    [Documentation]    Sets toleration using admin UI
    [Arguments]    ${toleration}
    Wait Until Page Contains Element    xpath:${TOLERATION_CHECKBOX}
    Sleep  2s
    ${selected} =    Run Keyword And Return Status    Checkbox Should Be Selected    xpath:${TOLERATION_CHECKBOX}
    IF  not ${selected}
        Click Element    xpath:${TOLERATION_CHECKBOX}
    END
    Wait Until Element Is Enabled    xpath://input[@id="toleration-key-input"]
    Input Text    xpath://input[@id="toleration-key-input"]    ${toleration}

Disable Pod Toleration Via UI
    [Documentation]    Disable toleration using admin UI
    Wait Until Page Contains Element    xpath:${TOLERATION_CHECKBOX}
    Sleep  2s
    ${selected} =    Run Keyword And Return Status    Checkbox Should Be Selected    xpath:${TOLERATION_CHECKBOX}
    IF  ${selected}
        Click Element    xpath:${TOLERATION_CHECKBOX}
    END
    Element Should Be Disabled    xpath://input[@id="toleration-key-input"]

Save Changes In Cluster Settings
    [Documentation]    Clicks on the "Save changes" button in Cluster Settings and
    ...    waits until "Cluster settings changes saved" is shown
    Wait Until Page Contains Element    xpath://button[.="Save changes"][@aria-disabled="false"]    timeout=15s
    Click Button    Save changes
    ${clicked}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element    xpath://button[.="Save changes"][@aria-disabled="true"]
    IF    ${clicked} == ${FALSE}
        Capture Page Screenshot
        Click Button    Save changes
    END
    Wait Until Keyword Succeeds    30    1
    ...    Wait Until Page Contains    Cluster settings changes saved
    # New setting applies after a few seconds, empirically >15s.
    # Sleep here to make sure it is applied.
    Sleep  30s

Enable "Usage Data Collection"
    [Documentation]    Once in Settings > Cluster Settings, enables "Usage Data Collection"
    ${is_data_collection_enabled}=    Run Keyword And Return Status    Checkbox Should Be Selected
    ...    ${USAGE_DATA_COLLECTION_XP}
    Set Test Variable    ${is_data_collection_enabled}    #robocop:disable
    IF    ${is_data_collection_enabled}==False
        Select Checkbox    ${USAGE_DATA_COLLECTION_XP}
        Save Changes In Cluster Settings
    END

Disable "Usage Data Collection"
    [Documentation]    Once in Settings > Cluster Settings, disables "Usage Data Collection"
    ${is_data_collection_enabled}=    Run Keyword And Return Status    Checkbox Should Be Selected
    ...    ${USAGE_DATA_COLLECTION_XP}
    Set Test Variable    ${is_data_collection_enabled}    #robocop:disable
    IF    ${is_data_collection_enabled}==True
        Unselect Checkbox    ${USAGE_DATA_COLLECTION_XP}
        Save Changes In Cluster Settings
    END

Set PVC Value In RHODS Dashboard
    [Documentation]    Change the default value for PVC
    ...    only whole number is selected
    [Arguments]    ${size}
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains Element  xpath://input[@id="pvc-size-input"]  timeout=30
    Input Text    //input[@id="pvc-size-input"]    ${size}
    Save Changes In Cluster Settings

Restore PVC Value To Default Size
    [Documentation]    Set the PVC value to default
    ...    value i.e., 20Gi
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains Element  xpath://input[@id="pvc-size-input"]  timeout=30
    Click Button    Restore Default
    Save Changes In Cluster Settings

Set Notebook Culler Timeout
    [Documentation]    Modifies the notebook culler timeout using the dashboard UI setting it to ${new_timeout} seconds
    [Arguments]    ${new_timeout}
    ${hours}  ${minutes} =  Convert To Hours And Minutes  ${new_timeout}
    Sleep  5
    ${disabled_field} =  Run Keyword And Return Status    Page Should Contain Element
    ...    xpath://input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==True
        Click Element  xpath://input[@id="culler-timeout-limited"]
    END
    Input Text  //input[@id="hour-input"]  ${hours}
    Input Text  //input[@id="minute-input"]  ${minutes}
    Sleep  0.5s
    ${changed_setting} =  Run Keyword And Return Status    Page Should Contain Element
    ...    xpath://button[.="Save changes"][@aria-disabled="false"]
    IF  ${changed_setting}==True
        Save Changes In Cluster Settings
    END

Disable Notebook Culler
    [Documentation]    Disables the culler (i.e. sets the default timeout of 1 year)
    Open Dashboard Settings    settings_page=Cluster settings
    Sleep  5
    ${disabled_field} =  Run Keyword And Return Status  Page Should Contain Element
    ...    xpath://input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==False
        Click Element  xpath://input[@id="culler-timeout-unlimited"]
        Save Changes In Cluster Settings
    END

Modify Notebook Culler Timeout
    [Documentation]    Modifies the culler timeout via UI
    [Arguments]    ${new_timeout}
    Open Dashboard Settings    settings_page=Cluster settings
    Set Notebook Culler Timeout  ${new_timeout}
    Sleep  10s  msg=Give time for rollout

Open Dashboard Settings
    [Documentation]    Opens the RHODS dashboard and navigates to the Cluster settings page
    [Arguments]    ${settings_page}
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Sleep  1s
    ${settings_hidden} =  Run Keyword And Return Status  Page Should Contain Element
    ...    xpath://section[@aria-labelledby="settings"][@hidden=""]
    IF  ${settings_hidden}==True
        Click Element  xpath://button[@id="settings"]
    END
    Click Element  xpath://a[.="${settings_page}"]
    IF    "${settings_page}" == "Notebook images"
        ${exp_page_title}=    Set Variable    Notebook images settings
    ELSE IF     "${settings_page}" == "Cluster settings"
        ${exp_page_title}=    Set Variable    Cluster Settings
    ELSE IF     "${settings_page}" == "Serving runtimes"
        ${exp_page_title}=    Set Variable    Serving runtimes
    ELSE IF     "${settings_page}" == "User management"
        ${exp_page_title}=    Set Variable    User and group settings
    END
    Wait For RHODS Dashboard To Load    expected_page=${exp_page_title}
    ...    wait_for_cards=${FALSE}
