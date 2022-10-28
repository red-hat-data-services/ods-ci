*** Settings ***
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
# ${DC_DELETE_BTN_XP}=                 xpath=//button[text()="Delete data connection"]


*** Keywords ***
Create S3 Data Connection
    [Arguments]    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}    ${aws_s3_endpoint}    ${aws_region}    ${connected_workbench}=${NONE}    ${press_cancel}=${FALSE}    
    Click Button    ${DC_ADD_BTN_1_XP} 
    Wait Until Page Contains Element    ${S3_NAME_DC_INPUT_XP}
    Input Text    ${S3_NAME_DC_INPUT_XP}    ${dc_name}
    Input Text    ${S3_KEY_DC_INPUT_XP}    ${aws_access_key}
    Input Text    ${S3_SECRET_DC_INPUT_XP}    ${aws_secret_access}
    Input Text    ${S3_ENDPOINT_DC_INPUT_XP}    ${aws_s3_endpoint}
    Input Text    ${S3_REGION_DC_INPUT_XP}    ${aws_region}
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE    
        Wait Until Element Is Enabled    ${STORAGE_ADD_BTN_2_XP}
        Click Button    ${STORAGE_ADD_BTN_2_XP}
    END
    Wait Until Modal Disappears
    Wait Until Project Is Open    project_title=${project_title}

Data Connection Should Be Listed
    [Arguments]     ${name}   ${type}   ${connected_workbench}
    Run keyword And Continue On Failure     Page Should Contain Element    ${DC_SECTION_XP}//td[@data-label="Name"]/h4[text()="${name}"]
    Run keyword And Continue On Failure     Page Should Contain Element    ${DC_SECTION_XP}//tr[td[@data-label="Name"]/h4[text()="${name}"]]/td[text()=" ${type}"]
    IF    "${connected_workbench}" == "${NONE}"
        Run Keyword And Continue On Failure    Page Should Contain Element    ${DC_SECTION_XP}//tr[td[@data-label="Name"]/h4[text()="${name}"]]/td[text()="No connections"]
    ELSE
        FOR    ${index}    ${workbench_title}    IN ENUMERATE    @{connected_workbench}
            Log    ${index}: ${workbench_title}
            Run Keyword And Continue On Failure    Page Should Contain Element    ${DC_SECTION_XP}//tr[td[@data-label="Name"]/h4[text()="${name}"]]/td[@data-label="Connected workbenches"]/ul/li[text()="${workbench_title}"]
        END
    END

Data Connection Should Not Be Listed
    [Arguments]     ${name}
    Run keyword And Continue On Failure     Wait Until Page Does Not Contain Element    ${DC_SECTION_XP}//tr[td[@data-label="Name"]/h4[text()="${name}"]]

Get Openshift Secret From Data Connection
    [Arguments]     ${dc_name}      ${namespace}
    ${rc}  ${secret_name}=    Run And Return Rc And Output   oc get secret -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${dc_name}")].metadata.name}'
    [Return]    ${rc}    ${secret_name}

Delete Data Connection
    [Arguments]     ${name}    ${press_cancel}=${FALSE}
    Click Action From Actions Menu    item_title=${name}    item_type=data connection    action=Delete
    Handle Deletion Confirmation Modal    item_title=${name}    item_type=data connection    press_cancel=${press_cancel}