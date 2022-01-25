*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Library         ../../../libs/Helpers.py
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
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

Dashboard Test Teardown
  Close All Browsers



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
        ${status}=  Check HTTP Status Code   link_to_check=${href}
        Log To Console    ${idx}. ${href} gets status code ${status}
    END

Verify Explore Tab Refactoring
    [Tags]  ODS-488-ref
    # test setup
    Click Link    Explore
    Sleep  3
    Check Number of Cards
    Check Cards Details

Verify Explore Tab
    [Tags]  ODS-488
    # test setup X
    # check num of cards X
    # check card details
    # check sidebar deails (titles)
    # check sidebar links (http status + expected links)
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Click Link    Explore
    Sleep  3
    ${n_tiles}=  Get Element Count    xpath:${TILES_XP}
    #FOR    ${idx}    IN RANGE    1    2+1
    FOR    ${idx}    IN RANGE    1    ${n_tiles}+1
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
        ${sidebar_exists}=  Run Keyword and Return Status  Wait Until Page Contains Element    xpath://div[contains(@class,'pf-c-drawer__panel-main')]
        Sleep  1
        #Wait Until Page Contains Element    xpath://div[contains(@class,'odh-markdown-view')]/h1[text()='${APPS_DICT}[${app_id}][sidebar_h1]']
        IF    $CMS_BADGE_TITLE in $card_badges_titles
            Run Keyword And Continue On Failure    Should Be Equal   ${sidebar_exists}  ${FALSE}
        ELSE
            Run Keyword And Continue On Failure    Should Be Equal   ${sidebar_exists}  ${TRUE}
        END
        IF    ${sidebar_exists} == ${TRUE}
            ${sidebar_links}=  Get WebElements    xpath://div[contains(@class,'pf-c-drawer__panel-main')]//a
            ${list_links}=  Create List
            ${list_textlinks}=  Create List
            FOR    ${link_idx}    ${s_link}    IN ENUMERATE    @{sidebar_links}
                ${link_text}=  Get Text    ${s_link}
                ${link_href}=  Get Element Attribute    ${s_link}    href
                ${link_status}=  Get HTTP Status Code   ${link_href}
                ${lt_json_list}=  Set Variable  ${APPS_DICT}[${app_id}][sidebar_links][${link_idx}]
                # ${lt_json_list}=  Set Variable  ${APPS_DICT}[${app_id}][sidebar_links][${link_text}]
                IF    "partial-matching" in $lt_json_list
                     Run Keyword And Continue On Failure  Should Contain    ${link_href}    ${lt_json_list}[1]
                ELSE
                    Run Keyword And Continue On Failure  Should Be Equal  ${link_href}  ${lt_json_list}[1]
                END
                Append To List    ${list_links}  ${link_href}
                Append To List    ${list_textlinks}  ${link_text}
            END
            Log List    ${list_links}
            Log List    ${list_textlinks}
            ${n_links}=  Get Length  ${sidebar_links}
            ${len_appsdict_links}=  Get Length  ${APPS_DICT}[${app_id}][sidebar_links]
            Run Keyword And Continue On Failure  Should Be Equal  ${n_links}  ${len_appsdict_links}


            ${h1}=  Get Text    xpath://div[contains(@class,'odh-markdown-view')]/h1
            Run Keyword And Continue On Failure  Should Be Equal  ${h1}  ${APPS_DICT}[${app_id}][sidebar_h1]
            ${getstarted_title}=  Get Text  xpath://div[contains(@class,'pf-c-drawer__panel-main')]//div[@class='odh-get-started__header']/h1[contains(@class, 'title')]
            ${getstarted_provider}=  Get Text  xpath://div[contains(@class,'pf-c-drawer__panel-main')]//div[@class='odh-get-started__header']//span[contains(@class, 'provider')]
            Run Keyword And Continue On Failure  Should Be Equal   ${getstarted_title}  ${APPS_DICT}[${app_id}][title]
            Run Keyword And Continue On Failure  Should Be Equal   ${getstarted_provider}  ${APPS_DICT}[${app_id}][provider]
            Click Button  xpath://button[@aria-label='Close drawer panel']
            Wait Until Page Does Not Contain Element    xpath://div[contains(@class,'odh-markdown-view')]/h1
        END
    END

