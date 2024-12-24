*** Settings ***
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
    [Documentation]  Add OpenShift Groups to Data Science administrators From RHODS Dashboard
    [Arguments]     @{admin_groups}
    Click Button   ${ADMIN_GROUPS_SECTION}//button[@aria-label="Select the OpenShift groups that contain all Data Science administrators."]
    FOR    ${group}    IN    @{admin_groups}
        ${present}=    Run Keyword And Return Status    Element Should Be Visible
        ...    ${ADMIN_GROUPS_LIST}//*[text()="${group}"]
        IF    not ${present}
            Click Element    ${ADMIN_GROUPS_SECTION}//*[text()="${group}"]
        END
    END
    Press Keys    None    ESC

Add OpenShift Groups To Data Science User Groups
    [Documentation]  Add OpenShift Groups to Data Science User From RHODS Dashboard
    [Arguments]     @{user_groups}
    Click Button   ${USER_GROUPS_SECTION}//button[@aria-label="Select the OpenShift groups that contain all Data Science users."]
    FOR    ${group}    IN    @{user_groups}
        ${present}=    Run Keyword And Return Status    Element Should Be Visible
        ...    ${USER_GROUPS_LIST}//*[text()="${group}"]
        IF    not ${present}
            Click Element    ${USER_GROUPS_SECTION}//*[text()="${group}"]
        END
    END
    Press Keys    None    ESC

Launch Dashboard And Check User Management Option Is Available For The User
    [Documentation]  Login To Dashboard And Check User Management Option Availablity.
    ...   For Non-Admin Users The 'Menu > Settings' Should Be Unavailable (${FALSE}).
    [Arguments]    ${username}  ${password}  ${auth_type}  ${settings_should_be}=${TRUE}
    Launch Dashboard    ocp_user_name=${username}  ocp_user_pw=${password}  ocp_user_auth_type=${auth_type}
    ...    dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    ${authorization_required}=  Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize jupyterhub service account
    IF    ${settings_should_be}
        # Wait up to 2 minutes as a workaround for bug RHOAIENG-11116
        Menu.Navigate To Page    Settings    User management    timeout=2m
        Wait Until Element Is Visible    //button[@aria-label="Select the OpenShift groups that contain all Data Science administrators."]    timeout=10s
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
    [Documentation]  Save User Management Settings In Dashboard
    [Arguments]    ${timeout}=3s
    Press Keys    None    ESC
    Scroll Element Into View    ${SAVE_BUTTON}
    ${button_enabled}=    Run Keyword And Return Status
    ...    Wait Until Element Is Enabled   ${SAVE_BUTTON}
    IF    ${button_enabled}
        Click Button    ${SAVE_BUTTON}
        Wait Until Keyword Succeeds    30    1
    ...    Wait Until Page Contains    changes saved
    END

AdminGroups In OdhDashboardConfig CRD Should Be
    [Documentation]  Verify Expect Changes Are Present In CRD
    [Arguments]  @{UIadminGroupsList}
    ${dashnoardConfig}   Oc Get   kind=OdhDashboardConfig   namespace=${APPLICATIONS_NAMESPACE}  field_selector=metadata.name=odh-dashboard-config
    ${adminGroups}  Set Variable  ${dashnoardConfig[0]["spec"]["groupsConfig"]["adminGroups"]}
    @{adminGroupsList}  Split String  ${adminGroups}  ,
    Lists Should Be Equal    ${UIadminGroupsList}  ${adminGroupsList}    ignore_order=True

AllowedGroups In OdhDashboardConfig CRD Should Be
    [Documentation]  Verify Expect Changes Are Present In CRD
    [Arguments]   @{UIallowedGroupList}
    ${dashnoardConfig}   Oc Get   kind=OdhDashboardConfig   namespace=${APPLICATIONS_NAMESPACE}  field_selector=metadata.name=odh-dashboard-config
    ${allowedGroups}  Set Variable  ${dashnoardConfig[0]["spec"]["groupsConfig"]["allowedGroups"]}
    @{allowedGroupsList}  Split String  ${allowedGroups}  ,
    Lists Should Be Equal    ${UIadminGroupsList}  ${adminGroupsList}    ignore_order=True

Clear User Management Settings
    [Documentation]  Clear all groups from User Management Settings
    @{remove_users_list}  Get Webelements  ${GROUP_BTN_XP}
    FOR  ${user}   IN   @{remove_users_list}
        Click Button  ${GROUP_BTN_XP}
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
        ${exp_page_title}=    Set Variable    Notebook image settings
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


Check IF Multi Model Serving IS Disabled From DSC And Cluster Setting
    [Documentation]    Check Multi model should be disabled from DSC and dashboard
    Component Should Not Be Enabled  modelmeshserving
    ${status}=   Get Checkbox State Of Multi Model Serving Platforms
    Should Be Equal As Strings    ${status}   ${FALSE}
    Element Should Be Disabled    ${MULTI_MODEL_SERVING_CHECK_BOX}


Check IF Multi Model Serving IS Enabled From DSC And Cluster Setting
    [Documentation]    Check Multi model should be enabled from DSC and dashboard
    Component Should Be Enabled  modelmeshserving
    ${status}=   Get Checkbox State Of Multi Model Serving Platforms
    Should Be Equal    ${status}  ${TRUE}
    Element Should Be Enabled    ${MULTI_MODEL_SERVING_CHECK_BOX}
    Should Be Equal    ${status}  ${True}
    Element Should Be Enabled     ${MULTI_MODEL_SERVING_CHECK_BOX}

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
