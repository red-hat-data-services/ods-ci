*** Settings ***
Documentation    Collection of keywords to interact with the administration of Accelerator Profiles
Resource       ../../../Common.robot


*** Variables ***
${CREATE_ACCELERATOR_PROFILE_EMPTY_LIST_BTN}=    //button[@data-id="display-accelerator-modal-button"]
${CREATE_ACCELERATOR_PROFILE_BTN}=    //button[@data-id="create-accelerator-profile"]
${EDIT_ACCELERATOR_PROFILE_BTN}=    //table[@id='accelerator-profile-table']//span[text()='Edit']/ancestor::button
${DELETE_ACCELERATOR_PROFILE_BTN}=    //table[@id='accelerator-profile-table']//span[text()='Delete']/ancestor::button
${ACCELERATOR_PROFILE_GRID_COLUMN_NAME}=    //table[@id='accelerator-profile-table']//td[@data-label='Name']
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
    ODHDashboard.Handle Deletion Confirmation Modal  ${name}    item_type=accelerator profile

Create An Accelerator Profile Via UI
    [Documentation]    Fill Accelerator Profile values with the ones provided in the arguments and click on
    ...                create button
    ...                view: Create Accelerator profile
    [Arguments]   ${name}  ${identifier}  ${description}=${EMPTY}  ${enabled}=True
    ...           ${tolerations}=${EMPTY}  ${tol_operator}=Equal  ${tol_effect}=None  ${tol_key}=key
    ...           ${tol_value}=value  ${tol_seconds}=Forever
    Click On Create Accelerator Profile Button
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

Edit Accelerator Profile
    [Documentation]    Modify Accelerator Profile values with the ones provided in the arguments and click on
    ...                "Update acccelerator profile" button
    ...                view: Edit Accelerator profile
    [Arguments]   ${original_display_name}  ${display_name}=${EMPTY}  ${identifier}=${EMPTY}  ${description}=${EMPTY}
    ...           ${enabled}=${EMPTY}  ${tolerations}=${EMPTY}  ${tol_operator}=${EMPTY}  ${tol_effect}=${EMPTY}
    ...           ${tol_key}=${EMPTY}  ${tol_value}=${EMPTY}  ${tol_seconds}=${EMPTY}
    Click On Edit Accelerator Profile    ${original_display_name}
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
    Click On Edit Accelerator Profile    ${display_name}
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
