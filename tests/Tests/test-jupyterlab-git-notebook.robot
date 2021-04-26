*** Settings ***
Resource  ../Resources/ODS.robot
Library         DebugLibrary

*** Variables ***


*** Test Cases ***
Open ODH Dashboard
  [Tags]  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For Condition  return document.title == "Red Hat OpenShift Data Science Dashboard"

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
  Select Notebook Image  s2i-generic-data-science-notebook
  #This env is required until JupyterLab is the default interface in RHODS
  Add Spawner Environment Variable  JUPYTER_ENABLE_LAB  true
  Spawn Notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  Sanity

  Wait for JupyterLab Splash Screen

  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document

  Close Other JupyterLab Tabs

  ##################################################
  # Manual Notebook Input
  ##################################################
  Add and Run JupyterLab Code Cell  !pip install boto3
  Wait Until JupyterLab Code Cell Is Not Active
  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*

  Add and Run JupyterLab Code Cell  import os
  Add and Run JupyterLab Code Cell  print("Hello World!")
  Capture Page Screenshot

  JupyterLab Code Cell Error Output Should Not Be Visible

  ##################################################
  # Git clone repo and run existing notebook
  ##################################################
  Maybe Open JupyterLab Sidebar  File Browser
  Navigate Home In JupyterLab Sidebar
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

  Logout JupyterLab
