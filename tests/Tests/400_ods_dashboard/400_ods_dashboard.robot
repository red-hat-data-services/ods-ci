*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Library         RequestsLibrary
Test Setup      Dashboard Test Setup
Test Teardown   Dashboard Test Teardown
Variables       ../../Resources/Page/ODH/ODHDashboard/AppsInfoDictionary.py

*** Variables ***
${TILES_XP}=  //article[contains(@class, 'pf-c-card')]
${HEADER_XP}=  div[@class='pf-c-card__header']
${TITLE_XP}=  div[@class='pf-c-card__title']//span[contains(@class, "title")]
${PROVIDER_XP}=  div[@class='pf-c-card__title']//span[contains(@class, "provider")]
${DESCR_XP}=  div[@class='pf-c-card__body']
${BADGES_XP}=  ${HEADER_XP}/div[contains(@class, 'badges')]/span[contains(@class, 'badge') or contains(@class, 'coming-soon')]
${OFFICIAL_BADGE_XP}=  div[@class='pf-c-card__title']//span[contains(@class, "title")]/img[contains(@class, 'supported-image')]
${IMAGE_XP}=  ${HEADER_XP}/*[contains(@class, 'odh-card__header-fallback-img')]
# check if there is a fallback images instead a real image: <svg class="odh-card__header-brand odh-card__header-brand pf-c-brand odh-card__header-fallback-img"


*** Keywords ***
Dashboard Test Setup
  Set Library Search Order  SeleniumLibrary

Dashboard Test Teardown
  Close All Browsers

Get HTTP Status Code
    [Arguments]  ${link_to_check}
    ${response}=    RequestsLibrary.GET  ${link_to_check}   expected_status=any
    Run Keyword And Continue On Failure  Status Should Be  200
    [Return]  ${response.status_code}


*** Test Cases ***
Verify Resource Link Http status code
    [Tags]  Sanity
    ...     ODS-531
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
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

Verify Explore Tab
    [Tags]  ODS-488
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Click Link    Explore
    Sleep  3
    ${n_tiles}=  Get Element Count    xpath:${TILES_XP}
    FOR    ${idx}    IN RANGE    1    3
    # FOR    ${idx}    IN RANGE    1    ${n_tiles}+1
        ${app_id}=  Get Element Attribute    xpath:(${TILES_XP})[${idx}]    id
        Log    ${app_id}
        ${card_title}=  Get Text    xpath:(${TILES_XP})[${idx}]/${TITLE_XP}
        ${card_provider}=  Get Text    xpath:(${TILES_XP})[${idx}]/${PROVIDER_XP}
        ${card_desc}=  Get Text    xpath:(${TILES_XP})[${idx}]/${DESCR_XP}
        ${card_badges}=  Get WebElements    xpath:(${TILES_XP})[${idx}]/${BADGES_XP}
        ${card_badges_titles}=  Create List

        Run Keyword And Continue On Failure  Should Be Equal   ${card_title}  ${APPS_DICT}[${app_id}][title]
        Run Keyword And Continue On Failure  Should Be Equal   ${card_provider}  ${APPS_DICT}[${app_id}][provider]
        Run Keyword And Continue On Failure  Should Be Equal   ${card_desc}  ${APPS_DICT}[${app_id}][description]
        FOR    ${cb}    IN    @{card_badges}
            ${btitle}=  Get Text   ${cb}
            Append To List    ${card_badges_titles}  ${btitle}
        END
        Run Keyword And Continue On Failure  Lists Should Be Equal  ${card_badges_titles}  ${APPS_DICT}[${app_id}][badges]
        Run Keyword If    $RH_BADGE_TITLE in $card_badges_titles
        ...    Run Keyword And Continue On Failure  Page Should Contain Element    xpath:(${TILES_XP})[${idx}]/${OFFICIAL_BADGE_XP}

        # for each tile get sidebar links
        # for each link checks:
        #   - link https status
        #   - link is among the expected ones (add in AppsInfoDic file
        Click Element  xpath:(${TILES_XP})[${idx}]
        Wait Until Page Contains Element    xpath://div[contains(@class,'odh-markdown-view')]/h1[text()='${card_title}']
        ${sidebar_links}=  Get WebElements    xpath://div[contains(@class,'pf-c-drawer__panel-main')]//a
        FOR    ${s_link}    IN    @{sidebar_links}
            ${link_text}=  Get Text    ${s_link}
            ${link_href}=  Get Element Attribute    ${s_link}    href
            Log    ${link_text}
            ${link_status}=  Get HTTP Status Code   ${link_href}
        END
        Click Button  xpath://button[@aria-label='Close drawer panel']
    END
