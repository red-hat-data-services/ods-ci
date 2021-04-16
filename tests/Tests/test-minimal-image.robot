*** Settings ***
Resource  ../Resources/ODS.robot
Library         DebugLibrary
Library         JupyterLibrary

*** Variables ***


*** Test Cases ***
Open ODH Dashboard
  [Tags]  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For Condition  return document.title == "Open Data Hub Dashboard"

Can Launch Jupyterhub
  [Tags]  Sanity
  Launch JupyterHub From ODH Dashboard Dropdown

Can Login to Jupyterhub
  [Tags]  Sanity
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account

Can Spawn Notebook
  [Tags]  Sanity
  # We need to skip this testcase if the user has an existing pod
  ${spawner_visible} =  JupyterHub Spawner Is Visible
  Skip If  ${spawner_visible}!=True  The user has an existing notebook pod running
  Select Notebook Image  s2i-minimal-notebook
  #This env is required until JupyterLab is the default interface in RHODS
  Add Spawner Environment Variable  JUPYTER_ENABLE_LAB  true
  Spawn Notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  Sanity

  Wait for JupyterLab Splash Screen

  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document
  
  ${is_kernel_selected} =  Run Keyword And Return Status  Page Should Not Contain Element  xpath=/html/body/div[3]
  Run Keyword If  not ${is_kernel_selected}  Click Button  xpath=/html/body/div[3]/div/div[2]/button[2]

  Close Other JupyterLab Tabs

  ##################################################
  # Manual Notebook Input
  ##################################################
  # Sometimes the kernel is not ready if we run the cell too fast
  Sleep  5
  Run Cell And Check For Errors  !pip install boto3

  Add and Run JupyterLab Code Cell  import os
  Run Cell And Check Output  print("Hello World!")  Hello World!

  #Needs to change for RHODS release
  Run Cell And Check Output  !python --version  Python 3.6.8
  #Run Cell And Check Output  !python --version  Python 3.8.7

  Capture Page Screenshot
  JupyterLab Code Cell Error Output Should Not Be Visible

  ##################################################
  # Git clone repo and run existing notebook
  ##################################################
  #Maybe Open JupyterLab Sidebar  File Browser
  #Navigate Home In JupyterLab Sidebar
  #Open With JupyterLab Menu  Git  Clone a Repository
  #Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  https://github.com/lugi0/minimal-nb-image-test
  #Click Element  xpath://div[.="CLONE"]

  #The above doesn't work currently since the git plugin is not available
  #In the minimal image
  Add and Run JupyterLab Code Cell  !git clone https://github.com/lugi0/minimal-nb-image-test

  #When cloning from inside a notebook cell it takes a while for the folder to appear
  Sleep  10
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=/html/body/div[3]/div/div[1]/input  minimal-nb-image-test/minimal-nb.ipynb
  Click Element  xpath://div[.="Open"]

  Wait Until minimal-nb.ipynb JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs

  Open With JupyterLab Menu  Run  Run All Cells
  Wait Until JupyterLab Code Cell Is Not Active
  JupyterLab Code Cell Error Output Should Not Be Visible

  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*
  Should Be Equal As Strings  ${output}  [0.40201256371442895, 0.8875, 0.846875, 0.875, 0.896875, 0.9116818405511811]

  Logout JupyterLab
