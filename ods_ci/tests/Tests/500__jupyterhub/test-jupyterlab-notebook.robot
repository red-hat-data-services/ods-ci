*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot

Library          DebugLibrary

Suite Setup      Begin Web Test
Suite Teardown   End Web Test
Test Tags       JupyterHub


*** Variables ***


*** Test Cases ***
Open RHODS Dashboard
  [Tags]  Sanity    Tier1
  Wait for RHODS Dashboard to Load

Can Launch Jupyterhub
  [Tags]  Sanity    Tier1
  Launch Jupyter From RHODS Dashboard Link

Can Login to Jupyterhub
  [Tags]  Sanity    Tier1
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  IF  ${authorization_required}  Authorize jupyterhub service account
  #Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
  Wait Until Page Contains  Start a notebook server

Can Spawn Notebook
  [Tags]  Sanity    Tier1
  Fix Spawner Status
  Spawn Notebook With Arguments  image=science-notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  Sanity  ODS-906    Tier1
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

Verify A Default Image Is Provided And Starts Successfully
    [Documentation]    Verify that, if a user doesn't explicitly select any jupyter image
    ...    a default one is selected and it can be spawned successfully
    [Tags]    Sanity    Tier1
    ...       ODS-469
    Clean Up Server
    Stop JupyterLab Notebook Server
    Go To    ${ODH_DASHBOARD_URL}
    ${user_data} =    Get Previously Selected Notebook Image Details
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook
    Run Keyword And Warn On Failure   Login To Openshift  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    IF  ${authorization_required}  Authorize jupyterhub service account
    Run Keyword And Continue On Failure  Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
    Open New Notebook In Jupyterlab Menu
    Verify Notebook Name And Image Tag  user_data=${user_data}
    ${has_spawn_failed} =    Has Spawn Failed
    Should Be Equal As Strings    ${has_spawn_failed}    False


Refine Notebook Controller Routes
    [Documentation]   When JL Loses its Pods,
    ...   Restart link should takes you to the Spawner Page.
    [Tags]   ODS-1765
    ...      Tier2
    Launch JupyterHub Spawner From Dashboard
    Run Keyword And Ignore Error   Spawn Notebook With Arguments
    ${safe_username} =   Get Safe Username    ${TEST_USER.USERNAME}
    ${user_name} =    Set Variable    jupyter-nb-${safe_username}
    Run  oc delete notebook ${user_name} -n ${NOTEBOOKS_NAMESPACE}
    Wait Until Page Contains    Server unavailable or unreachable       timeout=120
    ${ele}    Get WebElement   //button[.="Restart"]
    Execute Javascript    arguments[0].click();     ARGUMENTS    ${ele}
    Switch Window  locator=NEW
    Wait Until Page Contains    Start a notebook server   timeout=60s

Spawn Jupyter Notebook When Notebook CR Is Deleted
    [Documentation]   When you have a Notebook, and you delete that Notebook CR,
    ...   then try to create another one notebook sucesfully
    [Tags]   ODS-1764
    ...      Tier2
    Launch JupyterHub Spawner From Dashboard
    Run Keyword And Ignore Error    Spawn Notebook With Arguments
    ${safe_username} =   Get Safe Username    ${TEST_USER.USERNAME}
    ${user_name} =    Set Variable    jupyter-nb-${safe_username}
    Run  oc delete notebook ${user_name} -n ${NOTEBOOKS_NAMESPACE}
    Close Browser
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook

*** Keywords ***
Verify Notebook Name And Image Tag
    [Documentation]    Verifies that expected notebook is spawned and image tag is not latest
    [Arguments]    ${user_data}
    @{notebook_details} =    Split String    ${userdata}    :
    ${notebook_name} =    Strip String    ${notebook_details}[0]
    Spawned Image Check    image=${notebook_name}
    Should Not Be Equal As Strings    ${notebook_details}[1]    latest    strip_spaces=True

Get Previously Selected Notebook Image Details
    [Documentation]  Returns image:tag information from the Notebook CR for a user
    ...    or minimal-gpu:default if the CR doesn't exist (default pre selected image in spawner)
    ${safe_username} =   Get Safe Username    ${TEST_USER.USERNAME}
    ${user_name} =    Set Variable    jupyter-nb-${safe_username}
    # The TC using this kw only cares about the image:tag information, let's get that
    # directly
    ${user_data} =  Run  oc get notebook ${user_name} -o yaml -n ${NOTEBOOKS_NAMESPACE} | yq '.spec.template.spec.containers[0].image' | xargs basename
    ${notfound} =  Run Keyword And Return Status  Should Be Equal As Strings  ${user_data}  null
    IF  ${notfound}==True
      ${user_data} =  Set Variable  minimal-gpu:default
    END
    RETURN    ${user_data}
