*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Library          DebugLibrary
Library          JupyterLibrary
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
  Select Notebook Image  s2i-generic-data-science-notebook
  ${ID} =  Spawner Environment Variable Exists  AWS_ACCESS_KEY_ID
  ${PW} =  Spawner Environment Variable Exists  AWS_SECRET_ACCESS_KEY
  
  IF  ${ID}
    Remove Spawner Environment Variable  AWS_ACCESS_KEY_ID
  END
  Add Spawner Environment Variable  AWS_ACCESS_KEY_ID  ${S3.AWS_ACCESS_KEY_ID}

  IF  ${PW}
    Remove Spawner Environment Variable  AWS_SECRET_ACCESS_KEY
  END
  Add Spawner Environment Variable  AWS_SECRET_ACCESS_KEY  ${S3.AWS_SECRET_ACCESS_KEY}

  Spawn Notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  Sanity
  Wait for JupyterLab Splash Screen  timeout=30
  Maybe Select Kernel
  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document
  Close Other JupyterLab Tabs
  Maybe Open JupyterLab Sidebar  File Browser
  Navigate Home In JupyterLab Sidebar
  Open With JupyterLab Menu  Git  Clone a Repository
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  https://github.com/lugi0/clustering-notebook
  Click Element  xpath://div[.="CLONE"]
  Sleep  10
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  clustering-notebook/CCFraud-clustering-S3.ipynb
  Click Element  xpath://div[.="Open"]
  Wait Until CCFraud-clustering-S3.ipynb JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs
  Open With JupyterLab Menu  Run  Run All Cells
  Wait Until JupyterLab Code Cell Is Not Active  timeout=300
  JupyterLab Code Cell Error Output Should Not Be Visible
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*
