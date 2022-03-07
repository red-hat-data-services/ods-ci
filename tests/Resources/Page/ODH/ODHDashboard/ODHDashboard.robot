*** Settings ***
Resource      ../../../Page/Components/Components.resource
Resource       ../../../Common.robot
Library       JupyterLibrary


*** Variables ***
${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}=                //*[@class="pf-c-drawer__panel-main"]//div[@class="odh-get-started__header"]/h1
${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}=         //*[@class="pf-c-drawer__panel-main"]//button[.='Enable']
${ODH_DASHBOARD_SIDEBAR_HEADER_GET_STARTED_ELEMENT}=   //*[@class="pf-c-drawer__panel-main"]//*[.='Get started']
${CARDS_XP}=  //article[contains(@class, 'pf-c-card')]
${JH_CARDS_XP}=   //article[@id="jupyterhub"]
${HEADER_XP}=  div[@class='pf-c-card__header']
${TITLE_XP}=  div[@class='pf-c-card__title']//span[contains(@class, "title")]
${PROVIDER_XP}=  div[@class='pf-c-card__title']//span[contains(@class, "provider")]
${DESCR_XP}=  div[@class='pf-c-card__body']
${BADGES_XP}=  ${HEADER_XP}/div[contains(@class, 'badges')]/span[contains(@class, 'badge') or contains(@class, 'coming-soon')]
${OFFICIAL_BADGE_XP}=  div[@class='pf-c-card__title']//span[contains(@class, "title")]/img[contains(@class, 'supported-image')]
${FALLBK_IMAGE_XP}=  ${HEADER_XP}/svg[contains(@class, 'odh-card__header-fallback-img')]
${IMAGE_XP}=  ${HEADER_XP}/img[contains(@class, 'odh-card__header-brand')]
${APPS_DICT_PATH}=  tests/Resources/Page/ODH/ODHDashboard/AppsInfoDictionary.json
${SIDEBAR_TEXT_CONTAINER_XP}=  //div[contains(@class,'odh-markdown-view')]
${SUCCESS_MSG_XP}=  //div[@class='pf-c-alert pf-m-success']


*** Keywords ***
Launch Dashboard
  [Arguments]  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}  ${dashboard_url}  ${browser}  ${browser_options}
  Open Browser  ${dashboard_url}  browser=${browser}  options=${browser_options}
  Login To RHODS Dashboard  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
  Wait for RHODS Dashboard to Load

Authorize rhods-dashboard service account
  Wait Until Page Contains  Authorize Access
  Checkbox Should Be Selected  user:info
  Click Element  approve

Login To RHODS Dashboard
   [Arguments]  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
   #Wait Until Page Contains  Log in with
   ${oauth_prompt_visible} =  Is OpenShift OAuth Login Prompt Visible
   Run Keyword If  ${oauth_prompt_visible}  Click Button  Log in with OpenShift
   ${login-required} =  Is OpenShift Login Visible
   Run Keyword If  ${login-required}  Login To Openshift  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
   ${authorize_service_account} =  Is rhods-dashboard Service Account Authorization Required
   Run Keyword If  ${authorize_service_account}  Authorize rhods-dashboard service account

Wait for RHODS Dashboard to Load
  [Arguments]  ${dashboard_title}="Red Hat OpenShift Data Science Dashboard"
  Wait For Condition  return document.title == ${dashboard_title}  timeout=15

Wait Until RHODS Dashboard ${dashboard_app} Is Visible
  # Ideally the timeout would be an arg but Robot does not allow "normal" and "embedded" arguments
  # Setting timeout to 30seconds since anything beyond that should be flagged as a UI bug
  Wait Until Element is Visible  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]  30seconds

Launch ${dashboard_app} From RHODS Dashboard Link
  Wait Until RHODS Dashboard ${dashboard_app} Is Visible
  Click Link  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]/../div[contains(@class,"pf-c-card__footer")]/a
  Switch Window  NEW

Launch ${dashboard_app} From RHODS Dashboard Dropdown
  Wait Until RHODS Dashboard ${dashboard_app} Is Visible
  Click Button  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]/..//button[contains(@class,pf-c-dropdown__toggle)]
  Click Link  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]/..//a[.="Launch"]
  Switch Window  NEW

Verify Service Is Enabled
  [Documentation]   Verify the service appears in Applications > Enabled
  [Arguments]  ${app_name}
  Menu.Navigate To Page    Applications    Enabled
  Wait Until Page Contains    JupyterHub  timeout=30
  Wait Until Page Contains    ${app_name}  timeout=150
  Page Should Contain Element    xpath://article//*[.='${app_name}']/../..   message=${app_name} should be enabled in ODS Dashboard
  Page Should Not Contain Element    xpath://article//*[.='${app_name}']/..//div[contains(@class,'enabled-controls')]/span[contains(@class,'disabled-text')]  message=${app_name} is marked as Disabled. Check the license


Verify Service Is Not Enabled
  [Documentation]   Verify the service is not present in Applications > Enabled
  [Arguments]  ${app_name}
  ${app_is_enabled} =  Run Keyword And Return Status   Verify Service Is Enabled    ${app_name}
  Should Be True   not ${app_is_enabled}   msg=${app_name} should not be enabled in ODS Dashboard

Verify Service Is Available In The Explore Page
  [Documentation]   Verify the service appears in Applications > Explore
  [Arguments]  ${app_name}
  Menu.Navigate To Page    Applications    Explore
  Wait Until Page Contains    JupyterHub  timeout=30
  Capture Page Screenshot
  Page Should Contain Element    //article//*[.='${app_name}']

Remove Disabled Application From Enabled Page
   [Documentation]  The keyword let you re-enable or remove the card from Enabled page
   ...              for those application whose license is expired. You can control the action type
   ...              by setting the "disable" argument to either "disable" or "enable".
   [Arguments]  ${app_id}
   ${card_disabled_xp}=  Set Variable  //article[@id='${app_id}']//div[contains(@class,'enabled-controls')]/span[contains(@class,'disabled-text')]
   Wait Until Page Contains Element  xpath:${card_disabled_xp}  timeout=180
   Click Element  xpath:${card_disabled_xp}
   Wait Until Page Contains   To remove card click
   ${buttons_here}=  Get WebElements    xpath://div[contains(@class,'popover__body')]//button[text()='here']
   Click Element  ${buttons_here}[1]
   Wait Until Page Does Not Contain Element    xpath://article[@id='${app_id}']
   Capture Page Screenshot  disabled_card_removed.png


Verify Service Provides "Enable" Button In The Explore Page
  [Documentation]   Verify the service appears in Applications > Explore and, after clicking on the tile, the sidebar opens and there is an "Enable" button
  [Arguments]  ${app_name}
  Menu.Navigate To Page    Applications    Explore
  Wait Until Page Contains    JupyterHub  timeout=30
  Page Should Contain Element    xpath://article//*[.='${app_name}']/../..
  Click Element     xpath://article//*[.='${app_name}']/../..
  Capture Page Screenshot
  Wait Until Page Contains Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}   timeout=10   error=${app_name} does not have sidebar with information in the Explore page of ODS Dashboard
  Page Should Contain Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}   message=${app_name} does not have a "Enable" button in ODS Dashboard

Verify Service Provides "Get Started" Button In The Explore Page
  [Documentation]   Verify the service appears in Applications > Explore and, after clicking on the tile, the sidebar opens and there is a "Get Started" button
  [Arguments]  ${app_name}
  Menu.Navigate To Page    Applications    Explore
  Wait Until Page Contains    JupyterHub  timeout=30
  Page Should Contain Element    xpath://article//*[.='${app_name}']/../..
  Click Element     xpath://article//*[.='${app_name}']/../..
  Capture Page Screenshot
  Wait Until Page Contains Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}   timeout=10   error=${app_name} does not have sidebar with information in the Explore page of ODS Dashboard
  Page Should Contain Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_GET_STARTED_ELEMENT}   message=${app_name} does not have a "Get started" button in ODS Dashboard

Go To RHODS Dashboard
  [Documentation]   Go to RHOODS dashboard>login  and wait for it to load
  Go To  ${ODH_DASHBOARD_URL}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

Check HTTP Status Code
    [Arguments]  ${link_to_check}  ${expected}=200
    ${response}=    RequestsLibrary.GET  ${link_to_check}   expected_status=any
    Run Keyword And Continue On Failure  Status Should Be  ${expected}
    [Return]  ${response.status_code}

Load Expected Data Of RHODS Explore Section
    ${apps_dict_obj}=  Load Json File  ${APPS_DICT_PATH}
    ${apps_dict_obj}=  Set Variable  ${apps_dict_obj}[apps]
    [Return]  ${apps_dict_obj}

Wait Until Cards Are Loaded
    Wait Until Page Contains Element    xpath://div[contains(@class,'odh-explore-apps__gallery')]

Get App ID From Card
    [Arguments]  ${card_locator}
    ${id}=  Get Element Attribute    xpath:${card_locator}    id
    [Return]  ${id}

Get Number Of Cards
    ${n_cards}=   Get Element Count    xpath:${CARDS_XP}
    [Return]    ${n_cards}

Check Number Of Displayed Cards Is Correct
    [Arguments]  ${expected_data}
    ${n_cards}=  Get Number Of Cards
    ${expected_n_cards}=  Get Length    ${expected_data}
    Run Keyword And Continue On Failure    Should Be Equal  ${n_cards}  ${expected_n_cards}

Get Card Texts
    [Arguments]  ${card_locator}
    ${title}=  Get Text    xpath:${card_locator}/${TITLE_XP}
    ${provider}=  Get Text    xpath:${card_locator}/${PROVIDER_XP}
    ${desc}=  Get Text    xpath:${card_locator}/${DESCR_XP}
    [Return]  ${title}  ${provider}  ${desc}

Check Card Texts
    [Arguments]  ${card_locator}  ${app_id}  ${expected_data}
    ${card_title}  ${card_provider}  ${card_desc}=  Get Card Texts  card_locator=${card_locator}
    Run Keyword And Continue On Failure  Should Be Equal   ${card_title}  ${expected_data}[${app_id}][title]
    Run Keyword And Continue On Failure  Should Be Equal   ${card_provider}  ${expected_data}[${app_id}][provider]
    Run Keyword And Continue On Failure  Should Be Equal   ${card_desc}  ${expected_data}[${app_id}][description]

Get Card Badges Titles
    [Arguments]  ${card_locator}
    ${badges}=  Get WebElements    xpath:${card_locator}/${BADGES_XP}
    ${badges_titles}=  Create List
    FOR    ${cb}    IN    @{badges}
        ${btitle}=  Get Text   ${cb}
        Append To List    ${badges_titles}  ${btitle}
    END
    [Return]  ${badges_titles}

Check Card Badges And Return Titles
    [Arguments]  ${card_locator}  ${app_id}  ${expected_data}
    ${card_badges_titles}=  Get Card Badges Titles  card_locator=${card_locator}
    Run Keyword And Continue On Failure  Lists Should Be Equal  ${card_badges_titles}  ${expected_data}[${app_id}][badges]
    Run Keyword If    $RH_BADGE_TITLE in $card_badges_titles
    ...    Run Keyword And Continue On Failure  Page Should Contain Element    xpath:${card_locator}/${OFFICIAL_BADGE_XP}
    [Return]  ${card_badges_titles}

Open Get Started Sidebar And Return Status
    [Arguments]  ${card_locator}
    Click Element  xpath:${card_locator}
    ${status}=  Run Keyword and Return Status  Wait Until Page Contains Element    xpath://div[contains(@class,'pf-c-drawer__panel-main')]
    Sleep  1
    [Return]  ${status}

Close Get Started Sidebar
    Click Button  xpath://button[@aria-label='Close drawer panel']
    Wait Until Page Does Not Contain Element    xpath://div[contains(@class,'odh-markdown-view')]/h1

Check Get Started Sidebar Status
    [Arguments]  ${sidebar_status}  ${badges_titles}
    IF    $CMS_BADGE_TITLE in $badges_titles
        Run Keyword And Continue On Failure    Should Be Equal   ${sidebar_status}  ${FALSE}
    ELSE
        Run Keyword And Continue On Failure    Should Be Equal   ${sidebar_status}  ${TRUE}
    END

Get Sidebar Links
    ${link_elements}=  Get WebElements    xpath://div[contains(@class,'pf-c-drawer__panel-main')]//a
    [Return]  ${link_elements}

Check Sidebar Links
    [Arguments]  ${app_id}  ${expected_data}
    ${sidebar_links}=  Get Sidebar Links
    ${n_links}=  Get Length  ${sidebar_links}
    ${expected_n_links}=  Get Length  ${expected_data}[${app_id}][sidebar_links]
    Run Keyword And Continue On Failure  Should Be Equal  ${n_links}  ${expected_n_links}
    ${list_links}=  Create List
    ${list_textlinks}=  Create List
    FOR    ${link_idx}    ${s_link}    IN ENUMERATE    @{sidebar_links}
        ${link_idx}=  Convert To String    ${link_idx}
        ${link_text}=  Get Text    ${s_link}
        ${link_href}=  Get Element Attribute    ${s_link}    href
        ${link_status}=  Check HTTP Status Code   link_to_check=${link_href}  expected=200
        ${expected_link}=  Set Variable  ${expected_data}[${app_id}][sidebar_links][${link_idx}][url]
        ${expected_text}=  Set Variable  ${expected_data}[${app_id}][sidebar_links][${link_idx}][text]
        ${lt_json_list}=  Set Variable  ${expected_data}[${app_id}][sidebar_links][${link_idx}][matching]
        IF    $lt_json_list == "partial"
             Run Keyword And Continue On Failure  Should Contain    ${link_href}  ${expected_link}
        ELSE
            Run Keyword And Continue On Failure  Should Be Equal  ${link_href}  ${expected_link}
        END
        Run Keyword And Continue On Failure  Should Be Equal  ${link_text}  ${expected_text}
        Append To List    ${list_links}  ${link_href}
        Append To List    ${list_textlinks}  ${link_text}
    END
    Log List    ${list_links}
    Log List    ${list_textlinks}

Check Sidebar Header Text
    [Arguments]  ${app_id}  ${expected_data}
    ${h1}=  Get Text    xpath://div[contains(@class,'odh-markdown-view')]/h1
    Run Keyword And Continue On Failure  Should Be Equal  ${h1}  ${expected_data}[${app_id}][sidebar_h1]
    ${getstarted_title}=  Get Text  xpath://div[contains(@class,'pf-c-drawer__panel-main')]//div[@class='odh-get-started__header']/h1[contains(@class, 'title')]
    ${getstarted_provider}=  Get Text  xpath://div[contains(@class,'pf-c-drawer__panel-main')]//div[@class='odh-get-started__header']//span[contains(@class, 'provider')]
    Run Keyword And Continue On Failure  Should Be Equal   ${getstarted_title}  ${expected_data}[${app_id}][title]
    Run Keyword And Continue On Failure  Should Be Equal   ${getstarted_provider}  ${expected_data}[${app_id}][provider]

Check Get Started Sidebar
    [Arguments]  ${card_locator}  ${card_badges}  ${app_id}  ${expected_data}
    ${sidebar_exists}=  Open Get Started Sidebar And Return Status  card_locator=${card_locator}
    Check Get Started Sidebar Status   sidebar_status=${sidebar_exists}   badges_titles=${card_badges}
    IF    ${sidebar_exists} == ${TRUE}
        Check Sidebar Links  app_id=${app_id}  expected_data=${expected_data}
        Check Sidebar Header Text  app_id=${app_id}  expected_data=${expected_data}
        Close Get Started Sidebar
    END

Get Image Name
    [Arguments]  ${card_locator}
    ${src}=  Get Element Attribute    xpath:${card_locator}/${IMAGE_XP}  src
    ${image_name}=  Fetch From Right    ${src}    ${ODH_DASHBOARD_URL}
    [Return]  ${src}  ${image_name}

Check Card Image
    [Arguments]  ${card_locator}  ${app_id}  ${expected_data}
    ${src}  ${image_name}=  Get Image Name  card_locator=${card_locator}
    ${expected_image}=  Set Variable  ${expected_data}[${app_id}][image]
    Run Keyword And Continue On Failure    Should Be Equal    ${image_name}    ${expected_image}
    Run Keyword And Continue On Failure    Page Should Not Contain Element    xpath:${card_locator}/${FALLBK_IMAGE_XP}

Check Cards Details Are Correct
   [Arguments]  ${expected_data}
   ${card_n}=  Get Number Of Cards
   FOR    ${idx}    IN RANGE    1    ${card_n}+1
        ${card_xp}=  Set Variable  (${CARDS_XP})[${idx}]
        ${application_id}=  Get App ID From Card  card_locator=${card_xp}
        Log    ${application_id}
        Check Card Texts  card_locator=${card_xp}  app_id=${application_id}  expected_data=${expected_data}
        ${badges_titles}=  Check Card Badges And Return Titles  card_locator=${card_xp}  app_id=${application_id}  expected_data=${expected_data}
        Check Card Image  card_locator=${card_xp}  app_id=${application_id}  expected_data=${expected_data}
        Check Get Started Sidebar  card_locator=${card_xp}  card_badges=${badges_titles}  app_id=${application_id}  expected_data=${expected_data}
    END

Success Message Should Contain
    [Documentation]    Checks that the confirmation message after enabling/removing
    ...                an application from Dashboard contains the desired text
    [Arguments]    ${app_full_name}
    Wait Until Page Contains Element   xpath:${SUCCESS_MSG_XP}
    ${succ_msg}=   Get Text    xpath:${SUCCESS_MSG_XP}
    Run Keyword And Continue On Failure    Should Contain    ${succ_msg}    ${app_full_name}

Re-validate License For Disabled Application From Enabled Page
   [Documentation]  The keyword let you re-enable or remove the card from Enabled page
   ...              for those application whose license is expired. You can control the action type
   ...              by setting the "disable" argument to either "disable" or "enable".
   [Arguments]  ${app_id}
   ${card_disabled_xp}=  Set Variable  //article[@id='${app_id}']//div[contains(@class,'enabled-controls')]/span[contains(@class,'disabled-text')]
   Wait Until Page Contains Element  xpath:${card_disabled_xp}  timeout=120
   Click Element  xpath:${card_disabled_xp}
   Wait Until Page Contains   To remove card click
   ${buttons_here}=  Get WebElements    xpath://div[contains(@class,'popover__body')]//button[text()='here']
   Click Element  ${buttons_here}[0]


