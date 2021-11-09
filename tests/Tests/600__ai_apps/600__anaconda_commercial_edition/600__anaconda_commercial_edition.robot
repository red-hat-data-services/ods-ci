*** Settings ***
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Library         SeleniumLibrary
Library         XML
Library         ../../../../libs/Helpers.py
Suite Setup     Anaconda Commercial Edition Suite Setup
Suite Teardown  Anaconda Commercial Edition Suite Teardown

*** Variables ***
${anaconda_appname}=  anaconda-ce
${anaconda_key_in}=  Anaconda CE Key
${invalid_key}=  abcdef-invalidkey
${error_msg}=  error\nValidation failed\nError attempting to validate. Please check your entries.
${val_success_msg}=  Validation result: 200


*** Test Cases ***
Verify Anaconda Commercial Edition Is Available In RHODS Dashboard Explore Page
  [Tags]  ODS-262  Smoke  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Verify Service Is Available In The Explore Page    Anaconda Commercial Edition
  Verify Service Provides "Get Started" Button In The Explore Page    Anaconda Commercial Edition
  Verify Service Provides "Enable" Button In The Explore Page    Anaconda Commercial Edition

Verify Anaconda Commercial Edition Fails Activation When Key Is Invalid
  [Tags]  Sanity
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
  ## Page Should Not Contain  Anaconda Commercial Edition
  Wait Until RHODS Dashboard JupyterHub Is Visible
  Capture Page Screenshot  enabletab_anaconda_notpresent.png
  Page Should Not Contain Element  xpath://div[@class="pf-c-card__title"]/span[.="Anaconda Commercial Edition"]

Verify User Is Able to Activate Anaconda Commercial Edition
  [Tags]  Sanity
  ...     ODS-272
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Enable Anaconda  ${ANACONDA_CE.ACTIVATION_KEY}
  Wait Until Keyword Succeeds    50  1  Page Should Not Contain Element    xpath://*/div[contains(@class, "bullseye")]
  ##Wait Until Keyword Succeeds    30  1  Page Should Not Contain    Connect Anaconda to JupyterHub
  Capture Page Screenshot  anaconda_success_activation.png
  Menu.Navigate To Page    Applications    Enabled
  # Page Should Not Contain  Anaconda Commercial Edition
  Wait Until RHODS Dashboard JupyterHub Is Visible
  Capture Page Screenshot  enabletab_anaconda_present.png
  Page Should Contain Element  xpath://div[@class="pf-c-card__title"]/span[.="Anaconda Commercial Edition"]
  ${val_result}=  Get Anaconda Validator Logs
  Log  ${val_result}
  Should Be Equal  ${val_result}  ${val_success_msg}

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
  # ${button_status}=  Get Element Attribute    xpath://*/footer/*[contains(@data-ouia-component-id,'OUIA-Generated-Button-primary')]    aria-disabled
  ${button_status}=  Get Element Attribute    xpath://*/footer/*[.='Connect']    aria-disabled
  [Return]   ${button_status}

Get Anaconda Validator Logs
  # Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Go To  ${OCP_CONSOLE_URL}
  Login To Openshift    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    ${OCP_ADMIN_USER.AUTH_TYPE}
  Maybe Skip Tour
  Navigate To Page    Workloads    Pods
  Select Project By Name    redhat-ods-applications
  Wait Until Page Contains Element    xpath://input[@data-test='name-filter-input']
  Input Text    xpath://input[@data-test='name-filter-input']    anaconda-ce-periodic-validator-job-custom-run
  Sleep  2
  Click Button    xpath://*/th[@data-label='Created']/button  # asc order
  Click Button    xpath://*/th[@data-label='Created']/button  # desc order
  Click Link    xpath://tr[@data-id='0-0']/td[@id='name']/*/a
  Click Link    Logs
  Sleep  2
  Capture Page Screenshot  logs_page.png
  ${logs_text}=  Get Text    xpath://div[@class='log-window__lines']
  ${log_rows}=  Text To List  ${logs_text}
  [Return]  ${log_rows[0]}

