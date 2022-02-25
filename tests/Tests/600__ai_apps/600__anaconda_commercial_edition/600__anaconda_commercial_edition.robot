*** Settings ***
Documentation   Test integration with Anaconda Commerical Edition ISV
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/Page/OCPDashboard/Page.robot
Resource        ../../../Resources/Page/ODH/JupyterHub/LoginJupyterHub.robot
Resource        ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource        ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../Resources/Page/ODH/AiApps/Anaconda.resource
Library         SeleniumLibrary
Library         JupyterLibrary
Library         ../../../../libs/Helpers.py
Suite Setup     Anaconda Commercial Edition Suite Setup


*** Test Cases ***
Verify Anaconda Commercial Edition Is Available In RHODS Dashboard Explore/Enabled Page
  [Documentation]  Tests if ACE and its Activation button are present in Explore page.
  ...              If the button is not there, it checks if ACE is already enabled
  [Tags]  Smoke  Sanity
  ...     ODS-262
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load
  Verify Service Is Available In The Explore Page    Anaconda Commercial Edition
  Verify Service Provides "Get Started" Button In The Explore Page    Anaconda Commercial Edition
  ${status}=   Run Keyword And Return Status
  ...               Verify Service Provides "Enable" Button In The Explore Page    Anaconda Commercial Edition
  Run Keyword If   ${status} == ${False}   Run Keywords
  ...              Verify Service Is Enabled      Anaconda Commercial Edition
  ...              AND
  ...              FAIL   Anaconda Commercial Edition does not have a "Enable" button
  ...                     in ODH Dashboard since it has been alreday Enabled and Present in Enabled Page  # robocop: disable

Verify Anaconda Commercial Edition Fails Activation When Key Is Invalid
  [Documentation]  Checks that if user inserts an invalid key,
  ...              the Anaconda CE validation fails as expected
  [Tags]  Tier2
  ...     ODS-310  ODS-367
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load
  Enable Anaconda  license_key=${INVALID_KEY}     license_validity=${FALSE}
  Anaconda Activation Should Have Failed
  Click Button    Cancel
  Menu.Navigate To Page    Applications    Enabled
  Wait Until RHODS Dashboard JupyterHub Is Visible
  Capture Page Screenshot  enabletab_anaconda_notpresent.png
  Page Should Not Contain Element  xpath://div[@class="pf-c-card__title"]/span[.="Anaconda Commercial Edition"]

Verify User Is Able to Activate Anaconda Commercial Edition
  [Tags]  Tier2
  ...     ODS-272  ODS-344  ODS-501  ODS-588
  ...     KnownIssues
  [Documentation]  Performs the Anaconda CE activation, spawns a JL using the Anaconda image,
  ...              validate the token, install a library and try to import it.
  ...              At the end, it stops the JL server and returns to the spawner
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load
  Enable Anaconda  ${ANACONDA_CE.ACTIVATION_KEY}
  Capture Page Screenshot  anaconda_success_activation.png
  Menu.Navigate To Page    Applications    Enabled
  Wait Until RHODS Dashboard JupyterHub Is Visible
  Capture Page Screenshot  enabletab_anaconda_present.png
  Page Should Contain Element  xpath://div[@class="pf-c-card__title"]/span[.="Anaconda Commercial Edition"]
  Go To  ${OCP_CONSOLE_URL}
  Login To Openshift    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    ${OCP_ADMIN_USER.AUTH_TYPE}
  Maybe Skip Tour
  ${val_result}=  Get Pod Logs From UI  namespace=redhat-ods-applications
  ...                                   pod_search_term=anaconda-ce-periodic-validator-job-custom-run
  Log  ${val_result}
  Should Be Equal  ${val_result[0]}  ${VAL_SUCCESS_MSG}
  Wait Until Keyword Succeeds    1200  1  Check Anaconda CE Image Build Status  Complete
  Go To  ${ODH_DASHBOARD_URL}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Launch JupyterHub Spawner From Dashboard
  Wait Until Page Contains Element  xpath://input[@name="Anaconda Commercial Edition"]
  Wait Until Element Is Enabled    xpath://input[@name="Anaconda Commercial Edition"]   timeout=10
  Spawn Notebook With Arguments  image=s2i-minimal-notebook-anaconda
  Run Cell And Check Output    !conda token set ${ANACONDA_CE.ACTIVATION_KEY}    ${TOKEN_VAL_SUCCESS_MSG}
  Capture Page Screenshot  anaconda_token_val_cell.png
  Add And Run JupyterLab Code Cell  !conda install -y numpy
  Wait Until JupyterLab Code Cell Is Not Active
  Run Cell And Check For Errors  import numpy as np
  Capture Page Screenshot  conda_lib_install_result.png
  Maybe Open JupyterLab Sidebar   File Browser
  Fix Spawner Status  # used to close the server and go back to Spawner
  Wait Until Page Contains Element  xpath://input[@name='Anaconda Commercial Edition']  timeout=15
  [Teardown]    Remove Anaconda Commercial Edition Component


*** Keywords ***
Anaconda Commercial Edition Suite Setup
  [Documentation]  Setup for ACE test suite
  Set Library Search Order  SeleniumLibrary



