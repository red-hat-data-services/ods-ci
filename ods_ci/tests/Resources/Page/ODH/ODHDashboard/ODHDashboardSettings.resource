*** Settings ***
Library         Collections
Library         OpenShiftLibrary
Resource        ../../LoginPage.robot
Resource        ../../ODH/JupyterHub/LoginJupyterHub.robot
Resource        ../../../ODS.robot


*** Variables ***
${TOLERATION_CHECKBOX}=    //input[@id="tolerations-enabled-checkbox"]
${GROUP_BTN_XP}=    //button[@aria-label="Clear input value"]
${SINGLE_MODE_SERVING_CHECK_BOX}=   //input[@id="single-model-serving-platform-enabled-checkbox"]
${MULTI_MODEL_SERVING_CHECK_BOX}=   //input[@id="multi-model-serving-platform-enabled-checkbox"]
${CUSTOM_EMPTY_GROUP}=    empty-group
${ADMIN_GROUPS_SECTION}=    //div[@data-testid="data-science-administrator-groups"]
${ADMIN_GROUPS_LIST}=    ${ADMIN_GROUPS_SECTION}//div[@role="group" and @aria-label="Current selections"]
${USER_GROUPS_SECTION}=    //div[@data-testid="data-science-user-groups"]
${USER_GROUPS_LIST}=    ${USER_GROUPS_SECTION}//div[@role="group" and @aria-label="Current selections"]
${SAVE_BUTTON}=    //button[contains(., "Save changes")]

*** Keywords ***
Add OpenShift Groups To Data Science Administrators
    [Documentation]  Add OpenShift Groups to Data Science administrators From RHODS Dashboard.
    ...    On >=3.5 uses data-testid selectors for the table-based UI; on <=3.4 uses
    ...    multi-select dropdown with PR3160-compatible partial aria-label match.
    ...    This keyword is additive: it adds groups without removing existing ones.
    [Arguments]     @{admin_groups}
    ${is_35}=    Is RHODS Version Greater Or Equal Than    3.5.0
    IF    ${is_35}
        FOR    ${group}    IN    @{admin_groups}
            Add Group In Section    ${ADMIN_GROUPS_SECTION}    ${group}
        END
    ELSE
        Click Button    ${ADMIN_GROUPS_SECTION}//button[contains(@aria-label, "Select the groups that contain all")]
        FOR    ${group}    IN    @{admin_groups}
            ${present}=    Run Keyword And Return Status    Element Should Be Visible
            ...    ${ADMIN_GROUPS_SECTION}//div[@data-testid="group-setting-select"]//ul//*[text()="${group}"]
            IF    not ${present}
                Click Element    //li[@data-testid="select-multi-typeahead-${group}"]/button
            END
        END
        Press Keys    None    ESC
    END

Add OpenShift Groups To Data Science User Groups
    [Documentation]  Add OpenShift Groups to Data Science User From RHODS Dashboard.
    ...    On >=3.5 uses data-testid selectors for the table-based UI; on <=3.4 uses
    ...    multi-select dropdown with PR3160-compatible partial aria-label match.
    ...    This keyword is additive: it adds groups without removing existing ones.
    [Arguments]     @{user_groups}
    ${is_35}=    Is RHODS Version Greater Or Equal Than    3.5.0
    IF    ${is_35}
        FOR    ${group}    IN    @{user_groups}
            Add Group In Section    ${USER_GROUPS_SECTION}    ${group}
        END
    ELSE
        Click Button    ${USER_GROUPS_SECTION}//button[contains(@aria-label, "Select the groups that contain all")]
        FOR    ${group}    IN    @{user_groups}
            ${present}=    Run Keyword And Return Status    Element Should Be Visible
            ...    ${USER_GROUPS_SECTION}//div[@data-testid="group-setting-select"]//ul//*[text()="${group}"]
            IF    not ${present}
                Click Element    //li[@data-testid="select-multi-typeahead-${group}"]/button
            END
        END
        Press Keys    None    ESC
    END

Launch Dashboard And Check User Management Option Is Available For The User
    [Documentation]  Login To Dashboard And Check User Management Option Availablity.
    ...   For Non-Admin Users The 'Menu > Settings' Should Be Unavailable (${FALSE}).
    [Arguments]    ${username}  ${password}  ${auth_type}  ${settings_should_be}=${TRUE}
    Launch Dashboard    ocp_user_name=${username}  ocp_user_pw=${password}  ocp_user_auth_type=${auth_type}
    ...    dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    Verify Service Account Authorization Not Required
    IF    ${settings_should_be}
        # Wait up to 2 minutes as a workaround for bug RHOAIENG-11116
        Menu.Navigate To Page    Settings    User management    timeout=2m
        ${is_35}=    Is RHODS Version Greater Or Equal Than    3.5.0
        IF    ${is_35}
            Wait Until Element Is Visible
            ...    ${ADMIN_GROUPS_SECTION}//button[@data-testid="add-group-button"]    timeout=10s
        ELSE
            Wait Until Element Is Visible
            ...    ${ADMIN_GROUPS_SECTION}//button[contains(@aria-label, "Select the groups that contain all")]    timeout=10s
        END
    ELSE
        Verify Cluster Settings Is Not Available
    END

Remove OpenShift Groups From Data Science User Groups
    [Documentation]   Remove OpenShift Groups From Data Science User Groups From Dashboard
    [Arguments]   @{user_groups}
    FOR    ${group}    IN    @{user_groups}
        ${group_exists}=    Run Keyword And Return Status
        ...    Wait Until Element Is Visible    ${USER_GROUPS_LIST}//*[.="${group}"]    timeout=10s
        IF    ${group_exists}    Click Button
        ...    ${USER_GROUPS_LIST}//*[.="${group}"]/following::button[@aria-label="close"]
    END
    Press Keys    None    ESC

Remove OpenShift Groups From Data Science Administrator Groups
    [Documentation]  Remove OpenShift Groups From Data Science Administrator Groups From Dashboard
    [Arguments]     @{admin_groups}
    FOR    ${group}    IN    @{admin_groups}
        ${group_exists}=    Run Keyword And Return Status
        ...    Wait Until Element Is Visible    ${ADMIN_GROUPS_LIST}//*[.="${group}"]    timeout=10s
        IF    ${group_exists}    Click Button
        ...    ${ADMIN_GROUPS_LIST}//*[.="${group}"]/following::button[@aria-label="close"]
    END
    Press Keys    None    ESC

Save Changes In User Management Setting
    [Documentation]  Save User Management Settings In Dashboard. On RHOAI >=3.5 the
    ...    User Management page auto-saves each change; this keyword returns early when
    ...    on that page. On <=3.4 or Cluster settings the Save button is clicked as before.
    [Arguments]    ${timeout}=3s
    Press Keys    None    ESC
    # On >=3.5 User Management page there is no Save button (changes auto-save per action).
    # Detect by version AND the User Management section sentinel element.
    ${is_35}=    Is RHODS Version Greater Or Equal Than    3.5.0
    ${on_user_mgmt}=    Run Keyword And Return Status
    ...    Page Should Contain Element    ${ADMIN_GROUPS_SECTION}
    IF    ${is_35} and ${on_user_mgmt}    RETURN
    Scroll Element Into View    ${SAVE_BUTTON}
    ${button_enabled}=    Run Keyword And Return Status
    ...    Wait Until Element Is Enabled    ${SAVE_BUTTON}
    IF    ${button_enabled}
        Click Button    ${SAVE_BUTTON}
    END

AdminGroups In OdhDashboardConfig CRD Should Be
    [Documentation]  Verify OdhDashboardConfig Admin Groups include '${UIadminGroupsList}'
    [Arguments]  @{UIadminGroupsList}
    ${dashnoardConfig}   Oc Get   kind=OdhDashboardConfig   namespace=${APPLICATIONS_NAMESPACE}  field_selector=metadata.name=odh-dashboard-config
    ${adminGroups}  Set Variable  ${dashnoardConfig[0]["spec"]["groupsConfig"]["adminGroups"]}
    @{adminGroupsList}  Split String  ${adminGroups}  ,
    Lists Should Be Equal    ${UIadminGroupsList}  ${adminGroupsList}    ignore_order=True

AllowedGroups In OdhDashboardConfig CRD Should Be
    [Documentation]  Verify OdhDashboardConfig Allowed Groups include '${UIallowedGroupList}'
    [Arguments]   @{UIallowedGroupList}
    ${dashnoardConfig}   Oc Get   kind=OdhDashboardConfig   namespace=${APPLICATIONS_NAMESPACE}  field_selector=metadata.name=odh-dashboard-config
    ${allowedGroups}  Set Variable  ${dashnoardConfig[0]["spec"]["groupsConfig"]["allowedGroups"]}
    @{allowedGroupsList}  Split String  ${allowedGroups}  ,
    Lists Should Be Equal    ${UIallowedGroupList}  ${allowedGroupsList}    ignore_order=True

Clear User Management Settings
    [Documentation]  Clear all groups from User Management Settings. On RHOAI >=3.5 the
    ...    table-based UI enforces a minimum of 1 group per section, making full clear
    ...    impossible. Use 'Set Exact Data Science Administrator/User Groups' instead.
    ${is_35}=    Is RHODS Version Greater Or Equal Than    3.5.0
    IF    ${is_35}
        Fail    Clear is not supported on >=3.5 (minimum 1 group per section). Use Set Exact Data Science Administrator/User Groups.    # robocop: disable: line-too-long
    END
    @{remove_users_list}=    Get Webelements    ${GROUP_BTN_XP}
    FOR    ${user}    IN    @{remove_users_list}
        Click Button    ${GROUP_BTN_XP}
    END

Set Pod Toleration Via UI
    [Documentation]    Sets toleration using admin UI
    [Arguments]    ${toleration}
    Scroll Element Into View    ${TOLERATION_CHECKBOX}
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
    [Documentation]    Clicks on the "Save changes" button in Cluster settings and
    ...    waits until "Cluster settings changes saved" is shown
    Save Changes In User Management Setting
    # New setting applies after a few seconds, empirically >15s.
    # Sleep here to make sure it is applied.
    Sleep  30s

Settings Page Should Be Unavailable
    [Documentation]    Wait up to ${timeout} for the Setting Page to become Unavailable (for non-Admin RHOAI users)
    [Arguments]    ${timeout}=30s
    ${setting_disapeared}=    Set Variable    ${FALSE}
    WHILE   not ${setting_disapeared}    limit=${timeout}
    ...    on_limit_message=Timeout exceeded waiting for Setting Page to become Unavailable
        Reload Page
        Sleep   5s
        ${setting_disapeared}=    Run Keyword And Return Status
        ...    Page Should Contain Element    //div[@data-testid="not-found-page-title"]
    END

Enable "Usage Data Collection"
    [Documentation]    Once in Settings > Cluster settings, enables "Usage Data Collection"
    ${is_data_collection_enabled}=    Run Keyword And Return Status    Checkbox Should Be Selected
    ...    ${USAGE_DATA_COLLECTION_XP}
    Set Test Variable    ${is_data_collection_enabled}    #robocop:disable
    IF    ${is_data_collection_enabled}==False
        Select Checkbox    ${USAGE_DATA_COLLECTION_XP}
        Save Changes In Cluster Settings
    END

Disable "Usage Data Collection"
    [Documentation]    Once in Settings > Cluster settings, disables "Usage Data Collection"
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
    ...    xpath://button[@data-testid="submit-cluster-settings" and not(contains(@class, 'disabled'))]
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
    ...    xpath://button[string()="Settings"]/../section[@hidden]
    IF  ${settings_hidden}==True
        Click Element  xpath://button[string()="Settings"]
    END
    Click Element  xpath://a[.="${settings_page}"]
    IF    "${settings_page}" == "Workbench images"
        ${exp_page_title}=    Set Variable    Workbench images
    ELSE IF     "${settings_page}" == "Cluster settings"
        ${exp_page_title}=    Set Variable    Cluster settings
    ELSE IF     "${settings_page}" == "Serving runtimes"
        ${exp_page_title}=    Set Variable    Serving runtimes
    ELSE IF     "${settings_page}" == "User management"
        ${exp_page_title}=    Set Variable    User management
    END
    Wait For RHODS Dashboard To Load    expected_page=${exp_page_title}
    ...    wait_for_cards=${FALSE}

Get Checkbox State Of Multi Model Serving Platforms
    [Documentation]    Checks if  Multi model serving platform is enabled/checked in Cluster setting
    ${is_checked}=  Run Keyword And Return Status  Checkbox Should Be Selected  ${MULTI_MODEL_SERVING_CHECK_BOX}
    RETURN  ${is_checked}

Get Checkbox State Of Single Model Serving Platforms
    [Documentation]    Checks if  Single model serving platform is enabled/checked in Cluster setting
    ${is_checked}=  Run Keyword And Return Status  Checkbox Should Be Selected  ${SINGLE_MODE_SERVING_CHECK_BOX}
    RETURN  ${is_checked}

Select CheckBox Single Model Serving Platforms
    [Documentation]    Enables Single model serving platform
    Select Checkbox   ${SINGLE_MODE_SERVING_CHECK_BOX}


Select CheckBox Multi Model Serving Platforms
    [Documentation]    Enables Multi Modelserving platforms
    Select Checkbox   ${MULTI_MODEL_SERVING_CHECK_BOX}

Deselect CheckBox Single Model Serving Platforms
    [Documentation]    Disable checkbox Single Modelserving platforms
    Unselect Checkbox   ${SINGLE_MODE_SERVING_CHECK_BOX}

Deselect CheckBox Multi Model Serving Platforms
    [Documentation]    Disable checkbox Multi Modelserving platforms
    Unselect Checkbox   ${MULTI_MODEL_SERVING_CHECK_BOX}

Select Both Model Serving Platforms
    [Documentation]    Enables Multi Modeland Single Modelserving platforms
    Select CheckBox Single Model Serving Platforms
    Select CheckBox Multi Model Serving Platforms

Deselect Both Model Serving Platforms
    [Documentation]    Disbale Multi Modeland Single Modelserving platforms
    Deselect CheckBox Single Model Serving Platforms
    Deselect CheckBox Multi Model Serving Platforms


Check IF Single Model Serving Is Disabled From DSC And Cluster Setting
    [Documentation]    Check single model should be disabled from DSC and dashboard
    Component Should Not Be Enabled  kserve
    ${status}=   Get Checkbox State Of Single Model Serving Platforms
    Should Be Equal As Strings   ${status}   ${FALSE}
    Element Should Be Disabled    ${SINGLE_MODE_SERVING_CHECK_BOX}


Check IF Single Model Serving Is Enabled From DSC And Cluster Setting
    [Documentation]    Check single model should be enabled from DSC and dashboard
    Component Should Be Enabled  kserve
    ${status}=   Get Checkbox State Of Single Model Serving Platforms
    Should Be Equal As Strings   ${status}   ${TRUE}
    Element Should Be Enabled    ${SINGLE_MODE_SERVING_CHECK_BOX}

Set RHODS Admins Group Empty Group
    [Documentation]     Sets the "adminGroups" field in "odh-dashboard-config" ConfigMap
    ...                 to the given empty group (i.e., with no users)
    Set Access Groups Settings    admins_group=${CUSTOM_EMPTY_GROUP}
    ...    users_group=${STANDARD_SYSTEM_GROUP}

Set RHODS Admins Group To system:authenticated    # robocop:disable
    [Documentation]    Sets the "adminGroups" field in "odh-dashboard-config" ConfigMap
    ...    to the system:authenticated group
    Set Access Groups Settings    admins_group=system:authenticated
    ...    users_group=${STANDARD_SYSTEM_GROUP}

Set RHODS Admins Group To Inexistent Group
    [Documentation]    Sets the "adminGroups" field in "odh-dashboard-config" ConfigMap
    ...    to the given inexistent group
    Set Access Groups Settings    admins_group=${CUSTOM_INEXISTENT_GROUP}
    ...    users_group=${STANDARD_SYSTEM_GROUP}

Set RHODS Users Group Empty Group
    [Documentation]    Sets the "allowedGroups" field in "odh-dashboard-config" ConfigMap
    ...    to the given empty group (i.e., with no users)
    Set Access Groups Settings    admins_group=${STANDARD_ADMINS_GROUP}
    ...    users_group=${CUSTOM_EMPTY_GROUP}

Set RHODS Users Group To rhods-users    # robocop:disable
    [Documentation]    Sets the "allowedGroups" field in "odh-dashboard-config" ConfigMap
    ...    to the rhods-users group
    Set Access Groups Settings    admins_group=${STANDARD_ADMINS_GROUP}
    ...    users_group=${STANDARD_USERS_GROUP}

Set RHODS Users Group To Inexistent Group
    [Documentation]    Sets the "allowedGroups" field in "odh-dashboard-config" ConfigMap
    ...    to the given inexistent group
    Set Access Groups Settings    admins_group=${STANDARD_ADMINS_GROUP}
    ...    users_group=${CUSTOM_INEXISTENT_GROUP}
    ${true_status}=  BuiltIn.Convert To Boolean    True
    Should Be Equal    ${status}  ${true_status}
    Element Should Be Enabled    ${MULTI_MODEL_SERVING_CHECK_BOX}

# RHOAI 3.5+ User Management helpers (odh-dashboard rhoai-3.5 verified selectors)

Set Exact Data Science Administrator Groups
    [Documentation]    Set exact administrator groups. Adds desired first, removes extras, asserts.
    [Arguments]    @{desired_groups}
    Set Exact Groups In Section    ${ADMIN_GROUPS_SECTION}    @{desired_groups}

Set Exact Data Science User Groups
    [Documentation]    Set exact user groups. Adds desired first, removes extras, asserts.
    [Arguments]    @{desired_groups}
    Set Exact Groups In Section    ${USER_GROUPS_SECTION}    @{desired_groups}

Set Exact Groups In Section
    [Documentation]    Ensure a 3.5+ section contains exactly the specified groups.
    ...    Adds desired groups first (minimum-1 constraint), then removes extras, then asserts.
    [Arguments]    ${section}    @{desired_groups}
    ${count}=    Get Length    ${desired_groups}
    IF    ${count} == 0
        Fail    msg=Cannot set exact groups: desired list is empty (minimum 1 group per section)
    END
    FOR    ${group}    IN    @{desired_groups}
        Add Group In Section    ${section}    ${group}
    END
    @{current_names}=    Get Group Names In Section    ${section}
    FOR    ${name}    IN    @{current_names}
        ${keep}=    Run Keyword And Return Status
        ...    Should Contain    ${desired_groups}    ${name}
        IF    not ${keep}
            Remove Group From Section    ${section}    ${name}
        END
    END
    @{final_names}=    Get Group Names In Section    ${section}
    Lists Should Be Equal    ${final_names}    ${desired_groups}    ignore_order=${TRUE}
    ...    msg=Exact groups mismatch: wanted ${desired_groups}, got ${final_names}

Add Group In Section
    [Documentation]    Add a single group via 3.5+ UI. Skips if already present.
    [Arguments]    ${section}    ${group}
    @{existing}=    Get Group Names In Section    ${section}
    ${already}=    Run Keyword And Return Status    Should Contain    ${existing}    ${group}
    IF    ${already}    RETURN
    Click Button    ${section}//button[@data-testid="add-group-button"]
    Select And Save Group In Section    ${section}    ${group}

Select And Save Group In Section
    [Documentation]    Type, select, and save a group in an open 3.5+ add-group form.
    [Arguments]    ${section}    ${group}
    Wait Until Element Is Visible    ${section}//input[@role="combobox"]    timeout=10s
    Input Text    ${section}//input[@role="combobox"]    ${group}
    ${option_xp}=    Build Option XPath    ${group}
    Wait Until Element Is Visible    ${option_xp}    timeout=10s
    Click Element    ${option_xp}
    ${save_btn}=    Set Variable    ${section}//button[@data-testid="save-new-group-button"]
    Wait Until Element Is Enabled    ${save_btn}    timeout=5s
    Wait Until Element Is Visible    ${save_btn}\[not(@aria-disabled="true")]    timeout=5s
    Click Button    ${save_btn}
    Wait Until Element Is Not Visible    ${save_btn}    timeout=10s

Remove Group From Section
    [Documentation]    Remove a named group via 3.5+ remove button and confirmation modal.
    ...    Fails if the group is the last remaining one (aria-disabled or HTML disabled).
    [Arguments]    ${section}    ${group}
    ${btn_xp}=    Build Remove Button XPath    ${section}    ${group}
    ${btn_disabled_xp}=    Evaluate    $btn_xp + '[@aria-disabled="true"]'
    Wait Until Element Is Visible    ${btn_xp}    timeout=10s
    Page Should Not Contain Element    ${btn_disabled_xp}
    ...    msg=Cannot remove '${group}': last group in section (minimum 1 required)
    Wait Until Element Is Enabled    ${btn_xp}    timeout=5s
    Click Element    ${btn_xp}
    Wait Until Element Is Visible    //div[@data-testid="remove-group-modal"]    timeout=10s
    Click Button    //button[@data-testid="modal-remove-button"]
    Wait Until Element Is Not Visible    //div[@data-testid="remove-group-modal"]    timeout=10s
    Wait Until Element Is Not Visible    ${btn_xp}    timeout=10s

Get Group Names In Section
    [Documentation]    Return group name strings from a 3.5+ section table.
    [Arguments]    ${section}
    @{name_elements}=    Get WebElements    ${section}//td[@data-label="Name"]//p
    @{names}=    Create List
    FOR    ${elem}    IN    @{name_elements}
        ${text}=    Get Text    ${elem}
        Append To List    ${names}    ${text}
    END
    RETURN    @{names}

Build Option XPath
    [Documentation]    Build XPath for selecting a group option in TypeaheadSelect.
    [Arguments]    ${group}
    ${name_lit}=    Build XPath Literal    ${group}
    ${select_text}=    Evaluate    'Select "' + $group + '"'
    ${select_lit}=    Build XPath Literal    ${select_text}
    RETURN    //li[@role="option"][normalize-space(.)=${name_lit} or normalize-space(.)=${select_lit}]

Build Remove Button XPath
    [Documentation]    Build XPath for a group's remove button with escaped data-testid.
    [Arguments]    ${section}    ${group}
    ${testid_val}=    Evaluate    "remove-group-button " + $group
    ${testid_lit}=    Build XPath Literal    ${testid_val}
    RETURN    ${section}//button[@data-testid=${testid_lit}]

Build XPath Literal
    [Documentation]    Return an XPath string literal with proper quote escaping.
    [Arguments]    ${value}
    ${result}=    Evaluate    "'" + $value + "'" if "'" not in $value else '"' + $value + '"' if '"' not in $value else "concat(" + ",".join(x for i, p in enumerate($value.split("'")) for x in (['"' + chr(39) + '"'] if i else []) + (["'" + p + "'"] if p else [])) + ")"    # robocop: disable=line-too-long
    RETURN    ${result}
