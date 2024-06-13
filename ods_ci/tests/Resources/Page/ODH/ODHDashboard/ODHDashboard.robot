*** Settings ***
Resource      ../../../Page/Components/Components.resource
Resource      ../../../Page/OCPDashboard/UserManagement/Groups.robot
Resource       ../../../Common.robot
Resource       ../JupyterHub/ODHJupyterhub.resource
Resource      ../../../Page/ODH/ODHDashboard/ResourcesPage.resource
Resource      ../../../Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource    ../../../OCP.resource
Library       JupyterLibrary


*** Variables ***
# This variable is overriden for ODH runs via 'ods_ci/test-variables-odh-overwrite.yml'
${ODH_DASHBOARD_PROJECT_NAME}=   Red Hat OpenShift AI

${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}=         //*[@class="pf-v5-c-drawer__panel-main"]//button[.='Enable']
${ODH_DASHBOARD_SIDEBAR_HEADER_GET_STARTED_ELEMENT}=   //*[@class="pf-v5-c-drawer__panel-main"]//*[.='Get started']
${CARDS_XP}=  //*[(contains(@class, 'odh-card')) and (contains(@class, 'pf-v5-c-card'))]
${CARD_BUTTON_XP}=  //input[@name="odh-explore-selectable-card"]
${RES_CARDS_XP}=  //div[contains(@data-ouia-component-type, "Card")]
${JUPYTER_CARD_XP}=    //div[@data-testid="card jupyter"]
${EXPLORE_PANEL_XP}=    //div[@data-testid="explore-drawer-panel"]
${HEADER_XP}=  div[@class='pf-v5-c-card__header']
${TITLE_XP}=   div[@class='pf-v5-c-card__title']//span
${TITLE_XP_OLD}=  div[@class='pf-v5-c-card__title']//div/div[1]
${PROVIDER_XP}=  div[@class='pf-v5-c-card__title']//span[contains(@class, "provider")]
${DESCR_XP}=  div[@class='pf-v5-c-card__body']
${BADGES_XP}=  ${HEADER_XP}//div[contains(@class, 'badge') or contains(@class, 'coming-soon')]
${BADGES_XP_OLD}=  ${HEADER_XP}/div[contains(@class, 'badges')]/span[contains(@class, 'badge') or contains(@class, 'coming-soon')]
${OFFICIAL_BADGE_XP}=  div[@class='pf-v5-c-card__title']//img
${OFFICIAL_BADGE_XP_OLD}=  div[@class='pf-v5-c-card__title']//img[contains(@class, 'supported-image')]    # robocop: disable
${FALLBK_IMAGE_XP}=  ${HEADER_XP}/svg[contains(@class, 'odh-card__header-fallback-img')]
${IMAGE_XP}=  ${HEADER_XP}//picture[contains(@class,'pf-m-picture')]/source
${IMAGE_XP_OLD}=  ${HEADER_XP}/img[contains(@class, 'odh-card__header-brand')]
${APPS_DICT_PATH_LATEST}=   ods_ci/tests/Resources/Files/AppsInfoDictionary_latest.json
${SIDEBAR_TEXT_CONTAINER_XP}=  //div[contains(@class,'odh-markdown-view')]
${SUCCESS_MSG_XP}=  //div[@class='pf-v5-c-alert pf-m-success']
${PAGE_TITLE_XP}=  //*[@data-testid="app-page-title"]
${CLUSTER_SETTINGS_XP}=  //*[@data-testid="app-page-title" and text()="Cluster settings"]
${PVC_SIZE_INPUT_XP}=           xpath=//*[@data-testid="pvc-size-input"]
${USAGE_DATA_COLLECTION_XP}=    //*[@id="usage-data-checkbox"]
${CUSTOM_IMAGE_SOFTWARE_TABLE}=  //caption[contains(., "the advertised software")]/../tbody
${CUSTOM_IMAGE_PACKAGE_TABLE}=  //caption[contains(., "the advertised packages")]/../tbody
${CUSTOM_IMAGE_LAST_ROW_SAVE_BTN}=  tr[last()]/td[last()]/button[@id="save-package-software-button"]  # Save button
${CUSTOM_IMAGE_LAST_ROW_EDIT_BTN}=  tr[last()]/td[last()]/button[@id="edit-package-software-button"]  # Edit OR Save button of last row (depends on context)
${CUSTOM_IMAGE_LAST_ROW_DELETE_BTN}=  tr[last()]/td[last()]/button[@id="delete-package-software-button"]  # Remove button of last row
${CUSTOM_IMAGE_LAST_ROW_NAME}=  tr[last()]/td[1]
${CUSTOM_IMAGE_LAST_ROW_VERSION}=  tr[last()]/td[2]
${CUSTOM_IMAGE_EDIT_BTN}=  button[@id="edit-package-software-button"]
${CUSTOM_IMAGE_REMOVE_BTN}=  button[@id="delete-package-software-button"]
${NOTIFICATION_DRAWER_CLOSE_BTN}=  //div[@class="pf-v5-c-drawer__panel"]/div/div//button
${NOTIFICATION_DRAWER_CLOSED}=  //div[@class="pf-v5-c-drawer__panel" and @hidden=""]
${GROUPS_CONFIG_CM}=    groups-config
${RHODS_GROUPS_CONFIG_CM}=    rhods-groups-config
${RHODS_LOGO_XPATH}=    //img[@alt="${ODH_DASHBOARD_PROJECT_NAME} Logo"]
@{ISV_TO_REMOVE_SELF_MANAGED}=      Create List     starburst   nvidia    rhoam


*** Keywords ***
Launch Dashboard
  [Arguments]  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}  ${dashboard_url}  ${browser}  ${browser_options}
  ...          ${expected_page}=Enabled    ${wait_for_cards}=${TRUE}    ${browser_alias}=${NONE}
  Open Browser  ${dashboard_url}  browser=${browser}  options=${browser_options}
  ...    alias=${browser_alias}
  Login To RHODS Dashboard  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
  Wait For RHODS Dashboard To Load    expected_page=${expected_page}
  ...    wait_for_cards=${wait_for_cards}

Authorize rhods-dashboard service account
  Wait Until Page Contains  Authorize Access
  Checkbox Should Be Selected  user:info
  Click Element  approve

Login To RHODS Dashboard
   [Arguments]  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
   # Wait until we are in the OpenShift auth page or already in Dashboard
   ${expected_text_list}=    Create List    Log in with    Data Science Projects
   Wait Until Page Contains A String In List    ${expected_text_list}
   ${oauth_prompt_visible}=  Is OpenShift OAuth Login Prompt Visible
   IF  ${oauth_prompt_visible}  Click Button  Log in with OpenShift
   ${login-required}=  Is OpenShift Login Visible
   IF  ${login-required}  Login To Openshift  ${ocp_user_name}  ${ocp_user_pw}  ${ocp_user_auth_type}
   ${authorize_service_account}=  Is rhods-dashboard Service Account Authorization Required
   IF  ${authorize_service_account}  Authorize rhods-dashboard service account
   Navigate To Page    Applications    Enabled

Logout From RHODS Dashboard
    [Documentation]  Logs out from the current user in the RHODS dashboard
    ...    This will reload the page and show the `Log in with OpenShift` page
    ...    so you want to use `Login to RHODS Dashboard` after this
    # Another option for the logout button
    #${user} =  Get Text  xpath:/html/body/div/div/header/div[2]/div/div[3]/div/button/span[1]
    #Click Element  xpath://span[.="${user}"]/..
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.21.0
    IF  ${version_check}==True
        Click Button  xpath://button[@id="user-menu-toggle"]
    ELSE
        Click Button  xpath:(//button[@id="toggle-id"])[2]
    END
    Wait Until Page Contains Element  xpath://a[.="Log out"]
    Click Element  xpath://a[.="Log out"]
    Wait Until Page Contains  Log in with OpenShift

Wait For RHODS Dashboard To Load
    [Arguments]  ${dashboard_title}="${ODH_DASHBOARD_PROJECT_NAME}"    ${wait_for_cards}=${TRUE}
    ...          ${expected_page}=Enabled
    Wait For Condition    return document.title == ${dashboard_title}    timeout=60s
    Wait Until Page Contains Element    xpath:${RHODS_LOGO_XPATH}    timeout=20s
    IF    "${expected_page}" != "${NONE}"    Wait For Dashboard Page Title    ${expected_page}    timeout=75s
    IF    ${wait_for_cards} == ${TRUE}
        Wait Until Keyword Succeeds    3 times   5 seconds    Wait Until Cards Are Loaded
    END

Wait For Dashboard Page Title
    [Documentation]    Wait until the visible title (h1) of the current Dashboard page is '${page_title}'
    [Arguments]  ${page_title}    ${timeout}=10s
    ${page_title_element}=    Set Variable    //*[@data-testid="app-page-title"]
    Wait Until Element is Visible    ${page_title_element}    timeout=${timeout}
    # Sometimes the h1 text is inside a child element, thus get it with textContent attribute
    ${title}=    Get Element Attribute    ${page_title_element}    textContent
    Should Be Equal    ${title}    ${page_title}

Wait Until RHODS Dashboard ${dashboard_app} Is Visible
  # Ideally the timeout would be an arg but Robot does not allow "normal" and "embedded" arguments
  # Setting timeout to 30seconds since anything beyond that should be flagged as a UI bug
  Wait Until Element is Visible    xpath://div[contains(@class,'gallery')]/div//div[@class="pf-v5-c-card__title"]//*[text()="${dashboard_app}"]
  ...    timeout=30s

Launch ${dashboard_app} From RHODS Dashboard Link
  Menu.Navigate To Page    Applications    Enabled
  Wait For RHODS Dashboard To Load    wait_for_cards=${TRUE}
  ...    expected_page=Enabled
  IF    "OpenShift" in $dashboard_app
      ${splits}=    Split String From Right    ${dashboard_app}    max_split=1
      Click Link   xpath:${CARDS_XP}//*[text()='${splits[0]} ']/../..//a
  ELSE
      IF    "${dashboard_app}" == "Jupyter"
          Click Link    xpath://div[contains(@class,'pf-v5-l-gallery')]/div[contains(@class,'pf-v5-c-card')]/div[@class="pf-v5-c-card__title"]//span[text()="${dashboard_app}"]/../../..//div[contains(@class,"pf-v5-c-card__footer")]/a
      ELSE
          Click Link    xpath://div[contains(@class,'pf-v5-l-gallery')]/div[contains(@class,'pf-v5-c-card')]/div[@class="pf-v5-c-card__title"]//span[text()="${dashboard_app}"]/../..//div[contains(@class,"pf-v5-c-card__footer")]/a
      END
  END
  IF    "${dashboard_app}" != "Jupyter"
       Switch Window  NEW
  END

Launch ${dashboard_app} From RHODS Dashboard Dropdown
  Wait Until RHODS Dashboard ${dashboard_app} Is Visible
  Click Button  xpath://div[@class="pf-v5-c-card__title" and .="${dashboard_app}"]/..//button[contains(@class,pf-v5-c-dropdown__toggle)]
  Click Link  xpath://div[@class="pf-v5-c-card__title" and .="${dashboard_app}"]/..//a[.="Launch"]
  Switch Window  NEW

Verify Service Is Enabled
  [Documentation]   Verify the service appears in Applications > Enabled
  [Arguments]  ${app_name}    ${timeout}=180s
  Menu.Navigate To Page    Applications    Enabled
  # Jupyter App should always be listed
  Wait Until Page Contains    Jupyter    timeout=30s
  Wait Until Page Contains    ${app_name}    timeout=${timeout}
  Page Should Contain Element    xpath://div//*[.='${app_name}']/../..   message=${app_name} should be enabled in ODS Dashboard
  Page Should Not Contain Element    xpath://div//*[.='${app_name}']/..//div[contains(@class,'enabled-controls')]/span[contains(@class,'disabled-text')]  message=${app_name} is marked as Disabled. Check the license

Verify Service Is Not Enabled
  [Documentation]   Verify the service is not present in Applications > Enabled
  [Arguments]  ${app_name}
  ${app_is_enabled}=  Run Keyword And Return Status   Verify Service Is Enabled    ${app_name}    timeout=10s
  Should Be True   not ${app_is_enabled}   msg=${app_name} should not be enabled in ODS Dashboard

Verify Service Is Available In The Explore Page
  [Documentation]   Verify the service appears in Applications > Explore
  [Arguments]  ${app_name}    ${split_last}=${FALSE}
  Menu.Navigate To Page    Applications    Explore
  Wait For RHODS Dashboard To Load    expected_page=Explore
  Capture Page Screenshot
  IF    ${split_last}==${TRUE}
      ${splits}=    Split String From Right    ${app_name}    max_split=1
      Page Should Contain Element    xpath:${CARDS_XP}//*[text()='${splits[0]} ']
      Page Should Contain Element    xpath:${CARDS_XP}//*[text()='${splits[1]}']
  ELSE
      Page Should Contain Element    xpath:${CARDS_XP}//*[.='${app_name}']
  END

Verify Service Is Not Available In The Explore Page
  [Documentation]   Verify the service appears in Applications > Explore
  [Arguments]  ${app_name}    ${split_last}=${FALSE}
  Menu.Navigate To Page    Applications    Explore
  Wait For RHODS Dashboard To Load    expected_page=Explore
  Capture Page Screenshot
  IF    ${split_last}==${TRUE}
      ${splits}=    Split String From Right    ${app_name}    max_split=1
      Page Should Not Contain Element    xpath:${CARDS_XP}//*[text()='${splits[0]} ']
      Page Should Not Contain Element    xpath:${CARDS_XP}//*[text()='${splits[1]}']
  ELSE
      Page Should Not Contain Element    xpath:${CARDS_XP}//*[.='${app_name}']
  END

Remove Disabled Application From Enabled Page
   [Documentation]  The keyword let you re-enable or remove the card from Enabled page
   ...              for those application whose license is expired. You can control the action type
   ...              by setting the "disable" argument to either "disable" or "enable".
   [Arguments]  ${app_id}
   ${card_disabled_xp}=  Set Variable  //div[@id='${app_id}']//span[contains(@class,'disabled-text')]
   Wait Until Page Contains Element  xpath:${card_disabled_xp}  timeout=300
   Click Element  xpath:${card_disabled_xp}
   Wait Until Page Contains   To remove card click
   ${buttons_here}=  Get WebElements    css:div[class*='popover'] button
   Click Element  ${buttons_here}[2]
   Wait Until Page Does Not Contain Element    xpath://div[@id='${app_id}']
   Capture Page Screenshot  ${app_id}_removed.png

Open "Get Started" For App Name
  [Documentation]   Open Explore page and select a Card titled "${app_name}", to view its "Get Started" on the sidebar
  [Arguments]  ${app_name}    ${app_id}=${NONE}
  Menu.Navigate To Page    Applications    Explore
  Wait For RHODS Dashboard To Load    expected_page=Explore
  IF    "${app_id}" == "${NONE}"
      ${card_locator}=    Set Variable    //*[contains(@data-testid,"cardtitle") and contains(text(),'${app_name}')]
  ELSE
      ${card_locator}=    Set Variable    ${CARDS_XP}\[@id='${app_id}']
  END
  ${status}=    Open Get Started Sidebar And Return Status    card_locator=${card_locator}
  Capture Page Screenshot
  Run Keyword And Continue On Failure    Should Be Equal    ${status}    ${TRUE}

Verify Service Provides "Enable" Button In The Explore Page
  [Documentation]   Verify the service appears in Applications > Explore
  ...    and after clicking on the tile, the sidebar opens and there is an "Enable" button
  [Arguments]  ${app_name}    ${app_id}=${NONE}
  Open "Get Started" For App Name    ${app_name}    ${app_id}
  Page Should Contain Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}   message=${app_name} does not have a "Enable" button in ODS Dashboard

Verify Service Provides "Get Started" Button In The Explore Page
  [Documentation]   Verify the service appears in Applications > Explore
  ...    and after clicking on the circle next to the title, the sidebar opens and there is a "Get Started" button
  [Arguments]  ${app_name}    ${app_id}=${NONE}
  Open "Get Started" For App Name    ${app_name}    ${app_id}
  Page Should Contain Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_GET_STARTED_ELEMENT}   message=${app_name} does not have a "Get started" button in ODS Dashboard

Go To RHODS Dashboard
  [Documentation]   Go to RHOODS dashboard>login  and wait for it to load
  Go To  ${ODH_DASHBOARD_URL}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load

Load Expected Data Of RHODS Explore Section
    ${apps_dict_obj}=  Load Json File  ${APPS_DICT_PATH_LATEST}
    ${apps_dict_obj}=  Set Variable  ${apps_dict_obj}[apps]
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    ${is_self_managed} == ${TRUE}
        ${installed_rhods_type}=    Set Variable    Self-managed
    ELSE
        ${installed_rhods_type}=    Set Variable    Cloud Service
    END
    FOR    ${index}  ${app}    IN ENUMERATE    @{apps_dict_obj}
        Log    ${index}: ${app}: ${apps_dict_obj}[${app}][rhods_type]
        ${to_be_displayed}=    Run Keyword And Return Status
        ...    List Should Contain Value    ${apps_dict_obj}[${app}][rhods_type]    ${installed_rhods_type}
        IF    "${to_be_displayed}" == "${FALSE}"
            Remove From Dictionary   ${apps_dict_obj}   ${app}
        END
    END
    RETURN  ${apps_dict_obj}

Wait Until Cards Are Loaded
    [Documentation]    Waits until the Application cards are displayed in the page
    ${status}=    Run Keyword and Return Status    Wait Until Page Contains Element
    ...    xpath:${CARDS_XP}    timeout=10s
    IF    not ${status}    Reload Page
    Should Be True   ${status}   msg=This might be caused by bug RHOAIENG-404

Get App ID From Card
    [Arguments]  ${card_locator}
    ${id}=  Get Element Attribute    xpath:${card_locator}    id
    RETURN  ${id}

Get Number Of Cards
    ${n_cards}=   Get Element Count    xpath:${CARDS_XP}
    RETURN    ${n_cards}

Check Number Of Displayed Cards Is Correct
    [Arguments]  ${expected_data}
    ${n_cards}=  Get Number Of Cards
    ${expected_n_cards}=  Get Length    ${expected_data}
    Run Keyword And Continue On Failure    Should Be Equal  ${n_cards}  ${expected_n_cards}

Get Card Texts
    [Arguments]  ${card_locator}    ${badges_title}=${EMPTY}
    Log    ${badges_title}
    IF    "Red Hat managed" in $badges_title
        ${title_xp_mod}=    Set Variable    ${TITLE_XP}/..
    ELSE
        ${title_xp_mod}=    Set Variable    ${TITLE_XP}
    END
    ${title}=  Get Text    xpath:${card_locator}/${title_xp_mod}
    IF    "Red Hat managed" in $badges_title
        ${title}=    Replace String    string=${title}    search_for=\n    replace_with=${EMPTY}
        ${title}=    Split String    string=${title}    separator=by    max_split=1
        ${title}=    Set Variable    ${title[0]}
    END
    ${provider}=  Get Text    xpath:${card_locator}/${PROVIDER_XP}
    ${desc}=  Get Text    xpath:${card_locator}/${DESCR_XP}
    RETURN  ${title}  ${provider}  ${desc}

Check Card Texts
    [Arguments]    ${card_locator}    ${app_id}    ${expected_data}    ${badges_title}
    ${card_title}  ${card_provider}  ${card_desc}=  Get Card Texts  card_locator=${card_locator}
    ...    badges_title=${badges_title}
    Run Keyword And Continue On Failure  Should Be Equal   ${card_title}  ${expected_data}[${app_id}][title]
    Run Keyword And Continue On Failure  Should Be Equal   ${card_provider}  ${expected_data}[${app_id}][provider]
    Run Keyword And Continue On Failure  Should Be Equal   ${card_desc}  ${expected_data}[${app_id}][description]

Get Card Badges Titles
    [Arguments]  ${card_locator}
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.21.0
    IF  ${version_check}==True
        ${versioned_badge_xp}=    Set Variable    ${BADGES_XP}
    ELSE
        ${versioned_badge_xp}=    Set Variable    ${BADGES_XP_OLD}
    END
    ${badges}=  Get WebElements    xpath:${card_locator}/${versioned_badge_xp}
    ${badges_titles}=  Create List
    FOR    ${cb}    IN    @{badges}
        ${btitle}=  Get Text   ${cb}
        Append To List    ${badges_titles}  ${btitle}
    END
    RETURN  ${badges_titles}

Check Card Badges And Return Titles
    [Arguments]  ${card_locator}  ${app_id}  ${expected_data}
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.21.0
    IF  ${version_check}==True
        ${versioned_official_badge_xp}=    Set Variable    ${OFFICIAL_BADGE_XP}
    ELSE
        ${versioned_official_badge_xp}=    Set Variable    ${OFFICIAL_BADGE_XP_OLD}
    END
    ${card_badges_titles}=  Get Card Badges Titles  card_locator=${card_locator}
    Run Keyword And Continue On Failure  Lists Should Be Equal  ${card_badges_titles}  ${expected_data}[${app_id}][badges]
    IF    $RH_BADGE_TITLE in $card_badges_titles
    ...    Run Keyword And Continue On Failure  Page Should Contain Element
    ...    xpath:${card_locator}/${versioned_official_badge_xp}
    RETURN  ${card_badges_titles}

Open Get Started Sidebar And Return Status
    [Arguments]  ${card_locator}
    Wait Until Element Is Visible    xpath:${card_locator}
    Wait Until Element Is Enabled     xpath:${card_locator}    timeout=20s     error=Element is not clickbale  #robocop : disable
    Mouse Down    ${card_locator}
    Mouse Up    ${card_locator}
    ${status}=    Run Keyword And Return Status    Wait Until Page Contains Element
    ...    xpath://div[contains(@class,'pf-v5-c-drawer__panel-main')]
    Sleep  1
    RETURN  ${status}

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
    ${link_elements}=  Get WebElements    xpath://div[contains(@class,'pf-v5-c-drawer__panel-main')]//a
    RETURN  ${link_elements}

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
        IF    ${link_status} != 200    Capture Page Screenshot
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
    ${getstarted_title}=  Get Text  xpath://div[contains(@class,'pf-v5-c-drawer__head')]
    ${titles}=    Split String    ${getstarted_title}   separator=\n    max_split=1
    Run Keyword And Continue On Failure  Should Be Equal   ${titles[0]}  ${expected_data}[${app_id}][title]
    Run Keyword And Continue On Failure  Should Be Equal   ${titles[1]}  ${expected_data}[${app_id}][provider]

Check Get Started Sidebar
    [Arguments]  ${card_locator}  ${card_badges}  ${app_id}  ${expected_data}
    ${sidebar_exists}=  Open Get Started Sidebar And Return Status  card_locator=${card_locator}
    Run Keyword And Continue On Failure    Check Get Started Sidebar Status   sidebar_status=${sidebar_exists}   badges_titles=${card_badges}
    IF    ${sidebar_exists} == ${TRUE}
        Run Keyword And Continue On Failure    Check Sidebar Links  app_id=${app_id}  expected_data=${expected_data}
        Run Keyword And Continue On Failure    Check Sidebar Header Text  app_id=${app_id}  expected_data=${expected_data}
        Run Keyword And Continue On Failure    Close Get Started Sidebar
    END

Get Image Name
    [Arguments]  ${card_locator}
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.21.0
    IF  ${version_check}==True
        ${versioned_image_xp}=    Set Variable    ${IMAGE_XP}
        ${versioned_src_xp}=    Set Variable    srcset
    ELSE
        ${versioned_image_xp}=    Set Variable    ${IMAGE_XP_OLD}
        ${versioned_src_xp}=    Set Variable    src
    END
    ${src}=  Get Element Attribute    xpath:${card_locator}/${versioned_image_xp}  ${versioned_src_xp}
    ${image_name}=  Fetch From Right    ${src}    ${ODH_DASHBOARD_URL}
    RETURN  ${src}  ${image_name}

Check Card Image
    [Arguments]  ${card_locator}  ${app_id}  ${expected_data}
    ${src}  ${image_name}=  Get Image Name  card_locator=${card_locator}
    Run Keyword And Continue On Failure    Should Be Equal    ${image_name}   ${expected_data}[${app_id}][image]
    Run Keyword And Continue On Failure    Page Should Not Contain Element    xpath:${card_locator}/${FALLBK_IMAGE_XP}

Check Cards Details Are Correct
   [Arguments]  ${expected_data}
   ${card_n}=  Get Number Of Cards
   FOR    ${idx}    IN RANGE    1    ${card_n}+1
        ${card_xp}=  Set Variable  (${CARDS_XP})[${idx}]
        ${application_id}=  Get App ID From Card  card_locator=${card_xp}
        Log    ${application_id}
        ${badges_titles}=  Check Card Badges And Return Titles  card_locator=${card_xp}  app_id=${application_id}  expected_data=${expected_data}
        Check Card Texts  card_locator=${card_xp}  app_id=${application_id}  expected_data=${expected_data}
        ...    badges_title=${badges_titles}
        Check Card Image  card_locator=${card_xp}  app_id=${application_id}  expected_data=${expected_data}
        Check Get Started Sidebar  card_locator=${card_xp}  card_badges=${badges_titles}  app_id=${application_id}  expected_data=${expected_data}
    END

Check Dashboard Diplayes Expected ISVs
   [Arguments]  ${expected_data}
   ${card_n}=  Get Number Of Cards
   FOR    ${idx}    IN RANGE    1    ${card_n}+1
        ${card_xp}=  Set Variable  (${CARDS_XP})[${idx}]
        ${application_id}=  Get App ID From Card  card_locator=${card_xp}
        Log    ${application_id}
        Run Keyword And Continue On Failure    Dictionary Should Contain Key    ${expected_data}    ${application_id}
        ...                              msg=${application_id} is not among the expected ISVs
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
   ${card_disabled_xp}=  Set Variable  //div[@id='${app_id}']//div[contains(@class,'enabled-controls')]/span[contains(@class,'disabled-text')]
   Wait Until Page Contains Element  xpath:${card_disabled_xp}  timeout=120
   Click Element  xpath:${card_disabled_xp}
   Wait Until Page Contains   To remove card click
   ${buttons_here}=  Get WebElements    xpath://div[contains(@class,'popover__body')]//button[text()='here']
   Click Element  ${buttons_here}[0]

Get Question Mark Links
    [Documentation]      It returns the link elements from the question mark
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.21.0
    IF  ${version_check}==True
        Click Button  id:help-icon-toggle
    ELSE
        Click Element    xpath=//*[@id="toggle-id"]
    END
    @{links_list}=  Create List
    @{link_elements}=  Get WebElements
    ...    //a[contains(@class,"pf-v5-c-dropdown__menu-item")]
    FOR  ${link}  IN  @{link_elements}
         ${href}=    Get Element Attribute    ${link}    href
         Append To List    ${links_list}    ${href}
    END
    RETURN  @{links_list}

Get RHODS Documentation Links From Dashboard
    [Documentation]    It returns a list containing rhods documentation links
    Click Link    Resources
    Wait For RHODS Dashboard To Load    expected_page=Resources
    ${href_view_the_doc}=    Get Element Attribute    //a[contains(text(),'view the documentation.')]    href
    ${links}=    Get Question Mark Links
    Insert Into List    ${links}    0    ${href_view_the_doc}
    RETURN  @{links}

Check External Links Status
    [Documentation]      It iterates through the links and cheks their HTTP status code
    [Arguments]     ${links}
    FOR  ${idx}  ${href}  IN ENUMERATE  @{links}  start=1
        ${status}=  Check HTTP Status Code   link_to_check=${href}
        Log    ${idx}. ${href} gets status code ${status}
    END

Verify Cluster Settings Is Available
    [Documentation]    Verifies submenu Settings > Cluster settings is visible
    Page Should Contain    Settings
    Menu.Navigate To Page    Settings    Cluster settings
    Capture Page Screenshot
    Wait Until Page Contains Element    ${CLUSTER_SETTINGS_XP}    timeout=30
    Wait Until Page Contains Element    ${PVC_SIZE_INPUT_XP}    timeout=30

Verify Cluster Settings Is Not Available
    [Documentation]    Verifies submenu Settings > Cluster settings is not visible
    ${cluster_settings_available}=    Run Keyword And Return Status    Verify Cluster Settings Is Available
    Should Not Be True    ${cluster_settings_available}    msg=Cluster Settings shoudn't be visible for this user

Search Items In Resources Section
    [Arguments]     ${element}
    Click Link      Resources
    Sleep   5
    ${version-check}=  Is RHODS Version Greater Or Equal Than    1.18.0
    IF    ${version-check} == True
        Input Text  xpath://input[@class="pf-v5-c-text-input-group__text-input"]       ${element}
    ELSE
        Input Text  xpath://input[@class="pf-v5-c-search-input__text-input"]       ${element}
    END

Verify Username Displayed On RHODS Dashboard
    [Documentation]    Verifies that given username matches with username present on RHODS Dashboard
    [Arguments]    ${user_name}
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.21.0
    IF  ${version_check}==True
        ${versioned_user_xp}=    Set Variable
        ...    xpath=//button[@id="user-menu-toggle"]/span[contains(@class,'toggle-text')]
    ELSE
        ${versioned_user_xp}=    Set Variable  xpath=//div[@class='pf-v5-c-page__header-tools-item'][3]//span[1]
    END

    Element Text Should Be    ${versioned_user_xp}    ${user_name}

RHODS Notification Drawer Should Contain
    [Documentation]    Verifies RHODS Notifications contains given Message
    [Arguments]     ${message}
    Click Element    xpath=//*[contains(@class,'notification-badge')]
    Run Keyword And Continue On Failure    Wait Until Page Contains  text=${message}  timeout=10s
    Close Notification Drawer

Open Notebook Images Page
    [Documentation]    Opens the RHODS dashboard and navigates to the Notebook Image Settings page
    Wait Until Page Contains    Settings
    Page Should Contain    Settings
    Menu.Navigate To Page    Settings    Notebook images
    Wait Until Page Contains    Notebook images
    Wait Until Page Contains    Import new image    # This should assure us that the page content is ready

Import New Custom Image
    [Documentation]    Opens the Custom Image import view and imports an image
    ...    Software and Packages should be passed as dictionaries
    [Arguments]    ${repo}    ${name}    ${description}    ${software}    ${packages}
    Sleep  1
    Open Custom Image Import Popup
    Input Text    xpath://input[@id="byon-image-location-input"]    ${repo}
    Input Text    xpath://input[@id="byon-image-name-input"]    ${name}
    Input Text    xpath://input[@id="byon-image-description-input"]    ${description}
    # No button present anymore?
    #Add Softwares To Custom Image    ${software}
    #Add Packages To Custom Image    ${packages}
    Click Element    xpath://button[.="Import"]

Open Custom Image Import Popup
    [Documentation]    Opens the Custom Image import view, using the appropriate button
    Click Element  xpath://button[.="Import new image"]
    Wait Until Page Contains    Import notebook image

Add Softwares To Custom Image
    [Documentation]    Loops through a dictionary to add software to the custom img metadata
    [Arguments]    @{software}
    Click Element  xpath://button/span[.="Software"]
    FOR  ${sublist}  IN  @{software}
        FOR  ${element}  IN  @{sublist}
            Wait Until Element Is Visible    xpath://button[.="Add Software" or .="Add software"]
            Click Element  xpath://button[.="Add Software" or .="Add software"]
            Click Element  xpath:${CUSTOM_IMAGE_SOFTWARE_TABLE}/${CUSTOM_IMAGE_LAST_ROW_EDIT_BTN}
            Input Text  xpath:${CUSTOM_IMAGE_SOFTWARE_TABLE}/${CUSTOM_IMAGE_LAST_ROW_NAME}/input[@id="software-package-input"]  ${element}
            Input Text  xpath:${CUSTOM_IMAGE_SOFTWARE_TABLE}/${CUSTOM_IMAGE_LAST_ROW_VERSION}/input[@id="version-input"]  ${sublist}[${element}]
            Click Element  xpath:${CUSTOM_IMAGE_SOFTWARE_TABLE}/${CUSTOM_IMAGE_LAST_ROW_SAVE_BTN}
        END
    END

Add Packages To Custom Image
    [Documentation]    Loops through a dictionary to add packages to the custom img metadata
    [Arguments]    @{packages}
    Click Element  xpath://button/span[.="Packages"]
    FOR  ${sublist}  IN  @{packages}
        FOR  ${element}  IN  @{sublist}
            Wait Until Element Is Visible    xpath://button[.="Add Package" or .="Add package"]
            Click Element  xpath://button[.="Add Package" or .="Add package"]
            Click Element  xpath:${CUSTOM_IMAGE_PACKAGE_TABLE}/${CUSTOM_IMAGE_LAST_ROW_EDIT_BTN}
            Input Text  xpath:${CUSTOM_IMAGE_PACKAGE_TABLE}/${CUSTOM_IMAGE_LAST_ROW_NAME}/input[@id="software-package-input"]  ${element}
            Input Text  xpath:${CUSTOM_IMAGE_PACKAGE_TABLE}/${CUSTOM_IMAGE_LAST_ROW_VERSION}/input[@id="version-input"]  ${sublist}[${element}]
            Click Element  xpath:${CUSTOM_IMAGE_PACKAGE_TABLE}/${CUSTOM_IMAGE_LAST_ROW_SAVE_BTN}
        END
    END

Remove Software From Custom Image
    [Documentation]    Removes specific software from a custom image's metadata
    ...    Assuming the edit view of said image is already open
    [Arguments]    ${software_name}
    Click Element  xpath://button/span[.="Software"]
    Click Button  xpath://td[.="${software_name}"]/..//${CUSTOM_IMAGE_REMOVE_BTN}

Remove Package From Custom Image
    [Documentation]    Removes specific package from a custom image's metadata
    ...    Assuming the edit view of said image is already open
    [Arguments]    ${package_name}
    Click Element  xpath://button/span[.="Packages"]
    Click Button  xpath://td[.="${package_name}"]/..//${CUSTOM_IMAGE_REMOVE_BTN}

Delete Custom Image
# Need to check if image is REALLY deleted
    [Documentation]    Deletes a custom image through the dashboard UI.
    ...    Needs an additional check on removed ImageStream
    [Arguments]    ${image_name}
    Click Button  xpath://td[@data-label="Name"]/div/div/div[.="${image_name} "]/../../../../td[last()]//button
    ${image_name_id}=  Replace String  ${image_name}  ${SPACE}  -
    Click Element  xpath://td[@data-label="Name"]/div/div/div[.="${image_name} "]/../../../../td[last()]//button/..//button[@id="custom-${image_name_id}-delete-button"]  # robocop: disable
    Handle Deletion Confirmation Modal  ${image_name}  notebook image

Open Edit Menu For Custom Image
    [Documentation]    Opens the edit view for a specific custom image
    [Arguments]    ${image_name}
    Click Button  xpath://td[.="${image_name}"]/../td[last()]//button
    Click Element  xpath://td[.="${image_name}"]/../td[last()]//button/..//button[@id="${image_name}-edit-button"]
    Wait Until Page Contains  Delete Notebook Image

Expand Custom Image Details
    [Documentation]    Expands a custom image's row in the dashboard UI
    [Arguments]    ${image_name}
    ${is_expanded}=  Run Keyword And Return Status
    ...  Page Should Contain Element  xpath://td[.="${image_name}"]/../td[1]/button[@aria-expanded="true"]
    IF  ${is_expanded}==False
        Click Button  xpath://td[.="${image_name}"]/../td[1]//button
    END

Collapse Custom Image Details
    [Documentation]    Collapses a custom image's row in the dashboard UI
    [Arguments]    ${image_name}
    ${is_expanded}=  Run Keyword And Return Status
    ...  Page Should Contain Element  xpath://td[.="${image_name}"]/../td[1]/button[@aria-expanded="true"]
    IF  ${is_expanded}==True
        Click Button  xpath://td[.="${image_name}"]/../td[1]//button
    END

Verify Custom Image Description
    [Documentation]    Verifies that the description shown in the dashboard UI
    ...    matches the given one
    [Arguments]    ${image_name}    ${expected_description}
    ${exists}=  Run Keyword And Return Status  Page Should Contain Element
    ...  xpath://td[@data-label="Name"]/div/div/div[.="${image_name} "]/../../../../td[@data-label="Description" and .="${expected_description}"]  # robocop: disable
    IF  ${exists}==False
        ${desc}=  Get Text  xpath://td[@data-label="Name"]/div/div/div[.="${image_name} "]/../../../../td[@data-label="Description"]
        Log  Description for ${image_name} does not match ${expected_description} - Actual description is ${desc}
        FAIL
    END
    RETURN    ${exists}

Verify Custom Image Is Listed
    [Documentation]    Verifies that the custom image is displayed in the dashboard
    ...    UI with the correct name
    [Arguments]    ${image_name}
    # whitespace after ${image_name} in the xpath is important!
    Sleep  2s  #wait for page to finish loading
    ${exists}=  Run Keyword And Return Status  Page Should Contain Element  xpath://td[@data-label="Name"]/div/div/div[.="${image_name} "]  # robocop: disable
    IF  ${exists}==False
        Log  ${image_name} not visible in page
        FAIL
    END
    RETURN    ${exists}

Verify Custom Image Provider
    [Documentation]    Verifies that the user listed for an image in the dahsboard
    ...    UI matches the given one
    [Arguments]    ${image_name}    ${expected_user}
    ${exists}=  Run Keyword And Return Status  Page Should Contain Element
    ...  xpath://td[@data-label="Name"]/div/div/div[.="${image_name} "]/../../../../td[@data-label="Provider" and .="${expected_user}"]  # robocop: disable
    IF  ${exists}==False
        ${user}=  Get Text  xpath://td[@data-label="Name"]/div/div/div[.="${image_name} "]/../../../../td[@data-label="Provider"]  # robocop: disable
        Log  User for ${image_name} does not match ${expected_user} - Actual user is ${user}
        FAIL
    END
    RETURN  ${exists}

Enable Custom Image
    [Documentation]    Enables a custom image (i.e. displayed in JH) [WIP]
    [Arguments]    ${image_name}
    ${is_enabled}=  # Need to find a check
    IF  ${is_enabled}==False
        Click Element  xpath://td[@data-label="Name"]/div/div/div[.="${image_name} "]/../../../..//input
    END

Disable Custom Image
    [Documentation]    Disables a custom image (i.e. not displayed in JH) [WIP]
    [Arguments]    ${image_name}
    ${is_enabled}=  # Need to find a check
    IF  ${is_enabled}==True
        Click Element  xpath://td[@data-label="Name"]/div/div/div[.="${image_name} "]/../../../..//input
    END

Close Notification Drawer
    [Documentation]    Closes the dashboard notification drawer, if it is open
    # the notification popup could be present and prevent from closing the drawer, let's check and close if exists
    ${popup}=  Run Keyword And Return Status  Page Should Contain Element  xpath://div[@aria-label="Danger Alert"]
    IF  ${popup}==True
        Click Element    xpath://div[@aria-label="Danger Alert"]//button[contains(@aria-label,"Close Danger alert")]
    END
    ${closed}=  Run Keyword And Return Status  Page Should Contain Element  ${NOTIFICATION_DRAWER_CLOSED}
    IF  ${closed}==False
        Click Element  ${NOTIFICATION_DRAWER_CLOSE_BTN}
    END

RHODS Notification Drawer Should Not Contain
    [Documentation]    Verifies RHODS Notifications does not contain given Message
    [Arguments]     ${message}
    Click Element    xpath=//*[contains(@class,'notification-badge')]
    Page Should Not Contain  text=${message}
    Close Notification Drawer

Sort Resources By
    [Documentation]    Changes the sort of items in resource page
    [Arguments]    ${sort_type}
    Click Button    //*[contains(., "Sort by")]
    Click Button    //button[@data-key="${sort_type}"]
    Sleep    1s

Clear Dashboard Notifications
    [Documentation]     Clears Notifications present in RHODS dashboard
    Click Element    xpath=//*[contains(@class,'notification-badge')]
    Sleep  2s  reason=To avoid Element Not Interactable Exception
    ${notification_count}=  Get Element Count    class:odh-dashboard__notification-drawer__item-remove
    FOR    ${index}    IN RANGE    ${notification_count}
        Click Element    xpath=//*[contains(@class,"odh-dashboard__notification-drawer__item-remove")]
    END
    Close Notification Drawer

Get Dashboard Pods Names
    [Documentation]     Retrieves the names of dashboard pods
    ${dash_pods}=    Oc Get    kind=Pod    namespace=${APPLICATIONS_NAMESPACE}     label_selector=app=${DASHBOARD_APP_NAME}
    ...                        fields=['metadata.name']
    ${names}=   Create List
    FOR    ${pod_name}    IN    @{dash_pods}
        Append To List      ${names}    ${pod_name}[metadata.name]
    END
    RETURN   ${names}

Get Dashboard Pod Logs
    [Documentation]     Fetches the logs from one dashboard pod
    [Arguments]     ${pod_name}
    ${pod_logs}=    Oc Get Pod Logs  name=${pod_name}  namespace=${APPLICATIONS_NAMESPACE}  container=${DASHBOARD_APP_NAME}
    ${pod_logs_lines}=    Split String    string=${pod_logs}  separator=\n
    ${n_lines}=    Get Length    ${pod_logs_lines}
    Log     ${pod_logs_lines}[${n_lines-3}:]
    IF   "${pod_logs_lines}[${n_lines-1}]" == "${EMPTY}"
        Remove From List    ${pod_logs_lines}   ${n_lines-1}
        ${n_lines}=     Get Length    ${pod_logs_lines}
    END
    RETURN    ${pod_logs_lines}   ${n_lines}

Get ConfigMaps For RHODS Groups Configuration
    [Documentation]     Returns a dictionary containing "rhods-group-config" and "groups-config"
    ...                 ConfigMaps
    ${rgc_status}   ${rgc_yaml}=     Run Keyword And Ignore Error     OpenShiftLibrary.Oc Get
    ...    kind=ConfigMap  name=${RHODS_GROUPS_CONFIG_CM}   namespace=${APPLICATIONS_NAMESPACE}
    ${gc_status}   ${gc_yaml}=      Run Keyword And Ignore Error     OpenShiftLibrary.Oc Get
    ...    kind=ConfigMap  name=${GROUPS_CONFIG_CM}   namespace=${APPLICATIONS_NAMESPACE}
    IF   $rgc_status == 'FAIL'
        ${rgc_yaml}=    Create List   ${EMPTY}
    END
    IF   $gc_status == 'FAIL'
        ${gc_yaml}=    Create List    ${EMPTY}
    END
    ${group_config_maps}=   Create Dictionary     rgc=${rgc_yaml}[0]     gc=${gc_yaml}[0]
    Log     ${group_config_maps}
    RETURN    ${group_config_maps}

Get Links From Switcher
    [Documentation]    Returns the OpenShift Console and OpenShift Cluster Manager Link
    ${list_of_links}=    Create List
    ${link_elements}=    Get WebElements    //a[@class="pf-m-external pf-v5-c-app-launcher__menu-item" and not(starts-with(@href, '#'))]
    FOR    ${ext_link}    IN    @{link_elements}
        ${href}=    Get Element Attribute    ${ext_link}    href
        Append To List    ${list_of_links}    ${href}
    END
    RETURN    ${list_of_links}

Open Application Switcher Menu
    [Documentation]     Clicks on the App Switcher in the top navigation bar of RHODS Dashboard
    Click Button    //button[@class="pf-v5-c-app-launcher__toggle"]

Maybe Wait For Dashboard Loading Spinner Page
    [Documentation]     Detecs the loading symbol (spinner) and wait for it to disappear.
    ...                 If the spinner does not appear, the keyword ignores the error.
    [Arguments]    ${timeout-pre}=3s    ${timeout}=5s
    ${do not wait for spinner}=    Get Variable Value    ${ODH_DASHBOARD_DO_NOT_WAIT_FOR_SPINNER_PAGE}  # defaults to None if undefined
    IF   ${do not wait for spinner} == ${true}
      RETURN
    END
    ${spinner_ball}=   Set Variable    xpath=//span[@class="pf-v5-c-spinner__tail-ball"]
    Run Keyword And Ignore Error    Run Keywords
    ...    Wait Until Page Contains Element    ${spinner_ball}    timeout=${timeout-pre}
    ...    AND
    ...    Wait Until Page Does Not Contain Element    ${spinner_ball}    timeout=${timeout}

Reload RHODS Dashboard Page
    [Documentation]    Reload the web page and wait for RHODS Dashboard
    ...    to be loaded
    [Arguments]    ${expected_page}=Enabled    ${wait_for_cards}=${TRUE}
    Reload Page
    Wait For RHODS Dashboard To Load    expected_page=${expected_page}
    ...    wait_for_cards=${wait_for_cards}

Handle Deletion Confirmation Modal
    [Documentation]    Handles confirmation modal on item deletion
    [Arguments]     ${item_title}    ${item_type}   ${press_cancel}=${FALSE}    ${additional_msg}=${NONE}
    # Once fixed https://issues.redhat.com/browse/RHODS-9730 change the button xpath to
    # xpath=//button[text()="Delete ${item_type}"]
    ${delete_btn_xp}=    Set Variable    xpath=//button[contains(text(), 'Delete')]
    Wait Until Generic Modal Appears
    Run Keyword And Warn On Failure    Page Should Contain    Delete ${item_type}?
    Run Keyword And Warn On Failure    Page Should Contain    This action cannot be undone.
    IF    "${additional_msg}" != "${NONE}"
        Run Keyword And Continue On Failure    Page Should Contain    ${additional_msg}
    END
    Run Keyword And Continue On Failure    Page Should Contain    Type ${item_title} to confirm deletion:
    Run Keyword And Continue On Failure    Element Should Be Disabled    ${delete_btn_xp}
    Input Text    xpath=//input[@id="delete-modal-input"]    ${item_title}
    Wait Until Element Is Enabled    ${delete_btn_xp}
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Click Button    ${delete_btn_xp}
    END
    Wait Until Generic Modal Disappears

Click Action From Actions Menu
    [Documentation]    Clicks an action from Actions menu (3-dots menu on the right)
    [Arguments]    ${item_title}    ${action}    ${item_type}=${NONE}
    Click Element       xpath=//tr[td[@data-label="Name"]//*[text()="${item_title}"]]/td[contains(@class,"-table__action")]//button[@aria-label="Kebab toggle"]    # robocop: disable
    IF    "${item_type}" != "${NONE}"
        ${action}=    Catenate    ${action}    ${item_type}
    END
    Wait Until Page Contains Element       xpath=//tr[td[@data-label="Name"]//*[text()="${item_title}"]]//td//li//*[text()="${action}"]    # robocop: disable
    Click Element       xpath=//tr[td[@data-label="Name"]//*[text()="${item_title}"]]//td//li//*[text()="${action}"]
