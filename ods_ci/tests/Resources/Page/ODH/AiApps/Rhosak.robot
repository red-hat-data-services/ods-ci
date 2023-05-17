*** Settings ***
Library     SeleniumLibrary
Library     ../../../../../libs/Helpers.py
Resource    ../JupyterHub/JupyterLabLauncher.robot
Resource    ../../Components/Components.resource
Resource    ../ODHDashboard/ODHDashboard.robot
Resource    ../../../ODS.robot


*** Keywords ***
Enable RHOSAK
    [Documentation]    Perfors the RHOSAK activation though RHODS Dashboard
    Menu.Navigate To Page    Applications    Explore
    Wait For RHODS Dashboard To Load    expected_page=Explore
    ${status}=    Open Get Started Sidebar And Return Status    card_locator=//*[@id='${RHOSAK_REAL_APPNAME}']
    Run Keyword And Continue On Failure    Should Be Equal    ${status}    ${TRUE}
    Page Should Contain Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}
    ...    message=${RHOSAK_REAL_APPNAME} does not have a "Enable" button in ODS Dashboard
    Click Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}
    Wait Until Page Contains Element    xpath://div[contains(@id, 'pf-modal-part')]
    Click Button    xpath://footer/button[text()='Enable']
    Wait Until Page Contains Element    xpath://div[@class='pf-c-alert pf-m-success']

Remove RHOSAK From Dashboard
    [Documentation]    Uninstall RHOSAK from RHODS Dashboard
    Delete RHODS Config Map    name=rhosak-validation-result    namespace=redhat-ods-applications
    #Delete Configmap    name=rhosak-validation-result    namespace=redhat-ods-applications
    Close All Browsers
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=${RHOSAK_REAL_APPNAME}
