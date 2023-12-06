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
  [Tags]  Smoke
  ...     Tier1
  ...     ODS-262
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load
  Verify Service Is Available In The Explore Page Based On Version
  Verify Service Provides "Get Started" Button In The Explore Page Based On Version
  ${status}=   Run Keyword And Return Status
  ...               Verify Service Provides "Enable" Button In The Explore Page Based On Version
  IF   ${status} == ${False}   Run Keywords
  ...              Verify Anaconda Service Is Enabled Based On Version
  ...              AND
  ...              FAIL   msg=Anaconda Professional does not have a "Enable" button in ODH Dashboard since it has been alreday Enabled and Present in Enabled Page  # robocop: disable

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
  Wait Until RHODS Dashboard Jupyter Is Visible
  Capture Page Screenshot  enabletab_anaconda_notpresent.png
  Verify Anaconda Card Not Present Based On Version

Verify User Is Able to Activate Anaconda Professional
  [Tags]  Tier2
  ...     ODS-272  ODS-344  ODS-501  ODS-588  ODS-1082  ODS-1304  ODS-462   ODS-283  ODS-650
  [Documentation]  Performs the Anaconda CE activation, spawns a JL using the Anaconda image,
  ...              validate the token, install a library and try to import it.
  ...              At the end, it stops the JL server and returns to the spawner
  Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
  ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
  ...    browser_options=${BROWSER.OPTIONS}
  Enable Anaconda  ${ANACONDA_CE.ACTIVATION_KEY}
  Capture Page Screenshot  anaconda_success_activation.png
  Menu.Navigate To Page    Applications    Enabled
  Wait Until RHODS Dashboard Jupyter Is Visible
  Verify Anaconda Card Present Based On Version
  Open OCP Console
  Login To Openshift    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    ${OCP_ADMIN_USER.AUTH_TYPE}
  Maybe Skip Tour
  ${val_result}=  Get Pod Logs From UI  namespace=${APPLICATIONS_NAMESPACE}
  ...                                   pod_search_term=anaconda-ce-periodic-validator-job-custom-run
  Log  ${val_result}
  Should Be Equal  ${val_result[0]}  ${VAL_SUCCESS_MSG}
  Wait Until Keyword Succeeds    400 times  5s  Check Anaconda CE Image Build Status  Complete
  Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
  ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
  ...    browser_options=${BROWSER.OPTIONS}
  Launch JupyterHub Spawner From Dashboard
  Run Keyword And Continue On Failure  Verify Anaconda Element Present Based On Version
  Run Keyword And Continue On Failure  Verify Anaconda Element Enabled Based On Version
  Spawn Notebook With Arguments  image=minimal-notebook-anaconda
  Verify Git Plugin
  Check condarc File Content
  Install Numpy Package Should Fail
  Validate Anaconda Token
  Install Numpy Package Should Be Successful
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

Install Numpy Package Should Fail
    [Documentation]     Tries to install python package "numpy" and checks
    ...                 if the output matches the expected error message.
    ...                 The installation should fail because runs before token validation
    ${pkg_install_out}=     Run Cell And Get Output    !conda install -y numpy
    ${pkg_install_out}=     Remove String Using Regexp    ${pkg_install_out}    ${\n}|${SPACE}
    ${PKG_INSTALL_ERROR_MSG}=     Remove String Using Regexp    ${PKG_INSTALL_ERROR_MSG}    ${\n}|${SPACE}
    Should Be Equal As Strings      ${PKG_INSTALL_ERROR_MSG}    ${pkg_install_out}

Validate Anaconda Token
    [Documentation]     Sets the token using "conda" command. It is necessary to start
    ...                 using the conda  packages
    Run Cell And Check Output    !conda token set ${ANACONDA_CE.ACTIVATION_KEY}    ${TOKEN_VAL_SUCCESS_MSG}
    Capture Page Screenshot  anaconda_token_val_cell.png

Install Numpy Package Should Be Successful
    [Documentation]     Tries to install python package "numpy" and checks
    ...                 if it runs without errors.
    ...                 The installation should be successful because runs after token validation
    Add And Run JupyterLab Code Cell In Active Notebook  !conda install -y numpy
    Wait Until JupyterLab Code Cell Is Not Active
    Run Cell And Check For Errors  import numpy as np
    Capture Page Screenshot  conda_lib_install_result.png

Check condarc File Content
    [Documentation]     Checks the location and content of the "condarc" configuration file
    ${condarc_cat_out}=     Run Cell And Get Output    !cat /etc/conda/condarc
    ${condarc_cat_out}=     Remove String Using Regexp    ${condarc_cat_out}    ${\n}|${SPACE}
    ${CONDARC_CAT_RESULT}=     Remove String Using Regexp    ${CONDARC_CAT_RESULT}    ${\n}|${SPACE}
    Should Be Equal As Strings      ${CONDARC_CAT_RESULT}    ${condarc_cat_out}
    Run Keyword And Continue On Failure
    ...             Run Cell And Check Output   !cat $HOME/.condarc    cat: /opt/app-root/src/.condarc: No such file or directory

