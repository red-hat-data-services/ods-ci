*** Settings ***
Resource  ../Resources/ODS.robot
Library         DebugLibrary

*** Variables ***
${MYBROWSER} =  chrome


*** Test Cases ***
Open ODH Dashboard
  [Tags]  Sanity
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
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
  # Official SKIP status will be available in Robot Framework 4.0
  # See: https://github.com/robotframework/robotframework/issues/3622
  Run Keyword If  ${spawner_visible}!=True  Set Tags  SKIP
  Pass Execution If  ${spawner_visible}!=True  SKIP:The user has an existing notebook pod running
  Select Notebook Image  s2i-lab-elyra
  Spawn Notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  Sanity
  Launch a new JupyterLab Document

  Add and Run JupyterLab Code Cell  import os
  Add and Run JupyterLab Code Cell  print("Hello World!")
  Capture Page Screenshot

  JupyterLab Code Cell Error Output Should Not Be Visible

  Add and Run JupyterLab Code Cell  !pip freeze
  Wait Until JupyterLab Code Cells Is Not Active
  Capture Page Screenshot

  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*

  Close JupyterLab Selected Tab
  Logout JupyterLab
