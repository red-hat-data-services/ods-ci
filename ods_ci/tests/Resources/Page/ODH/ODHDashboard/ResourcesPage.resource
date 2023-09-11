*** Settings ***
Resource    ../../OCPDashboard/InstalledOperators/InstalledOperators.robot
Library     SeleniumLibrary
Library     Collections
Library     String


*** Variables ***
${XP_SEARCH_BAR}=    //input[@aria-label='Search input']


*** Keywords ***
Select Checkbox Using Id
    [Documentation]    Select check-box
    [Arguments]    ${id}
    Select Checkbox    id=${id}
    sleep    1s

Deselect Checkbox Using Id
    [Documentation]    Deselect check-box
    [Arguments]    ${id}
    Unselect Checkbox    id=${id}
    sleep    1s

Select Checkbox Filter By Label
    [Arguments]     ${partial_label}
    ${checkboxes}=      Get Webelements    xpath=//input[contains(@title, '${partial_label}')]
    FOR    ${index}    ${checkbox}    IN ENUMERATE    @{checkboxes}
        ${id}=   Get Element Attribute    ${checkbox}     id
        Select Checkbox Using Id    id=${id}
    END

Search Resources
    [Arguments]     ${search_term}
    Wait Until Page Contains Element    xpath=${XP_SEARCH_BAR}
    Input Text    xpath=${XP_SEARCH_BAR}   text=${search_term}

Number Of Items Should Be
    [Documentation]    Checks if the page contain the expected number of items.
    ...                Returns the list of items (webElements) plus the actual number
    [Arguments]    ${expected_number}
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.21.0
    IF  ${version_check}==True
        ${versioned_title_xp}=    Set Variable    //div[@class="pf-c-card__title"]/div[@class="pf-c-content"]
    ELSE
        ${versioned_title_xp}=    Set Variable    //div[@class="pf-c-card__title odh-card__doc-title"]
    END
    @{items}=    Get WebElements    ${versioned_title_xp}
    ${actual_n_results}=    Get Length     ${items}
    Run Keyword And Continue On Failure    Should Be Equal As Integers     ${actual_n_results}     ${expected_number}
    RETURN    ${items}    ${actual_n_results}

Verify The Resources Are Filtered
    [Documentation]    verified the items, ${index_of_text} is index text appear on resource 0 = title,1=provider,2=tag(like documentation,tutorial)
    [Arguments]    ${list_of_items}=${NONE}
    ...            ${expected_types}=${NONE}    ${expected_providers}=${NONE}
    ...            ${expected_number}=${NONE}
    IF    "${list_of_items}" != "${NONE}"
        ${exp_n_results}=       Get Length     ${list_of_items}
    ELSE
        ${exp_n_results}=    Set Variable    ${expected_number}
    END
    ${items}   ${_}=    Number Of Items Should Be    expected_number=${exp_n_results}
    FOR    ${item}    IN    @{items}
        @{texts}=    Split String    ${item.text}    \n
        IF    "${list_of_items}" != "${NONE}"
            Run Keyword And Continue On Failure
            ...    List Should Contain Value    ${list_of_items}    ${texts}[0]    # item title
        END
        IF    "${expected_types}" != "${NONE}"
            ${version_check}=  Is RHODS Version Greater Or Equal Than  1.21.0
            IF  ${version_check}==True
                ${versioned_type}=    Get Text    xpath=//ul[@aria-label='Label group category']/li[1]
            ELSE
                ${versioned_type}=    Set Variable    ${texts}[2]
            END
            Run Keyword And Continue On Failure
            ...    List Should Contain Value    ${expected_types}    ${versioned_type}    # item type
        END
        IF    "${expected_providers}" != "${NONE}"
            Run Keyword And Continue On Failure
            ...    List Should Contain Value    ${expected_providers}    ${texts}[1]    # item provider
        END
    END

Resource Page Should Contain
    [Arguments]     ${search_term}   ${expected_items}    ${filter}=${NONE}
    IF    filter != None
        Select Checkbox Filter By Label     partial_label=${filter}
    END
    Search Resources    search_term=${search_term}
    Verify The Resources Are Filtered    list_of_items=${expected_items}
