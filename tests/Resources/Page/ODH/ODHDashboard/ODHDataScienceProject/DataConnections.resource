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


*** Keywords ***
Create S3 Data Connection
    [Arguments]    ${project_title}    ${dc_name}    ${aws_access_key}    ${aws_secret_access}    ${aws_s3_endpoint}    ${aws_region}    ${connected_wrksp}=${NONE}    ${press_cancel}=${FALSE}    
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
    [Arguments]     ${name}   ${type}   ${connected_wrksp}
    Run keyword And Continue On Failure     Page Should Contain Element    ${DC_SECTION_XP}//td/h4[text()="${name}"]
    Run keyword And Continue On Failure     Page Should Contain Element    ${DC_SECTION_XP}//tr[td/h4[text()="${name}"]]/td[text()=" ${type}"]
    IF    "${connected_wrksp}" == "${NONE}"
        Run Keyword And Continue On Failure    Page Should Contain Element    ${DC_SECTION_XP}//tr[td/h4[text()="${name}"]]/td[text()="No connections"]
    ELSE
        FOR    ${index}    ${wrksp_title}    IN ENUMERATE    @{connected_wrksp}
            Log    ${index}: ${wrksp_title}
            Run Keyword And Continue On Failure    Page Should Contain Element    ${DC_SECTION_XP}//tr[td/h4[text()="${name}"]]/td/ul/li[text()="${wrksp_title}"]
        END
    END

Get Openshift Secret From Data Connection
    [Arguments]     ${dc_name}      ${namespace}
    ${rc}  ${secret_name}=    Run And Return Rc And Output   oc get secret -n ${namespace} -o jsonpath='{.items[?(@.metadata.annotations.openshift\\.io/display-name=="${dc_name}")].metadata.name}'
    [Return]    ${rc}    ${secret_name}
