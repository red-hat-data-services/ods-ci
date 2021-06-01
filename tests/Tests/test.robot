*** Settings ***
Library          DebugLibrary
Resource         ../Resources/ODS.robot
Resource         ../Resources/Common.robot
Resource         ../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Suite Teardown   End Web Test

*** Variables ***


*** Test Cases ***
Logged into OpenShift
   [Tags]  Sanity  Smoke  ODS-127
   Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
   Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}

Can Launch Jupyterhub
   [Tags]  Sanity  Smoke  ODS-129
   #This keyword will work with accounts that are not cluster admins.
   Launch Jupyterhub via App
   Login To ODH Dashboard  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
   Launch JupyterHub From ODH Dashboard Dropdown

Can Login to Jupyterhub
   [Tags]  Sanity  Smoke  ODS-128
   Login To Jupyterhub  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
   ${authorization_required} =  Is Service Account Authorization Required
   Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
   Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']

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
   Launch a new JupyterLab Document
   Close Other JupyterLab Tabs

Can Launch Python3
   [Tags]  Sanity  TBC
   Launch Python3 JupyterHub


