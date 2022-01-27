*** Settings ***
Resource         ../../Resources/ODS.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Test Setup      Dashboard Test Setup
Test Teardown   Dashboard Test Teardown


*** Keywords ***
Dashboard Test Setup
  Set Library Search Order  SeleniumLibrary
  Load App Info JSON File
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

Dashboard Test Teardown
  Close All Browsers


*** Test Cases ***
Verify Resource Link Http status code
    [Tags]  Sanity
    ...     ODS-531
    Click Link    Resources
    Sleep  5
    ${link_elements}=  Get WebElements    //a[@class="odh-card__footer__link" and not(starts-with(@href, '#'))]
    ${len}=  Get Length    ${link_elements}
    Log To Console    ${len} Links found\n
    FOR  ${idx}  ${ext_link}  IN ENUMERATE  @{link_elements}  start=1
        ${href}=  Get Element Attribute    ${ext_link}    href
        ${status}=  Check HTTP Status Code   link_to_check=${href}
        Log To Console    ${idx}. ${href} gets status code ${status}
    END

Verify Explore Tab Refactoring
    [Tags]  Sanity
    ...     ODS-488
    Click Link    Explore
    Wait Until Cards Are Loaded
    Check Number of Cards
    Check Cards Details

Verify Json
   [Tags]  json
   ${link_idx}=  Set Variable  0
   ${link_idx_str}=  Convert To String    ${link_idx}
   ${tmp}=  Run Keyword and Continue On Failure  Set Variable  ${APPS_DICT}[anaconda-ce][sidebar_links][${link_idx_str}]
   ${tmp}=  Run Keyword and Continue On Failure  Set Variable  ${APPS_DICT}[anaconda-ce][sidebar_links]['${link_idx}']
   ${tmp}=  Run Keyword and Continue On Failure  Set Variable  ${APPS_DICT}[anaconda-ce][sidebar_links]["${link_idx}"]

