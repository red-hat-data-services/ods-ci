*** Settings ***
Documentation    Collection of keywords to interact with Serving runtimes page
Resource       ../../../Common.robot


*** Variables ***
${ADD_RUNTIME_BTN_XP}=    //button[text()="Add serving runtime"]
${SUBMIT_RUNTIME_BTN_XP}=    //button[text()="Add"]
${UPLOAD_RUNTIME_BTN_XP}=    //button[text()="Upload files"]
${SCRATCH_RUNTIME_BTN_XP}=    //button[text()="Start from scratch"]
${EDITOR_RUNTIME_BTN_XP}=    //div[contains(@class, "odh-dashboard__code-editor")]


*** Keywords ***
Click Add Serving Runtime Template Button
    SeleniumLibrary.Wait Until Page Contains Element    ${ADD_RUNTIME_BTN_XP}
    SeleniumLibrary.Click Element    ${ADD_RUNTIME_BTN_XP}
    Run Keyword And Continue On Failure    SeleniumLibrary.Page Should Contain    Add a serving runtime
    Run Keyword And Continue On Failure    SeleniumLibrary.Page Should Contain    Drag a file here, upload files, or start from scratch.
    Run Keyword And Continue On Failure    SeleniumLibrary.Page Should Contain Element    ${UPLOAD_RUNTIME_BTN_XP}
    Run Keyword And Continue On Failure    SeleniumLibrary.Page Should Contain Element    ${SCRATCH_RUNTIME_BTN_XP}
    Run Keyword And Continue On Failure    SeleniumLibrary.Page Should Contain Element    ${EDITOR_RUNTIME_BTN_XP}
    
Upload Serving Runtime Template
    [Documentation]    Uploads via UI a YAML file containing a custom Serving Runtime definition
    [Arguments]    ${runtime_filepath}
    Click Add Serving Runtime Template Button
    SeleniumLibrary.Click Element   ${UPLOAD_RUNTIME_BTN_XP}
    ${rc}    ${pwd}=    Run And Return Rc And Output    echo $PWD
    Should Be Equal As Integers    ${rc}    ${0}
    SeleniumLibrary.Choose File    ${EDITOR_RUNTIME_BTN_XP}//input[@type="file"]    ${pwd}/${runtime_filepath}
    Run Keyword And Continue On Failure    SeleniumLibrary.Wait Until Page Contains Element    //span[text()="kind"]
    Run Keyword And Continue On Failure    SeleniumLibrary.Wait Until Page Contains Element    //span[text()="ServingRuntime"]
    Submit Serving Runtime Template

Submit Serving Runtime Template
    SeleniumLibrary.Click Element    ${SUBMIT_RUNTIME_BTN_XP}
    Wait For RHODS Dashboard To Load    expected_page=Serving runtimes
    ...    wait_for_cards=${FALSE}

Serving Runtime Template Should Be Listed
    [Arguments]    ${displayed_name}
    Run Keyword And Continue On Failure
    ...    SeleniumLibrary.Wait Until Page Contains Element
    ...    //table//tr/td[@data-label="Name"]//div[text()="${displayed_name}"]
    ...    timeout=10s

Delete Serving Runtime Template
    [Arguments]    ${displayed_name}    ${press_cancel}=${FALSE}
    ODHDashboard.Click Action From Actions Menu    item_title=${displayed_name}
    ...    action=Delete
    Handle Deletion Confirmation Modal    item_title=${displayed_name}    item_type=serving runtime    press_cancel=${press_cancel}

Delete Serving Runtime Template From CLI
    [Arguments]    ${displayed_name}
    ${resource_name}=    Get OpenShift Template Resource Name By Displayed Name
    ...    displayed_name=${displayed_name}
    IF    "${resource_name}" == "${EMPTY}"
        Log   No Templates corresponding to ${displayed_name} Runtime.
    ELSE
        Oc Delete    kind=Template    name=${resource_name}    namespace=${APPLICATIONS_NAMESPACE}
    END

Get OpenShift Template Resource Name By Displayed Name
    [Arguments]    ${displayed_name}
    ${rc}    ${resource_name}=    Run And Return Rc And Output
    ...    oc get templates -ojson -n redhat-ods-applications | jq '.items[] | select(.objects[].metadata.annotations."openshift.io/display-name"=="${displayed_name}") | .metadata.name' | tr -d '"'
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${resource_name}

