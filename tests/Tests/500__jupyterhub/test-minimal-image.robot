*** Settings ***
Force Tags       Smoke  Sanity
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Variables ***

*** Test Cases ***
Open RHODS Dashboard
  Wait for RHODS Dashboard to Load

Can Launch Jupyterhub
  ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
  IF  ${version-check}==True
    Launch JupyterHub From RHODS Dashboard Link
  ELSE
    Launch JupyterHub From RHODS Dashboard Dropdown
  END

Can Login to Jupyterhub
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']

Can Spawn Notebook
  [Tags]  ODS-901  ODS-903
  Fix Spawner Status
  Spawn Notebook With Arguments  image=s2i-minimal-notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  ODS-905  ODS-907  ODS-913  ODS-914  ODS-915  ODS-916  ODS-917  ODS-918  ODS-919
  ##################################################
  # Manual Notebook Input
  ##################################################
  # Sometimes the kernel is not ready if we run the cell too fast
  Sleep  5
  Run Cell And Check For Errors  !pip install boto3

  Add and Run JupyterLab Code Cell in Active Notebook  import os
  Run Cell And Check Output  print("Hello World!")  Hello World!
  Python Version Check

  Capture Page Screenshot
  JupyterLab Code Cell Error Output Should Not Be Visible

  ##################################################
  # Git clone repo and run existing notebook
  ##################################################
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  Git  Clone a Repository
  Wait Until Page Contains    Clone a repo   timeout=30
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  https://github.com/lugi0/minimal-nb-image-test
  Click Element  xpath://div[.="CLONE"]
  Sleep  1
  Open With JupyterLab Menu  File  Open from Path…
  Wait Until Page Contains    Open Path   timeout=30
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  minimal-nb-image-test/minimal-nb.ipynb
  Click Element  xpath://div[.="Open"]

  Wait Until minimal-nb.ipynb JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs

  Open With JupyterLab Menu  Run  Run All Cells
  Wait Until JupyterLab Code Cell Is Not Active  timeout=300
  JupyterLab Code Cell Error Output Should Not Be Visible

  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*
  Should Be Equal As Strings  ${output}  [0.40201256371442895, 0.8875, 0.846875, 0.875, 0.896875, 0.9116818405511811]
