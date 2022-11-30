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


*** Keywords ***
Open Model Serving Home Page
    [Documentation]    Verifies submenu Settings > "Model Serving" is visible and navigates to page
    Page Should Contain    Model Serving
    Click Link      Model Serving
    Wait Until Page Contains    Manage and view the health and performance of your deployed models.    timeout=30
    Wait Until Page Contains Element    ${MS_HEADER_XP}    timeout=30
    Maybe Wait For Dashboard Loading Spinner Page

Serve Model
    [Documentation]
    [Arguments]    ${project_name}    ${model_name}    ${framework}    ${data_connection_name}    ${model_path}
    ...    ${existing_data_connection}=${TRUE}
    Wait Until Page Contains    Serve model
    Click Button    Serve model
    Wait Until Page Contains Element    xpath://h1[.="Deploy model"]
    Select Project    ${project_name}
    Set Model Name    ${model_name}
    Select Framework    ${framework}
    IF    ${existing_data_connection}==${TRUE} 
        #Select Radio Button    group_name=radiogroup    value=existing-data-connection-radio
        #Selected by default, let's skip for now
        Select Existing Data Connection    ${data_connection_name}
        Set Folder Path    ${model_path}
    ELSE
        Select Radio Button    group_name=radiogroup    value=new-data-connection-radio
        Set Up New Data Connection    dc_name=${data_connection_name}
        Set Folder Path    ${model_path}
    END
    Click Button    Deploy
    Wait Until Page Does Not Contain    xpath://h1[.="Deploy model"]

Select Project
    [Documentation]
    [Arguments]    ${project_name}
    # If there's only one project for the user, no need to do anything - let's check it has the correct name though
    Wait Until Page Contains Element    xpath://span[.="Project"]
    ${choice}=    Run Keyword And Return Status    Page Should Not Contain Element    xpath://span[.="Project"]/../../..//p[.="${project_name}"]
    IF    ${choice}==${TRUE}
        Click Element    xpath://span[.="Project"]/../../..//button[@aria-label="Options menu"]
        Click Element    xpath://li/button[.="${project_name}"]
        Sleep    1s  # After selecting the project the modal refreshes and can cause issues to Selenium
    END

Set Model Name
    [Documentation]
    [Arguments]    ${model_name}
    Input Text    xpath://input[@id="inference-service-name-input"]    ${model_name}

Select Framework
    [Documentation]
    [Arguments]    ${framework}
    Click Element    xpath://span[.="Model framework"]/../../..//button[@aria-label="Options menu"]
    Click Element    xpath://li/button[contains(., "${framework}")]


Select Existing Data Connection
    [Documentation]
    [Arguments]    ${data_connection_name}
    Click Element    xpath://span[.="Name"]/../../..//button[@aria-label="Options menu"]
    Click Element    xpath://li/button[.="${data_connection_name}"]

Set Folder Path
    [Documentation]
    [Arguments]    ${model_path}
    Input Text    xpath://input[@id="storage-path"]    ${model_path}

Set Up New Data Connection
    [Documentation]
    [Arguments]    ${dc_name}    ${aws_access_key}=${S3.AWS_ACCESS_KEY_ID}
    ...    ${aws_bucket_name}=${S3_DEFAULT_BUCKET}    ${aws_secret_access}=${S3.AWS_SECRET_ACCESS_KEY}
    ...    ${aws_region}=${S3_DEFAULT_REGION}    ${aws_s3_endpoint}=${S3_DEFAULT_ENDPOINT}
    Wait Until Page Contains Element    ${S3_NAME_DC_INPUT_XP}
    Input Text    ${S3_NAME_DC_INPUT_XP}    ${dc_name}
    Input Text    ${S3_KEY_DC_INPUT_XP}    ${aws_access_key}
    Input Text    ${S3_SECRET_DC_INPUT_XP}    ${aws_secret_access}
    Input Text    ${S3_ENDPOINT_DC_INPUT_XP}    ${aws_s3_endpoint}
    Input Text    ${S3_REGION_DC_INPUT_XP}    ${aws_region}
    Input Text    ${S3_BUCKET_DC_INPUT_XP}    ${aws_bucket_name}

Verify Model Status
    [Documentation]
    [Arguments]    ${model_name}    ${expected_status}=success
    IF    "${expected_status}"=="success"
        Wait Until Keyword Succeeds    30s    5s    Page Should Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}//span[contains(@class,"pf-c-icon__content")][contains(@class,"pf-m-success")]
        Page Should Not Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}//span[contains(@class,"pf-c-icon__content")][contains(@class,"pf-m-danger")]
    ELSE
        Wait Until Keyword Succeeds    30s    5s    Page Should Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}//span[contains(@class,"pf-c-icon__content")][contains(@class,"pf-m-danger")]
        Page Should Not Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}//span[contains(@class,"pf-c-icon__content")][contains(@class,"pf-m-success")]
    END

Delete Model Via UI
    [Documentation]
    [Arguments]    ${model_name}
    Click Element    //div[.="${model_name} "]/../../td[@class="pf-c-table__action"]//button
    Click Element    //div[.="${model_name} "]/../../td[@class="pf-c-table__action"]//button/..//button[.="Delete"]
    Input Text    xpath://input[@id="delete-modal-input"]    ${model_name}
    Click Button    Delete deployed model
    Wait Until Page Does Not Contain Element    //div[.="${model_name} "]

Open Model Edit Modal
    [Documentation]
    [Arguments]    ${model_name}
    Click Element    //div[.="${model_name} "]/../../td[@class="pf-c-table__action"]//button
    Click Element    //div[.="${model_name} "]/../../td[@class="pf-c-table__action"]//button/..//button[.="Delete"]
    Wait Until Page Contains    xpath://h1[.="Deploy model"]

Get Model Route via UI
    [Documentation]
    [Arguments]    ${model_name}
    ${url}=    Get Element Attribute    //div[.="${model_name} "]${MS_TABLE_ENDPOINT_INPUT}    value
    [Return]    ${url}
    # //div[.="test-model-no-token "]/../../td[@data-label="Project"] (.= project name)
    # //div[.="test-model-no-token "]/../../td[@data-label="Inference endpoint"]//div[@class="pf-c-clipboard-copy__group"]/input (value=url)
    # //div[.="test-model-no-token "]/../../td[@data-label="Status"]//span[contains(@class,"pf-c-icon__content")] (class=status?) (pf-m-danger > failed)  (pf-m-danger) (pf-m-success)
    # //div[.="test-model-no-token "]/../../td[@data-label="Status"]//span[contains(@class,"pf-c-icon__content")]
    # //div[.="test-model-no-token "]/../../td[@class="pf-c-table__action"]//button
    # //div[.="test-model-no-token "]/../../td[@class="pf-c-table__action"]//button/..//button[.="Edit"]
    # //div[.="test-model-no-token "]/../../td[@class="pf-c-table__action"]//button/..//button[.="Delete"]