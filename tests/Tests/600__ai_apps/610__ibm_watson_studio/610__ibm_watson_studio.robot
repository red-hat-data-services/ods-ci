*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Library         SeleniumLibrary
Suite Setup     IBM Watson Studio Suite Setup
Suite Teardown  IBM Watson Studio Suite Teardown

*** Test Cases ***
Verify IBM Watson Studio Is Available In RHODS Dashboard Explore Page
  [Tags]  ODS-267  Smoke  Sanity
  Verify Service Is Available In The Explore Page    IBM Watson Studio
  Verify Service Provides "Get Started" Button In The Explore Page    IBM Watson Studio

Verify all the IBM Resources have been removed from RHODS Dashboard
    [Tags]  ODS-1139
    Click Link    Resources
    Sleep  5
    Input text      //input[@class="pf-c-search-input__text-input"]     IBM
    ${link_elements}=  Get WebElements    //a[@class="odh-card__footer__link" and not(starts-with(@href, '#'))]
    ${len}=  Get Length    ${link_elements}
    Should Be Equal As Integers     ${len}  0
    Menu.Navigate To Page    Applications    Explore
    Wait Until Page Contains    JupyterHub  timeout=30
    Page Should Not Contain Element     //article[@id="watson-studio"]

* Keywords ***
IBM Watson Studio Suite Setup
  Set Library Search Order  SeleniumLibrary
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

IBM Watson Studio Suite Teardown
  Close All Browsers
