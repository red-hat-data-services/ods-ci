*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          DebugLibrary

#Suite Setup      Begin Web Test
Suite Setup      Accelerated Setup Suite
Suite Teardown   End Web Test


*** Keywords ***
Accelerated Setup Suite
  Set Library Search Order  SeleniumLibrary
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}

*** Variables ***

*** Test Cases ***

Open RHODS Dashboard
  [Tags]  Start Sequence
  Capture Page Screenshot
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load
  Capture Page Screenshot
