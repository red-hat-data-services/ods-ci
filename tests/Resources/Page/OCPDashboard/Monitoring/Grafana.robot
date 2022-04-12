*** Settings ***
Documentation    Cointans Grafana Releted keyword
Library        OperatingSystem
Library        Process
Library        SeleniumLibrary
Library        RequestsLibrary

*** Variables ***
${SLIDE_MENU_DROPDOWN}          //div[@class="sidemenu-item dropdown"]
${GRAFANA_SEARCH_BUTTON}        //*[text()="Search"]


*** Keywords ***
Go To Grafana Dashbord Search
    [Documentation]    Check if Jupyterhub SLI option is available
    Wait Until Element Is Visible     ${SLIDE_MENU_DROPDOWN}
    Run Keywords
    ...    Click Element    ${SLIDE_MENU_DROPDOWN}
    ...    AND
    ...    Click Element    ${GRAFANA_SEARCH_BUTTON}

Wait Until Grafana Page Is UP
    [Arguments]  ${TIMEOUT}  ${RETRIES}=1
    [Documentation]  Wait until grafana Page is up and running
    FOR  ${i}   IN RANGE  ${TIMEOUT}
        Sleep  ${RETRIES}   msg=Waiting until port forwarding is active
        ${ret_code}  ${Output} =   Run And Return Rc And Output  GET http://localhost:3001/api/health
        Exit For Loop IF  ${ret_code} == 0
    END
    [Return]  ${Output}
