*** Settings ***
Resource         ../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource         ../../Resources/Common.robot
Suite Setup      Dashboard Test Setup
Suite Teardown   End Web Test


*** Test Cases ***
Verify pip changes after Restarting the notebook is not permenant
  [Tags]  Sanity
  ...     ODS-257
  Install and Import Package In JupyterLab  paramiko
  Stop JupyterLab Notebook Server
  Capture Page Screenshot
  Fix Spawner Status
  Spawn Notebook With Arguments
  Capture Page Screenshot
  Add and Run JupyterLab Code Cell in Active Notebook  import paramiko
  Wait Until JupyterLab Code Cell Is Not Active
  Verify package is Not Installed In JupyterLab  paramiko
  Capture Page Screenshot


*** Keywords ***
Dashboard Test Setup
  Begin Web Test
  Wait for RHODS Dashboard to Load
  Launch JupyterHub Spawner From Dashboard
  Spawn Notebook With Arguments
