*** Settings ***
Library          DebugLibrary
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Suite Setup      JupyterHub Testing Suite Setup
Suite Teardown   End Web Test
Force Tags       JupyterHub

*** Variables ***


*** Test Cases ***
Logged into OpenShift
   [Tags]  Sanity  Smoke  ODS-127
   Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
   Login To Openshift  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
   Wait Until OpenShift Console Is Loaded


Can Launch Jupyterhub
   [Tags]  Sanity  Smoke  ODS-935
   #This keyword will work with accounts that are not cluster admins.
   Launch Jupyterhub via App
   Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
   Wait for RHODS Dashboard to Load
   ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
   IF  ${version-check}==True
      Launch JupyterHub From RHODS Dashboard Link
   ELSE
      Launch JupyterHub From RHODS Dashboard Dropdown
   END

Can Login to Jupyterhub
   [Tags]  Sanity  Smoke  ODS-936
   Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
   ${authorization_required} =  Is Service Account Authorization Required
   Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
   Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']  timeout=30

Can Spawn Notebook
   [Tags]  Sanity
   Fix Spawner Status
   Select Notebook Image  s2i-generic-data-science-notebook
   Select Notebook Image  s2i-minimal-notebook
   Select Container Size  Small
   # Cannot set number of required GPUs on clusters without GPUs anymore
   #Set Number of required GPUs  9
   #Set Number of required GPUs  0
   Add Spawner Environment Variable  env_one  one
   Remove Spawner Environment Variable  env_one
   Add Spawner Environment Variable  env_two  two
   Remove Spawner Environment Variable  env_two
   Add Spawner Environment Variable  env_three  three
   Remove Spawner Environment Variable  env_three

   Add Spawner Environment Variable  env_four  four
   Add Spawner Environment Variable  env_five  five
   Add Spawner Environment Variable  env_six  six
   Remove Spawner Environment Variable  env_four
   Remove Spawner Environment Variable  env_five
   Remove Spawner Environment Variable  env_six
   Spawn Notebook
   Wait for JupyterLab Splash Screen  timeout=30
   Sleep  3
   Maybe Close Popup
   ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
   Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
   Launch a new JupyterLab Document
   Close Other JupyterLab Tabs

Can Launch Python3
   [Tags]  Sanity  TBC
   Launch Python3 JupyterHub


*** Keywords ***
JupyterHub Testing Suite Setup
  Set Library Search Order  SeleniumLibrary
