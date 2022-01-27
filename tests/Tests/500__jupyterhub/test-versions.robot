*** Settings ***
Force Tags       Sanity
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Variables ***
@{notebook_images}  s2i-minimal-notebook  s2i-generic-data-science-notebook  tensorflow  pytorch

*** Test Cases ***
Verify Installed Libraries
  [Tags]  Sanity
  ...     ODS-340  ODS-695  ODS-204  ODS-205  ODS-206  ODS-207  ODS-215  ODS-216  ODS-217  ODS-218
  Wait for RHODS Dashboard to Load
  ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
  IF  ${version-check}==True
    Launch JupyterHub From RHODS Dashboard Link
  ELSE
    Launch JupyterHub From RHODS Dashboard Dropdown
  END
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
  Verify Libraries In Base Images

*** Keywords ***
Verify Libraries In Base Images
    FOR  ${img}  IN  @{notebook_images}
        @{list} =  Create List
        ${text} =  Fetch Image Description Info  ${img}
        Append To List  ${list}  ${text}
        ${tmp} =  Fetch Image Tooltip Info  ${img}
        ${list} =  Combine Lists  ${list}  ${tmp}
        Log  ${list}
        Spawn Notebook With Arguments  image=${img}
        Check Versions In JupyterLab  ${list}
        Clean Up Server
        Stop JupyterLab Notebook Server
        Go To  ${ODH_DASHBOARD_URL}
        Wait for RHODS Dashboard to Load
        Launch JupyterHub From RHODS Dashboard Link
        Wait Until JupyterHub Spawner Is Ready
    END
