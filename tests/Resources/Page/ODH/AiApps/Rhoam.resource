*** Settings ***
Documentation       Keyword suites to interact with Anaconda Commercial Edition

Resource            ../../ODH/ODHDashboard/ODHDashboard.robot
Library             OpenShiftCLI
Library             OperatingSystem


*** Variables ***
${RHOAM_DISPLAYED_NAME}=    OpenShift API Management

*** Keywords ***
Get RHOAM Installation Stage
    # ${rhmi_obj}=    OpenshiftCLI.Get    kind=RHMI    name=rhoam    namespace=redhat-rhoam-operator
    ${rhmi_stage}=     Run    oc get rhmi rhoam -n redhat-rhoam-operator -o json | jq .status.stage | sed 's/"//g'
    [Return]    ${rhmi_stage}

RHOAM Installation Stage Should Be
    [Arguments]    ${exp_stage}
    ${current_stage}=   Get RHOAM Installation Stage
    Should Be Equal    ${rhmi_stage}    ${exp_stage}

Wait Until RHOAM Installation Is Completed
    [Arguments]     ${retries}=20   ${retries_interval}=2min
    # Wait Until Keyword Succeeds    40 min    1 min    RHOAM Installation Stage Should Be   complete
    FOR  ${retry_idx}  IN RANGE  0  1+${retries}
        Log To Console    checking rhoam stage: retry ${retry_idx}+1
        ${current_stage}=   Get RHOAM Installation Stage
        Log To Console    RHOAM current installation stage: ${current_stage}
        ${completed_flag}=     Run Keyword And Return Status    Should Be Equal    ${current_stage}    complete
        Exit For Loop If    $completed_flag == True
        Sleep    ${retries_interval}
    END
    IF    $completed_flag == False
        Fail    RHOAM didn't get "complete" stage after ${retries} retries. Check the installation..
    END

Verify RHOAM Is Enabled IN RHODS Dashboard
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Verify Service Is Enabled    app_name=${RHOAM_DISPLAYED_NAME}
