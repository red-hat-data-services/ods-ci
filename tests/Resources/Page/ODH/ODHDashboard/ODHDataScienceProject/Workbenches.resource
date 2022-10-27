*** Settings ***
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${WORKBENCH_CREATE_BTN_XP}=           xpath=//button[text()="Create workbench"]
${WORKBENCH_NAME_INPUT_XP}=               xpath=//input[@name="workbench-name"]
${WORKBENCH_DESCR_TXT_XP}=                xpath=//textarea[@name="workbench-description"]
${WORKBENCH_IMAGE_MENU_BTN_XP}=           xpath=//section[@id="notebook-image"]//button[@aria-label="Options menu"]
${WORKBENCH_IMAGE_ITEM_BTN_XP}=           xpath=//ul[@id="workbench-image-stream-selection"]/li/button
${WORKBENCH_SIZE_MENU_BTN_XP}=           xpath=//section[@id="deployment-size"]//button[@aria-label="Options menu"]
${WORKBENCH_SIZE_ITEM_BTN_XP}=           xpath=//ul[@id="container-size"]/li/button
${WORKBENCH_STATUS_STOPPED}=                  Stopped
${WORKBENCH_STATUS_RUNNING}=                  Running
${WORKBENCH_STATUS_STARTING}=                 Starting...
${WORKBENCH_STOP_BTN_XP}=                 xpath=//button[text()="Stop workbench"]
${WORKBENCH_DELETE_BTN_XP}=                 xpath=//button[text()="Delete notebook"]
&{IMAGE_ID_MAPPING}=                 Minimal Python=s2i-minimal-notebook    CUDA=minimal-gpu   PyTorch=pytorch
...                                  Standard Data Science=s2i-generic-data-science-notebook    TensorFlow=tensorflow
${WORKBENCH_CREATE_START_BTN_XP}=     xpath=//button[text()="Create and start"]


*** Keywords ***
Create Workspace
    [Documentation]     Creates a new workbench in a Data Science project. It assumes
    ...                 the DS Project deta
    [Arguments]     ${workbench_title}  ${workbench_description}  ${prj_title}   ${image_name}   ${deployment_size}
    ...             ${storage}  ${pv_existent}   ${pv_name}  ${pv_description}  ${pv_size}  ${start}=${FALSE}
    ...             ${press_cancel}=${FALSE}
    Click Element    ${WORKBENCH_CREATE_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_NAME_INPUT_XP}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    Input Text    ${WORKBENCH_NAME_INPUT_XP}    ${workbench_title}
    Input Text    ${WORKBENCH_DESCR_TXT_XP}    ${workbench_description}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    Select Workspace Jupyter Image    image_name=${image_name}
    ## Select Workspace Container Size # to fix, by default Small is already select
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
        IF    ${start} == ${TRUE}
            Wait Until Element Is Enabled    ${WORKBENCH_CREATE_START_BTN_XP}
            Click Button    ${WORKBENCH_CREATE_START_BTN_XP}
        ELSE
            Wait Until Element Is Enabled    ${GENERIC_CREATE_BTN_XP}
            Click Button    ${GENERIC_CREATE_BTN_XP}
        END
    END
    Wait Until Modal Disappears
    Wait Until Project Is Open    project_title=${prj_title}

Select An Existent PV
    [Arguments]    ${name}
    Run Keyword And Continue On Failure    Wait Until Element Is Enabled    xpath=//input[@placeholder="Select a persistent storage"]
    Click Element    xpath=//input[@placeholder="Select a persistent storage"]
    Wait Until Page Contains Element    xpath=//ul/li/button[text()="${name}"]
    Wait Until Page Contains Element    xpath=//div[contains(@class,"pf-c-select")]/ul/li/button[text()="${name}"]
    Click Element   xpath=//ul/li/button[text()="${name}"]

Select Workspace Jupyter Image
    [Arguments]     ${image_name}
    Wait Until Page Contains Element    ${WORKBENCH_IMAGE_MENU_BTN_XP}
    Click Button    ${WORKBENCH_IMAGE_MENU_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_IMAGE_ITEM_BTN_XP}/span[text()="${image_name}"]
    Click Element    ${WORKBENCH_IMAGE_ITEM_BTN_XP}/span[text()="${image_name}"]

Select Workspace Container Size
    [Arguments]     ${size_name}=Small
    Wait Until Page Contains Element    ${WORKBENCH_SIZE_MENU_BTN_XP}
    Click Button    ${WORKBENCH_SIZE_MENU_BTN_XP}
    Wait Until Page Contains Element    ${WORKBENCH_SIZE_ITEM_BTN_XP}/span[text()="${size_name}"]
    Click Element    ${WORKBENCH_SIZE_ITEM_BTN_XP}/span[text()="${size_name}"]

Workspace Should Be Listed
    [Arguments]     ${workbench_title}
    Run keyword And Continue On Failure     Page Should Contain Element    xpath=//td/h4[text()="${workbench_title}"]

Workspace Status Should Be
    [Arguments]     ${workbench_title}      ${status}
    Run keyword And Continue On Failure     Page Should Contain Element    xpath=//tr[td/h4[text()="${workbench_title}"]]/td/label/span[text()="${status}"]

Wait Until Workspace Is Started
    [Arguments]     ${workbench_title}      ${timeout}=30s
    Wait Until Keyword Succeeds    ${timeout}    5s      Workspace Status Should Be      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}

Start Workspace
    [Arguments]     ${workbench_title}
    ${is_stopped}=      Run Keyword And Return Status   Workspace Status Should Be      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_STOPPED}
    IF    ${is_stopped} == ${TRUE}
        Click Element       xpath=//tr[td/h4[text()="${workbench_title}"]]/td/label/span[@class="pf-c-switch__toggle"]
    ELSE
        Log     msg=Cannot start ${workbench_title} workbench because it is not stopped.
    END
    Wait Until Workspace Is Started     workbench_title=${workbench_title}

Access To Workspace  
    [Arguments]    ${username}=${TEST_USER.USERNAME}  ${password}=${TEST_USER.PASSWORD}  ${auth_type}=${TEST_USER.AUTH_TYPE}
    Switch Window   NEW
    Run Keyword And Warn On Failure   Login To Openshift  ${username}  ${password}  ${auth_type}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
    Maybe Close Popup

Launch Workspace
    [Arguments]     ${workbench_title}
    ${is_started}=      Run Keyword And Return Status   Workspace Status Should Be      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}
    IF    ${is_started} == ${TRUE}
        Click Link       xpath=//tr[td/h4[text()="${workbench_title}"]]/td/a[text()="Open"]
        Access To Workspace
    ELSE
        Fail   msg=Cannot launch workbench ${workbench_title} because it is not running...
    END

Stop Workspace
    [Arguments]     ${workbench_title}    ${press_cancel}=${FALSE}
    ${is_started}=      Run Keyword And Return Status   Workspace Status Should Be      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}
    IF    ${is_started} == ${TRUE}
        Click Element       xpath=//tr[td/h4[text()="${workbench_title}"]]/td/label/span[@class="pf-c-switch__toggle"]
        Wait Until Modal Appears
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
        

    ELSE
        Fail   msg=Cannot stop workbench ${workbench_title} because it is not running...
    END

Delete Workspace
    [Arguments]     ${workbench_title}    ${press_cancel}=${FALSE}
    Click Element       xpath=//tr[td/h4[text()="${workbench_title}"]]/td[@class="pf-c-table__action"]/div/button[@aria-label="Actions"]
    Wait Until Page Contains Element       xpath=//tr[td/h4[text()="${workbench_title}"]]/td[@class="pf-c-table__action"]/div/ul/li/button[text()="Delete workbench"]
    Click Element       xpath=//tr[td/h4[text()="${workbench_title}"]]/td[@class="pf-c-table__action"]/div/ul/li/button[text()="Delete workbench"]
    Wait Until Modal Appears
    Run Keyword And Continue On Failure    Page Should Contain    Confirm notebook delete
    Run Keyword And Continue On Failure    Page Should Contain    Are you sure you want to delete ${workbench_title}?
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Click Button    ${WORKBENCH_DELETE_BTN_XP}
    END
    Wait Until Modal Disappears

Check Launched Workspace Is The Correct One
    [Arguments]     ${workbench_title}      ${image}    ${namespace}
    ${_}  ${cr_name}=    Get Openshift Notebook CR From Workspace    workbench_title=${workbench_title}  namespace=${namespace}
    # check notebook id from URL..
    ${current_url}=     Get Location
    Location Should Contain    ${cr_name}
    Location Should Contain    ${namespace}
    Open New Notebook In Jupyterlab Menu
    Spawned Image Check    ${IMAGE_ID_MAPPING}[${image}]
    # ${spawn_fail} =  Has Spawn Failed

Get Openshift Notebook CR From Workspace
    [Arguments]     ${workbench_title}      ${namespace}
    # ${res}  ${cr_name}=     Run Keyword And Ignore Error     Oc Get    kind=Notebook
    # ...                                                 field_selector=metadata.annotations.openshift.io/display-name=${workbench_title},metadata.namespace=${namespace}
    # ...                                                 fields=[metadata.name]
    ${rc}  ${cr_name}=    Run And Return Rc And Output   oc get notebook -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${workbench_title}")].metadata.name}'
    [Return]    ${rc}    ${cr_name}


