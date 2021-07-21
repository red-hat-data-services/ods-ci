*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Library          DebugLibrary

Suite Setup      Begin Web Test
Suite Teardown   End Web Test


*** Variables ***


*** Test Cases ***
Open ODH Dashboard
  [Tags]  Sanity
  Wait for ODH Dashboard to Load

Can Launch Jupyterhub
  [Tags]  Sanity
  Launch JupyterHub From ODH Dashboard Dropdown

Can Login to Jupyterhub
  [Tags]  Sanity
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']

Can Spawn Notebook
  [Tags]  Sanity
  Fix Spawner Status
  Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  Sanity

  Wait for JupyterLab Splash Screen  timeout=30
  Maybe Select Kernel
  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document
  Close Other JupyterLab Tabs

  Add and Run JupyterLab Code Cell  import os
  Add and Run JupyterLab Code Cell  print("Hello World!")
  Capture Page Screenshot

  JupyterLab Code Cell Error Output Should Not Be Visible

  Add and Run JupyterLab Code Cell  !pip freeze
  Wait Until JupyterLab Code Cell Is Not Active
  Capture Page Screenshot

  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*
