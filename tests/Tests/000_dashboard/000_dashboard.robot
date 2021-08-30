*** Settings ***
# Resource  ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
# Library         SeleniumLibrary
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Library         RequestsLibrary
Test Setup      Dashboard Test Setup
Test Teardown   Dashboard Test Teardown

*** Keywords ***
Dashboard Test Setup
  Set Library Search Order  SeleniumLibrary

Dashboard Test Teardown
  Close All Browsers

Get HTTP Status Code
    [Arguments]  ${link_to_check}
    ${response}=    GET  ${link_to_check}   expected_status=any
    Run Keyword And Continue On Failure  Status Should Be  200
    [Return]  ${response.status_code}


*** Test Cases ***
Verify Resource Link Http status code
    [Tags]  BD-Test
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    #Wait for ODH Dashboard to Load
    Click Link    Resources
    Sleep  5
    ${link_elements}=  Get WebElements    //a[@class="odh-card__footer__link" and not(starts-with(@href, '#'))]
    ${len}=  Get Length    ${link_elements}
    Log To Console    ${len} Links found\n
    FOR  ${idx}  ${ext_link}  IN ENUMERATE  @{link_elements}  start=1
        ${href}=  Get Element Attribute    ${ext_link}    href
        ${status}=  Get HTTP Status Code   ${href}
        Log To Console    ${idx}. ${href} gets status code ${status}
    END



