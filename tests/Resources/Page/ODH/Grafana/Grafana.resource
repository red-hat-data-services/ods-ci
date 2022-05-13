*** Settings ***
Documentation    Contains Grafana Releted keyword
Library        OperatingSystem
Library        Process
Library        SeleniumLibrary


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
