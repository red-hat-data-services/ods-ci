*** Settings ***
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${WORKBENCH_SECTION_XP}=             xpath=//div[div//h4[@id="workbenches"]]
${WORKBENCH_CREATE_BTN_XP}=           xpath=//button[text()="Create workbench"]
${WORKBENCH_CREATE_BTN_2_XP}=         xpath=//button[@id="create-button"]
${WORKBENCH_NAME_INPUT_XP}=               xpath=//input[@name="workbench-name"]
${WORKBENCH_DESCR_TXT_XP}=                xpath=//textarea[@name="workbench-description"]
${WORKBENCH_IMAGE_MENU_BTN_XP}=           xpath=//section[@id="notebook-image"]//button[@aria-label="Options menu"]
${WORKBENCH_IMAGE_ITEM_BTN_XP}=           xpath=//ul[@id="workbench-image-stream-selection"]/li/button
${WORKBENCH_SIZE_MENU_BTN_XP}=           xpath=//section[@id="deployment-size"]//button[@aria-label="Options menu"]
${WORKBENCH_SIZE_ITEM_BTN_XP}=           xpath=//ul[@id="container-size"]/li/button
${WORKBENCH_ADD_VAR_BTN_XP}=           xpath=//button[text()="Add variable"]
${WORKBENCH_STATUS_STOPPED}=                  Stopped
${WORKBENCH_STATUS_RUNNING}=                  Running
${WORKBENCH_STATUS_STARTING}=                 Starting...
${WORKBENCH_STOP_BTN_XP}=                 xpath=//button[text()="Stop workbench"]
&{IMAGE_ID_MAPPING}=                 Minimal Python=s2i-minimal-notebook    CUDA=minimal-gpu   PyTorch=pytorch
...                                  Standard Data Science=s2i-generic-data-science-notebook    TensorFlow=tensorflow
${KEYVALUE_TYPE}=        Key / value


*** Keywords ***
Create Workbench
    [Documentation]     Creates a new workbench in a Data Science project. It assumes
    ...                 the DS Project deta
    [Arguments]     ${workbench_title}  ${workbench_description}  ${prj_title}   ${image_name}   ${deployment_size}
    ...             ${storage}  ${pv_existent}   ${pv_name}  ${pv_description}  ${pv_size}   ${press_cancel}=${FALSE}  ${envs}=${NONE}
    Click Element    ${WORKBENCH_CREATE_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_NAME_INPUT_XP}
    Run Keyword And Continue On Failure     Element Should Be Disabled    ${WORKBENCH_CREATE_BTN_2_XP}
    Input Text    ${WORKBENCH_NAME_INPUT_XP}    ${workbench_title}
    Input Text    ${WORKBENCH_DESCR_TXT_XP}    ${workbench_description}
    Run Keyword And Continue On Failure     Element Should Be Disabled    ${WORKBENCH_CREATE_BTN_2_XP}
    Select Workbench Jupyter Image    image_name=${image_name}
    ## Select Workbench Container Size # to fix, by default Small is already select
    IF    "${envs}" != "${NONE}"
        ${envs_copy}=    Copy List    ${envs}    deepcopy=${TRUE}
        Add Environment Variables In Workbench    env_variables=${envs_copy}
    END
    IF    "${storage}" == "Persistent"
        IF    ${pv_existent} == ${TRUE}
            Click Element    xpath=//input[@name="persistent-existing-storage-type-radio"]
            Select An Existent PV   name=${pv_name}
        ELSE IF   ${pv_existent} == ${FALSE}
            Click Element   xpath=//input[@name="persistent-new-storage-type-radio"]
            Fill In New PV Data    name=${pv_name}    description=${pv_description}  size=${pv_size}
        ELSE
            Log    msg="pv_existent" argument is required when selected storage type is "Persistent"   level=ERROR
        END
    ELSE
        Click Element   xpath=//input[@name="ephemeral-storage-type-radio"]
    END
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Wait Until Element Is Enabled    ${WORKBENCH_CREATE_BTN_2_XP}
        Click Button    ${WORKBENCH_CREATE_BTN_2_XP}
    END
    Wait Until Modal Disappears
    Wait Until Project Is Open    project_title=${prj_title}

Add Environment Variables In Workbench
    [Arguments]    ${env_variables}
    Click Element    ${WORKBENCH_ADD_VAR_BTN_XP}
    ${n_objects}=    Get Length    ${env_variables}
    FOR    ${idx}   ${env_variable}    IN ENUMERATE    @{env_variables}    start=1
        ${k8s__type}=    Set Variable    ${env_variable}[k8s_type]
        ${input_type}=    Set Variable    ${env_variable}[input_type]
        Remove From Dictionary    ${env_variable}     k8s_type    input_type
        Select Environment Variable Types    k8s_type=${k8s__type}    input_type=${input_type}    variable_index=${idx}
        IF    "${input_type}" == "${KEYVALUE_TYPE}"
            ${n_pairs}=    Get Length    ${env_variable.keys()}
            FOR  ${pair_idx}   ${key}  ${value}  IN ENUMERATE  &{env_variable}
                Log   ${pair_idx}-${key}-${value}
                Run Keyword And Continue On Failure    Wait Until Page Contains Element    xpath=//input[@aria-label="key of item ${pair_idx}"]
                Input Text    xpath=//section[@aria-label="Environment variables"]/div[@class="pf-l-split"][${idx}]//input[@aria-label="key of item ${pair_idx}"]    ${key}
                Input Text    xpath=//section[@aria-label="Environment variables"]/div[@class="pf-l-split"][${idx}]//input[@aria-label="value of item ${pair_idx}"]    ${value}
                IF    ${n_pairs}-${pair_idx} > 1
                    Click Element    xpath=//section[@aria-label="Environment variables"]/div[@class="pf-l-split"][${idx}]//button[text()="Add another variable"]
                END
            END      
        END
        IF    ${n_objects}-${idx} > 0
            Click Button    Add more variables
        END
    END

Select Environment Variable Types
    [Arguments]    ${k8s_type}    ${input_type}    ${variable_index}
    Run Keyword And Continue On Failure    Wait Until Page Contains Element    xpath=//section[@aria-label="Environment variables"]/div[@class="pf-l-split"][${variable_index}]//div[@class="pf-l-stack__item"]/div[contains(@class,"pf-c-select")]/button
    Click Element    xpath=//section[@aria-label="Environment variables"]/div[@class="pf-l-split"][${variable_index}]//div[contains(@class,"pf-c-select")]/button
    Wait Until Page Contains Element    xpath=//ul[@role="listbox"]/li/button[text()="${k8s_type}"]
    Click Element    xpath=//ul[@role="listbox"]/li/button[text()="${k8s_type}"]
    Run Keyword And Continue On Failure    Wait Until Page Contains Element    xpath=//section[@aria-label="Environment variables"]//button[div/span[text()="Select one"]]
    Click Element    xpath=//section[@aria-label="Environment variables"]/div[@class="pf-l-split"][${variable_index}]//button[div/span[text()="Select one"]]
    Wait Until Page Contains Element    xpath=//ul[@role="listbox"]/li/button[text()="${input_type}"]
    Click Element    xpath=//ul[@role="listbox"]/li/button[text()="${input_type}"]

Remove All Environment Variables
    ${remove_buttons}=    Get WebElements    xpath=//section[@id="environment-variable"]//button
    FOR    ${rb}    IN    @{remove_buttons}
        Click Element    ${rb}
    END

Select An Existent PV
    [Arguments]    ${name}
    Run Keyword And Continue On Failure    Wait Until Element Is Enabled    xpath=//input[@placeholder="Select a persistent storage"]
    Click Element    xpath=//input[@placeholder="Select a persistent storage"]
    Wait Until Page Contains Element    xpath=//ul/li/button[text()="${name}"]
    Wait Until Page Contains Element    xpath=//div[contains(@class,"pf-c-select")]/ul/li/button[text()="${name}"]
    Click Element   xpath=//ul/li/button[text()="${name}"]

Select Workbench Jupyter Image
    [Arguments]     ${image_name}
    Wait Until Page Contains Element    ${WORKBENCH_IMAGE_MENU_BTN_XP}
    Click Button    ${WORKBENCH_IMAGE_MENU_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_IMAGE_ITEM_BTN_XP}/span[text()="${image_name}"]
    Click Element    ${WORKBENCH_IMAGE_ITEM_BTN_XP}/span[text()="${image_name}"]

Select Workbench Container Size
    [Arguments]     ${size_name}=Small
    Wait Until Page Contains Element    ${WORKBENCH_SIZE_MENU_BTN_XP}
    Click Button    ${WORKBENCH_SIZE_MENU_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_SIZE_ITEM_BTN_XP}/span[text()="${size_name}"]
    Click Element    ${WORKBENCH_SIZE_ITEM_BTN_XP}/span[text()="${size_name}"]

Workbench Should Be Listed
    [Arguments]     ${workbench_title}
    Run keyword And Continue On Failure     Wait Until Page Contains Element    ${WORKBENCH_SECTION_XP}//td[@data-label="Name"]/h4[div[text()="${workbench_title}"]]

Workbench Should Not Be Listed
    [Arguments]     ${workbench_title}
    Run keyword And Continue On Failure     Wait Until Page Does Not Contain Element    ${WORKBENCH_SECTION_XP}//td[@data-label="Name"]/h4[div[text()="${workbench_title}"]]

Workbench Status Should Be
    [Arguments]     ${workbench_title}      ${status}
    Run keyword And Continue On Failure     Page Should Contain Element    ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/h4[div[text()="${workbench_title}"]]]/td[@data-label="Status"]//p[text()="${status}"]

Wait Until Workbench Is Started
    [Arguments]     ${workbench_title}      ${timeout}=30s
    Wait Until Keyword Succeeds    ${timeout}    5s      Workbench Status Should Be      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}

Start Workbench
    [Arguments]     ${workbench_title}
    ${is_stopped}=      Run Keyword And Return Status   Workbench Status Should Be      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_STOPPED}
    IF    ${is_stopped} == ${TRUE}
        Click Element       ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/h4[div[text()="${workbench_title}"]]]/td[@data-label="Status"]//span[@class="pf-c-switch__toggle"]
    ELSE
        Log     msg=Cannot start ${workbench_title} workbench because it is not stopped.
    END
    Wait Until Workbench Is Started     workbench_title=${workbench_title}

Access To Workbench  
    [Arguments]    ${username}=${TEST_USER.USERNAME}  ${password}=${TEST_USER.PASSWORD}  ${auth_type}=${TEST_USER.AUTH_TYPE}
    Switch Window   NEW
    Run Keyword And Warn On Failure   Login To Openshift  ${username}  ${password}  ${auth_type}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
    Maybe Close Popup

Launch Workbench
    [Arguments]     ${workbench_title}
    ${is_started}=      Run Keyword And Return Status   Workbench Status Should Be      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}
    IF    ${is_started} == ${TRUE}
        Click Link       ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/h4[div[text()="${workbench_title}"]]]/td/a[text()="Open"]
        Access To Workbench
    ELSE
        Fail   msg=Cannot launch workbench ${workbench_title} because it is not running...
    END

Stop Workbench
    [Arguments]     ${workbench_title}    ${press_cancel}=${FALSE}
    ${is_started}=      Run Keyword And Return Status   Workbench Status Should Be      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}
    IF    ${is_started} == ${TRUE}
        Click Element       ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/h4[div[text()="${workbench_title}"]]]/td[@data-label="Status"]//span[@class="pf-c-switch__toggle"]
        Wait Until Modal Appears
        Handle Stop Workbench Confirmation Modal    press_cancel=${press_cancel} 
    ELSE
        Fail   msg=Cannot stop workbench ${workbench_title} because it is not running...
    END

Handle Stop Workbench Confirmation Modal
    [Arguments]    ${press_cancel}=${FALSE}
    Run Keyword And Continue On Failure    Page Should Contain    Stop workbench?
    Run Keyword And Continue On Failure    Page Should Contain    Are you sure you want to stop the workbench? Any changes without saving will be erased.
    Run Keyword And Continue On Failure    Page Should Contain    To save changes, access your workbench
    Run Keyword And Continue On Failure    Page Should Contain Element    xpath=//input[@id="dont-show-again"]
    Run Keyword And Continue On Failure    Click Element    xpath=//input[@id="dont-show-again"]
    Run Keyword And Continue On Failure    Click Element    xpath=//input[@id="dont-show-again"]
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Click Button    ${WORKBENCH_STOP_BTN_XP}
    END

Click Action From Actions Menu
    [Arguments]    ${item_title}    ${item_type}    ${action}    
    Click Element       xpath=//tr[td[@data-label="Name"]//*[text()="${item_title}"]]/td[@class="pf-c-table__action"]/div/button[@aria-label="Actions"]
    Wait Until Page Contains Element       xpath=//tr[td[@data-label="Name"]//*[text()="${item_title}"]]/td[@class="pf-c-table__action"]/div/ul/li/button[text()="Delete ${item_type}"]
    Click Element       xpath=//tr[td[@data-label="Name"]//*[text()="${item_title}"]]/td[@class="pf-c-table__action"]/div/ul/li/button[text()="Delete ${item_type}"]


Handle Deletion Confirmation Modal
    [Arguments]     ${item_title}    ${item_type}   ${press_cancel}=${FALSE}    ${additional_msg}=${NONE}
    Wait Until Modal Appears
    Run Keyword And Continue On Failure    Page Should Contain    Delete ${item_type}?
    Run Keyword And Continue On Failure    Page Should Contain    This action cannot be undone.
    IF    "${additional_msg}" != "${NONE}"
        Run Keyword And Continue On Failure    Page Should Contain    ${additional_msg}
    END
    Run Keyword And Continue On Failure    Page Should Contain    Confirm deletion by typing ${item_title} below:
    Run Keyword And Continue On Failure    Element Should Be Disabled    xpath=//button[text()="Delete ${item_type}"]
    Input Text    xpath=//input[@id="delete-modal-input"]    ${item_title}
    Wait Until Element Is Enabled    xpath=//button[text()="Delete ${item_type}"]
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Click Button    xpath=//button[text()="Delete ${item_type}"]
    END
    Wait Until Modal Disappears

    
Delete Workbench
    [Arguments]     ${workbench_title}    ${press_cancel}=${FALSE}
    Click Action From Actions Menu    item_title=${workbench_title}    item_type=workbench    action=Delete
    Handle Deletion Confirmation Modal    item_title=${workbench_title}    item_type=workbench    press_cancel=${press_cancel}

Check Launched Workbench Is The Correct One
    [Arguments]     ${workbench_title}      ${image}    ${namespace}
    ${_}  ${cr_name}=    Get Openshift Notebook CR From Workbench    workbench_title=${workbench_title}  namespace=${namespace}
    ${current_url}=     Get Location
    Location Should Contain    ${cr_name}
    Location Should Contain    ${namespace}
    Open New Notebook In Jupyterlab Menu
    Spawned Image Check    ${IMAGE_ID_MAPPING}[${image}]

Get Openshift Notebook CR From Workbench
    [Arguments]     ${workbench_title}      ${namespace}
    ${rc}  ${cr_name}=    Run And Return Rc And Output   oc get notebook -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${workbench_title}")].metadata.name}'
    [Return]    ${rc}    ${cr_name}


