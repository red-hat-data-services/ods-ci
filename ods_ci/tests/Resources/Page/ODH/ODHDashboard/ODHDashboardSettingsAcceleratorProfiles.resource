*** Settings ***
Documentation    Collection of keywords to interact with the administration of Accelerator Profiles
Resource       ../../../Common.robot


*** Variables ***
${CREATE_ACCELERATOR_PROFILE_EMPTY_LIST_BTN}=    //button[@data-id="display-accelerator-modal-button"]
${CREATE_ACCELERATOR_PROFILE_BTN}=    //button[@data-id="create-accelerator-profile"]
${EDIT_ACCELERATOR_PROFILE_BTN}=    //table[@id='accelerator-profile-table']//span[text()='Edit']/ancestor::button
${DELETE_ACCELERATOR_PROFILE_BTN}=    //table[@id='accelerator-profile-table']//span[text()='Delete']/ancestor::button
${ACCELERATOR_PROFILE_GRID_COLUMN_NAME}=    //table[@id='accelerator-profile-table']//td[@data-label='Name']
${ACCELERATOR_RESOURCES_DIRPATH}=    ods_ci/tests/Resources/Files/accelerator
${ACCELERATOR_PROFILE_SEARCH_INPUT}=    //input[@aria-label="Search input"]
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
    Search for accelerator profile in grid    ${name}
    ODHDashboard.Click Action From Actions Menu    ${name}    action=Edit

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

Search for accelerator profile in grid
    [Documentation]    Search for and specific Accelerator Profile in the grid
    ...                view: Settings -> Accelerator profiles
    [Arguments]   ${name}
    Wait Until Page Contains Element    ${ACCELERATOR_PROFILE_SEARCH_INPUT}
    Click Element    ${ACCELERATOR_PROFILE_SEARCH_INPUT}
    Clear Element And Input Text    ${ACCELERATOR_PROFILE_SEARCH_INPUT}   ${name}

Delete Accelerator Profile
    [Documentation]    Delete an specific Accelerator Profile from the Grid
    ...                view: Settings -> Accelerator profiles
    [Arguments]   ${name}
    Search for accelerator profile in grid    ${name}
    ODHDashboard.Click Action From Actions Menu    ${name}    action=Delete
    Wait Until Page Contains Element    ${ACCELERATOR_DELETE_MODAL_INPUT}
    Input Text    ${ACCELERATOR_DELETE_MODAL_INPUT}    ${name}
    Click Button    ${ACCELERATOR_DELETE_MODAL_DELETE_BUTTON}

Create An Accelerator Profile Via CLI
    [Documentation]    Create an instance of Accelerator Profile using OC
    [Arguments]   ${name}  ${ns}=redhat-ods-applications
    ${rc}    ${out}    Run And Return Rc And Output   oc create -f ${ACCELERATOR_RESOURCES_DIRPATH}/${name}.yaml -n ${ns}
    Should Be Equal As Integers    ${rc}     0

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
            Clear Element And Input Text    ${ACCELERATOR_TOLERATION_SECONDS_CUSTOM_VALUE}   ${tol_seconds}
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
        Clear Element And Input Text    ${ACCELERATOR_NAME}    ${display_name}
    END
    IF    "${identifier}" != "${EMPTY}"
        Clear Element And Input Text    ${ACCELERATOR_IDENTIFIER}    ${identifier}
    END
    IF    "${description}" != "${EMPTY}"
        Clear Element And Input Text    ${ACCELERATOR_DESCRIPTION}    ${description}
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
            Clear Element And Input Text    ${ACCELERATOR_TOLERATION_KEY}    ${tol_key}
        END
        IF    "${tol_value}" != "${EMPTY}"
            Clear Element And Input Text    ${ACCELERATOR_TOLERATION_VALUE}    ${tol_value}
        END
        IF    "${tol_seconds}" != "${EMPTY}"
            IF    "${tol_seconds}" != "Forever"
                Click Element    ${ACCELERATOR_TOLERATION_SECONDS_CUSTOM_RADIO}
                Clear Element And Input Text    ${ACCELERATOR_TOLERATION_SECONDS_CUSTOM_VALUE}   ${tol_seconds}
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

Verify Accelerator Profile Has No Tolerations Via CLI
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
