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
  [Tags]  Sanity  ODS-902  ODS-904
  Fix Spawner Status
  &{S3-credentials} =  Create Dictionary  AWS_ACCESS_KEY_ID=${S3.AWS_ACCESS_KEY_ID}  AWS_SECRET_ACCESS_KEY=${S3.AWS_SECRET_ACCESS_KEY}
  Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook  envs=&{S3-credentials}

Can Launch Python3 Smoke Test Notebook
  [Tags]  Sanity  ODS-910  ODS-911  ODS-921  ODS-924  ODS-929  ODS-931  ODS-333
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  Git  Clone a Repository
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  https://github.com/lugi0/clustering-notebook
  Click Element  xpath://div[.="CLONE"]
  Sleep  10
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  clustering-notebook/CCFraud-clustering-S3.ipynb
  Click Element  xpath://div[.="Open"]
  Wait Until CCFraud-clustering-S3.ipynb JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs
  Sleep  5
  Open With JupyterLab Menu  Run  Run All Cells
  Wait Until JupyterLab Code Cell Is Not Active  timeout=300
  JupyterLab Code Cell Error Output Should Not Be Visible
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*
