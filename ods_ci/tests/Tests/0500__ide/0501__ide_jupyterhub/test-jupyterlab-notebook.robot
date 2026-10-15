*** Settings ***
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot

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
  Verify Service Account Authorization Not Required
  #Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
  Wait Until Page Contains  Start a basic workbench

Can Spawn Notebook
  [Tags]  Tier1
  Fix Spawner Status
  Spawn Notebook With Arguments  image=science-notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  Tier1  ODS-906
  Add And Run JupyterLab Code Cell In Active Notebook  import os
  Add And Run JupyterLab Code Cell In Active Notebook  print("Hello World!")
  Capture Page Screenshot

  JupyterLab Code Cell Error Output Should Not Be Visible

  Add And Run JupyterLab Code Cell In Active Notebook  !pip freeze
  Wait Until JupyterLab Code Cell Is Not Active
  Capture Page Screenshot

  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*
