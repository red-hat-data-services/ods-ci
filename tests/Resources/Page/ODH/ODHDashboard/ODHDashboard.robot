*** Settings ***
Resource      ../../../Page/Components/Components.resource
Library       JupyterLibrary

*** Variables ***
${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}                 //*[@class="pf-c-drawer__panel-main"]//div[@class="odh-get-started__header"]/h1
${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}         //*[@class="pf-c-drawer__panel-main"]//button[.='Enable']
${ODH_DASHBOARD_SIDEBAR_HEADER_GET_STARTED_ELEMENT}   //*[@class="pf-c-drawer__panel-main"]//*[.='Get started']

*** Keywords ***
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
  Wait For Condition  return document.title == ${dashboard_title}  timeout=60

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
  Page Should Contain Element    xpath://article//*[.='${app_name}']/../..   message=${app_name} should be enabled in ODS Dashboard

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

