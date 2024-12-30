*** Settings ***
Documentation    Collection of keywords to interact with Data Connections
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***

${S3_NAME_DC_INPUT}=            xpath=//input[@data-testid="connection-name-desc-name"]
${S3_KEY_DC_INPUT}=             xpath=//*[contains(@data-testid,"AWS_ACCESS_KEY_ID")]//input
${S3_SECRET_DC_INPUT}=          xpath=//*[contains(@data-testid,"AWS_SECRET_ACCESS_KEY")]//input
${S3_ENDPOINT_DC_INPUT}=        xpath=//*[contains(@data-testid,"AWS_S3_ENDPOINT")]//input
${S3_REGION_DC_INPUT}=          xpath=//*[contains(@data-testid,"AWS_DEFAULT_REGION")]//input
${S3_BUCKET_DC_INPUT}=          xpath=//*[contains(@data-testid,"AWS_S3_BUCKET")]//input
${DC_SECTION}=                  xpath=//*[@data-testid="connection-table"]
${DC_ADD_BTN_1}=                xpath=//*[@data-testid="create-connection-button"]
${DC_ADD_BTN_2}=                xpath=//button[@data-testid="add-connection-button"]
${CONNECTION_TYPE_DROPDOWN}=    xpath=//label[@for="connection-type"]/parent::div/parent::div//input


*** Keywords ***
Create S3 Data Connection
    [Documentation]    Creates a S3 Data Connection from DS Project details page
    [Arguments]    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}
    ...            ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}    ${aws_region}=${S3.AWS_DEFAULT_REGION}
    ...            ${connected_workbench}=${NONE}    ${press_cancel}=${FALSE}    ${aws_bucket_name}=${NONE}
    Open Data Science Project Details Page       project_title=${project_title}    tab_id=connections
    # The button has two different possitions depending on if there are already created connections
    ${btn_2_is_shown}=    Run Keyword And Return Status    Element Should Be Visible    ${DC_ADD_BTN_2}
    IF    ${btn_2_is_shown}
        Click Element    ${DC_ADD_BTN_2}
    ELSE
        Click Element    ${DC_ADD_BTN_1}
    END
    Select Connection Type From Add Connection Modal    S3 compatible object storage - v1
    Fill Data Connection Form    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}
    ...            aws_s3_endpoint=${aws_s3_endpoint}    aws_region=${aws_region}
    ...            connected_workbench=${connected_workbench}    press_cancel=${press_cancel}
    ...            aws_bucket_name=${aws_bucket_name}

Edit S3 Data Connection
    [Documentation]    Edits a S3 Data Connection from DS Project details page
    [Arguments]    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}    ${new_dc_name}=${dc_name}
    ...            ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}    ${aws_region}=${S3.AWS_DEFAULT_REGION}
    ...            ${connected_workbench}=${NONE}    ${press_cancel}=${FALSE}    ${aws_bucket_name}=${NONE}
    Click Action From Actions Menu    item_title=${dc_name}    action=Edit
    Fill Data Connection Form    ${project_title}    ${new_dc_name}    ${aws_access_key}    ${aws_secret_access}
    ...            aws_s3_endpoint=${aws_s3_endpoint}    aws_region=${aws_region}
    ...            connected_workbench=${connected_workbench}    press_cancel=${press_cancel}
    ...            aws_bucket_name=${aws_bucket_name}

Data Connection Should Be Listed
    [Documentation]    Checks a Data Connection is listed in DS Project details page
    [Arguments]     ${name}   ${type}   ${connected_workbench}
    Move To Tab    tab_title=Connections
    ${connection}=    Set Variable    ${DC_SECTION}//tr[td[@data-label="Name"]//*[.="${name}"]]
    Run Keyword And Continue On Failure     Page Should Contain Element    ${connection}
    Run Keyword And Continue On Failure     Page Should Contain Element    ${connection}//*[contains(.,"${type}")]
    IF    "${connected_workbench}" == "${NONE}"
        Run Keyword And Continue On Failure    Page Should Contain Element
        ...    ${connection}//*[@data-label="Connected resources" and .="-"]
    ELSE
        FOR    ${index}    ${workbench_title}    IN ENUMERATE    @{connected_workbench}
            Log    ${index}: ${workbench_title}
            Run Keyword And Continue On Failure    Page Should Contain Element
            ...    ${connection}/td[@data-label="Connected resources"]//*[.="${workbench_title}"]
        END
    END

Data Connection Should Not Be Listed
    [Documentation]    Checks a Data Connection is not listed in DS Project details page
    [Arguments]     ${name}
    Move To Tab    tab_title=Connections
    ${connection}=    Set Variable    ${DC_SECTION}//tr[td[@data-label="Name"]//*[.="${name}"]]
    Run Keyword And Continue On Failure     Wait Until Page Does Not Contain Element    ${connection}

Get Openshift Secret From Data Connection
    [Documentation]    Retrieves name of Openshift secret corresponding to a given S3 Data Connection based on Dispayed name in DS Project details page
    [Arguments]     ${dc_name}      ${namespace}
    ${rc}  ${secret_name}=    Run And Return Rc And Output   oc get secret -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${dc_name}")].metadata.name}'
    RETURN    ${rc}    ${secret_name}

Delete Data Connection
    [Documentation]    Deletes a Data Connection from DS Project details page
    [Arguments]     ${name}    ${press_cancel}=${FALSE}
    Click Action From Actions Menu    item_title=${name}    action=Delete
    Handle Deletion Confirmation Modal    item_title=${name}    item_type=data connection    press_cancel=${press_cancel}

Fill Data Connection Form
    [Documentation]    Data Connection Form can be used in the create or edit
    [Arguments]    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}
    ...            ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}    ${aws_region}=${S3.AWS_DEFAULT_REGION}
    ...            ${connected_workbench}=${NONE}    ${press_cancel}=${FALSE}    ${aws_bucket_name}=${NONE}
    Wait Until Page Contains Element    ${S3_NAME_DC_INPUT}
    Scroll And Input Text Into Element    ${S3_NAME_DC_INPUT}    ${dc_name}
    Scroll And Input Text Into Element    ${S3_KEY_DC_INPUT}    ${aws_access_key}
    Scroll And Input Text Into Element    ${S3_SECRET_DC_INPUT}    ${aws_secret_access}
    Scroll And Input Text Into Element    ${S3_ENDPOINT_DC_INPUT}    ${aws_s3_endpoint}
    Scroll And Input Text Into Element    ${S3_REGION_DC_INPUT}    ${aws_region}
    Scroll And Input Text Into Element    ${S3_BUCKET_DC_INPUT}    ${aws_bucket_name}
    IF    ${press_cancel}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Wait Until Element Is Enabled    ${GENERIC_CREATE_BTN_XP}
        Click Button    ${GENERIC_CREATE_BTN_XP}
    END
    Wait Until Generic Modal Disappears
    Wait Until Project Is Open    project_title=${project_title}
    IF    "${connected_workbench}" == "${NONE}"
        Log    msg=you are not connecting any workbenchs to ${dc_name} DataConnection
    ELSE
        FOR    ${workbench_title}    IN    @{connected_workbench}
            Move To Tab    tab_title=Workbenches
            Click Action From Actions Menu    item_title=${workbench_title}    action=Edit
            Add Existing Data Connection In Workbench    data_connection=${dc_name}
            Click Element    ${GENERIC_SUBMIT_BTN_XP}
            Wait Until Element Is Not Visible    ${GENERIC_SUBMIT_BTN_XP}    10s
        END
    END

Get Data Connection Form Values
    [Arguments]    ${dc_name}
    Click Action From Actions Menu    item_title=${dc_name}    action=Edit
    Wait Until Page Contains Element    ${S3_NAME_DC_INPUT}
    ${s3_name}   Get Element Attribute    ${S3_NAME_DC_INPUT}      value
    ${s3_key}   Get Element Attribute    ${S3_KEY_DC_INPUT}      value
    ${s3_secret}   Get Element Attribute    ${S3_SECRET_DC_INPUT}      value
    ${s3_endpoint}   Get Element Attribute    ${S3_ENDPOINT_DC_INPUT}      value
    ${s3_region}   Get Element Attribute    ${S3_REGION_DC_INPUT}      value
    ${s3_bucket}   Get Element Attribute    ${S3_BUCKET_DC_INPUT}      value
    [return]    ${s3_name}    ${s3_key}    ${s3_secret}    ${s3_endpoint}    ${s3_region}    ${s3_bucket}

Recreate S3 Data Connection
    [Documentation]    Edit Exisisting Or Create New S3 Data Connection from DS Project details page
    [Arguments]    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}
    ...            ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}    ${aws_region}=${S3.AWS_DEFAULT_REGION}
    ...            ${connected_workbench}=${NONE}    ${press_cancel}=${FALSE}    ${aws_bucket_name}=${NONE}
    Open Data Science Project Details Page       project_title=${project_title}    tab_id=connections
    ${is_exist}=  Run Keyword And Return Status
    ...    Wait Until Page Contains Element    ${DC_SECTION}//tr[td[@data-label="Name"]/*/div[.="${dc_name}"]]
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

Select Connection Type From Add Connection Modal
    [Documentation]    Select connection type from Add Connection modal
    [Arguments]    ${connection_type}
    Wait Until Page Contains Element    xpath=//header/h1/span[text()="Add connection"]
    Wait Until Page Contains Element    ${CONNECTION_TYPE_DROPDOWN}
    Click Element    ${CONNECTION_TYPE_DROPDOWN}
    Sleep    1    reason=Sometimes it takes a little bit longer to finish rendering all the dropdown content
    Click Element    xpath=//div[@id="connection-type"]//button//span[text()="${connection_type}"]
