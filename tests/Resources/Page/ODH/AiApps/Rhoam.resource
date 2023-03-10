*** Settings ***
Documentation       Keyword suites to interact with RHOAM addon

Resource            ../../ODH/ODHDashboard/ODHDashboard.robot
Library             OpenShiftLibrary


*** Variables ***
${RHOAM_DISPLAYED_NAME}=    OpenShift API Management


*** Keywords ***
Get RHOAM Installation Stage
    [Documentation]     Get the installation stage by reading the "RHOAM installation object" YAML
    ${rhmi_stage}=     Run    oc get rhmi rhoam -n redhat-rhoam-operator -o json | jq .status.stage | sed 's/"//g'
    RETURN    ${rhmi_stage}

RHOAM Installation Stage Should Be
    [Documentation]     Check if the current installation stage is the expected one
    [Arguments]    ${exp_stage}
    ${current_stage}=   Get RHOAM Installation Stage
    Should Be Equal    ${rhmi_stage}    ${exp_stage}

Wait Until RHOAM Installation Is Completed
    [Documentation]     It waits until the installation is completed (i.e., stage is equal to "complete")
    [Arguments]     ${retries}=30   ${retries_interval}=2min
    FOR  ${retry_idx}  IN RANGE  0  1+${retries}
        Log To Console    checking rhoam stage: retry ${retry_idx}
        ${current_stage}=   Get RHOAM Installation Stage
        Log To Console    RHOAM current installation stage: ${current_stage}
        ${completed_flag}=     Run Keyword And Return Status    Should Be Equal    ${current_stage}    complete
        Exit For Loop If    $completed_flag == True
        Sleep    ${retries_interval}
    END
    IF    $completed_flag == False
        Fail    RHOAM didn't get "complete" stage after ${retries} retries.
        ...     (time between retries: ${retries_interval}). Check the cluster..
    END

Verify RHOAM Is Enabled In RHODS Dashboard
    [Documentation]     Open the RHODS dashboard and checks if the RHOAM card
    ...                 is present in Enabled page
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Verify Service Is Enabled    app_name=${RHOAM_DISPLAYED_NAME}
    Launch ${RHOAM_DISPLAYED_NAME} From RHODS Dashboard Link
