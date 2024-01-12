*** Settings ***
Documentation    Contains Grafana Releted keyword
Resource        ../../../ODS.robot
Resource        ../../LoginPage.robot
Library         OperatingSystem
Library         Process
Library         SeleniumLibrary


*** Variables ***
${SLIDE_MENU_DROPDOWN}          //div[@class="sidemenu-item dropdown"]
${GRAFANA_SEARCH_BUTTON}        //*[text()="Search"]


*** Keywords ***
Go To Grafana Dashboard Search
    [Documentation]    Check if Jupyterhub SLI option is available
    Wait Until Element Is Visible     ${SLIDE_MENU_DROPDOWN}
    Run Keywords
    ...    Click Element    ${SLIDE_MENU_DROPDOWN}
    ...    AND
    ...    Click Element    ${GRAFANA_SEARCH_BUTTON}

Launch Grafana
    [Documentation]    Opens Grafana in Browser
    [Arguments]  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}  ${grafana_url}  ${browser}  ${browser_options}
    Open Browser  url=${grafana_url}  browser=${browser}  options=${browser_options}
    Wait Until Page Contains    text=Log in with OpenShift    timeout=15s
    Login To Grafana  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}

Login To Grafana
    [Documentation]    Login to Grafana
    [Arguments]  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
    ${oauth_prompt_visible} =  Is OpenShift OAuth Login Prompt Visible
    IF  ${oauth_prompt_visible}  Click Button  Log in with OpenShift
    ${login_required} =  Is OpenShift Login Visible
    IF  ${login_required}  Login To Openshift  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
    ${authorize_service_account} =  Is grafana Service Account Authorization Required
    IF  ${authorize_service_account}  Authorize Grafana Service Account

Authorize Grafana Service Account
    [Documentation]  Authorize Grafana Service Account
    Wait Until Page Contains  Authorize Access
    Checkbox Should Be Selected  user:info
    Click Element  approve

Select Explore
    [Documentation]  Selects Explore From Grafana Home Page
    Click Element    xpath=/html/body/grafana-app/sidemenu/div[2]/div[3]/a/span
    Wait Until Page Contains Element    xpath=//div[contains(@class,'grafana-select-value')]    timeout=60

Select Data Source
    [Documentation]  Selects The Given Data Source
    [Arguments]  ${datasource_name}
    Input Text    xpath=//div[contains(@class,'grafana-select-value')]//input    text=${datasource_name}
    Press Keys    None    RETURN
    Sleep    2    reason=Wait for Data Source to get selected

Run Promql Query
    [Documentation]  Runs Given PromQL Query
    [Arguments]  ${query}
    Press Keys    xpath=//span[contains(text(),'Enter a PromQL query')]    ${query}
    Press Keys    None    SHIFT+ENTER
