*** Settings ***
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


Verify The Resources Are Filtered
    [Documentation]    verified the items, ${index_of_text} is index text appear on resource 0 = title,1=provider,2=tag(like documentation,tutorial)
    [Arguments]    ${selector}    ${list_of_items}    ${index_of_text}=0
    @{items}=    Get WebElements    //div[@class="${selector}"]
    ${actual_n_results}=    Get Length     ${items}
    ${exp_n_results}=       Get Length     ${list_of_items}
    Should Be Equal     ${actual_n_results}     ${exp_n_results}
    FOR    ${item}    IN    @{items}
        @{texts}=    Split String    ${item.text}    \n
        List Should Contain Value    ${list_of_items}    ${texts}[${index_of_text}]
    END

Resource Page Should Contain
    [Arguments]     ${search_term}   ${expected_items}    ${filter}=${NONE}
    IF    filter != None
        Select Checkbox Filter By Label     partial_label=${filter}
    END
    Search Resources    search_term=${search_term}
    Verify The Resources Are Filtered    selector=pf-c-card__title odh-card__doc-title
    ...    list_of_items=${expected_items}

