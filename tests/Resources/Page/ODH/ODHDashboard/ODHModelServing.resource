*** Settings ***
Documentation    Collection of keywords to interact with Model Serving
Resource       ../../../Page/Components/Components.resource
Resource       ../../../Common.robot

*** Variables ***
${MS_HEADER_XP}=     xpath=//h1[text()="Deployed models"]
${S3_NAME_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field Name"]
${S3_KEY_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_ACCESS_KEY_ID"]
${S3_SECRET_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_SECRET_ACCESS_KEY"]
${S3_ENDPOINT_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_S3_ENDPOINT"]
${S3_REGION_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_DEFAULT_REGION"]
${S3_BUCKET_DC_INPUT_XP}=     xpath=//input[@aria-label="AWS field AWS_S3_BUCKET"]
${S3_DEFAULT_ENDPOINT}=    https://s3.amazonaws.com/
${S3_DEFAULT_REGION}=    us-east-1
${S3_DEFAULT_BUCKET}=    ods-ci-s3
${MS_TABLE_PROJECT}=    /../../td[@data-label="Project"]
${MS_TABLE_STATUS}=    /../../td[@data-label="Status"]
${MS_TABLE_ENDPOINT}=    /../../td[@data-label="Inference endpoint"]
${MS_TABLE_ENDPOINT_INPUT}=    ${MS_TABLE_ENDPOINT}//div[@class="pf-c-clipboard-copy__group"]/input
${MS_TABLE_DROPDOWN_TOGGLE}=    /../../td[@class="pf-c-table__action"]//button
${MS_TABLE_STATUS_SUCCESS}=    //span[contains(@class,"pf-c-icon__content")][contains(@class,"pf-m-success")]
${MS_TABLE_STATUS_FAILURE}=    //span[contains(@class,"pf-c-icon__content")][contains(@class,"pf-m-danger")]


*** Keywords ***
Open Model Serving Home Page
    [Documentation]    Verifies submenu Settings > "Model Serving" is visible and navigates to page
    Page Should Contain    Model Serving
    Click Link      Model Serving
    Wait Until Page Contains    Manage and view the health and performance of your deployed models.    timeout=30
    Wait Until Page Contains Element    ${MS_HEADER_XP}    timeout=30
    Maybe Wait For Dashboard Loading Spinner Page

Serve Model
    [Documentation]    Deploys a model via the Model Serving page (NOT the Model Server section of a DSP)
    ...    the framework should be either "onnx" or "openvino_ir". 
    [Arguments]    ${project_name}    ${model_name}    ${framework}    ${data_connection_name}    ${model_path}
    ...    ${existing_data_connection}=${TRUE}
    # TODO: Does not work if there's already a model deployed
    Wait Until Page Contains    Serve model
    Click Button    Serve model
    Wait Until Page Contains Element    xpath://h1[.="Deploy model"]
    Select Project    ${project_name}
    Set Model Name    ${model_name}
    Select Framework    ${framework}
    IF    ${existing_data_connection}==${TRUE} 
        # Select Radio Button    group_name=radiogroup    value=existing-data-connection-radio
        # Selected by default, let's skip for now
        Select Existing Data Connection    ${data_connection_name}
        Set Folder Path    ${model_path}
    ELSE
        # Existing connection radio is selected by default; for now blindly click on new connection radio
        Click Element    //input[@id="new-data-connection-radio"]
        # Select Radio Button    group_name=radiogroup    value=new-data-connection-radio
        Set Up New Data Connection    dc_name=${data_connection_name}
        Set Folder Path    ${model_path}
    END
    Click Button    Deploy
    Wait Until Page Does Not Contain    xpath://h1[.="Deploy model"]

Select Project
    [Documentation]    Selects a project in the "deploy model" modal. 
    ...    If the user has access to a single project or this is being done from within a DSP
    ...    there's no need to do anything but it checks that the project name is the expected one.
    [Arguments]    ${project_name}
    Wait Until Page Contains Element    xpath://span[.="Project"]
    ${choice}=    Run Keyword And Return Status    Page Should Not Contain Element    xpath://span[.="Project"]/../../..//p[.="${project_name}"]
    IF    ${choice}==${TRUE}
        Open Project Options Menu
        Click Element    xpath://li/button[.="${project_name}"]
        Wait Until Page Contains Element    //span[.="Project"]/../../..//span[.="${project_name}"]
    END

Set Model Name
    [Documentation]    Sets the model name in the "deploy model" modal
    [Arguments]    ${model_name}
    Input Text    xpath://input[@id="inference-service-name-input"]    ${model_name}

Select Framework
    [Documentation]    Selects the framework in the "deploy model" modal.
    ...    Possible values for now: "onnx", "openvino_ir"
    [Arguments]    ${framework}
    IF    "${framework}" == "onnx" or "${framework}" == "openvino_ir"
        Open Model framework Options Menu
        Click Element    xpath://li/button[contains(., "${framework}")]
    ELSE
        Fail    msg=unknown framework ${framework}, use one among "onnx" or "openvino_ir"
    END

Select Existing Data Connection
    [Documentation]    Selects an existing data connection in the "deploy model" modal.
    [Arguments]    ${data_connection_name}
    Open Name Options Menu
    Click Element    xpath://li/button[.="${data_connection_name}"]

Set Folder Path
    [Documentation]    Sets the given model path in the "deploy model" modal.
    ...    The path is expected to be relative to the S3 bucket being used.
    ...    e.g.: file in root of S3 bucket -> model_path = filename
    ...    e.g.: file in subfolder of S3 bucket -> model_path = subfolder/filename
    [Arguments]    ${model_path}
    Input Text    xpath://input[@id="storage-path"]    ${model_path}

Set Up New Data Connection
    [Documentation]    Fills in details for new data connection in "deploy model" modal
    [Arguments]    ${dc_name}    ${aws_access_key}=${S3.AWS_ACCESS_KEY_ID}
    ...    ${aws_bucket_name}=${S3_DEFAULT_BUCKET}    ${aws_secret_access}=${S3.AWS_SECRET_ACCESS_KEY}
    ...    ${aws_region}=${S3.AWS_DEFAULT_REGION}    ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}
    Wait Until Page Contains Element    ${S3_NAME_DC_INPUT_XP}
    Input Text    ${S3_NAME_DC_INPUT_XP}    ${dc_name}
    Input Text    ${S3_KEY_DC_INPUT_XP}    ${aws_access_key}
    Input Text    ${S3_SECRET_DC_INPUT_XP}    ${aws_secret_access}
    Input Text    ${S3_ENDPOINT_DC_INPUT_XP}    ${aws_s3_endpoint}
    Input Text    ${S3_REGION_DC_INPUT_XP}    ${aws_region}
    Input Text    ${S3_BUCKET_DC_INPUT_XP}    ${aws_bucket_name}

Verify Model Status
    [Documentation]    Checks the reported model status in the Model Serving page in the dashboard.
    ...    status can be "success" or any other string (which will expect failure status). this does NOT work
    ...    for the status in the "Model server" section of a DSP.
    [Arguments]    ${model_name}    ${expected_status}=success
    IF    "${expected_status}"=="success"
        Wait Until Keyword Succeeds    30s    5s    Page Should Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}${MS_TABLE_STATUS_SUCCESS}
        Page Should Not Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}${MS_TABLE_STATUS_FAILURE}
    ELSE
        Wait Until Keyword Succeeds    30s    5s    Page Should Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}${MS_TABLE_STATUS_FAILURE}
        Page Should Not Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}${MS_TABLE_STATUS_SUCCESS}
    END

Delete Model Via UI
    [Documentation]    Deletes a deployed model from the Model Serving page in the dashboard.
    [Arguments]    ${model_name}
    Click Element    //div[.="${model_name} "]${MS_TABLE_DROPDOWN_TOGGLE}
    Click Element    //div[.="${model_name} "]${MS_TABLE_DROPDOWN_TOGGLE}/..//button[.="Delete"]
    Wait Until Page Contains Element    xpath://input[@id="delete-modal-input"]
    Input Text    xpath://input[@id="delete-modal-input"]    ${model_name}
    Click Button    Delete deployed model
    Wait Until Page Does Not Contain Element    //div[.="${model_name} "]

Open Model Edit Modal
    [Documentation]    Opens the modal used to edit the details of an already deployed model.
    [Arguments]    ${model_name}
    Click Element    //div[.="${model_name} "]${MS_TABLE_DROPDOWN_TOGGLE}
    Click Element    //div[.="${model_name} "]${MS_TABLE_DROPDOWN_TOGGLE}/..//button[.="Edit"]
    Wait Until Page Contains    xpath://h1[.="Deploy model"]

Get Model Route via UI
    [Documentation]    Grabs the serving route (URL) of an already deployed model from the Model Serving page.
    [Arguments]    ${model_name}
    ${url}=    Get Element Attribute    //div[.="${model_name} "]${MS_TABLE_ENDPOINT_INPUT}    value
    [Return]    ${url}

Open ${section} Options Menu
    [Documentation]    Opens the "Options menu" dropdown for different sections
    ...    Valid sections are: "Name", "Model framework", "Project"
    Click Element    xpath://span[.="${section}"]/../../..//button[@aria-label="Options menu"]

    # //div[.="test-model-no-token "]/../../td[@data-label="Project"] (.= project name)
    # //div[.="test-model-no-token "]/../../td[@data-label="Inference endpoint"]//div[@class="pf-c-clipboard-copy__group"]/input (value=url)
    # //div[.="test-model-no-token "]/../../td[@data-label="Status"]//span[contains(@class,"pf-c-icon__content")] (class=status?) (pf-m-danger > failed)  (pf-m-danger) (pf-m-success)
    # //div[.="test-model-no-token "]/../../td[@data-label="Status"]//span[contains(@class,"pf-c-icon__content")]
    # //div[.="test-model-no-token "]/../../td[@class="pf-c-table__action"]//button
    # //div[.="test-model-no-token "]/../../td[@class="pf-c-table__action"]//button/..//button[.="Edit"]
    # //div[.="test-model-no-token "]/../../td[@class="pf-c-table__action"]//button/..//button[.="Delete"]
