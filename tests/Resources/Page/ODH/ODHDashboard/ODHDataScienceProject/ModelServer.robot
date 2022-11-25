*** Settings ***
Documentation    Collection of keywords to interact with Model Servers
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${S3_NAME_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field Name"]
${S3_KEY_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_ACCESS_KEY_ID"]
${S3_SECRET_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_SECRET_ACCESS_KEY"]
${S3_ENDPOINT_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_S3_ENDPOINT"]
${S3_REGION_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_DEFAULT_REGION"]
${DC_SECTION_XP}=             xpath=//div[div//h4[@id="data-connections"]]
${DC_ADD_BTN_1_XP}=           ${DC_SECTION_XP}/div/button[text()="Add data connection"]
${DC_ADD_BTN_2_XP}=           xpath=//footer/button[text()="Add data connection"]
${S3_BUCKET_DC_INPUT_XP}=     xpath=//input[@aria-label="AWS field AWS_S3_BUCKET"]
${S3_DEFAULT_ENDPOINT}=    https://s3.amazonaws.com/
${S3_DEFAULT_REGION}=    us-east-1


*** Keywords ***
Create Model Server
    [Documentation]    Keyword to create a Model Server in a Data Science Project
    [Arguments]    ${no_replicas}=1    ${server_size}=Small    ${ext_route}=${TRUE}    ${token}=${TRUE}
    Click Button    Configure server
    Wait Until Page Contains    //span[.="Configure model server"]
    Set Replicas Number With Buttons    ${no_replicas}
    Set Server Size    ${server_size}
    IF    ${ext_route}==${TRUE}
        Enable External Serving Route
    END
    IF    ${token}==${TRUE}
        Enable Token Authentication
        # Set Service Account name
        # Add Service Account
    END
    Click Button    Configure

Set Replicas Number With Buttons
    [Documentation]    Sets the number of replicas for the model serving pod
    [Arguments]    ${number}
    ${current}=    Get Element Attribute    xpath://div[@class="pf-c-number-input"]/div/input    value
    ${difference}=    Evaluate    int(${number})-int(${current})
    ${op}=    Set Variable    plus
    IF    ${difference}<${0}
        ${difference}=    Evaluate    abs(${difference})
        ${op}=    Set Variable    minus
    END
    FOR  ${idx}  IN RANGE  ${difference}
        IF ${op}==plus
            Click Plus Button
        ELSE
            Click Minus Button
        END
    END
    ${current}=    Get Element Attribute    xpath://div[@class="pf-c-number-input"]/div/input    value
    Should Be Equal As Integers    ${current}    ${number}

Set Server Size
    [Documentation]    Sets the size of the model serving pod
    ...    Can be "Small", "Medium", "Large", "Custom"
    ...    If "Custom", need CPU request/limit and Memory request/limit
    [Arguments]    ${size}
    Click Element    xpath://button[@aria-label="Options menu"]
    #Does Not Work for "Custom"
    #//li/button[.="Custom"]
    Click Element    xpath://li//span[.="${size}"]/../../button
    #TODO: Implement Custom

Enable External Serving Route
    [Documentation]    Enables the serving route to be accessed externally
    Select Checkbox    xpath://input[@id="alt-form-checkbox-route"]

Enable Token Authentication
    [Documentation]    Enables Token authentication to serving route
    Select Checkbox    xpath://input[@id="alt-form-checkbox-auth"]
    #TODO: change service account name