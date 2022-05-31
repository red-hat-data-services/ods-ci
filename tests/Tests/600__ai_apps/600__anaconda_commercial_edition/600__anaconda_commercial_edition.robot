*** Settings ***
Documentation   Test integration with Anaconda ISV
Resource        ../../../Resources/Page/LoginPage.robot
Resource        ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../../Resources/Page/OCPDashboard/Page.robot
Resource        ../../../Resources/Page/ODH/JupyterHub/LoginJupyterHub.robot
Resource        ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource        ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource        ../../../Resources/Page/ODH/AiApps/Anaconda.resource
Resource        ../../../Resources/RHOSi.resource
Library         SeleniumLibrary
Library         JupyterLibrary
Library         ../../../../libs/Helpers.py
Suite Setup     Anaconda Suite Setup


*** Test Cases ***
Verify Anaconda Professional Is Available In RHODS Dashboard Explore/Enabled Page
  [Documentation]  Tests if ACE and its Activation button are present in Explore page.
  ...              If the button is not there, it checks if ACE is already enabled
  [Tags]  Smoke  Sanity
  ...     ODS-262
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load
  Verify Service Is Available In The Explore Page Based On Version
  Verify Service Provides "Get Started" Button In The Explore Page Based On Version
  ${status}=   Run Keyword And Return Status
  ...               Verify Service Provides "Enable" Button In The Explore Page Based On Version
  Run Keyword If   ${status} == ${False}   Run Keywords
  ...              Verify Anaconda Service Is Enabled Based On Version
  ...              AND
  ...              FAIL   msg=Anaconda Professional does not have a "Enable"
  ...    button in ODH Dashboard since it has been alreday Enabled and Present in Enabled Page  # robocop: disable

Verify Anaconda Professional Fails Activation When Key Is Invalid
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
  Verify Anaconda Card Not Present Based On Version

Verify User Is Able to Activate Anaconda Professional
  [Tags]  Tier2
  ...     ODS-272  ODS-344  ODS-501  ODS-588  ODS-1082  ODS-1304  ODS-462   ODS-283
  ...     ProductBug
  [Documentation]  Performs the Anaconda CE activation, spawns a JL using the Anaconda image,
  ...              validate the token, install a library and try to import it.
  ...              At the end, it stops the JL server and returns to the spawner
  Verify Anaconda In Kfdef
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load
  Enable Anaconda  ${ANACONDA_CE.ACTIVATION_KEY}
  Capture Page Screenshot  anaconda_success_activation.png
  Menu.Navigate To Page    Applications    Enabled
  Wait Until RHODS Dashboard JupyterHub Is Visible
  Capture Page Screenshot  enabletab_anaconda_present.png
  Check Doc And Quick Start Link In Enabled Page Tile    anaconda-ce
  Verify Anaconda Card Present Based On Version
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
  Run Keyword And Continue On Failure  Verify Anaconda Element Present Based On Version
  Run Keyword And Continue On Failure  Verify Anaconda Element Enabled Based On Version
  Spawn Notebook With Arguments  image=s2i-minimal-notebook-anaconda
  Verify Git Plugin
  Run Cell And Check Output    !conda token set ${ANACONDA_CE.ACTIVATION_KEY}    ${TOKEN_VAL_SUCCESS_MSG}
  Capture Page Screenshot  anaconda_token_val_cell.png
  Add And Run JupyterLab Code Cell  !conda install -y numpy
  Wait Until JupyterLab Code Cell Is Not Active
  Run Cell And Check For Errors  import numpy as np
  Capture Page Screenshot  conda_lib_install_result.png
  Verify Library Version Is Greater Than  jupyterlab  3.1.4
  Verify Library Version Is Greater Than  notebook    6.4.1
  Maybe Open JupyterLab Sidebar   File Browser
  Fix Spawner Status  # used to close the server and go back to Spawner
  Verify Anaconda Element Present Based On Version
  [Teardown]    Remove Anaconda Component


*** Keywords ***
Anaconda Suite Setup
  [Documentation]  Setup for ACE test suite
  Set Library Search Order  SeleniumLibrary
  RHOSi Setup

Verify Anaconda In Kfdef
    [Documentation]  Verifies if Anaconda is present in Kfdef
    ${res}=  Oc Get  kind=KfDef  namespace=redhat-ods-applications
    @{applications_names} =  Create List
    FOR    ${application}    IN    @{res[0]['spec']['applications']}
        Append To List    ${applications_names}  ${application['name']}
    END
    Should Contain  ${applications_names}  anaconda-ce

Check Doc And Quick Start Link In Anaconda
    Click Button    //article[@id="anaconda-ce"]/div/div/div/button
    ${href} =    Get Element Attribute    //a[contains(text(),"View documentation")]    href
    Check HTTP Status Code    ${href}
    Click Element    //a[contains(text(),"Open quick start")]
    Wait Until Page Contains    With Anaconda Professional
