*** Settings ***
Library         OpenShiftLibrary
Resource        ../../LoginPage.robot
Resource        ../../ODH/JupyterHub/LoginJupyterHub.robot
Resource        ../../../ODS.robot


*** Variables ***
${TOLERATION_CHECKBOX}=    //input[@id="tolerations-enabled-checkbox"]
${GROUP_BTN_XP}=    //button[@data-ouia-component-id="Remove"]
${SINGLE_MODE_SERVING_CHECK_BOX}=   //input[@id="single-model-serving-platform-enabled-checkbox"]
${MULTI_MODE_SERVING_CHECK_BOX}=   //input[@id="multi-model-serving-platform-enabled-checkbox"]
${CUSTOM_EMPTY_GROUP}=    empty-group
${CREATE_ACCELERATOR_PROFILE_EMPTY_LIST_BTN}=    //button[@data-id="display-accelerator-modal-button"]
${CREATE_ACCELERATOR_PROFILE_BTN}=    //button[@data-id="create-accelerator-profile"]
${EDIT_ACCELERATOR_PROFILE_BTN}=    //table[@id='accelerator-profile-table']//span[text()='Edit']/ancestor::button
${DELETE_ACCELERATOR_PROFILE_BTN}=    //table[@id='accelerator-profile-table']//span[text()='Delete']/ancestor::button
${ACCELERATOR_PROFILE_GRID_COLUMN_NAME}=    //table[@id='accelerator-profile-table']//td[@data-label='Name']
${ACCELERATOR_RESOURCES_DIRPATH}=    ods_ci/tests/Resources/Files/accelerator
${ACCELERATOR_NAME}=    //input[@id="accelerator-name"]
${ACCELERATOR_IDENTIFIER}=    //input[@id="accelerator-identifier"]
${ACCELERATOR_DESCRIPTION}=    //textarea[@id="accelerator-description"]
${ACCELERATOR_ENABLED_SWITCH}=    //input[@id="accelerator-enabled"]/following-sibling::span
${ACCELERATOR_ADD_TOLERATION_BTN}=    //button[@data-testid="add-toleration-button"]
${ACCELERATOR_ADD_TOLERATION_MODAL_FORM}=    //div[contains(@id, "pf-modal-part")]//span[text()="Add toleration"]
${ACCELERATOR_TOLERATION_OPERATOR_DROPDOWN}=    //div[@data-testid="toleration-operator-select"]/button
${CREATE_OR_UPDATE_ACCELERATOR_PROFILE_DETAIL_BTN}=    //button[@id="create-button"]
${ACCELERATOR_TOLERATION_EFFECT_DROPDOWN}=    //label[@for="effect-select"]/parent::*/following::*[1]//button
${ACCELERATOR_TOLERATION_KEY}=    //input[@id='toleration-key']
${ACCELERATOR_TOLERATION_VALUE}=    //input[@id='toleration-value']
${ACCELERATOR_TOLERATION_SECONDS_FOREVER_RADIO}=    //input[@id="forever"]
${ACCELERATOR_TOLERATION_SECONDS_CUSTOM_RADIO}=    //input[@id="custom-value"]
${ACCELERATOR_TOLERATION_SECONDS_CUSTOM_VALUE}=    //div[contains(@class, 'number-input')]//input
${ACCELERATOR_TOLERATION_ADD_OR_UPDATE_BUTTON}=    //button[@data-testid="modal-submit-button"]
${ACCELERATOR_EDIT_NAV_MENU_TOLERATIONS}=    //nav[@aria-label="Jump to section"]//span[text()="Tolerations"]
${ACCELERATOR_EDIT_TOLERATION_KEBAB_BTN}=    //section[@aria-label="Tolerations"]//table//button[@aria-label="Kebab toggle"]
${ACCELERATOR_EDIT_TOLERATION_MODAL_FORM}=    //div[contains(@id, "pf-modal-part")]//span[text()="Edit toleration"]
${ACCELERATOR_DISABLE_MODAL_DISABLE_BUTTON}=    //span[text()='Disable accelerator profile']/ancestor::header/following::footer/button[text()='Disable']
${ACCELERATOR_DELETE_MODAL_DELETE_BUTTON}=    //span[text()='Delete accelerator profile?']/ancestor::header/following::footer/button[text()='Delete']
${ACCELERATOR_DELETE_MODAL_INPUT}=    //input[@id="delete-modal-input"]


*** Keywords ***
Add OpenShift Groups To Data Science Administrators
    [Documentation]  Add OpenShift Groups to Data Science administrators From RHODS Dashboard
    [Arguments]     @{admin_groups}
    Click Button   (//button[@aria-label="Options menu"])[${1}]
    FOR    ${admin_group}    IN    @{admin_groups}
             ${present}=  Run Keyword And Return Status    Element Should Be Visible   //button[@role="option" and text()="${admin_group}" and @aria-selected="true"]
            IF  ${present} != True
                Click Button    //button[@role="option" and text()="${admin_group}"]
            END
    END
    Press Keys    None    ESC

Add OpenShift Groups To Data Science User Groups
    [Documentation]  Add OpenShift Groups to Data Science User From RHODS Dashboard
    [Arguments]     @{user_groups}
    Click Button    (//button[@aria-label="Options menu"])[${2}]

    FOR    ${user_group}    IN    @{user_groups}
            ${present}=  Run Keyword And Return Status
               ...  Element Should Be Visible   //button[@role="option" and text()="${user_group}" and @aria-selected="true"]
             IF  ${present} != True
                Click Element    //button[@role="option" and text()="${user_group}"]
             END
    END
    Press Keys    None    ESC

Open ODS Dashboard With Admin User
    [Documentation]    Opens a browser and logs into ODS Dashboard with a user belonging to the rhods-admins group
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}

Open ODS Dashboard With Non Admin User
    [Documentation]    Opens a browser and logs into ODS Dashboard with a user belonging to the rhods-users group
    Launch Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}

Launch Dashboard And Check User Management Option Is Available For The User
    [Documentation]  Launch Dashboard And Check User Management Option Is
     ...    Available For The User logged in
    [Arguments]   ${username}  ${password}  ${auth_type}
    Launch Dashboard  ocp_user_name=${username}  ocp_user_pw=${password}  ocp_user_auth_type=${auth_type}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    ${authorization_required} =  Is Service Account Authorization Required
    IF  ${authorization_required}  Authorize jupyterhub service account
    Menu.Navigate To Page    Settings    User management
    Wait Until Element Is Visible   //button[@aria-label="Options menu"]  timeout=20

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
    Sleep    120s    reason=Wait for Dashboard to apply the updated configuration...

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
    [Documentation]    Clicks on the "Save changes" button in Cluster settings and
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
    ${is_checked}=  Run Keyword And Return Status  Checkbox Should Be Selected  ${SINGLE_MODEL_SERVING_CHECK_BOX}
    RETURN  ${is_checked}

Click CheckBox Single Model Serving Platforms
    [Documentation]    Enables Single model serving platform
    ${status}=  Get Checkbox State Of Single Modelserving platforms
    IF  "${status}"=="False"
        Select Checkbox   ${SINGLE_MODEL_SERVING_CHECK_BOX}
    END

Click CheckBox Multi Model Serving Platforms
    [Documentation]    Enables Multi Modelserving platforms
    ${status}=  Get Checkbox State Of Multi Modelserving platforms
    IF  "${status}"=="False"
        Select Checkbox   ${MULTI_MODEL_SERVING_CHECK_BOX}
    END

UnClick CheckBox Single Model Serving Platforms
    [Documentation]    Disable checkbox Single Modelserving platforms
    ${status}=  Get Checkbox State Of Single Modelserving platforms
    IF  "${status}"=="True"
        Unselect Checkbox   ${SINGLE_MODEL_SERVING_CHECK_BOX}
    END

UnClick CheckBox Multi Model Serving Platforms
    [Documentation]    Disable checkbox Multi Modelserving platforms
    ${status}=  Get Checkbox State Of Single Modelserving platforms
    IF  "${status}"=="True"
        Unselect Checkbox   ${MULTI_MODEL_SERVING_CHECK_BOX}
    END

Click Both Model Serving Platforms
    [Documentation]    Enables Multi Modeland Single Modelserving platforms
    Click CheckBox Single Model Serving Platforms
    Click CheckBox Multi Model Serving Platforms

UnClick Both Model Serving Platforms
    [Documentation]    Disbale Multi Modeland Single Modelserving platforms
    UnClick CheckBox Single Model Serving Platforms
    UnClick CheckBox Multi Model Serving Platforms

Check IF Single Model Serving Is Disabled From DSC And Cluster Setting
    [Documentation]    Check single model should be disabled from DSC and dashboard
    Component Should Not Be Enabled  kserve
    ${status}=   Get Checkbox State Of Single Model Serving Platforms
    Should Be Equal As Strings    ${status}  False
    Element Should Be Disabled    ${SINGLE_MODEL_SERVING_CHECK_BOX}

Check IF Single Model Serving Is Enabled From DSC And Cluster Setting
    [Documentation]    Check single model should be enabled from DSC and dashboard
    Component Should Be Enabled  kserve
    ${status}=   Get Checkbox State Of Single Model Serving Platforms
    Should Be Equal As Strings   ${status}  True
    Element Should Be Enabled    ${SINGLE_MODEL_SERVING_CHECK_BOX}

Check IF Multi Model Serving IS Disabled From DSC And Cluster Setting
    [Documentation]    Check Multi model should be disabled from DSC and dashboard
    Component Should Not Be Enabled  modelmeshserving
    ${status}=   Get Checkbox State Of Multi Model Serving Platforms
    Should Be Equal As Strings    ${status}  False
    Element Should Be Disabled    ${MULTI_MODEL_SERVING_CHECK_BOX}

Check IF Multi Model Serving IS Enabled From DSC And Cluster Setting
    [Documentation]    Check Multi model should be enabled from DSC and dashboard
    Component Should Be Enabled  modelmeshserving
    ${status}=   Get Checkbox State Of Multi Model Serving Platforms
    Should Be Equal    ${status}  True
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

Click On Create Accelerator Profile Button
    [Documentation]    Click on the "Add new accelerator profile" (when there is none) or
    ...                the "Create accelerator profile" (when there is at least 1
    ...                previously created).
    ...                view: Settings -> Accelerator profiles
    ${empty_list} =  Run Keyword And Return Status    Wait Until Page Contains Element
    ...    ${CREATE_ACCELERATOR_PROFILE_EMPTY_LIST_BTN}  timeout=5s
    IF  ${empty_list}==True
        Click Button   ${CREATE_ACCELERATOR_PROFILE_EMPTY_LIST_BTN}
    ELSE
        Click Button   ${CREATE_ACCELERATOR_PROFILE_BTN}
    END

Click On Edit Accelerator Profile
    [Documentation]    Click on the the 3 dots button and then on the "Edit" button of an specific Accelerator Profile
    ...                from the grid
    ...                view: Settings -> Accelerator profiles
    [Arguments]   ${name}
    Wait Until Page Contains Element    ${ACCELERATOR_PROFILE_GRID_COLUMN_NAME}//*[text()='${name}']/ancestor::tr//button[@aria-label='Kebab toggle']
    Click Button    ${ACCELERATOR_PROFILE_GRID_COLUMN_NAME}//*[text()='${name}']/ancestor::tr//button[@aria-label='Kebab toggle']
    Wait Until Page Contains Element    ${EDIT_ACCELERATOR_PROFILE_BTN}
    Click Button    ${EDIT_ACCELERATOR_PROFILE_BTN}


Click On Enable Accelerator Profile
    [Documentation]    Click on the the Enable switch from an specific Accelerator Profile
    ...                view: Settings -> Accelerator profiles
    [Arguments]   ${name}
    Wait Until Page Contains Element    //input[@id='${name}-enable-switch']/following-sibling::span
    Click Element    //input[@id='${name}-enable-switch']/following-sibling::span

Disable Accelerator Profile
    [Documentation]    Disable an specific Accelerator Profile from the Grid
    ...                view: Settings -> Accelerator profiles
    [Arguments]   ${name}
    Click On Enable Accelerator Profile    ${name}
    Wait Until Page Contains Element    ${ACCELERATOR_DISABLE_MODAL_DISABLE_BUTTON}
    Click Button    ${ACCELERATOR_DISABLE_MODAL_DISABLE_BUTTON}

Delete Accelerator Profile
    [Documentation]    Delete an specific Accelerator Profile from the Grid
    ...                view: Settings -> Accelerator profiles
    [Arguments]   ${name}
    Wait Until Page Contains Element    ${ACCELERATOR_PROFILE_GRID_COLUMN_NAME}//*[text()='${name}']/ancestor::tr//button[@aria-label='Kebab toggle']
    Click Button    ${ACCELERATOR_PROFILE_GRID_COLUMN_NAME}//*[text()='${name}']/ancestor::tr//button[@aria-label='Kebab toggle']
    Wait Until Page Contains Element    ${DELETE_ACCELERATOR_PROFILE_BTN}
    Click Button    ${DELETE_ACCELERATOR_PROFILE_BTN}
    Wait Until Page Contains Element    ${ACCELERATOR_DELETE_MODAL_INPUT}
    Input Text    ${ACCELERATOR_DELETE_MODAL_INPUT}    ${name}
    Click Button    ${ACCELERATOR_DELETE_MODAL_DELETE_BUTTON}

Create An Accelerator Profile Via CLI
    [Documentation]    Create an instance of Accelerator Profile using OC
    [Arguments]   ${name}  ${ns}=redhat-ods-applications
    Run    oc create -f ${ACCELERATOR_RESOURCES_DIRPATH}/${name}.yaml -n ${ns}

Create An Accelerator Profile Via UI
    [Documentation]    Fill Accelerator Profile values with the ones provided in the arguments and click on
    ...                create button
    ...                view: Create Accelerator profile
    [Arguments]   ${name}  ${identifier}  ${description}=${EMPTY}  ${enabled}=True
    ...           ${tolerations}=${EMPTY}  ${tol_operator}=Equal  ${tol_effect}=None  ${tol_key}=key
    ...           ${tol_value}=value  ${tol_seconds}=Forever
    Wait Until Page Contains Element  ${ACCELERATOR_NAME}  timeout=5s
    Input Text    ${ACCELERATOR_NAME}    ${name}
    Input Text    ${ACCELERATOR_IDENTIFIER}    ${identifier}
    IF    "${description}" != "${EMPTY}"
        Input Text    ${ACCELERATOR_DESCRIPTION}    ${description}
    END
    # By default are enabled
    IF  ${enabled} != True
        Click Element    ${ACCELERATOR_ENABLED_SWITCH}
    END
    # Tolerations
    IF    "${tolerations}" != "${EMPTY}"
        Click Button    ${ACCELERATOR_ADD_TOLERATION_BTN}
        Wait Until Element Is Visible    ${ACCELERATOR_ADD_TOLERATION_MODAL_FORM}
        # Select Operator
        Click Button    ${ACCELERATOR_TOLERATION_OPERATOR_DROPDOWN}
        Click Element    //div[@data-testid="toleration-operator-select"]//div[text()="${tol_operator}"]
        # Select Effect
        Click Button    ${ACCELERATOR_TOLERATION_EFFECT_DROPDOWN}
        Click Element    //label[@for="effect-select"]/parent::*/following::div//*[text()="${tol_effect}"]
        # Input Key and value
        Input Text    ${ACCELERATOR_TOLERATION_KEY}    ${tol_key}
        Input Text    ${ACCELERATOR_TOLERATION_VALUE}    ${tol_value}
        # Toleration Seconds
        IF    "${tol_seconds}" != "Forever"
            Click Element    ${ACCELERATOR_TOLERATION_SECONDS_CUSTOM_RADIO}
            Clear element and input text    ${ACCELERATOR_TOLERATION_SECONDS_CUSTOM_VALUE}   ${tol_seconds}
        ELSE
            Click Element    ${ACCELERATOR_TOLERATION_SECONDS_FOREVER_RADIO}
        END
        Click Button    ${ACCELERATOR_TOLERATION_ADD_OR_UPDATE_BUTTON}
    END
    Click Button    ${CREATE_OR_UPDATE_ACCELERATOR_PROFILE_DETAIL_BTN}

Modify The Accelerator Profile
    [Documentation]    Modify Accelerator Profile values with the ones provided in the arguments and click on
    ...                "Update acccelerator profile" button
    ...                view: Edit Accelerator profile
    [Arguments]   ${original_display_name}  ${display_name}=${EMPTY}  ${identifier}=${EMPTY}  ${description}=${EMPTY}
    ...           ${enabled}=${EMPTY}  ${tolerations}=${EMPTY}  ${tol_operator}=${EMPTY}  ${tol_effect}=${EMPTY}
    ...           ${tol_key}=${EMPTY}  ${tol_value}=${EMPTY}  ${tol_seconds}=${EMPTY}
    Wait Until Element Is Visible   //h1[text()="Edit ${original_display_name}"]  timeout=10
    IF    "${display_name}" != "${EMPTY}"
        Clear element and input text    ${ACCELERATOR_NAME}    ${display_name}
    END
    IF    "${identifier}" != "${EMPTY}"
        Clear element and input text    ${ACCELERATOR_IDENTIFIER}    ${identifier}
    END
    IF    "${description}" != "${EMPTY}"
        Clear element and input text    ${ACCELERATOR_DESCRIPTION}    ${description}
    END
    # Click always, as there is no way from the UI to obtain the status of the switch,
    IF    "${enabled}" != "${EMPTY}"
        Click Element    ${ACCELERATOR_ENABLED_SWITCH}
    END
    IF    "${tolerations}" != "${EMPTY}"
        ${first_kebab}=    Catenate    SEPARATOR=    ${ACCELERATOR_EDIT_TOLERATION_KEBAB_BTN}    [1]
        Click Button    ${first_kebab}
        Wait Until Element Is Visible    ${first_kebab}/following::div//span[text()="Edit"]    timeout=10
        Click Element    ${first_kebab}/following::div//span[text()="Edit"]
        Wait Until Element Is Visible    ${ACCELERATOR_EDIT_TOLERATION_MODAL_FORM}    timeout=10
        IF    "${tol_operator}" != "${EMPTY}"
            Click Button    ${ACCELERATOR_TOLERATION_OPERATOR_DROPDOWN}
            Click Element    //div[@data-testid="toleration-operator-select"]//div[text()="${tol_operator}"]
        END
        IF    "${tol_effect}" != "${EMPTY}"
            Click Button    ${ACCELERATOR_TOLERATION_EFFECT_DROPDOWN}
            Click Element    //label[@for="effect-select"]/parent::*/following::div//*[text()="${tol_effect}"]
        END
        IF    "${tol_key}" != "${EMPTY}"
            Clear element and input text    ${ACCELERATOR_TOLERATION_KEY}    ${tol_key}
        END
        IF    "${tol_value}" != "${EMPTY}"
            Clear element and input text    ${ACCELERATOR_TOLERATION_VALUE}    ${tol_value}
        END
        IF    "${tol_seconds}" != "${EMPTY}"
            IF    "${tol_seconds}" != "Forever"
                Click Element    ${ACCELERATOR_TOLERATION_SECONDS_CUSTOM_RADIO}
                Clear element and input text    ${ACCELERATOR_TOLERATION_SECONDS_CUSTOM_VALUE}   ${tol_seconds}
            ELSE
                Click Element    ${ACCELERATOR_TOLERATION_SECONDS_FOREVER_RADIO}
            END
        END
        Click Button    ${ACCELERATOR_TOLERATION_ADD_OR_UPDATE_BUTTON}
    END
    Click Button    ${CREATE_OR_UPDATE_ACCELERATOR_PROFILE_DETAIL_BTN}

Delete Accelerator Profile Tolerations
    [Documentation]    Delete Tolerarions from an Accelerator Profile and click on "Update acccelerator profile" button
    ...                view: Edit Accelerator profile
    [Arguments]   ${display_name}
    Wait Until Element Is Visible    ${ACCELERATOR_EDIT_TOLERATION_KEBAB_BTN}
    Click Element     ${ACCELERATOR_EDIT_NAV_MENU_TOLERATIONS}
    ${tolerations_num}=  Get Element Count  ${ACCELERATOR_EDIT_TOLERATION_KEBAB_BTN}
    FOR    ${counter}    IN RANGE    ${tolerations_num}
        ${kebab_with_index}=    Catenate    SEPARATOR=    ${ACCELERATOR_EDIT_TOLERATION_KEBAB_BTN}    [1]
        Click Button    ${kebab_with_index}
        Wait Until Element Is Visible    ${kebab_with_index}/following::div//span[text()="Delete"]    timeout=10
        Click Element    ${kebab_with_index}/following::div//span[text()="Delete"]
    END
    Click Button    ${CREATE_OR_UPDATE_ACCELERATOR_PROFILE_DETAIL_BTN}

In The Accelerator Profiles Grid There Is An Accelerator Profile With Name
    [Documentation]    Verify that there is an specific Accelerator Profile in the Grid
    ...                view: Settings -> Accelerator profiles
    [Arguments]    ${display_name}
    Wait Until Element Is Visible   ${ACCELERATOR_PROFILE_GRID_COLUMN_NAME}//span[text()='${display_name}']  timeout=10

Get Accelerator Profile Spec Values via CLI
    [Documentation]  Get Spec fields from an specific Accelerator Profile Instance
    [Arguments]   ${display_name}    ${ns}=redhat-ods-applications
    ${ap_from_oc}=    Run     oc get acceleratorprofile -n ${ns} -o json | jq '.items[] | select(.spec.displayName == "${display_name}")'
    ${ap_json}=    Load Json String    ${ap_from_oc}
    ${ap_spec_dict}=    Get From Dictionary    ${ap_json}    spec
    RETURN    ${ap_spec_dict}

Can Not Get Accelerator Profile Via CLI
    [Documentation]  Get Spec fields from an specific Accelerator Profile Instance
    [Arguments]   ${name}    ${ns}=redhat-ods-applications
    ${rc}    ${out}=    Run And Return Rc And Output    oc get acceleratorprofile ${name} -n ${ns}
    Should Be Equal    "${rc}"    "1"
    Should Contain    ${out}    "${name}" not found

Verify Accelerator Profile Values Via CLI
    [Documentation]  Verifies that an specific Accelerator Profile exists, and it's value match with the expected
    [Arguments]   ${name}  ${identifier}=${EMPTY}  ${description}=${EMPTY}  ${enabled}=True
    ...           ${tolerations}=${EMPTY}  ${tol_operator}=Equal  ${tol_effect}=None  ${tol_key}=key
    ...           ${tol_value}=value  ${tol_seconds}=Forever   ${ns}=redhat-ods-applications
    ${ap_spec_dict}=    Get Accelerator Profile Spec Values via CLI    ${name}    ${ns}
    ${name_from_spec}=    Get From Dictionary    ${ap_spec_dict}    displayName
    ${enabled_from_spec}=    Get From Dictionary    ${ap_spec_dict}    enabled
    ${bool_enabled}=    Convert To Boolean    ${enabled}
    Should Be Equal    ${name_from_spec}    ${name}
    Should Be Equal    ${enabled_from_spec}    ${bool_enabled}
    # Identifier
    IF    "${description}" != "${EMPTY}"
        ${identifier_from_spec}=    Get From Dictionary    ${ap_spec_dict}    identifier
        Should Be Equal    ${identifier_from_spec}    ${identifier}
    END
    # Description
    IF    "${description}" != "${EMPTY}"
        ${description_from_spec}=    Get From Dictionary    ${ap_spec_dict}    description
        Should Be Equal    ${description_from_spec}    ${description}
    END
    # Tolerations
    IF    "${tolerations}" != "${EMPTY}"
        ${tolerations_from_spec}=    Get From Dictionary    ${ap_spec_dict}    tolerations
        ${tol_operator_retrieved}=    Get From Dictionary    ${tolerations_from_spec}[0]    operator
        Should Be Equal    ${tol_operator_retrieved}    ${tol_operator}
        ${tol_key_retrieved}=    Get From Dictionary    ${tolerations_from_spec}[0]    key
        Should Be Equal    ${tol_key_retrieved}    ${tol_key}
        ${tol_value_retrieved}=    Get From Dictionary    ${tolerations_from_spec}[0]    value
        Should Be Equal    ${tol_value_retrieved}    ${tol_value}
        # Effect
        ${tol_effect_retrieved}=    Get From Dictionary    ${tolerations_from_spec}[0]    effect
        IF    "${tol_effect}" == "None"
            Should Be Equal    ${tol_effect_retrieved}    ""
        ELSE
            Should Be Equal    ${tol_effect_retrieved}    ${tol_effect}
        END
        # Toleration Seconds
        IF    "${tol_seconds}" != "Forever"
            ${tol_seconds_retrieved}=    Get From Dictionary    ${tolerations_from_spec}[0]    tolerationSeconds
            Should Be Equal    "${tol_seconds_retrieved}"    "${tol_seconds}"
        END
    END

Verify Accelerator Profile has no tolerations Via CLI
    [Documentation]  Verifies that an specific Accelerator Profile exists, and it has no tolerations
    [Arguments]   ${name}    ${ns}=redhat-ods-applications
    ${ap_spec_dict}=    Get Accelerator Profile Spec Values via CLI    ${name}    ${ns}
    ${tolerations_from_spec}=    Get From Dictionary    ${ap_spec_dict}    tolerations
    Should Be Empty    ${tolerations_from_spec}

Delete All Accelerator Profiles Which Starts With
    [Documentation]    Delete all accelerator profiles given prefix. That prefix should match with the metadata.name
    ...                value of the OC Accelerator Profile resource
    ...                Uses OC
    [Arguments]   ${ap_prefix}  ${ns}=redhat-ods-applications
    ${ap_str} =    Run     oc get acceleratorprofiles -n ${ns} -o json | jq .items[].metadata.name | grep ${ap_prefix} | tr -d '"'
    @{ap_list}=    Split String    ${ap_str}    separator=\n
    Log     List of Accelerator Profiles to be deleted: @{ap_list}    console=yes
    FOR    ${ap_name}    IN    @{ap_list}
        ${ap_desc}=    Run    oc get acceleratorprofile ${ap_name} -n ${ns} -o json
        Log     ${ap_desc}    console=yes
        ${return_code}    ${output}    Run And Return Rc And Output
        ...    oc delete acceleratorprofile ${ap_name} -n ${ns}
        Should Be Equal As Integers  ${return_code}   0   msg=Error deleting Accelerator profile ${ap_name}
    END
