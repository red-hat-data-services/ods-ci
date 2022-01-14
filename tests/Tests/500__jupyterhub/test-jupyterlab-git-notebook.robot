*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          DebugLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Variables ***


*** Test Cases ***
Open RHODS Dashboard
  [Tags]  Sanity
  Wait for RHODS Dashboard to Load

Can Launch Jupyterhub
  [Tags]  Sanity
  ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
  IF  ${version-check}==True
    Launch JupyterHub From RHODS Dashboard Link
  ELSE
    Launch JupyterHub From RHODS Dashboard Dropdown
  END

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
  ##################################################
  # Manual Notebook Input
  ##################################################
  Sleep  5
  Add and Run JupyterLab Code Cell in Active Notebook  !pip install boto3
  Wait Until JupyterLab Code Cell Is Not Active
  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*

  Add and Run JupyterLab Code Cell in Active Notebook  import os
  Add and Run JupyterLab Code Cell in Active Notebook  print("Hello World!")
  Capture Page Screenshot

  JupyterLab Code Cell Error Output Should Not Be Visible

  ##################################################
  # Git clone repo and run existing notebook
  ##################################################
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  Git  Clone a Repository
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  https://github.com/sophwats/notebook-smoke-test
  Click Element  xpath://div[.="CLONE"]

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
