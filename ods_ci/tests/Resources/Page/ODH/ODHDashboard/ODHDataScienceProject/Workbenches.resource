*** Settings ***
Documentation    Collection of keywords to interact with Workbenches
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       ../ODHDataScienceProject/Storages.resource
Resource       Projects.resource


*** Variables ***
${WORKBENCH_SECTION_XP}=             xpath=//div[@id="workbenches"]
${WORKBENCH_CREATE_BTN_XP}=           xpath=//button[text()="Create workbench"]
${WORKBENCH_CREATE_BTN_2_XP}=         xpath=//button[@id="create-button"]
${WORKBENCH_NAME_INPUT_XP}=               xpath=//input[@name="workbench-name"]
${WORKBENCH_DESCR_TXT_XP}=                xpath=//textarea[@name="workbench-description"]
${WORKBENCH_IMAGE_MENU_BTN_XP}=           xpath=//section[@id="notebook-image"]//div[@id="workbench-image-stream-selection"]/button    # robocop: disable
${WORKBENCH_IMAGE_ITEM_BTN_XP}=           xpath=//div[@id="workbench-image-stream-selection"]//li//div
${WORKBENCH_SIZE_MENU_BTN_XP}=           xpath=//section[@id="deployment-size"]//button  # Removing the attribute in case it changes like it did for the image dropdown
${WORKBENCH_SIZE_SIDE_MENU_BTN}=           xpath=//nav[@aria-label="Jump to section"]//span[text()="Deployment size"]
${WORKBENCH_ACCELERATOR_DROPDOWN_XPATH}=    xpath=//label[@for='modal-notebook-accelerator']/ancestor::div[@class='pf-c-form__group']/descendant::button
${WORKBENCH_ACCELERATOR_INPUT_XPATH}=    xpath=//input[@aria-label='Number of accelerators']
${WORKBENCH_ACCELERATOR_LESS_BUTTON_XPATH}=    xpath=${WORKBENCH_ACCELERATOR_INPUT_XPATH}/preceding-sibling::button
${WORKBENCH_ACCELERATOR_PLUS_BUTTON_XPATH}=    xpath=${WORKBENCH_ACCELERATOR_INPUT_XPATH}/following-sibling::button
${WORKBENCH_SIZE_ITEM_BTN_XP}=           xpath=//ul[@data-id="container-size-select"]/li/button
${WORKBENCH_GPU_MENU_BTN_XP}=           xpath=//section[@id="deployment-size"]//button[contains(@aria-labelledby,"gpu-numbers")]     # robocop: disable
${WORKBENCH_GPU_ITEM_BTN_XP}=           xpath=//ul[@data-id="gpu-select"]/li/button
${WORKBENCH_ADD_VAR_BTN_XP}=           xpath=//button[text()="Add variable"]
${WORKBENCH_STATUS_STOPPED}=                  Stopped
${WORKBENCH_STATUS_RUNNING}=                  Running
${WORKBENCH_STATUS_STARTING}=                 Starting...
${WORKBENCH_STOP_BTN_XP}=                 xpath=//button[text()="Stop workbench"]
${WORKBENCH_IMAGE_VER_LABEL}=        //label[@for="workbench-image-version-selection"]
${WORKBENCH_IMAGE_VER_BUTTON}=       ${WORKBENCH_IMAGE_VER_LABEL}/../..//button
${WORKBENCH_IMAGE_VER_DROPDOWN}=     ${WORKBENCH_IMAGE_VER_BUTTON}/../ul[@id="workbench-image-version-selection"]
&{IMAGE_ID_MAPPING}=                 Minimal Python=minimal-notebook    CUDA=minimal-gpu   PyTorch=pytorch
...                                  Standard Data Science=data-science-notebook    TensorFlow=tensorflow
${KEYVALUE_TYPE}=        Key / value
${UPLOAD_TYPE}=        Upload
${ENV_VARIABLES_SECTION_XP}=        xpath=//section[@aria-label="Environment variables"]
${ERROR_ICON_XP}=        span[contains(@class,'pf-m-danger')]


*** Keywords ***
Create Workbench
    [Documentation]     Creates a new workbench in a Data Science project. It assumes
    ...                 the DS Project data. It allows to add new or existent PV storage,
    ...                 add Environment variables and select Jupyter image
    [Arguments]     ${workbench_title}  ${workbench_description}  ${prj_title}   ${image_name}   ${deployment_size}
    ...             ${storage}  ${pv_existent}   ${pv_name}  ${pv_description}  ${pv_size}    ${gpus}=${NONE}
    ...             ${press_cancel}=${FALSE}  ${version}=default  ${envs}=${NONE}
    Click Element    ${WORKBENCH_CREATE_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_NAME_INPUT_XP}
    Run Keyword And Continue On Failure     Element Should Be Disabled    ${WORKBENCH_CREATE_BTN_2_XP}
    Input Text    ${WORKBENCH_NAME_INPUT_XP}    ${workbench_title}
    Input Text    ${WORKBENCH_DESCR_TXT_XP}    ${workbench_description}
    Run Keyword And Continue On Failure     Element Should Be Disabled    ${WORKBENCH_CREATE_BTN_2_XP}
    Select Workbench Jupyter Image    image_name=${image_name}    version=${version}
    IF    "${deployment_size}" != "${NONE}"    Select Workbench Container Size    size_name=${deployment_size}
    IF    "${gpus}" != "${NONE}"    Select Workbench Number Of GPUs    gpus=${gpus}
    IF    "${envs}" != "${NONE}"
        ${envs_copy}=    Copy List    ${envs}    deepcopy=${TRUE}
        Add Environment Variables In Workbench    env_variables=${envs_copy}
    END
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.20.0
    IF  ${version_check}==True
        Run Keyword And Continue On Failure    Page Should Not Contain Element
        ...    xpath=//input[contains(@name,"ephemeral")]
    END
    IF    "${storage}" == "Persistent"
        IF    ${pv_existent} == ${TRUE}
            # Use the `Jump to section` links in the page to scroll the section into view
            Click Element    //a[@href="#cluster-storage"]
            Click Element    xpath=//input[@name="persistent-existing-storage-type-radio"]
            Select An Existent PV   name=${pv_name}
        ELSE IF   ${pv_existent} == ${FALSE}
            # Use the `Jump to section` links in the page to scroll the section into view
            Click Element    //a[@href="#cluster-storage"]
            Click Element   xpath=//input[@name="persistent-new-storage-type-radio"]
            Fill In New PV Data    name=${pv_name}    description=${pv_description}  size=${pv_size}
        ELSE
            Log    msg="pv_existent" argument not set, using default PV settings   level=WARN
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
    Wait Until Generic Modal Disappears  timeout=1 minute
    Wait Until Project Is Open    project_title=${prj_title}

Add Environment Variables In Workbench
    [Documentation]    Adds the environment variables through the workbench creation page
    [Arguments]    ${env_variables}
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.20.0
    IF  ${version_check}==True
        ${add_key_value_text}=    Set Variable    Add another key / value pair
    ELSE
        ${add_key_value_text}=    Set Variable    Add another variable
    END
    # Use the `Jump to section` links in the page to scroll the section into view
    Click Element    //a[@href="#environment-variables"]
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
                Run Keyword And Continue On Failure    Wait Until Page Contains Element
                ...    xpath=//input[@aria-label="key of item ${pair_idx}"]
                Input Text    ${ENV_VARIABLES_SECTION_XP}/div[@class="pf-l-split"][${idx}]//input[@aria-label="key of item ${pair_idx}"]
                ...           ${key}
                Input Text    ${ENV_VARIABLES_SECTION_XP}/div[@class="pf-l-split"][${idx}]//input[@aria-label="value of item ${pair_idx}"]
                ...           ${value}
                IF    ${n_pairs}-${pair_idx} > 1
                    Click Element    ${ENV_VARIABLES_SECTION_XP}/div[@class="pf-l-split"][${idx}]//button[text()="${add_key_value_text}"]
                    # The element we want to click might get pushed out of view on every loop, let's scroll by an approx
                    # amount of pixels for the block of elements that gets added.
                    IF    "${add_key_value_text}" == "Add another key / value pair"
                        Execute Javascript    document.getElementsByClassName("pf-c-drawer__content")[1].scrollBy(0,500)  # robocop: disable
                    ELSE IF    "${add_key_value_text}" == "Add another variable"
                        Execute Javascript    document.getElementsByClassName("pf-c-drawer__content")[1].scrollBy(0,700)  # robocop: disable
                    END
                END
            END
        ELSE IF  "${input_type}" == "${UPLOAD_TYPE}"
            ${rc}    ${pwd}=    Run And Return Rc And Output    echo $PWD
            Choose File    ${ENV_VARIABLES_SECTION_XP}/div[@class="pf-l-split"][${idx}]//div[@class="pf-c-file-upload"]//input[@type="file"]    ${pwd}/${env_variable}[filepath]
        END
        IF    ${n_objects}-${idx} > 0
            Click Button    Add more variables
        END
    END

Select Environment Variable Types
    [Documentation]    Selects the type of environment variable in the workbench creation page: Secret vs Config Map
    [Arguments]    ${k8s_type}    ${input_type}    ${variable_index}
    Run Keyword And Continue On Failure    Wait Until Page Contains Element
    ...    ${ENV_VARIABLES_SECTION_XP}/div[@class="pf-l-split"][${variable_index}]//div[@class="pf-l-stack__item"]/div[contains(@class,"pf-c-select")]/button
    Click Element    ${ENV_VARIABLES_SECTION_XP}/div[@class="pf-l-split"][${variable_index}]//div[contains(@class,"pf-c-select")]/button
    Wait Until Page Contains Element    xpath=//ul[@role="listbox"]/li/button[text()="${k8s_type}"]
    Click Element    xpath=//ul[@role="listbox"]/li/button[text()="${k8s_type}"]
    Run Keyword And Continue On Failure
    ...    Wait Until Page Contains Element    ${ENV_VARIABLES_SECTION_XP}//button[div/span[text()="Select one"]]
    Click Element    ${ENV_VARIABLES_SECTION_XP}/div[@class="pf-l-split"][${variable_index}]//button[div/span[text()="Select one"]]
    Wait Until Page Contains Element    xpath=//ul[@role="listbox"]/li/button[text()="${input_type}"]
    Click Element    xpath=//ul[@role="listbox"]/li/button[text()="${input_type}"]

Remove All Environment Variables
    [Documentation]    Removes all the added environment variables from the workbench creation page
    ${remove_buttons}=    Get WebElements    xpath=//section[@id="environment-variable"]//button
    FOR    ${rb}    IN    @{remove_buttons}
        Click Element    ${rb}
    END

Select An Existent PV
    [Documentation]    Selects an existent PV Storage in the workbench creation page
    [Arguments]    ${name}
    Run Keyword And Continue On Failure
    ...    Wait Until Element Is Enabled    xpath=//input[@placeholder="Select a persistent storage"]
    Click Element    xpath=//input[@placeholder="Select a persistent storage"]
    Wait Until Page Contains Element    xpath=//ul/li/button[text()="${name}"]
    Wait Until Page Contains Element    xpath=//div[contains(@class,"pf-c-select")]/ul/li/button[text()="${name}"]
    Click Element   xpath=//ul/li/button[text()="${name}"]

Select Workbench Jupyter Image
    [Documentation]    Selects a Jupyter image in the workbench creation page
    [Arguments]     ${image_name}    ${version}=default
    Wait Until Page Contains Element    ${WORKBENCH_IMAGE_MENU_BTN_XP}
    Click Button    ${WORKBENCH_IMAGE_MENU_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_IMAGE_ITEM_BTN_XP}\[text()="${image_name}"]    timeout=10s
    Click Element    ${WORKBENCH_IMAGE_ITEM_BTN_XP}\[text()="${image_name}"]
    IF    "${version}"=="default"
        Verify Version Selection Dropdown
    ELSE IF    "${version}"=="previous"
        Select Workbench Image Version    ${version}
    ELSE
        Fail    ${version} does not exist, use default/previous
    END

Verify Version Selection Dropdown
    [Documentation]    Verifies the version selection dropdown is present
    ...                uses the recommended image by default, and has two options
    Wait Until Page Contains Element    xpath=${WORKBENCH_IMAGE_VER_LABEL}
    Wait Until Page Contains Element    xpath=${WORKBENCH_IMAGE_VER_BUTTON}
    Page Should Contain Element    xpath=${WORKBENCH_IMAGE_VER_BUTTON}//div[contains(text(),"Recommended")]
    Click Element    xpath=${WORKBENCH_IMAGE_VER_BUTTON}
    Wait Until Page Contains Element    xpath=${WORKBENCH_IMAGE_VER_DROPDOWN}
    Page Should Contain Element    xpath=${WORKBENCH_IMAGE_VER_DROPDOWN}//span[contains(text(), "Python v${DEFAULT_PYTHON_VER}")]
    Page Should Contain Element    xpath=${WORKBENCH_IMAGE_VER_DROPDOWN}//span[contains(text(), "Python v${PREVIOUS_PYTHON_VER}")]
    Click Element    xpath=${WORKBENCH_IMAGE_VER_BUTTON}

Select Workbench Image Version
    [Documentation]    Select the (default | previous) image version
    [Arguments]    ${version}=default
    Verify Version Selection Dropdown
    Click Element    xpath=${WORKBENCH_IMAGE_VER_BUTTON}
    Wait Until Page Contains Element    xpath=${WORKBENCH_IMAGE_VER_DROPDOWN}
    IF    "${version}"=="default"
        Click Element    xpath=${WORKBENCH_IMAGE_VER_DROPDOWN}//span[contains(text(), "Python v${DEFAULT_PYTHON_VER}")]/..
    ELSE IF    "${version}"=="previous"
        Click Element    xpath=${WORKBENCH_IMAGE_VER_DROPDOWN}//span[contains(text(), "Python v${PREVIOUS_PYTHON_VER}")]/..
    ELSE
        Fail    ${version} does not exist, use default/previous
    END

Select Workbench Container Size
    [Documentation]    Selects the container size in the workbench creation page
    [Arguments]     ${size_name}=Small
    Wait Until Page Contains Element    ${WORKBENCH_SIZE_SIDE_MENU_BTN}
    Click Element    ${WORKBENCH_SIZE_SIDE_MENU_BTN}
    Wait Until Page Contains Element    ${WORKBENCH_SIZE_MENU_BTN_XP}
    Click Element    ${WORKBENCH_SIZE_MENU_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_SIZE_ITEM_BTN_XP}/span[text()="${size_name}"]
    Click Element    ${WORKBENCH_SIZE_ITEM_BTN_XP}/span[text()="${size_name}"]

Workbench Should Be Listed
    [Documentation]    Checks a workbench is listed in the DS Project details page
    [Arguments]     ${workbench_title}
    Run keyword And Continue On Failure
    ...    Wait Until Page Contains Element
    ...        ${WORKBENCH_SECTION_XP}//td[@data-label="Name"]/*[div[text()="${workbench_title}"]]

Workbench With Description Should Be Listed
    [Documentation]    Checks a workbench with particular name and description is listed in the DS Project details page
    [Arguments]     ${workbench_title}  ${workbench_description}
    Run keyword And Continue On Failure
    ...    Wait Until Page Contains Element
    ...        ${WORKBENCH_SECTION_XP}//td[@data-label="Name"][//div[text()="${workbench_title}"] and //p[text()="${workbench_description}"]]

Workbench Should Not Be Listed
    [Documentation]    Checks a workbench is not listed in the DS Project details page
    [Arguments]     ${workbench_title}
    Run keyword And Continue On Failure
    ...    Wait Until Page Does Not Contain Element
    ...        ${WORKBENCH_SECTION_XP}//td[@data-label="Name"]/*[div[text()="${workbench_title}"]]

Workbench Status Should Be
    [Documentation]    Checks a workbench status is the expected one in the DS Project details page
    [Arguments]     ${workbench_title}      ${status}
    Run keyword And Continue On Failure
    ...    Page Should Contain Element
    ...        ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/*[div[text()="${workbench_title}"]]]/td[@data-label="Status"]//p[text()="${status}"]

Status Error Icon Should Appear
    [Documentation]    Checks if the error icon appears on the given workbench
    [Arguments]     ${workbench_title}
    Reload Page
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Page Should Contain Element
    ...        ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/*[div[text()="${workbench_title}"]]]/td[@data-label="Status"]//p//${ERROR_ICON_XP}    # robocop: disable
    Mouse Over    ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/*[div[text()="${workbench_title}"]]]/td[@data-label="Status"]//p//${ERROR_ICON_XP}    # robocop: disable
    Wait Until Page Contains    Insufficient resources to start

Wait Until Workbench Is Started
    [Documentation]    Waits until workbench status is "RUNNING" in the DS Project details page
    [Arguments]     ${workbench_title}    ${timeout}=60s    ${status}=${WORKBENCH_STATUS_RUNNING}
    Wait Until Page Contains Element
    ...        ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/*[div[text()="${workbench_title}"]]]/td[@data-label="Status"]//p[text()="${status}"]    timeout=${timeout}  # robocop: disable

Wait Until Workbench Is Stopped
    [Documentation]    Waits until workbench status is "RUNNING" in the DS Project details page
    [Arguments]     ${workbench_title}      ${timeout}=40s
    Wait Until Keyword Succeeds    ${timeout}    5s      Workbench Status Should Be
    ...    workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_STOPPED}

Wait Until Workbench Is Restarting
    [Documentation]    Waits until workbench status is "STARTING" in the DS Project details page
    [Arguments]     ${workbench_title}      ${timeout}=40s
    Wait Until Keyword Succeeds    ${timeout}    5s      Workbench Status Should Be
    ...    workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_STARTING}

Start Workbench
    [Documentation]    Starts a workbench from the DS Project details page
    [Arguments]     ${workbench_title}      ${timeout}=60s

    ${is_stopped}=      Run Keyword And Return Status   Workbench Status Should Be
    ...    workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_STOPPED}
    IF    ${is_stopped} == ${TRUE}
        Click Element       ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/*[div[text()="${workbench_title}"]]]/td[@data-label="Status"]//span[@class="pf-c-switch__toggle"]
    ELSE
        Log     msg=Cannot start ${workbench_title} workbench because it is not stopped.
    END
    Wait Until Workbench Is Started     workbench_title=${workbench_title}   timeout=${timeout}

Access To Workbench
    [Documentation]    Gets access to a workbench from DS Project details page after it got launched
    [Arguments]    ${username}  ${password}  ${auth_type}
    Run Keyword And Warn On Failure    Wait Until Page Contains    Log in with OpenShift    timeout=15s
    ${oauth_prompt_visible} =    Is OpenShift OAuth Login Prompt Visible
    IF  ${oauth_prompt_visible}    Click Button     Log in with OpenShift
    Run Keyword And Warn On Failure   Login To Openshift  ${username}  ${password}  ${auth_type}
    ${authorization_required}=  Is Service Account Authorization Required
    IF  ${authorization_required}  Authorize Jupyterhub Service Account
    Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
    Maybe Close Popup

Launch And Access Workbench
    [Documentation]    Launches a workbench from DS Project details page
    [Arguments]     ${workbench_title}    ${username}=${TEST_USER_3.USERNAME}
    ...    ${password}=${TEST_USER_3.PASSWORD}  ${auth_type}=${TEST_USER_3.AUTH_TYPE}
    ${is_started}=      Run Keyword And Return Status   Workbench Status Should Be
    ...    workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}
    IF    ${is_started} == ${TRUE}
        Open Workbench    workbench_title=${workbench_title}
        Access To Workbench    username=${username}    password=${password}
        ...    auth_type=${auth_type}
    ELSE
        Fail   msg=Cannot Launch And Access Workbench ${workbench_title} because it is not running...
    END

Open Workbench
    [Documentation]    Clicks on "open" link for a given workbench
    [Arguments]    ${workbench_title}
    Click Link       ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/*[div[text()="${workbench_title}"]]]/td//a[text()="Open"]
    Switch Window   NEW

Stop Workbench
    [Documentation]    Stops a workbench from DS Project details page
    [Arguments]     ${workbench_title}    ${press_cancel}=${FALSE}    ${from_running}=${TRUE}
    ${is_started}=      Run Keyword And Return Status   Workbench Status Should Be
    ...    workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}
    ${is_starting}=      Run Keyword And Return Status   Workbench Status Should Be
    ...    workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_STARTING}
    IF    ${is_started} == ${TRUE} or ${is_starting} == ${TRUE}
        Click Element       ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/*[div[text()="${workbench_title}"]]]/td[@data-label="Status"]//span[@class="pf-c-switch__toggle"]
        Wait Until Generic Modal Appears
        Handle Stop Workbench Confirmation Modal    press_cancel=${press_cancel}
        ...    from_running=${from_running}
    ELSE
        Fail   msg=Cannot stop workbench ${workbench_title} because it is not neither running or starting...
    END

Handle Stop Workbench Confirmation Modal
    [Documentation]    Handles modal to stop workbench
    [Arguments]    ${press_cancel}=${FALSE}    ${from_running}=${TRUE}
    Run Keyword And Continue On Failure    Page Should Contain    Stop workbench?
    IF    ${from_running} == ${TRUE}
        Run Keyword And Continue On Failure
        ...    Page Should Contain    Are you sure you want to stop the workbench? Any changes without saving will be erased.
        Run Keyword And Continue On Failure    Page Should Contain    To save changes, access your
        Run Keyword And Continue On Failure    Page Should Contain Element    xpath=//a[.="workbench"]
    END
    Run Keyword And Continue On Failure    Page Should Contain Element    xpath=//input[@id="dont-show-again"]
    Run Keyword And Continue On Failure    Click Element    xpath=//input[@id="dont-show-again"]
    Run Keyword And Continue On Failure    Click Element    xpath=//input[@id="dont-show-again"]
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Click Button    ${WORKBENCH_STOP_BTN_XP}
    END

Click Action From Actions Menu
    [Documentation]    Clicks an action from Actions menu (3-dots menu on the right)
    [Arguments]    ${item_title}    ${item_type}    ${action}
    Click Element       xpath=//tr[td[@data-label="Name"]//*[text()="${item_title}"]]/td[@class="pf-c-table__action"]/div/button[@aria-label="Actions"]
    Wait Until Page Contains Element       xpath=//tr[td[@data-label="Name"]//*[text()="${item_title}"]]/td[@class="pf-c-table__action"]/div/ul/li/button[text()="${action} ${item_type}"]
    Click Element       xpath=//tr[td[@data-label="Name"]//*[text()="${item_title}"]]/td[@class="pf-c-table__action"]/div/ul/li/button[text()="${action} ${item_type}"]

Delete Workbench
    [Documentation]    Deletes a workbench
    [Arguments]     ${workbench_title}    ${press_cancel}=${FALSE}
    Workbenches.Click Action From Actions Menu    item_title=${workbench_title}    item_type=workbench    action=Delete
    Handle Deletion Confirmation Modal    item_title=${workbench_title}    item_type=workbench    press_cancel=${press_cancel}

Edit Workbench
    [Documentation]    Edits a workbench
    [Arguments]     ${workbench_title}
    Workbenches.Click Action From Actions Menu    item_title=${workbench_title}    item_type=workbench    action=Edit
    Wait Until Page Contains Element    ${WORKBENCH_NAME_INPUT_XP}
    # Also wait until the workbench name is populated in the text field - let's wait for DOM to finish
    Wait For Condition    return document.readyState == "complete"    timeout=5s

Check Launched Workbench Is The Correct One
    [Documentation]    Checks if the launched workbench is the expected one
    [Arguments]     ${workbench_title}    ${image}    ${project_title}
    ${namespace}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    ${_}  ${cr_name}=    Get Openshift Notebook CR From Workbench    workbench_title=${workbench_title}  namespace=${namespace}
    ${current_url}=     Get Location
    Location Should Contain    ${cr_name}
    Location Should Contain    ${namespace}
    Open New Notebook In Jupyterlab Menu
    Spawned Image Check    ${IMAGE_ID_MAPPING}[${image}]

Get Openshift Notebook CR From Workbench
    [Documentation]    Retrieves name of Notebook CR corresponding to a workbench
    [Arguments]     ${workbench_title}      ${namespace}
    ${rc}  ${cr_name}=    Run And Return Rc And Output   oc get notebook -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${workbench_title}")].metadata.name}'
    RETURN    ${rc}    ${cr_name}

Start Workbench Should Fail
    [Documentation]    Checks the workbench fails to start
    [Arguments]    ${workbench_title}
    ${failed}=    Run Keyword And Return Status
    ...    Wait Until Workbench Is Started     workbench_title=${workbench_title}
    IF    ${failed} != ${FALSE}    Fail    msg=Workbench is expected to fail starting...
    Run Keyword And Continue On Failure    Wait Until Keyword Succeeds    30 times    2s
    ...    Status Error Icon Should Appear    workbench_title=${workbench_title}
    Reload Page
    Workbench Should Be Listed    ${workbench_title}
    Wait Until Keyword Succeeds    20 times    2s
    ...    Status Error Icon Should Appear    workbench_title=${workbench_title}

Open Notebook Event Log
    [Documentation]    Opens the event log of the given workbench
    [Arguments]    ${workbench_title}    ${exp_preview_text}=${NONE}
    Click Element
    ...    ${WORKBENCH_SECTION_XP}//tr[td[@data-label="Name"]/*[div[text()="${workbench_title}"]]]/td[@data-label="Status"]//p[text()="${WORKBENCH_STATUS_STARTING}"]    # robocop: disable
    Page Should Contain Event Log Preview    expected_text=${exp_preview_text}
    Click Element    xpath=//div[contains(@class,"popover")]//footer/button[text()="Event log"]
    Wait Until Generic Modal Appears

Event Log Should Report The Failure
    [Documentation]    Checks that the Event log modal reports the
    ...                workbench start failure
    [Arguments]    ${exp_progress_text}=${NONE}    ${exp_result_text}=${NONE}
    Page Should Contain Event Log    expected_progress_text=${exp_progress_text}
    ...    expected_result_text=${exp_result_text}

Close Event Log
    [Documentation]    Closes the event log which was previously opened by the robot
    ${cancel_present}=    Run Keyword And Return Status
    ...    Page Should Contain Element    ${KFNBC_MODAL_CANCEL_XPATH}
    IF    ${cancel_present} == ${TRUE}
        Click Element    ${KFNBC_MODAL_CANCEL_XPATH}
    ELSE
        Click Element    ${KFNBC_MODAL_X_XPATH}
    END
    Wait Until Generic Modal Disappears

Page Should Contain Event Log Preview
    [Documentation]    Check if a preview of the event log is displayed when
    ...                user clicks on "Starting..." status label
    [Arguments]    ${expected_text}=${NONE}
    Wait Until Page Contains Element    xpath=//div[contains(@class,"popover")]//h6[text()="Notebook status"]
    IF   "${expected_text}" != "${NONE}"
        Page Should Contain Element
        ...    xpath=//div[contains(@class,"popover")]//div[contains(text(),"${expected_text}")]
    END
    Wait Until Page Contains Element
    ...    xpath=//div[contains(@class,"popover")]//footer/button[text()="Event log"]

Page Should Contain Event Log
    [Documentation]    Checks if the event log is displayed
    [Arguments]    ${expected_progress_text}=${NONE}    ${expected_result_text}=${NONE}
    Is Generic Modal Displayed
    Run Keyword And Continue On Failure    Page Should Contain    Starting server
    Run Keyword And Continue On Failure    Page Should Contain    Event log
    Run Keyword And Continue On Failure    Page Should Contain Element    css:ul[data-id="event-logs"]
    ${text}=    Get Text    css:ul[data-id="event-logs"]
    IF   "${expected_progress_text}" != "${NONE}"
        Page Should Contain Element
        ...    xpath=//div[@data-id="progress-bar"]//div[contains(text(),"${expected_progress_text}")]
    END
    IF   "${expected_result_text}" != "${NONE}"
        Page Should Contain Element
        ...    xpath=//div[contains(@class,"alert")]//h4[contains(text(),"${expected_result_text}")]
    END
    Capture Page Screenshot

Select Workbench Number Of GPUs
    [Documentation]    Selects the container size in the workbench creation page
    [Arguments]     ${gpus}    ${gpu_type}='Nvidia GPU'
    Wait Until Page Contains Element    ${WORKBENCH_SIZE_SIDE_MENU_BTN}
    Click Element    ${WORKBENCH_SIZE_SIDE_MENU_BTN}
    Wait Until Page Contains Element    ${WORKBENCH_ACCELERATOR_DROPDOWN_XPATH}
    Click Element    ${WORKBENCH_ACCELERATOR_DROPDOWN_XPATH}
    IF  "${gpus}" == "0"
        Click Element    xpath=//a[text()='None']
    ELSE
        # Select Accelerator Technology
        Wait Until Page Contains Element    xpath=//div[@class and text()=${gpu_type}]
        Click Element    xpath=//div[@class and text()=${gpu_type}]
        # Select number of GPU units
        ${actual_gpus}=    Get Value   ${WORKBENCH_ACCELERATOR_INPUT_XPATH}
        ${actual_gpus}=    Convert To Integer    ${actual_gpus}
        ${gpus}=    Convert To Integer    ${gpus}
        WHILE  ${actual_gpus} != ${gpus}
            IF  ${actual_gpus} < ${gpus}
                Click Element    ${WORKBENCH_ACCELERATOR_PLUS_BUTTON_XPATH}
            ELSE
                Click Element    ${WORKBENCH_ACCELERATOR_LESS_BUTTON_XPATH}
            END
            ${actual_gpus}=    Get Value   ${WORKBENCH_ACCELERATOR_INPUT_XPATH}
            ${actual_gpus}=    Convert To Integer    ${actual_gpus}
        END
    END

Edit GPU Number
    [Documentation]    Edit a workbench
    [Arguments]     ${workbench_title}    ${gpus}=1
    Workbenches.Click Action From Actions Menu    item_title=${workbench_title}    item_type=workbench    action=Edit
    ${status}=    Run Keyword And Return Status    Select Workbench Number Of GPUs    gpus=${gpus}
    IF    ${status} == ${FALSE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
        Fail    msg=it failed to select GPU instances
    ELSE
        Wait Until Element Is Enabled    ${WORKBENCH_CREATE_BTN_2_XP}
        Click Button    ${WORKBENCH_CREATE_BTN_2_XP}
    END

Delete Workbench From CLI
    [Documentation]    Deletes a workbench CR from CLI
    [Arguments]    ${workbench_title}    ${project_title}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    ${_}  ${cr_name}=    Get Openshift Notebook CR From Workbench
    ...    workbench_title=${workbench_title}  namespace=${ns_name}
    IF    "${cr_name}" == "${EMPTY}"
        Log    msg=There is probably no Workbench with Diplay Name equal to ${workbench_title}
        ...    level=WARN
    ELSE
    Oc Delete    kind=Notebook  name=${cr_name}  namespace=${ns_name}
    WHILE    ${TRUE}
        ${_}  ${cr_name}=    Get Openshift Notebook CR From Workbench
            ...    workbench_title=${workbench_title}  namespace=${ns_name}
        IF    "${cr_name}" == "${EMPTY}"    BREAK
            Sleep    5s    reason=let's not overload the API
        END
    END


Get Workbench Pod
    [Documentation]    Retrieves info of a workbench pod: namespace, CR resource name and pod definition
    [Arguments]    ${workbench_title}    ${project_title}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    ${_}  ${cr_name}=    Get Openshift Notebook CR From Workbench
    ...    workbench_title=${workbench_title}  namespace=${ns_name}
    ${pod_info}=    Oc Get    kind=Pod  name=${cr_name}-0  api_version=v1  namespace=${ns_name}
    RETURN    ${ns_name}    ${cr_name}    ${pod_info}
