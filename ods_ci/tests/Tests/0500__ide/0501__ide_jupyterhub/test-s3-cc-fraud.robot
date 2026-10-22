*** Settings ***
Resource         ../../../Resources/ODS.robot
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
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
  [Tags]  Tier1  ODS-902  ODS-904
  Fix Spawner Status
  Spawn Notebooks And Set S3 Credentials    image=science-notebook
