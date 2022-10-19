*** Settings ***
Resource      ../../../Page/Components/Components.resource
Resource      ../../../Page/OCPDashboard/UserManagement/Groups.robot
Resource       ../../../Common.robot
Resource       ../JupyterHub/ODHJupyterhub.resource
Resource    ../../../OCP.resource
Library       JupyterLibrary


*** Variables ***
${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}=                //*[@class="pf-c-drawer__panel-main"]//div[@class="odh-get-started__header"]/h1
${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}=         //*[@class="pf-c-drawer__panel-main"]//button[.='Enable']
${ODH_DASHBOARD_SIDEBAR_HEADER_GET_STARTED_ELEMENT}=   //*[@class="pf-c-drawer__panel-main"]//*[.='Get started']
${CARDS_XP}=  //article[contains(@class, 'pf-c-card')]
${SAMPLE_APP_CARD_XP}=   //article[@id="pachyderm"]
${HEADER_XP}=  div[@class='pf-c-card__header']
${TITLE_XP}=  div[@class='pf-c-card__title']//span[contains(@class, "title")]
${PROVIDER_XP}=  div[@class='pf-c-card__title']//span[contains(@class, "provider")]
${DESCR_XP}=  div[@class='pf-c-card__body']
${BADGES_XP}=  ${HEADER_XP}/div[contains(@class, 'badges')]/span[contains(@class, 'badge') or contains(@class, 'coming-soon')]
${OFFICIAL_BADGE_XP}=  div[@class='pf-c-card__title']//span[contains(@class, "title")]/img[contains(@class, 'supported-image')]
${FALLBK_IMAGE_XP}=  ${HEADER_XP}/svg[contains(@class, 'odh-card__header-fallback-img')]
${IMAGE_XP}=  ${HEADER_XP}/img[contains(@class, 'odh-card__header-brand')]
${APPS_DICT_PATH}=  tests/Resources/Files/AppsInfoDictionary.json
${APPS_DICT_PATH_LATEST}=   tests/Resources/Files/AppsInfoDictionary_latest.json
${SIDEBAR_TEXT_CONTAINER_XP}=  //div[contains(@class,'odh-markdown-view')]
${SUCCESS_MSG_XP}=  //div[@class='pf-c-alert pf-m-success']
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
${NOTIFICATION_DRAWER_CLOSE_BTN}=  //div[@class="pf-c-drawer__panel"]/div/div//button
${NOTIFICATION_DRAWER_CLOSED}=  //div[@class="pf-c-drawer__panel" and @hidden=""]
${GROUPS_CONFIG_CM}=    groups-config
${RHODS_GROUPS_CONFIG_CM}=    rhods-groups-config
${RHODS_LOGO_XPATH}=    //img[@alt="Red Hat OpenShift Data Science Logo"]
@{ISV_TO_REMOVE_SELF_MANAGED}=      Create List     starburst   nvidia    rhoam


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

Logout From RHODS Dashboard
    [Documentation]  Logs out from the current user in the RHODS dashboard
    ...    This will reload the page and show the `Log in with OpenShift` page
    ...    so you want to use `Login to RHODS Dashboard` after this
    # Another option for the logout button
    #${user} =  Get Text  xpath:/html/body/div/div/header/div[2]/div/div[3]/div/button/span[1]
    #Click Element  xpath://span[.="${user}"]/..
    Click Button  xpath:(//button[@id="toggle-id"])[2]
    Wait Until Page Contains Element  xpath://a[.="Log out"]
    Click Element  xpath://a[.="Log out"]
    Wait Until Page Contains  Log in with OpenShift

Wait for RHODS Dashboard to Load
    [Arguments]  ${dashboard_title}="Red Hat OpenShift Data Science"
    Wait For Condition    return document.title == ${dashboard_title}    timeout=15s
    Wait Until Page Contains Element    xpath:${RHODS_LOGO_XPATH}    timeout=15s

Wait Until RHODS Dashboard ${dashboard_app} Is Visible
  # Ideally the timeout would be an arg but Robot does not allow "normal" and "embedded" arguments
  # Setting timeout to 30seconds since anything beyond that should be flagged as a UI bug
  Wait Until Element is Visible  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]  30seconds

Launch ${dashboard_app} From RHODS Dashboard Link
  Wait Until RHODS Dashboard ${dashboard_app} Is Visible
  Click Link  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]/../div[contains(@class,"pf-c-card__footer")]/a
  IF    "${dashboard_app}" != "Jupyter"
       Switch Window  NEW
  END

Launch ${dashboard_app} From RHODS Dashboard Dropdown
  Wait Until RHODS Dashboard ${dashboard_app} Is Visible
  Click Button  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]/..//button[contains(@class,pf-c-dropdown__toggle)]
  Click Link  xpath://div[@class="pf-c-card__title" and .="${dashboard_app}"]/..//a[.="Launch"]
  Switch Window  NEW

Verify Service Is Enabled
  [Documentation]   Verify the service appears in Applications > Enabled
  [Arguments]  ${app_name}
  Menu.Navigate To Page    Applications    Enabled
  Wait Until Page Contains    Jupyter  timeout=30
  Wait Until Page Contains    ${app_name}  timeout=180
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
  Wait Until Page Contains    Jupyter  timeout=30
  Capture Page Screenshot
  Page Should Contain Element    //article//*[.='${app_name}']

Remove Disabled Application From Enabled Page
   [Documentation]  The keyword let you re-enable or remove the card from Enabled page
   ...              for those application whose license is expired. You can control the action type
   ...              by setting the "disable" argument to either "disable" or "enable".
   [Arguments]  ${app_id}
   ${card_disabled_xp}=  Set Variable  //article[@id='${app_id}']//div[contains(@class,'enabled-controls')]/span[contains(@class,'disabled-text')]
   Wait Until Page Contains Element  xpath:${card_disabled_xp}  timeout=300
   Click Element  xpath:${card_disabled_xp}
   Wait Until Page Contains   To remove card click
   ${buttons_here}=  Get WebElements    xpath://div[contains(@class,'popover__body')]//button[text()='here']
   Click Element  ${buttons_here}[1]
   Wait Until Page Does Not Contain Element    xpath://article[@id='${app_id}']
   Capture Page Screenshot  ${app_id}_removed.png


Verify Service Provides "Enable" Button In The Explore Page
  [Documentation]   Verify the service appears in Applications > Explore and, after clicking on the tile, the sidebar opens and there is an "Enable" button
  [Arguments]  ${app_name}
  Menu.Navigate To Page    Applications    Explore
  Wait Until Page Contains    Jupyter  timeout=30
  Page Should Contain Element    xpath://article//*[.='${app_name}']/../..
  Click Element     xpath://article//*[.='${app_name}']/../..
  Capture Page Screenshot
  Wait Until Page Contains Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}   timeout=10   error=${app_name} does not have sidebar with information in the Explore page of ODS Dashboard
  Page Should Contain Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}   message=${app_name} does not have a "Enable" button in ODS Dashboard

Verify Service Provides "Get Started" Button In The Explore Page
  [Documentation]   Verify the service appears in Applications > Explore and, after clicking on the tile, the sidebar opens and there is a "Get Started" button
  [Arguments]  ${app_name}
  Menu.Navigate To Page    Applications    Explore
  Wait Until Page Contains    Jupyter  timeout=30
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

Load Expected Data Of RHODS Explore Section
    ${version-check}=   Is RHODS Version Greater Or Equal Than  1.18.0
    IF  ${version-check}==True
        ${apps_dict_obj}=  Load Json File  ${APPS_DICT_PATH_LATEST}
    ELSE
        ${apps_dict_obj}=  Load Json File  ${APPS_DICT_PATH}
    END
    ${apps_dict_obj}=  Set Variable  ${apps_dict_obj}[apps]
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    ${is_self_managed} == ${TRUE}
        Remove From Dictionary   ${apps_dict_obj}   @{ISV_TO_REMOVE_SELF_MANAGED}
    END
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
        ${link_status}=  Run Keyword And Continue On Failure  Check HTTP Status Code   link_to_check=${link_href}  expected=200
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

Get Question Mark Links
    [Documentation]      It returns the link elements from the question mark
    @{links_list}=  Create List
    @{link_elements}=  Get WebElements
    ...    //a[@class="odh-dashboard__external-link pf-c-dropdown__menu-item" and not(starts-with(@href, '#'))]
    FOR  ${link}  IN  @{link_elements}
         ${href}=    Get Element Attribute    ${link}    href
         Append To List    ${links_list}    ${href}
    END
    [Return]  @{links_list}

Get RHODS Documentation Links From Dashboard
    [Documentation]    It returns a list containing rhods documentation links
    Click Link    Resources
    Sleep    2
    # get the documentation link
    ${href_view_the_doc}=    Get Element Attribute    //a[@class='odh-dashboard__external-link']    href
    Click Element    xpath=//*[@id="toggle-id"]
    ${links}=    Get Question Mark Links
    # inserting at 0th position
    Insert Into List    ${links}    0    ${href_view_the_doc}
    [Return]  @{links}

Check External Links Status
    [Documentation]      It iterates through the links and cheks their HTTP status code
    [Arguments]     ${links}
    FOR  ${idx}  ${href}  IN ENUMERATE  @{links}  start=1
        ${status}=  Check HTTP Status Code   link_to_check=${href}
        Log    ${idx}. ${href} gets status code ${status}
    END

Verify Cluster Settings Is Available
    [Documentation]    Verifies submenu Settings > Cluster settings" is visible
    Page Should Contain    Settings
    Menu.Navigate To Page    Settings    Cluster settings
    Capture Page Screenshot
    Wait Until Page Contains    Update global settings for all users    timeout=30
    Wait Until Page Contains Element    ${USAGE_DATA_COLLECTION_XP}    timeout=30

Verify Cluster Settings Is Not Available
    [Documentation]    Verifies submenu Settings > Cluster settings is not visible
    ${cluster_settings_available}=    Run Keyword And Return Status    Verify Cluster Settings Is Available
    Should Not Be True    ${cluster_settings_available}    msg=Cluster Settings shoudn't be visible for this user

Save Changes In Cluster Settings
    [Documentation]    Clicks on the "Save changes" button in Cluster Settings and
    ...    waits until "Settings changes saved" is shown
    Wait Until Page Contains Element    xpath://button[.="Save changes"][@aria-disabled="false"]    timeout=15s
    Click Button    Save changes
    Wait Until Keyword Succeeds    30    1
    ...    Wait Until Page Contains    Settings changes saved
    # New setting applies after a few seconds, empirically >15s.
    # Sleep here to make sure it is applied.
    Sleep  30s

Enable "Usage Data Collection"
    [Documentation]    Once in Settings > Cluster Settings, enables "Usage Data Collection"
    ${is_data_collection_enabled}=    Run Keyword And Return Status    Checkbox Should Be Selected
    ...    ${USAGE_DATA_COLLECTION_XP}
    IF    ${is_data_collection_enabled}==False
        Select Checkbox    ${USAGE_DATA_COLLECTION_XP}
        Save Changes In Cluster Settings
    END

Disable "Usage Data Collection"
    [Documentation]    Once in Settings > Cluster Settings, disables "Usage Data Collection"
    ${is_data_collection_enabled}=    Run Keyword And Return Status    Checkbox Should Be Selected
    ...    ${USAGE_DATA_COLLECTION_XP}
    IF    ${is_data_collection_enabled}==True
        Unselect Checkbox    ${USAGE_DATA_COLLECTION_XP}
        Save Changes In Cluster Settings
    END

Search Items In Resources Section
    [Arguments]     ${element}
    Click Link      Resources
    Sleep   5
    ${version-check}=  Is RHODS Version Greater Or Equal Than    1.18.0
    IF    ${version-check} == True
        Input Text  xpath://input[@class="pf-c-text-input-group__text-input"]       ${element}
    ELSE
        Input Text  xpath://input[@class="pf-c-search-input__text-input"]       ${element}
    END

Verify Username Displayed On RHODS Dashboard
    [Documentation]    Verifies that given username matches with username present on RHODS Dashboard
    [Arguments]    ${user_name}
    Element Text Should Be    xpath=//div[@class='pf-c-page__header-tools-item'][3]//span[1]    ${user_name}

Set PVC Value In RHODS Dashboard
    [Documentation]    Change the default value for PVC
    ...    only whole number is selected
    [Arguments]    ${size}
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains Element  xpath://input[@id="pvc-size-input"]  timeout=30
    Input Text    //input[@id="pvc-size-input"]    ${size}
    Save Changes In Cluster Settings

Restore PVC Value To Default Size
    [Documentation]    Set the PVC value to default
    ...    value i.e., 20Gi
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains Element  xpath://input[@id="pvc-size-input"]  timeout=30
    Click Button    Restore Default
    Save Changes In Cluster Settings

RHODS Notification Drawer Should Contain
    [Documentation]    Verifies RHODS Notifications contains given Message
    [Arguments]     ${message}
    Click Element    xpath=//*[contains(@class,'notification-badge')]
    Wait Until Page Contains  text=${message}  timeout=300s
    Close Notification Drawer

Open Notebook Images Page
    [Documentation]    Opens the RHODS dashboard and navigates to the Notebook Images page
    Page Should Contain    Settings
    Menu.Navigate To Page    Settings    Notebook Images
    Wait Until Page Contains    Notebook image settings
    Page Should Contain    Notebook image settings

Import New Custom Image
    [Documentation]    Opens the Custom Image import view and imports an image
    ...    Software and Packages should be passed as dictionaries
    [Arguments]    ${repo}    ${name}    ${description}    ${software}    ${packages}
    Sleep  1
    Open Custom Image Import Popup
    Input Text    xpath://input[@id="notebook-image-repository-input"]    ${repo}
    Input Text    xpath://input[@id="notebook-image-name-input"]    ${name}
    Input Text    xpath://input[@id="notebook-image-description-input"]    ${description}
    Add Softwares To Custom Image    ${software}
    Add Packages To Custom Image    ${packages}
    Click Element    xpath://button[.="Import"]

Open Custom Image Import Popup
    [Documentation]    Opens the Custom Image import view, using the appropriate button
    ${first_image} =  Run Keyword And Return Status  Page Should Contain Element  xpath://button[.="Import image"]
    IF  ${first_image}==True
        Click Element  xpath://button[.="Import image"]
    ELSE
        Click Element  xpath://button[.="Import new image"]
    END
    Wait Until Page Contains    Import Notebook images

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
    Click Button  xpath://td[.="${image_name}"]/../td[last()]//button
    Click Element  xpath://td[.="${image_name}"]/../td[last()]//button/..//li[@id="${image_name}-delete-button"]
    Wait Until Page Contains  Do you wish to permanently delete ${image_name}?
    Click Button  xpath://button[.="Delete"]

Open Edit Menu For Custom Image
    [Documentation]    Opens the edit view for a specific custom image
    [Arguments]    ${image_name}
    Click Button  xpath://td[.="${image_name}"]/../td[last()]//button
    Click Element  xpath://td[.="${image_name}"]/../td[last()]//button/..//li[@id="${image_name}-edit-button"]
    Wait Until Page Contains  Delete Notebook Image

Expand Custom Image Details
    [Documentation]    Expands a custom image's row in the dashboard UI
    [Arguments]    ${image_name}
    ${is_expanded} =  Run Keyword And Return Status  Page Should Contain Element  xpath://td[.="${image_name}"]/../td[1]/button[@aria-expanded="true"]
    IF  ${is_expanded}==False
        Click Button  xpath://td[.="${image_name}"]/../td[1]//button
    END

Collapse Custom Image Details
    [Documentation]    Collapses a custom image's row in the dashboard UI
    [Arguments]    ${image_name}
    ${is_expanded} =  Run Keyword And Return Status  Page Should Contain Element  xpath://td[.="${image_name}"]/../td[1]/button[@aria-expanded="true"]
    IF  ${is_expanded}==True
        Click Button  xpath://td[.="${image_name}"]/../td[1]//button
    END

Verify Custom Image Description
    [Documentation]    Verifies that the description shown in the dashboard UI
    ...    matches the given one
    [Arguments]    ${image_name}    ${expected_description}
    ${exists} =  Run Keyword And Return Status  Page Should Contain Element  xpath://td[.="${image_name}"]/../td[@data-label="Description"][.="${expected_description}"]
    IF  ${exists}==False
        ${desc} =  Get Text  xpath://td[.="${image_name}"]/../td[@data-label="Description"]
        Log  Description for ${image_name} does not match ${expected_description} - Actual description is ${desc}
        FAIL
    END
    [Return]    ${exists}

Verify Custom Image Is Listed
    [Documentation]    Verifies that the custom image is displayed in the dashboard
    ...    UI with the correct name
    [Arguments]    ${image_name}
    ${exists} =  Run Keyword And Return Status  Page Should Contain Element  xpath://td[.="${image_name}"]
    IF  ${exists}==False
        Log  ${image_name} not visible in page
        FAIL
    END
    [Return]    ${exists}

Verify Custom Image Owner
    [Documentation]    Verifies that the user listed for an image in the dahsboard
    ...    UI matches the given one
    [Arguments]    ${image_name}    ${expected_user}
    ${exists} =  Run Keyword And Return Status  Page Should Contain Element  xpath://td[.="${image_name}"]/../td[@data-label="User"][.="${expected_user}"]
    IF  ${exists}==False
        ${user} =  Get Text  xpath://td[.="${image_name}"]/../td[@data-label="User"]
        Log  User for ${image_name} does not match ${expected_user} - Actual user is ${user}
        FAIL
    END
    [Return]  ${exists}

Enable Custom Image
    [Documentation]    Enables a custom image (i.e. displayed in JH) [WIP]
    [Arguments]    ${image_name}
    ${is_enabled} =  # Need to find a check
    IF  ${is_enabled}==False
        Click Element  xpath://td[.="${image_name}"]/..//input
    END

Disable Custom Image
    [Documentation]    Disables a custom image (i.e. not displayed in JH) [WIP]
    [Arguments]    ${image_name}
    ${is_enabled} =  # Need to find a check
    IF  ${is_enabled}==True
        Click Element  xpath://td[.="${image_name}"]/..//input
    END

Close Notification Drawer
    [Documentation]    Closes the dashboard notification drawer, if it is open
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
    Click Element    //div[@class="pf-c-toolbar__content-section"]/div[2]/div/button
    Click Button    //button[@data-key="${sort_type}"]
    Sleep    1s

Clear Dashboard Notifications
    [Documentation]     Clears Notifications present in RHODS dashboard
    Click Element    xpath=//*[contains(@class,'notification-badge')]
    Sleep  2s  reason=To avoid Element Not Interactable Exception
    ${notification_count} =  Get Element Count    class:odh-dashboard__notification-drawer__item-remove
    FOR    ${index}    IN RANGE    ${notification_count}
        Click Element    xpath=//*[contains(@class,"odh-dashboard__notification-drawer__item-remove")]
    END
    Close Notification Drawer

Get Dashboard Pods Names
    [Documentation]     Retrieves the names of dashboard pods
    ${dash_pods}=    Oc Get    kind=Pod    namespace=redhat-ods-applications     label_selector=app=rhods-dashboard
    ...                        fields=['metadata.name']
    ${names}=   Create List
    FOR    ${pod_name}    IN    @{dash_pods}
        Append To List      ${names}    ${pod_name}[metadata.name]
    END
    [Return]   ${names}

Get Dashboard Pod Logs
    [Documentation]     Fetches the logs from one dashboard pod
    [Arguments]     ${pod_name}
    ${pod_logs}=            Oc Get Pod Logs  name=${pod_name}  namespace=redhat-ods-applications  container=rhods-dashboard
    ${pod_logs_lines}=      Split String    string=${pod_logs}  separator=\n
    ${n_lines}=     Get Length    ${pod_logs_lines}
    Log     ${pod_logs_lines}[${n_lines-3}:]
    IF   "${pod_logs_lines}[${n_lines-1}]" == "${EMPTY}"
        Remove From List    ${pod_logs_lines}   ${n_lines-1}
        ${n_lines}=     Get Length    ${pod_logs_lines}
    END
    [Return]    ${pod_logs_lines}   ${n_lines}

Get ConfigMaps For RHODS Groups Configuration
    [Documentation]     Returns a dictionary containing "rhods-group-config" and "groups-config"
    ...                 ConfigMaps
    ${rgc_status}   ${rgc_yaml}=     Run Keyword And Ignore Error     OpenShiftLibrary.Oc Get    kind=ConfigMap  name=${RHODS_GROUPS_CONFIG_CM}   namespace=redhat-ods-applications
    ${gc_status}   ${gc_yaml}=      Run Keyword And Ignore Error     OpenShiftLibrary.Oc Get    kind=ConfigMap  name=${GROUPS_CONFIG_CM}   namespace=redhat-ods-applications
    IF   $rgc_status == 'FAIL'
        ${rgc_yaml}=    Create List   ${EMPTY}
    END
    IF   $gc_status == 'FAIL'
        ${gc_yaml}=    Create List    ${EMPTY}
    END
    ${group_config_maps}=   Create Dictionary     rgc=${rgc_yaml}[0]     gc=${gc_yaml}[0]
    Log     ${group_config_maps}
    [Return]    ${group_config_maps}

Get Links From Switcher
    [Documentation]    Returns the OpenShift Console and OpenShift Cluster Manager Link
    ${list_of_links} =    Create List
    ${link_elements}=    Get WebElements    //a[@class="pf-m-external pf-c-app-launcher__menu-item" and not(starts-with(@href, '#'))]
    FOR    ${ext_link}    IN    @{link_elements}
        ${href}=    Get Element Attribute    ${ext_link}    href
        Append To List    ${list_of_links}    ${href}
    END
    [Return]    ${list_of_links}

Open Application Switcher Menu
    [Documentation]     Clicks on the App Switcher in the top navigation bar of RHODS Dashboard
    Click Button    //button[@class="pf-c-app-launcher__toggle"]
