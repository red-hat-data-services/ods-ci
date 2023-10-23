*** Settings ***
Documentation    Collection of keywords to interact with Storages
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${STORAGE_SECTION_XP}=             xpath=//div[@id="cluster-storages"]
${STORAGE_NAME_INPUT_XP}=          xpath=//input[@name="create-new-storage-name"]
${STORAGE_DESCR_INPUT_XP}=         xpath=//textarea[@name="create-new-storage-description"]
${STORAGE_SIZE_INPUT_XP}=         xpath=//div/input[contains(@aria-label,"input") or contains(@aria-label,"Input")]
${STORAGE_SIZE_PLUS_BTN_XP}=         xpath=//div/button[@aria-label="Plus"]
${STORAGE_MOUNT_DIR_INPUT_XP}=         xpath=//input[@aria-label="mount-path-folder-value"]
${STORAGE_WORKBENCH_SELECTOR_XP}=         xpath=//div[contains(@class,"modal")]//div[contains(@class,"pf-c-select")]/ul/li
${STORAGE_ADD_BTN_1_XP}=           ${STORAGE_SECTION_XP}//button[.="Add cluster storage"]
${STORAGE_ADD_BTN_2_XP}=           xpath=//footer/button[.="Add storage"]


*** Keywords ***
Storage Should Be Listed
    [Documentation]    Checks storage is listed in DS Project details page
    [Arguments]     ${name}   ${description}   ${type}   ${connected_workbench}
    Run Keyword And Continue On Failure     Wait Until Page Contains Element    ${STORAGE_SECTION_XP}//td[@data-label="Name"]//*/div[text()="${name}"]
    Run Keyword And Continue On Failure     Wait Until Page Contains Element    ${STORAGE_SECTION_XP}//td[@data-label="Name"]/p[text()="${description}"]
    Run Keyword And Continue On Failure     Wait Until Page Contains Element    ${STORAGE_SECTION_XP}//tr[td[@data-label="Name"]//*/div[text()="${name}"]]/td[@data-label="Type"]/p[contains(text(),"${type}")]
    IF    "${connected_workbench}" == "${NONE}"
        Run Keyword And Continue On Failure    Page Should Contain Element    ${STORAGE_SECTION_XP}//tr[td[@data-label="Name"]//*/div[text()="${name}"]]/td[text()="No connections"]
    ELSE
        FOR    ${index}    ${workbench_title}    IN ENUMERATE    @{connected_workbench}
            Run Keyword And Continue On Failure    Page Should Contain Element    ${STORAGE_SECTION_XP}//tr[td[@data-label="Name"]//*/div[text()="${name}"]]/td[@data-label="Connected workbenches"]/ul/li[text()="${workbench_title}"]
        END
    END

Storage Should Not Be Listed
    [Documentation]    Checks storage is not listed in DS Project details page
    [Arguments]     ${name}
    Run Keyword And Continue On Failure
    ...    Wait Until Page Does Not Contain Element
    ...    ${STORAGE_SECTION_XP}//tr[td[@data-label="Name"]//*/div[text()="${name}"]]
    ...    timeout=10s

Storage Size Should Be
    [Documentation]    Checks displayed PV size corresponds to PV size in Openshift.
    ...                Query on Openshift annotation based on this syntax: https://kubernetes.io/docs/reference/kubectl/jsonpath/
    [Arguments]     ${name}      ${size}    ${namespace}
    Run Keyword And Continue On Failure     Wait Until Page Contains Element    ${STORAGE_SECTION_XP}
    Click Element    ${STORAGE_SECTION_XP}//tr[td//*/div[text()="${name}"]]//button[@aria-label="Details"]
    Wait Until Element Is Visible    ${STORAGE_SECTION_XP}//tr[@class="pf-c-table__expandable-row pf-m-expanded"]
    Wait Until Page Contains Element    ${STORAGE_SECTION_XP}//tr[@class="pf-c-table__expandable-row pf-m-expanded"]/td/div[strong[text()="Size"]]/div    timeout=45s
    ${displayed_size}=      Get Text    ${STORAGE_SECTION_XP}//tr[@class="pf-c-table__expandable-row pf-m-expanded"]/td/div[strong[text()="Size"]]/div
    Run Keyword And Continue On Failure     Should Be Equal As Strings    ${displayed_size}    Max ${size}Gi
    ${rc}  ${oc_object_size}=    Run And Return Rc And Output   oc get pvc -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${name}")].spec.resources.requests.storage}'
    Run Keyword And Continue On Failure     Should Be Equal As Strings    ${oc_object_size}    ${size}Gi
    ${rc}  ${oc_object_size}=    Run And Return Rc And Output   oc get pvc -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${name}")].status.capacity.storage}'
    Run Keyword And Continue On Failure     Should Be Equal As Strings    ${oc_object_size}    ${size}Gi

Create PersistentVolume Storage
    [Documentation]    Create a PersistenVolume storage in DS Project details page
    [Arguments]    ${project_title}    ${name}    ${description}    ${size}    ${connected_workbench}=${NONE}    ${press_cancel}=${FALSE}
    Click Button    ${STORAGE_ADD_BTN_1_XP}
    Fill In New PV Data    ${name}    ${description}    ${size}    ${connected_workbench}
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Wait Until Element Is Enabled    ${STORAGE_ADD_BTN_2_XP}
        Click Button    ${STORAGE_ADD_BTN_2_XP}
    END
    Wait Until Generic Modal Disappears
    Wait Until Project Is Open    project_title=${project_title}

Fill In New PV Data
    [Documentation]    Compiles the modal for creating a new PersistenVolume storage in DS Project details page
    [Arguments]    ${name}    ${description}    ${size}    ${connected_workbench}=${NONE}
    ${is_storage_modal}=     Run Keyword And Return Status    Page Should Contain Element     ${STORAGE_ADD_BTN_2_XP}
    Wait Until Page Contains Element    ${STORAGE_NAME_INPUT_XP}
    IF   ${is_storage_modal} == ${TRUE}     Run Keyword And Continue On Failure     Element Should Be Disabled    ${STORAGE_ADD_BTN_2_XP}
    Clear Element Text    ${STORAGE_NAME_INPUT_XP}
    Input Text   ${STORAGE_NAME_INPUT_XP}   ${name}
    Wait Until Page Contains Element    ${STORAGE_DESCR_INPUT_XP}
    IF   ${is_storage_modal} == ${TRUE}    Run Keyword And Continue On Failure     Element Should Be Enabled    ${STORAGE_ADD_BTN_2_XP}
    Input Text   ${STORAGE_DESCR_INPUT_XP}   ${description}
    Clear Element Text    ${STORAGE_SIZE_INPUT_XP}
    IF    ${size} > 1
        FOR    ${counter}    IN RANGE    1    ${size}
            Click Element    ${STORAGE_SIZE_PLUS_BTN_XP}
        END
    END
    IF    "${connected_workbench}" == "${NONE}"
        Log    msg=you are not connecting any workbenchs to ${name} PV
    ELSE
        Run Keyword And Continue On Failure    Element Should Be Enabled    xpath=//div[contains(@class,"modal")]//div[contains(@class,"pf-c-select")]
        FOR    ${workbench_title}    IN    @{connected_workbench}
            ${mount_dir}=    Set Variable    ${connected_workbench}[${workbench_title}]
            Set Connection Between PV And Workbench    ${workbench_title}    ${mount_dir}
            Run Keyword And Continue On Failure     Element Should Be Enabled    ${STORAGE_ADD_BTN_2_XP}
        END
    END

Set Connection Between PV And Workbench
    [Documentation]    Connects a PV to an existent workbench
    [Arguments]    ${workbench_title}    ${mount_dir}
    Wait Until Element Is Enabled    xpath=//button[@aria-label="Options menu"]
    Click Element    xpath=//button[@aria-label="Options menu"]
    Wait Until Page Contains Element    ${STORAGE_WORKBENCH_SELECTOR_XP}/button[text()="${workbench_title}"]
    Click Element                       ${STORAGE_WORKBENCH_SELECTOR_XP}/button[text()="${workbench_title}"]
    Wait Until Page Contains Element    ${STORAGE_MOUNT_DIR_INPUT_XP}
    Run Keyword And Continue On Failure     Element Should Be Disabled    ${STORAGE_ADD_BTN_2_XP}
    Input Text    ${STORAGE_MOUNT_DIR_INPUT_XP}    ${mount_dir}

Delete Storage
    [Documentation]    Deletes a cluster storage from DS Project details page
    [Arguments]     ${name}    ${press_cancel}=${FALSE}
    Workbenches.Click Action From Actions Menu    item_title=${name}    item_type=storage    action=Delete
    Handle Deletion Confirmation Modal    item_title=${name}    item_type=storage    press_cancel=${press_cancel}

Get Openshift PVC From Storage
    [Documentation]    Retrieves the PVC resource name from Openshift given the Displayed Name in DS Project details page
    [Arguments]     ${name}      ${namespace}
    ${rc}  ${pvc_name}=    Run And Return Rc And Output   oc get pvc -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${name}")].metadata.name}'
    RETURN    ${rc}    ${pvc_name}

Delete PVC From CLI
    [Documentation]    Deletes a given PVC from CLI
    [Arguments]    ${pvc_title}    ${project_title}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    ${_}  ${cr_name}=    Get Openshift PVC From Storage
    ...    name=${pvc_title}  namespace=${ns_name}
    Oc Delete    kind=PersistentVolumeClaim   name=${cr_name}   namespace=${ns_name}
