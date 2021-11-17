*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/Page/OCPDashboard/Page.robot
Resource        ../../../Resources/Page/ODH/JupyterHub/LoginJupyterHub.robot
Resource        ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Library         SeleniumLibrary
Library         XML
Library         JupyterLibrary
Library         ../../../../libs/Helpers.py
Suite Setup     Anaconda Commercial Edition Suite Setup
Suite Teardown  Anaconda Commercial Edition Suite Teardown

*** Variables ***
${anaconda_appname}=  anaconda-ce
${anaconda_key_in}=  Anaconda CE Key
${invalid_key}=  abcdef-invalidkey
${error_msg}=  error\nValidation failed\nError attempting to validate. Please check your entries.
${val_success_msg}=  Validation result: 200
${token_val_success_msg}=  Success! Your token was validated and Conda has been configured.

*** Test Cases ***
Verify Anaconda Commercial Edition Is Available In RHODS Dashboard Explore/Enabled Page
  [Tags]  ODS-262  Smoke  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify Service Is Available In The Explore Page    Anaconda Commercial Edition
  Verify Service Provides "Get Started" Button In The Explore Page    Anaconda Commercial Edition
  ${status}       Run keyword and Return Status         Verify Service Provides "Enable" Button In The Explore Page    Anaconda Commercial Edition 
  Run Keyword If   ${status} == ${False}   Run Keywords
  ...              Verify Service Is Enabled      Anaconda Commercial Edition 
  ...              AND
  ...              FAIL   Anaconda Commercial Edition does not have a "Enable" button in ODH Dashboard since it has been alreday Enabled and Present in Enabled Page


Verify Anaconda Commercial Edition Fails Activation When Key Is Invalid
  [Documentation]  This TC wants to check that if user inserts an invalid key, the Anaconda CE validation fails as expected
  [Tags]  Smoke  Sanity
  ...     ODS-310  ODS-367
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Enable Anaconda  ${invalid_key}
  Wait Until Keyword Succeeds    30  1  Check Connect Button Status  false
  Capture Page Screenshot  anaconda_failed_activation.png
  ${text} =  Get Text  xpath://*[@class="pf-c-form__alert"]
  Should Be Equal  ${text}  ${error_msg}
  Click Button    Cancel
  Menu.Navigate To Page    Applications    Enabled
  Wait Until RHODS Dashboard JupyterHub Is Visible
  Capture Page Screenshot  enabletab_anaconda_notpresent.png
  Page Should Not Contain Element  xpath://div[@class="pf-c-card__title"]/span[.="Anaconda Commercial Edition"]

Verify User Is Able to Activate Anaconda Commercial Edition
  [Tags]  Sanity  Smoke
  ...     ODS-272  ODS-344  ODS-501
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Enable Anaconda  ${ANACONDA_CE.ACTIVATION_KEY}
  Wait Until Keyword Succeeds    50  1  Page Should Not Contain Element    xpath://*/div[contains(@class, "bullseye")]
  Capture Page Screenshot  anaconda_success_activation.png
  Menu.Navigate To Page    Applications    Enabled
  Wait Until RHODS Dashboard JupyterHub Is Visible
  Capture Page Screenshot  enabletab_anaconda_present.png
  Page Should Contain Element  xpath://div[@class="pf-c-card__title"]/span[.="Anaconda Commercial Edition"]
  ${val_result}=  Get Anaconda Validator Logs
  Log  ${val_result}
  Should Be Equal  ${val_result}  ${val_success_msg}
  Wait Until Keyword Succeeds    1200  1  Check Anaconda CE Image Build Status  Complete
  Spawn and Check JupyterLab Using Anaconda CE Image

** Keywords ***
Anaconda Commercial Edition Suite Setup
  Set Library Search Order  SeleniumLibrary

Anaconda Commercial Edition Suite Teardown
  Close All Browsers

Enable Anaconda
  [Arguments]  ${license_key}
  Menu.Navigate To Page    Applications    Explore
  Wait Until Page Contains    Anaconda Commercial Edition  timeout=30
  Click Element     xpath://*[@id='${anaconda_appname}']
  Wait Until Page Contains Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}   timeout=10   error=${anaconda_appname} does not have sidebar with information in the Explore page of ODS Dashboard
  Page Should Contain Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}   message=${anaconda_appname} does not have a "Enable" button in ODS Dashboard
  Click Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}
  Wait Until Page Contains Element    xpath://*[@id='${anaconda_key_in}']
  Input Text    xpath://*[@id='${anaconda_key_in}']    ${license_key}
  Click Button    Connect

Check Connect Button Status
  [Arguments]  ${target_status}  # true/false
  ${status}=  Get Connect Button Status
  Should Be Equal    ${status}    ${target_status}

Get Connect Button Status
  ${button_status}=  Get Element Attribute    xpath://*/footer/*[.='Connect']    aria-disabled
  [Return]   ${button_status}

Get Anaconda Validator Logs
  Go To  ${OCP_CONSOLE_URL}
  Login To Openshift    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    ${OCP_ADMIN_USER.AUTH_TYPE}
  Maybe Skip Tour
  Navigate To Page    Workloads    Pods
  Search Last Item Instance By Title in OpenShift Table  search_term=anaconda-ce-periodic-validator-job-custom-run  namespace=redhat-ods-applications
  Click Link    xpath://tr[@data-id='0-0']/td[@id='name']/*/a
  Click Link    Logs
  Sleep  2
  Capture Page Screenshot  logs_page.png
  ${logs_text}=  Get Text    xpath://div[@class='log-window__lines']
  ${log_rows}=  Text To List  ${logs_text}
  [Return]  ${log_rows[0]}

Check Anaconda CE Image Build Status
  [Arguments]  ${target_status}
  Navigate To Page    Builds    Builds
  Search Last Item Instance By Title in OpenShift Table  search_term=minimal-notebook-anaconda  namespace=redhat-ods-applications
  ${ace_build_status}=  Get Text    xpath://tr[@data-id='0-0']/td/*/span[@data-test='status-text']
  Log To Console    \nACE BUILD STATUS: ${ace_build_status}
  Run Keyword If    "${ace_build_status}" == "Failed"
  ...    Fail  the Anaconda image build has failed
  ...  ELSE
  ...    Should Be Equal    ${ace_build_status}    ${target_status}

Spawn and Check JupyterLab Using Anaconda CE Image
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Menu.Navigate To Page    Applications    Enabled
  Launch JupyterHub From RHODS Dashboard Dropdown
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Fix Spawner Status
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
  Wait Until Page Contains Element  xpath://input[@name='Anaconda Commercial Edition']
  Wait Until Element Is Enabled    xpath://input[@name='Anaconda Commercial Edition']   timeout=600
  Spawn Notebook With Arguments  image=s2i-minimal-notebook-anaconda
  Wait for JupyterLab Splash Screen  timeout=60
  Maybe Select Kernel
  Sleep  5
  Close Other JupyterLab Tabs
  Capture Page Screenshot  closedtabs.png
  Launch a new JupyterLab Document
  Sleep  5
  Maybe Select Kernel
  Close Other JupyterLab Tabs
  Run Cell And Check Output    !conda token set ${ANACONDA_CE.ACTIVATION_KEY}    ${token_val_success_msg}
  Capture Page Screenshot  anaconda_token_val_cell.png
  Add and Run JupyterLab Code Cell  !conda install -y numpy
  Wait Until JupyterLab Code Cell Is Not Active
  Run Cell And Check For Errors  import numpy as np
  Maybe Open JupyterLab Sidebar   File Browser
  Fix Spawner Status
  Wait Until Page Contains Element  xpath://input[@name='Anaconda Commercial Edition']


