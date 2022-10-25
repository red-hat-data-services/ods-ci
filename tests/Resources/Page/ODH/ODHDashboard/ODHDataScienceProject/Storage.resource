*** Settings ***
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${STORAGE_NAME_INPUT_XP}=          xpath=//input[@name="create-new-storage-name"]
${STORAGE_DESCR_INPUT_XP}=         xpath=//textarea[@name="create-new-storage-description"]
${STORAGE_SIZE_INPUT_XP}=         xpath=//div/input[@aria-label="Input"]
${STORAGE_SIZE_PLUS_BTN_XP}=         xpath=//div/button[@aria-label="Plus"]
${STORAGE_MOUNT_DIR_INPUT_XP}=         xpath=//input[@aria-label="mount-path-folder-value"]
${STORAGE_WRKSP_SELECTOR_XP}=         xpath=//div[contains(@class,"modal")]//div[contains(@class,"pf-c-select")]/ul/li
${STORAGE_ADD_BTN_1_XP}=           xpath=//div[div/h4[@id="storages"]]/div/button[text()="Add storage"]
${STORAGE_ADD_BTN_2_XP}=           xpath=//footer/button[contains(text(), "Add")]

*** Keywords ***
Storage Should Be Listed
    [Arguments]     ${name}   ${description}   ${type}   ${connected_wrksp}
    Run keyword And Continue On Failure     Page Should Contain Element    xpath=//td/h4[text()="${name}"]
    Run keyword And Continue On Failure     Page Should Contain Element    xpath=//td/p[text()="${description}"]
    Run keyword And Continue On Failure     Page Should Contain Element    xpath=//tr[td/h4[text()="${name}"]]/td/p[text()=" ${type}"]
    IF    "${connected_wrksp}" == "${NONE}"
        Run Keyword And Continue On Failure    Page Should Contain Element    xpath=//tr[td/h4[text()="${name}"]]/td[text()="No connections"]
    ELSE
        FOR    ${index}    ${wrksp_title}    IN ENUMERATE    @{connected_wrksp}
            Log    ${index}: ${wrksp_title}
            Run Keyword And Continue On Failure    Page Should Contain Element    xpath=//tr[td/h4[text()="${name}"]]/td/ul/li[text()="${wrksp_title}"]
        END
    END

Storage Size Should Be
    [Documentation]        https://kubernetes.io/docs/reference/kubectl/jsonpath/
    [Arguments]     ${name}      ${size}    ${namespace}
    Click Element    xpath=//tr[td/h4[text()="${name}"]]/td/button[contains(@id,"expand-toggle")]
    Wait Until Element Is Visible    xpath=//tr[@class="pf-c-table__expandable-row pf-m-expanded"]
    Wait Until Page Contains Element    xpath=//tr[@class="pf-c-table__expandable-row pf-m-expanded"]/td/div[strong[text()="Size"]]/div/div[3]
    ${displayed_size}=      Get Text    xpath=//tr[@class="pf-c-table__expandable-row pf-m-expanded"]/td/div[strong[text()="Size"]]/div/div[3]
    Run keyword And Continue On Failure     Should Be Equal As Strings    ${displayed_size}    ${size}Gi
    ${rc}  ${oc_object_size}=    Run And Return Rc And Output   oc get pvc -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${name}")].spec.resources.requests.storage}'
    Run keyword And Continue On Failure     Should Be Equal As Strings    ${oc_object_size}    ${size}Gi
    ${rc}  ${oc_object_size}=    Run And Return Rc And Output   oc get pvc -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${name}")].status.capacity.storage}'
    Run keyword And Continue On Failure     Should Be Equal As Strings    ${oc_object_size}    ${size}Gi

Create PersistenVolume Storage
    [Arguments]    ${name}    ${description}    ${size}    ${connected_wrksp}=${NONE}    ${press_cancel}=${FALSE}
    Click Button    ${STORAGE_ADD_BTN_1_XP}
    Fill In New PV Data    ${name}    ${description}    ${size}    ${connected_wrksp}
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE    
        Wait Until Element Is Enabled    ${STORAGE_ADD_BTN_2_XP}
        Click Button    ${STORAGE_ADD_BTN_2_XP}
    END
    Wait Until Modal Disappears
    Wait Until Project Is Open    project_title=${prj_title}

Fill In New PV Data
    [Arguments]    ${name}    ${description}    ${size}    ${connected_wrksp}=${NONE}
    Wait Until Page Contains Element    ${STORAGE_NAME_INPUT_XP}
    Input Text   ${STORAGE_NAME_INPUT_XP}   ${name}
    Wait Until Page Contains Element    ${STORAGE_DESCR_INPUT_XP}
    Input Text   ${STORAGE_DESCR_INPUT_XP}   ${description}
    Clear Element Text    ${STORAGE_SIZE_INPUT_XP}
    IF    ${size} > 1
        FOR    ${counter}    IN RANGE    1    ${size}
            Click Element    ${STORAGE_SIZE_PLUS_BTN_XP}
        END        
    END
    IF    "${connected_wrksp}" == "${NONE}"
        Log    msg=you are not connecting any workspaces to ${name} PV
    ELSE
        Run Keyword And Continue On Failure    Element Should Be Enabled    xpath=//div[contains(@class,"modal")]//div[contains(@class,"pf-c-select")]
        FOR    ${wrksp_title}    IN    @{connected_wrksp}
            ${mount_dir}=    Set Variable    ${connected_wrksp}[${wrksp_title}]
            Set Connection Between PV And Workspace    ${wrksp_title}    ${mount_dir}
        END
    END
    
Set Connection Between PV And Workspace
    [Arguments]    ${wrksp_title}    ${mount_dir}
    Wait Until Element Is Enabled    xpath=//button[@aria-label="Options menu"]
    Click Element    xpath=//button[@aria-label="Options menu"]
    Wait Until Page Contains Element    ${STORAGE_WRKSP_SELECTOR_XP}/button[text()="${wrksp_title}"]
    Click Element                       ${STORAGE_WRKSP_SELECTOR_XP}/button[text()="${wrksp_title}"]
    Wait Until Page Contains Element    ${STORAGE_MOUNT_DIR_INPUT_XP}
    Input Text    ${STORAGE_MOUNT_DIR_INPUT_XP}    ${mount_dir}
