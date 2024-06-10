*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          DebugLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test
Test Tags       JupyterHub

*** Variables ***


*** Test Cases ***
Open RHODS Dashboard
  [Tags]  Tier1
  Wait For RHODS Dashboard To Load

Can Launch Jupyterhub
  [Tags]  Tier1
  Launch Jupyter From RHODS Dashboard Link

Can Login to Jupyterhub
  [Tags]  Tier1
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  IF  ${authorization_required}  Authorize jupyterhub service account
  #Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
  Wait Until Page Contains  Start a notebook server

Can Spawn Notebook
  [Tags]  Tier1
  Fix Spawner Status
  Spawn Notebook With Arguments  image=science-notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  Tier1
  ##################################################
  # Manual Notebook Input
  ##################################################
  Sleep  5
  Add And Run JupyterLab Code Cell In Active Notebook  !pip install boto3
  Wait Until JupyterLab Code Cell Is Not Active
  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*

  Add And Run JupyterLab Code Cell In Active Notebook  import os
  Add And Run JupyterLab Code Cell In Active Notebook  print("Hello World!")
  Capture Page Screenshot

  JupyterLab Code Cell Error Output Should Not Be Visible

  ##################################################
  # Git clone repo and run existing notebook
  ##################################################
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  Git  Clone a Repository
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  https://github.com/sophwats/notebook-smoke-test
  Click Element  xpath://button[.="Clone"]

  Open With JupyterLab Menu  File  Open from Path…
  Input Text  //div[.="Open Path"]/../div[contains(@class, "jp-Dialog-body")]//input  notebook-smoke-test/watermark-smoke-test.ipynb
  Click Element  xpath://div[.="Open"]

  Wait Until watermark-smoke-test.ipynb JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs

  Open With JupyterLab Menu  Run  Run All Cells
  Wait Until JupyterLab Code Cell Is Not Active
  JupyterLab Code Cell Error Output Should Not Be Visible

  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*
