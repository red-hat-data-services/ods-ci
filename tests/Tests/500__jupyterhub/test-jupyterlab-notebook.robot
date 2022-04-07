*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          DebugLibrary

Suite Setup      Begin Web Test
Suite Teardown   End Web Test
Force Tags       JupyterHub


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
  [Tags]  Sanity
  Fix Spawner Status
  Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  Sanity  ODS-906
  Add and Run JupyterLab Code Cell in Active Notebook  import os
  Add and Run JupyterLab Code Cell in Active Notebook  print("Hello World!")
  Capture Page Screenshot

  JupyterLab Code Cell Error Output Should Not Be Visible

  Add and Run JupyterLab Code Cell in Active Notebook  !pip freeze
  Wait Until JupyterLab Code Cell Is Not Active
  Capture Page Screenshot

  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*

Verify A Default Image Is Provided And Starts Successfully
    [Documentation]    Verify that, if a user doesn't explicitly select any jupyter image
    ...    a default one is selected and it can be spawned successfully
    [Tags]    Sanity
    ...       ODS-469
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook
    ${has_spawn_failed} =    Has Spawn Failed
    Should Be Equal As Strings    ${has_spawn_failed}    False
    Sleep    30s
    Click Element    xpath=//div[@title='Python 3']
    Verify Notebook Name And Image Tag


*** Keywords ***
Verify Notebook Name And Image Tag
    [Documentation]    Verifies that expected notebook is spawned and image tag is not latest
    @{user_data} =    Get Previously Selected Notebook Image Details
    @{notebook_details} =    Split String    ${userdata}[1]    :
    ${notebook_name} =    Strip String    ${notebook_details}[1]
    Spawned Image Check    image=${notebook_name}
    Should Not Be Equal As Strings    ${notebook_details}[2]    latest    strip_spaces=True
