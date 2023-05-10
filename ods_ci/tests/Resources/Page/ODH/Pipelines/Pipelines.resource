*** Settings ***
Documentation    Keywords to interact with Pipeline runs


*** Variables ***
${PIPELINE_FAILED_RUN} =    //*[local-name() = 'svg'][@style="color: rgb(213, 0, 0); height: 18px; width: 18px;"]
${PIPELINE_SUCCESSFUL_RUN} =     //*[local-name() = 'svg'][@style="color: rgb(52, 168, 83); height: 18px; width: 18px;"]


*** Keywords ***
Verify Successful Pipeline Run
    [Documentation]    Given a job ID, this keyword expects to be on the details page of that job.
    ...    It will check that the pipeline run was successful, with a given timeout (in seconds)
    [Arguments]    ${job_id}    ${timeout}=300
    WHILE    True    limit=${timeout} seconds
        Wait Until Page Contains Element    xpath=//span[@title="${job_id}"]    timeout=30s
        ${failed} =    Run Keyword And Return Status    Page Should Contain Element    //span[@title="${job_id}"]${PIPELINE_FAILED_RUN}
        ${passed} =    Run Keyword And Return Status    Page Should Contain Element    //span[@title="${job_id}"]${PIPELINE_SUCCESSFUL_RUN}
        IF    ${failed}==False and ${passed}==True
            Capture Page Screenshot
            BREAK
        ELSE IF    ${failed}==True and ${passed}==False
            Capture Page Screenshot
            Fail
        ELSE IF    ${failed}==False and ${passed}==False
            Log    Pipeline Still Running
            Capture Page Screenshot
        ELSE
            Log    Unknown Status, Check Logs
            Capture Page Screenshot
            Fail
        END
        Sleep    10s
        Reload Page
    END
