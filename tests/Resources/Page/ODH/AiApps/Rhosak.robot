*** Settings ***
Library     SeleniumLibrary
Library     ../../../../libs/Helpers.py
Library     OpenShiftCLI
Resource    ../JupyterHub/JupyterLabLauncher.robot
Resource    ../../Components/Components.resource
Resource    ../ODHDashboard/ODHDashboard.robot


*** Keywords ***
Check Consumer And Producer Output Equality
    [Documentation]    Checks the code cell outputs are equal between Producer and Consumer notebooks
    [Arguments]    ${producer_text}    ${consumer_text}
    ${producer_output_list}=    Text To List    text=${producer_text}
    ${consumer_output_list}=    Text To List    text=${consumer_text}
    Should Be Equal    ${producer_output_list}    ${consumer_output_list}[1:]

Open Producer Notebook
    [Documentation]    Open the Producer notebook in JL
    [Arguments]    ${dir_path}    ${filename}
    Open With JupyterLab Menu    File    Open from Path…
    Input Text    xpath=//input[@placeholder="/path/relative/to/jlab/root"]    ${dir_path}/${filename}
    Click Element    xpath://div[.="Open"]
    Wait Until ${filename} JupyterLab Tab Is Selected

Open Consumer Notebook
    [Documentation]    Open the Consumer notebook in JL
    [Arguments]    ${dir_path}    ${filename}
    Open With JupyterLab Menu    File    Open from Path…
    Input Text    xpath=//input[@placeholder="/path/relative/to/jlab/root"]    ${dir_path}/${filename}
    Click Element    xpath://div[.="Open"]
    Wait Until ${filename} JupyterLab Tab Is Selected

Enable RHOSAK
    [Documentation]    Perfors the RHOSAK activation though RHODS Dashboard
    Menu.Navigate To Page    Applications    Explore
    Wait Until Page Contains    ${RHOSAK_DISPLAYED_APPNAME}    timeout=30
    Click Element    xpath://*[@id='${RHOSAK_REAL_APPNAME}']
    Wait Until Page Contains Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}    timeout=10
    ...    error=${RHOSAK_REAL_APPNAME} does not have sidebar with information in the Explore page of ODS Dashboard
    Page Should Contain Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}
    ...    message=${RHOSAK_REAL_APPNAME} does not have a "Enable" button in ODS Dashboard
    Click Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}
    Wait Until Page Contains Element    xpath://div[contains(@id, 'pf-modal-part')]
    Click Button    xpath://footer/button[text()='Enable']
    Wait Until Page Contains Element    xpath://div[@class='pf-c-alert pf-m-success']

Remove RHOSAK From Dashboard
    [Documentation]    Uninstall RHOSAK from RHODS Dashboard
    Delete Configmap    name=rhosak-validation-result    namespace=redhat-ods-applications
    Close All Browsers
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=${RHOSAK_REAL_APPNAME}
