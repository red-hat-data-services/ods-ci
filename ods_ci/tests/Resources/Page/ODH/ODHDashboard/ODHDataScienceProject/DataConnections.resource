*** Settings ***
Documentation    Collection of keywords to interact with Data Connections
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${S3_NAME_DC_INPUT_XP}=         xpath=//input[@aria-label="Field list Name"]
${S3_KEY_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list AWS_ACCESS_KEY_ID"]
${S3_SECRET_DC_INPUT_XP}=       xpath=//input[@aria-label="Field list AWS_SECRET_ACCESS_KEY"]
${S3_ENDPOINT_DC_INPUT_XP}=     xpath=//input[@aria-label="Field list AWS_S3_ENDPOINT"]
${S3_REGION_DC_INPUT_XP}=       xpath=//input[@aria-label="Field list AWS_DEFAULT_REGION"]
${DC_SECTION_XP}=               xpath=//section[@id="data-connections"]
${DC_ADD_BTN_1_XP}=             xpath=//*[@data-testid="add-data-connection-button"]
${S3_BUCKET_DC_INPUT_XP}=       xpath=//*[@data-testid="field AWS_S3_BUCKET"]
${S3_DC_ADD_BTN}=               xpath=//*[@data-testid="data-connection-submit-button"]
${S3_DC_EDIT_BTN}=              xpath=//footer/button[.="Update data connection"]
${DC_WORKBENCH_SELECTOR_XP}=    xpath=//div[@data-testid="connect-existing-workbench-group"]//ul/li


*** Keywords ***
Create S3 Data Connection
    [Documentation]    Creates a S3 Data Connection from DS Project details page
    [Arguments]    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}
    ...            ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}    ${aws_region}=${S3.AWS_DEFAULT_REGION}
    ...            ${connected_workbench}=${NONE}    ${press_cancel}=${FALSE}    ${aws_bucket_name}=${NONE}
    Open Data Science Project Details Page       project_title=${project_title}    tab_id=data-connections
    Wait Until Element Is Visible     ${DC_ADD_BTN_1_XP}    timeout=30s
    Click Button                      ${DC_ADD_BTN_1_XP}
    Fill Data Connection Form    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}
    ...            ${S3_DC_ADD_BTN}    aws_s3_endpoint=${aws_s3_endpoint}    aws_region=${aws_region}
    ...            connected_workbench=${connected_workbench}    press_cancel=${press_cancel}
    ...            aws_bucket_name=${aws_bucket_name}

Edit S3 Data Connection
    [Documentation]    Edits a S3 Data Connection from DS Project details page
    [Arguments]    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}    ${new_dc_name}=${dc_name}
    ...            ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}    ${aws_region}=${S3.AWS_DEFAULT_REGION}
    ...            ${connected_workbench}=${NONE}    ${press_cancel}=${FALSE}    ${aws_bucket_name}=${NONE}
    ODHDashboard.Click Action From Actions Menu    item_title=${dc_name}    item_type=data connection    action=Edit
    Fill Data Connection Form    ${project_title}    ${new_dc_name}    ${aws_access_key}    ${aws_secret_access}
    ...            ${S3_DC_EDIT_BTN}    aws_s3_endpoint=${aws_s3_endpoint}    aws_region=${aws_region}
    ...            connected_workbench=${connected_workbench}    press_cancel=${press_cancel}
    ...            aws_bucket_name=${aws_bucket_name}

Set Connection Between Data Connection And Workbench
    [Documentation]    Connects a DataConnection to an existent workbench
    [Arguments]    ${workbench_title}
    Wait Until Element Is Enabled    xpath=//button[@aria-label="Notebook select"]
    Click Element    xpath=//button[@aria-label="Notebook select"]
    Wait Until Page Contains Element    ${DC_WORKBENCH_SELECTOR_XP}/button[.="${workbench_title}"]
    Click Element                       ${DC_WORKBENCH_SELECTOR_XP}/button[.="${workbench_title}"]

Data Connection Should Be Listed
    [Documentation]    Checks a Data Connection is listed in DS Project details page
    [Arguments]     ${name}   ${type}   ${connected_workbench}
    ${connection_xp}=    Set Variable    ${DC_SECTION_XP}//tr[td[@data-label="Name"]//div[.="${name}"]]
    Run Keyword And Continue On Failure     Page Should Contain Element    ${connection_xp}
    Run Keyword And Continue On Failure     Page Should Contain Element    ${connection_xp}/td[.=" ${type}"]
    IF    "${connected_workbench}" == "${NONE}"
        Run Keyword And Continue On Failure    Page Should Contain Element
        ...    ${connection_xp}/td[.="No connections"]
    ELSE
        FOR    ${index}    ${workbench_title}    IN ENUMERATE    @{connected_workbench}
            Log    ${index}: ${workbench_title}
            Run Keyword And Continue On Failure    Page Should Contain Element
            ...    ${connection_xp}/td[@data-label="Connected workbenches"]//*[.="${workbench_title}"]
        END
    END

Data Connection Should Not Be Listed
    [Documentation]    Checks a Data Connection is not listed in DS Project details page
    [Arguments]     ${name}
    Run Keyword And Continue On Failure     Wait Until Page Does Not Contain Element
    ...    ${DC_SECTION_XP}//tr[td[@data-label="Name"]/*/div[.="${name}"]]

Get Openshift Secret From Data Connection
    [Documentation]    Retrieves name of Openshift secret corresponding to a given S3 Data Connection based on Dispayed name in DS Project details page
    [Arguments]     ${dc_name}      ${namespace}
    ${rc}  ${secret_name}=    Run And Return Rc And Output   oc get secret -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${dc_name}")].metadata.name}'
    RETURN    ${rc}    ${secret_name}

Delete Data Connection
    [Documentation]    Deletes a Data Connection from DS Project details page
    [Arguments]     ${name}    ${press_cancel}=${FALSE}
    ODHDashboard.Click Action From Actions Menu    item_title=${name}    item_type=data connection    action=Delete
    Handle Deletion Confirmation Modal    item_title=${name}    item_type=data connection    press_cancel=${press_cancel}

Fill Data Connection Form
    [Documentation]    Data Connection Form can be used in the create or edit
    [Arguments]    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}    ${action_btn}
    ...            ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}    ${aws_region}=${S3.AWS_DEFAULT_REGION}
    ...            ${connected_workbench}=${NONE}    ${press_cancel}=${FALSE}    ${aws_bucket_name}=${NONE}
    Wait Until Page Contains Element    ${S3_NAME_DC_INPUT_XP}
    Input Text    ${S3_NAME_DC_INPUT_XP}    ${dc_name}
    Input Text    ${S3_KEY_DC_INPUT_XP}    ${aws_access_key}
    Input Text    ${S3_SECRET_DC_INPUT_XP}    ${aws_secret_access}
    Input Text    ${S3_ENDPOINT_DC_INPUT_XP}    ${aws_s3_endpoint}
    Input Text    ${S3_REGION_DC_INPUT_XP}    ${aws_region}
    Input Text    ${S3_BUCKET_DC_INPUT_XP}    ${aws_bucket_name}
    IF    "${connected_workbench}" == "${NONE}"
        Log    msg=you are not connecting any workbenchs to ${dc_name} DataConnection
    ELSE
        Run Keyword And Continue On Failure
        ...    Element Should Be Enabled    xpath=//div[contains(@class,"modal")]//button[@aria-label="Notebook select"]
        FOR    ${workbench_title}    IN    @{connected_workbench}
            Set Connection Between Data Connection And Workbench    ${workbench_title}
            Run Keyword And Continue On Failure     Element Should Be Enabled    ${S3_DC_ADD_BTN}
        END
    END
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Wait Until Element Is Enabled    ${action_btn}
        Click Button    ${action_btn}
    END
    Wait Until Generic Modal Disappears
    Wait Until Project Is Open    project_title=${project_title}

Get Data Connection Form Values
    [Arguments]    ${dc_name}
    ODHDashboard.Click Action From Actions Menu    item_title=${dc_name}    item_type=data connection    action=Edit
    Wait Until Page Contains Element    ${S3_NAME_DC_INPUT_XP}
    ${s3_name}   get element attribute    ${S3_NAME_DC_INPUT_XP}      value
    ${s3_key}   get element attribute    ${S3_KEY_DC_INPUT_XP}      value
    ${s3_secret}   get element attribute    ${S3_SECRET_DC_INPUT_XP}      value
    ${s3_endpoint}   get element attribute    ${S3_ENDPOINT_DC_INPUT_XP}      value
    ${s3_region}   get element attribute    ${S3_REGION_DC_INPUT_XP}      value
    ${s3_bucket}   get element attribute    ${S3_BUCKET_DC_INPUT_XP}      value
    [return]    ${s3_name}    ${s3_key}    ${s3_secret}    ${s3_endpoint}    ${s3_region}    ${s3_bucket}

Recreate S3 Data Connection
    [Documentation]    Edit Exisisting Or Create New S3 Data Connection from DS Project details page
    [Arguments]    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}
    ...            ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}    ${aws_region}=${S3.AWS_DEFAULT_REGION}
    ...            ${connected_workbench}=${NONE}    ${press_cancel}=${FALSE}    ${aws_bucket_name}=${NONE}
    Open Data Science Project Details Page       project_title=${project_title}    tab_id=data-connections
    ${is_exist}=  Run Keyword And Return Status
    ...    Wait Until Page Contains Element    ${DC_SECTION_XP}//tr[td[@data-label="Name"]/*/div[.="${dc_name}"]]
    IF  ${is_exist}
        Log    Data Connection '${dc_name}' already exists, updating connection    console=True
        Edit S3 Data Connection    project_title=${project_title}    dc_name=${dc_name}    new_dc_name=${dc_name}${SPACE}
        ...    aws_access_key=${aws_access_key}    aws_secret_access=${aws_secret_access}
        ...    aws_bucket_name=${aws_bucket_name}    aws_region=${aws_region}    press_cancel=${press_cancel}
        ...    aws_s3_endpoint=${aws_s3_endpoint}    connected_workbench=${connected_workbench}
    ELSE
        Log    Data Connection '${dc_name}' does not exist, creating a new connection    console=True
        Create S3 Data Connection    project_title=${project_title}    dc_name=${dc_name}
        ...    aws_access_key=${aws_access_key}    aws_secret_access=${aws_secret_access}
        ...    aws_bucket_name=${aws_bucket_name}    aws_region=${aws_region}    press_cancel=${press_cancel}
        ...    aws_s3_endpoint=${aws_s3_endpoint}
        ...    connected_workbench=${connected_workbench}
    END
