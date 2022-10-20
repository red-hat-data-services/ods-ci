*** Settings ***
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${WORKSPACE_CREATE_BTN_XP}=           xpath=//a[text()="Create data science workspace"]
${WRKSP_NAME_INPUT_XP}=               xpath=//input[@name="workspace-name"]
${WRKSP_DESCR_TXT_XP}=                xpath=//textarea[@name="workspace-description"]
${WRKSP_IMAGE_MENU_BTN_XP}=           xpath=//section[@id="notebook-image"]//button[@aria-label="Options menu"]
${WRKSP_IMAGE_ITEM_BTN_XP}=           xpath=//ul[@id="workspace-image-stream-selection"]/li/button
${WRKSP_SIZE_MENU_BTN_XP}=           xpath=//section[@id="deployment-size"]//button[@aria-label="Options menu"]
${WRKSP_SIZE_ITEM_BTN_XP}=           xpath=//ul[@id="container-size"]/li/button
${WRKSP_STATUS_STOPPED}=                  Stopped
${WRKSP_STATUS_RUNNING}=                  Started
${WRKSP_STATUS_STARTING}=                 Starting
${WRKSP_STOP_BTN_XP}=                 xpath=//button[text()="Stop workspace"]
${WRKSP_DELETE_BTN_XP}=                 xpath=//button[text()="Delete notebook"]
&{IMAGE_ID_MAPPING}=                 Minimal Python=s2i-minimal-notebook    CUDA=minimal-gpu   PyTorch=pytorch
...                                  Standard Data Science=s2i-generic-data-science-notebook    TensorFlow=tensorflow
${WRKSP_CREATE_START_BTN_XP}=     xpath=//button[text()="Create and launch"]


*** Keywords ***
Create Workspace v1
    [Documentation]     Creates a new workspace in a Data Science project. It assumes
    ...                 the DS Project details page is open
    [Arguments]     ${name}   ${description}=${EMPTY}   ${image_name}=Minimal Python    ${size}=Small
    Click Element    ${WORKSPACE_CREATE_BTN_XP}
    Wait Until Page Contains Element    ${WRKSP_NAME_INPUT_XP}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    Input Text    ${WRKSP_NAME_INPUT_XP}    ${name}
    Input Text    ${WRKSP_DESCR_TXT_XP}    ${description}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    Select Workspace Jupyter Image    image_name=${image_name}
    ## Select Workspace Container Size # to fix, by default Small is already select
    Wait Until Element Is Enabled    ${GENERIC_CREATE_BTN_XP}
    Click Button    ${GENERIC_CREATE_BTN_XP}
    Wait Until Modal Disappears

Create Workspace
    [Documentation]     Creates a new workspace in a Data Science project. It assumes
    ...                 the DS Project deta
    # [Arguments]     ${name}   ${description}=${EMPTY}   ${image_name}=Minimal Python    ${size}=Small
    [Arguments]     ${wrksp_title}  ${wrksp_description}  ${prj_title}   ${image_name}   ${deployment_size}
    ...             ${storage}  ${pv_existent}   ${pv_name}  ${pv_description}  ${pv_size}  ${start}=${FALSE}
    ...             ${press_cancel}=${FALSE}
    Click Element    ${WORKSPACE_CREATE_BTN_XP}
    Wait Until Page Contains Element    ${WRKSP_NAME_INPUT_XP}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    Input Text    ${WRKSP_NAME_INPUT_XP}    ${wrksp_title}
    Input Text    ${WRKSP_DESCR_TXT_XP}    ${wrksp_description}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    Select Workspace Jupyter Image    image_name=${image_name}
    ## Select Workspace Container Size # to fix, by default Small is already select
    IF    "${storage}" == "Persistent"
        Click Element   xpath=//input[@name="persistent-storage-type-radio"]
        IF    ${pv_existent} == ${TRUE}
            Click Element    xpath=//input[@name="add-existing-storage-checkbox"]
            Wait Until Element Is Enabled    xpath=//div[input[@name="add-existing-storage-checkbox"]]//div[@class="pf-c-form__group"]/div[@class="pf-c-form__group-control"]/div/div/div/input
            Click Element    xpath=//div[input[@name="add-existing-storage-checkbox"]]//div[@class="pf-c-form__group"]/div[@class="pf-c-form__group-control"]/div/div/div/input
            Wait Until Page Contains Element    xpath=//ul/li/button[text()="${prj_title}"]
            Click Element   xpath=//ul/li/button[text()="${prj_title}"]
            # select PV - function not available yet in the product
        ELSE IF   ${pv_existent} == ${FALSE}
            Click Element   xpath=//input[@name="create-new-storage-checkbox"]
            Wait Until Page Contains Element    xpath=//div[input[@name="create-new-storage-checkbox"]]//input[@name="create-new-storage-name"]
            Input Text   xpath=//div[input[@name="create-new-storage-checkbox"]]//input[@name="create-new-storage-name"]   ${pv_name}
            Wait Until Page Contains Element    xpath=//div[input[@name="create-new-storage-checkbox"]]//textarea[@name="create-new-storage-description"]
            Input Text   xpath=//div[input[@name="create-new-storage-checkbox"]]//textarea[@name="create-new-storage-description"]   ${pv_description}
            # Clear Element Text    xpath=//div[@name="create-new-storage-size"]/div/input[@aria-label="Input"]
            # Input Text    xpath=//div[@name="create-new-storage-size"]/div/input[@aria-label="Input"]   ${pv_size}
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
            Wait Until Element Is Enabled    ${WRKSP_CREATE_START_BTN_XP}
            Click Button    ${WRKSP_CREATE_START_BTN_XP}
        ELSE
            Wait Until Element Is Enabled    ${GENERIC_CREATE_BTN_XP}
            Click Button    ${GENERIC_CREATE_BTN_XP}
        END
    END
    Wait Until Modal Disappears
    Wait Until Project Is Open    project_title=${prj_title}

Select Workspace Jupyter Image
    [Arguments]     ${image_name}
    Wait Until Page Contains Element    ${WRKSP_IMAGE_MENU_BTN_XP}
    Click Button    ${WRKSP_IMAGE_MENU_BTN_XP}
    Wait Until Page Contains Element    ${WRKSP_IMAGE_ITEM_BTN_XP}/span[text()="${image_name}"]
    Click Element    ${WRKSP_IMAGE_ITEM_BTN_XP}/span[text()="${image_name}"]

Select Workspace Container Size
    [Arguments]     ${size_name}=Small
    Wait Until Page Contains Element    ${WRKSP_SIZE_MENU_BTN_XP}
    Click Button    ${WRKSP_SIZE_MENU_BTN_XP}
    Wait Until Page Contains Element    ${WRKSP_SIZE_ITEM_BTN_XP}/span[text()="${size_name}"]
    Click Element    ${WRKSP_SIZE_ITEM_BTN_XP}/span[text()="${size_name}"]

Workspace Should Be Listed
    [Arguments]     ${workspace_title}
    Run keyword And Continue On Failure     Page Should Contain Element    xpath=//td/h4[text()="${workspace_title}"]

Workspace Status Should Be
    [Arguments]     ${workspace_title}      ${status}
    Run keyword And Continue On Failure     Page Should Contain Element    xpath=//tr[td/h4[text()="${workspace_title}"]]/td/label/span[text()="${status}"]

Wait Until Workspace Is Started
    [Arguments]     ${workspace_title}      ${timeout}=25s
    Wait Until Keyword Succeeds    ${timeout}    5s      Workspace Status Should Be      workspace_title=${workspace_title}   status=${WRKSP_STATUS_RUNNING}

Start Workspace
    [Arguments]     ${workspace_title}
    ${is_stopped}=      Run Keyword And Return Status   Workspace Status Should Be      workspace_title=${workspace_title}   status=${WRKSP_STATUS_STOPPED}
    IF    ${is_stopped} == ${TRUE}
        Click Element       xpath=//tr[td/h4[text()="${workspace_title}"]]/td/label/span[@class="pf-c-switch__toggle"]
    ELSE
        Log     msg=Cannot start ${workspace_title} workspace because it is not stopped.
    END
    Wait Until Workspace Is Started     workspace_title=${workspace_title}

Access To Workspace  
    [Arguments]    ${username}=${TEST_USER.USERNAME}  ${password}=${TEST_USER.PASSWORD}  ${auth_type}=${TEST_USER.AUTH_TYPE}
    Switch Window   NEW
    Run Keyword And Warn On Failure   Login To Openshift  ${username}  ${password}  ${auth_type}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
    Maybe Close Popup

Launch Workspace
    [Arguments]     ${workspace_title}
    ${is_started}=      Run Keyword And Return Status   Workspace Status Should Be      workspace_title=${workspace_title}   status=${WRKSP_STATUS_RUNNING}
    IF    ${is_started} == ${TRUE}
        Click Link       xpath=//tr[td/h4[text()="${workspace_title}"]]/td/a[text()="Open"]
        Access To Workspace
    ELSE
        Log   msg=Cannot launch workspace ${workspace_title} because it is not running..   level=ERROR
    END

Stop Workspace
    [Arguments]     ${workspace_title}    ${press_cancel}=${FALSE}
    ${is_started}=      Run Keyword And Return Status   Workspace Status Should Be      workspace_title=${workspace_title}   status=${WRKSP_STATUS_RUNNING}
    IF    ${is_started} == ${TRUE}
        Click Element       xpath=//tr[td/h4[text()="${workspace_title}"]]/td/label/span[@class="pf-c-switch__toggle"]
        Wait Until Modal Appears
        Run Keyword And Continue On Failure    Page Should Contain    Stop workspace?
        Run Keyword And Continue On Failure    Page Should Contain    Are you sure you want to stop the workspace? Any changes without saving will be erased.
        Run Keyword And Continue On Failure    Page Should Contain    To save changes, access your workspace
        Run Keyword And Continue On Failure    Page Should Contain Element    xpath=//input[@id="dont-show-again"]
        Run Keyword And Continue On Failure    Click Element    xpath=//input[@id="dont-show-again"]
        Run Keyword And Continue On Failure    Click Element    xpath=//input[@id="dont-show-again"]
        IF    ${press_cancel} == ${TRUE}
            Click Button    ${GENERIC_CANCEL_BTN_XP}
        ELSE
            Click Button    ${WRKSP_STOP_BTN_XP}
        END
        

    ELSE
        Fail   msg=Cannot stop workspace ${workspace_title} because it is not running...
    END

Delete Workspace
    [Arguments]     ${workspace_title}    ${press_cancel}=${FALSE}
    Click Element       xpath=//tr[td/h4[text()="${workspace_title}"]]/td[@class="pf-c-table__action"]/div/button[@aria-label="Actions"]
    Wait Until Page Contains Element       xpath=//tr[td/h4[text()="${workspace_title}"]]/td[@class="pf-c-table__action"]/div/ul/li/button[text()="Delete workspace"]
    Click Element       xpath=//tr[td/h4[text()="${workspace_title}"]]/td[@class="pf-c-table__action"]/div/ul/li/button[text()="Delete workspace"]
    Wait Until Modal Appears
    Run Keyword And Continue On Failure    Page Should Contain    Confirm notebook delete
    Run Keyword And Continue On Failure    Page Should Contain    Are you sure you want to delete ${workspace_title}?
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Click Button    ${WRKSP_DELETE_BTN_XP}
    END


Check Launched Workspace Is The Correct One
    [Arguments]     ${workspace_title}      ${image}    ${namespace}
    ${_}  ${cr_name}=    Get Openshift Notebook CR From Workspace    workspace_title=${workspace_title}  namespace=${namespace}
    # check notebook id from URL..
    ${current_url}=     Get Location
    Location Should Contain    ${cr_name}
    Location Should Contain    ${namespace}
    Open New Notebook In Jupyterlab Menu
    Spawned Image Check    ${IMAGE_ID_MAPPING}[${image}]
    # ${spawn_fail} =  Has Spawn Failed

Get Openshift Notebook CR From Workspace
    [Arguments]     ${workspace_title}      ${namespace}
    # ${res}  ${cr_name}=     Run Keyword And Ignore Error     Oc Get    kind=Notebook
    # ...                                                 field_selector=metadata.annotations.openshift.io/display-name=${workspace_title},metadata.namespace=${namespace}
    # ...                                                 fields=[metadata.name]
    ${rc}  ${cr_name}=    Run And Return Rc And Output   oc get notebook -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${workspace_title}")].metadata.name}'
    [Return]    ${rc}    ${cr_name}


