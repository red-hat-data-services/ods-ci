*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot

Suite Setup      Begin Web Test
Suite Teardown   End Web Test


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

Can Launch Python3 Notebook And Install Library
  [Tags]  Sanity 
  ...     ODS-257
  Add and Run JupyterLab Code Cell in Active Notebook  !pip install paramiko
  Add and Run JupyterLab Code Cell in Active Notebook  import paramiko
  Capture Page Screenshot
  Wait Until JupyterLab Code Cell Is Not Active
  JupyterLab Code Cell Error Output Should Not Be Visible
  Capture Page Screenshot


  Stop JupyterLab Notebook Server
  Capture Page Screenshot

  Fix Spawner Status
  Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook
  Capture Page Screenshot

  Add and Run JupyterLab Code Cell in Active Notebook  import paramiko
  Wait Until JupyterLab Code Cell Is Not Active
  
  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Split String    ${output}, " "
  Should Contain  ${output}  ModuleNotFoundError
  Capture Page Screenshot
