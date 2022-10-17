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


*** Keywords ***
Create Workspace
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
    Wait Until Modal Disappear

Create Workspace v2
    [Documentation]     Creates a new workspace in a Data Science project. It assumes
    ...                 the DS Project deta
    # [Arguments]     ${name}   ${description}=${EMPTY}   ${image_name}=Minimal Python    ${size}=Small
    [Arguments]     ${wrksp_title}  ${wrksp_description}  ${prj_title}   ${image_name}   ${deployment_size}
    ...             ${storage}  ${pv_existent}   ${pv_name}  ${pv_description}  ${pv_size}
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
            Wait Until Page Contains Element    xpath=//div[input[@name="add-existing-storage-checkbox"]]//button[@aria-label="Options menu"]
            Click Element    xpath=//div[input[@name="add-existing-storage-checkbox"]]//button[@aria-label="Options menu"]
            Wait Until Page Contains Element    xpath=//ul/li/button[text()="${prj_title}"]
            Click Element   xpath=//ul/li/button[text()="${prj_title}"]
            # select PV - function not available yet in the product
        ELSE IF   ${pv_existent} == ${FALSE}
            Click Element   xpath=//input[@name="create-new-storage-checkbox"]
            Wait Until Page Contains Element    xpath=//div[input[@name="create-new-storage-checkbox"]]//input[@name="create-new-storage-name"]
            Input Text   xpath=//div[input[@name="create-new-storage-checkbox"]]//input[@name="create-new-storage-name"]   ${pv_name}
            Wait Until Page Contains Element    xpath=//div[input[@name="create-new-storage-checkbox"]]//textarea[@name="create-new-storage-description"]
            Input Text   xpath=//div[input[@name="create-new-storage-checkbox"]]//textarea[@name="create-new-storage-description"]   ${pv_name}
            Clear Element Text    xpath=//div[@name="create-new-storage-size"]/div/input[@aria-label="Input"]
            Input Text    xpath=//div[@name="create-new-storage-size"]/div/input[@aria-label="Input"]   ${pv_size}
        ELSE
            Fail    msg="pv_existent" argument is required when selected storage type is "Persistent"
        END
    ELSE
        Click Element   xpath=//input[@name="ephemeral-storage-type-radio"]
    END
    Wait Until Element Is Enabled    ${GENERIC_CREATE_BTN_XP}
    Click Button    ${GENERIC_CREATE_BTN_XP}
    Wait Until Modal Disappear

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
        Click Element       xpath=//tr[td/h4[text()="${workspace_title}"]]/td/label/input
    ELSE
        Log     msg=Cannot start ${workspace_title} workspace because it is not stopped.
    END
    Wait Until Workspace Is Started     workspace_title=${workspace_title}

Launch Workspace
    [Arguments]     ${workspace_title}
    ${is_started}=      Run Keyword And Return Status   Workspace Status Should Be      workspace_title=${workspace_title}   status=${WRKSP_STATUS_RUNNING}
    IF    ${is_started} == ${TRUE}
        Click Link       xpath=//tr[td/h4[text()="${workspace_title}"]]/td/a[text()="Open"]
            Run Keyword And Warn On Failure   Login To Openshift  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
     ${authorization_required} =  Is Service Account Authorization Required
     Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
     Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
     Maybe Close Popup
    ELSE
        Log   msg=Cannot launch workspace ${workspace_title} because it is not running..   level=ERROR
    END

Check Launched Workspace Is The Correct One
    [Arguments]     ${workspace_title}      ${image}
    # check notebook id from URL..
    Open New Notebook In Jupyterlab Menu
    Spawned Image Check    ${image}
    # ${spawn_fail} =  Has Spawn Failed

