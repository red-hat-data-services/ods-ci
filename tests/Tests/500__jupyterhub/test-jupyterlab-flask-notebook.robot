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
  [Tags]  Tier2
  Wait for RHODS Dashboard to Load

Can Launch Jupyterhub
  [Tags]  Tier2
  Launch JupyterHub From RHODS Dashboard Dropdown

Can Login to Jupyterhub
  [Tags]  Tier2
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']

Can Spawn Notebook
  [Tags]  Tier2
  Fix Spawner Status
  Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook

Can Run Flask Test Notebook
  [Tags]  Tier2

  Wait for JupyterLab Splash Screen  timeout=30

  Maybe Select Kernel
  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document

  Close Other JupyterLab Tabs

  ##################################################
  # Git clone repo and run existing notebook
  ##################################################
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  Git  Clone a Repository
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  https://github.com/tmckayus/flask-notebook
  Click Element  xpath://div[.="CLONE"]

  # Run the flask server
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  //div[.="Open Path"]/../div[contains(@class, "jp-Dialog-body")]//input  flask-notebook/run_flask.ipynb
  Click Element  xpath://div[.="Open"]
  Wait Until run_flask.ipynb JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs
  Open With JupyterLab Menu  Run  Run All Cells
  # Sleep is necessary here because the server never ends but it needs time to get up and running
  Sleep  15

  # Run the curl command
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  //div[.="Open Path"]/../div[contains(@class, "jp-Dialog-body")]//input  flask-notebook/curl_local.ipynb
  Click Element  xpath://div[.="Open"]
  Wait Until curl_local.ipynb JupyterLab Tab Is Selected
  Open With JupyterLab Menu  Run  Run All Cells
  # Sleep here is necessary because for some reason "Wait Until JupyterLab Code Cell Is Not Active" doesn't seem to work here.
  # Without the sleep, robot goes immediately to gathering input. So, we give the cell 15 seconds to complete
  Sleep  15
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Match  ${output}  Hello World!
  Close JupyterLab Selected Tab

  # Shutdown flask server
  Wait Until run_flask.ipynb JupyterLab Tab Is Selected
  Open With JupyterLab Menu  Kernel  Interrupt Kernel
  Wait Until JupyterLab Code Cell Is Not Active

  Close JupyterLab Selected Tab
  Logout JupyterLab
