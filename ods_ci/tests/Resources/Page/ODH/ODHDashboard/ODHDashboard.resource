*** Settings ***
Resource   ODHDashboard.robot
Resource   ../../LoginPage.robot
Library    RequestsLibrary
Library    SeleniumLibrary

*** Variables ***
${PARTNER_BADGE_TITLE}=  Partner managed
${SELF_BADGE_TITLE}=  Self-managed
${RH_BADGE_TITLE}=  Red Hat managed
${CMS_BADGE_TITLE}=  Coming soon
${BETA_BADGE_TITLE}=  Beta


*** Keywords ***
Open ODS Dashboard With Admin User
    [Documentation]    Opens a browser and logs into ODS Dashboard with a user belonging to the rhods-admins group
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}

Open ODS Dashboard With Non Admin User
    [Documentation]    Opens a browser and logs into ODS Dashboard with a user belonging to the rhods-users group
    Launch Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}    expected_page=${NONE}
