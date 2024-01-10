*** Settings ***
Library             SeleniumLibrary
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource            ../../../Resources/RHOSi.resource

Test Setup          Dashboard Test Setup
Test Teardown       Dashboard Test Teardown


*** Variables ***
${SB_CARDS_XP}=     //div[@id="starburst"]
${SB_BETA_DESC}=    //*[@class="pf-v5-c-drawer__panel-main"]//div[@class="pf-v5-c-alert pf-m-inline pf-m-info"]


*** Test Cases ***
Verify if the Starburst Beta text has been removed from Getting Started
    [Tags]  Tier2
    ...     ODS-1158    ODS-605

    Click Link    Explore
    Wait Until Cards Are Loaded
    Open Get Started Sidebar And Return Status    card_locator=${SB_CARDS_XP}
    Check Beta Description


*** Keywords ***
Check Beta Description
    ${version-check}=    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version-check}==True
        Page Should not Contain Element    xpath:${SB_BETA_DESC}
    ELSE
        Page Should Contain Element    xpath:${SB_BETA_DESC}
    END

Dashboard Test Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}

Dashboard Test Teardown
    Close All Browsers
