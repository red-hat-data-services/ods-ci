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
${ACCELERATOR_NAME}=    //input[@id="accelerator-name"]
${ACCELERATOR_IDENTIFIER}=    //input[@id="accelerator-identifier"]
${ACCELERATOR_DESCRIPTION}=    //textarea[@id="accelerator-description"]
${ACCELERATOR_ENABLED_SWITCH}=    //input[@id="accelerator-enabled"]/following-sibling::span
${ACCELERATOR_ADD_TOLERATION_BTN}=    //button[@data-testid="add-toleration-button"]
${CREATE_ACCELERATOR_PROFILE_DETAIL_BTN}=    //button[@id="create-button"]

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

Click On Create Accelerator profile button
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

Create An Accelerator Profile using values
    [Documentation]    Fill Accelerator Profile values with the ones provided in the arguments and click on
    ...                create button
    ...                view: Create Accelerator profile
    [Arguments]   ${name}  ${identifier}  ${description}=${EMPTY}  ${enabled}=True
    ...           ${tolerations}=${EMPTY}

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
    # TODO: Tolerations
    Click Button    ${CREATE_ACCELERATOR_PROFILE_DETAIL_BTN}

In The Accelerator Profiles Grid There Is An Accelerator Profile With Name
    [Documentation]    Verify that there is an specific Accelerator Profile in the Grid
    ...                view: Settings -> Accelerator profiles
    [Arguments]   ${name}

    Wait Until Element Is Visible   //table[@id='accelerator-profile-table']//td[@data-label='Name']//span[text()='${name}']  timeout=10

Verify Accelerator Profile Values
    [Documentation]  Verifies that an specific Accelerator Profile exists, and it's value match with the expected
    [Arguments]   ${name}  ${identifier}  ${description}=${EMPTY}  ${enabled}=True
    ...           ${tolerations}=${EMPTY}  ${ns}=redhat-ods-applications

    ${ap_from_oc}=    Run     oc get acceleratorprofile -n ${ns} -o json | jq '.items[] | select(.spec.displayName == "${name}")'
    ${ap_json}=    Load Json String    ${ap_from_oc}
    ${ap_spec_dict}=    Get From Dictionary    ${ap_json}    spec
    ${name_from_spec}=    Get From Dictionary    ${ap_spec_dict}    displayName
    ${enabled_from_spec}=    Get From Dictionary    ${ap_spec_dict}    enabled
    ${identifier_from_spec}=    Get From Dictionary    ${ap_spec_dict}    identifier
    ${tolerations_from_spec}=    Get From Dictionary    ${ap_spec_dict}    tolerations
    ${bool_enabled}=    Convert To Boolean    ${enabled}
    Should Be Equal    ${name_from_spec}    ${name}
    Should Be Equal    ${identifier_from_spec}    ${identifier}
    Should Be Equal    ${enabled_from_spec}    ${bool_enabled}
    IF    "${description}" != "${EMPTY}"
        ${description_from_spec}=    Get From Dictionary    ${ap_spec_dict}    description
        Should Be Equal    ${description_from_spec}    ${description}
    END
    # TODO: Tolerations

Delete All Accelerator Profiles Which Starts With
    [Documentation]    Delete all accelerator profiles given prefix. That prefix should match with the metadata.name
    ...                value of the OC Accelerator Profile resource
    ...                Uses OC
    [Arguments]   ${ap_prefix}  ${ns}=redhat-ods-applications

    ${ap_str} =    Run     oc get acceleratorprofiles -n ${ns} -o json | jq .items[].metadata.name | grep ${ap_prefix} | tr -d '"'
    @{ap_list}=    Split String    ${ap_str}    separator=\n
    Log     List of Accelerator Profiles to be deleted: @{ap_list}    console=yes
    FOR    ${ap_name}    IN    @{ap_list}
        ${return_code}    ${output}    Run And Return Rc And Output
        ...    oc delete acceleratorprofile ${ap_name} -n ${ns}
        Should Be Equal As Integers  ${return_code}   0   msg=Error deleting Accelerator profile ${ap_name}
    END
