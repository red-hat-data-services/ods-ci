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
Minimal CUDA test
  Wait for ODH Dashboard to Load
  Launch JupyterHub From ODH Dashboard Dropdown
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
  Fix Spawner Status
  # Size needs to change
  Spawn Notebook With Arguments  image=minimal-gpu  size=Default
  Wait for JupyterLab Splash Screen  timeout=30
  Maybe Select Kernel
  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document
  Close Other JupyterLab Tabs
  Sleep  5
  Run Cell And Check Output  !python --version  Python 3.8.6
  #Run Cell And Check Output  !python --version  Python 3.8.7
  Run Cell And Check Output  !nvcc --version | grep nvcc:  nvcc: NVIDIA (R) Cuda compiler driver
  Run Cell And Check Output  !nvcc --version | grep "Cuda compilation"  Cuda compilation tools, release 11.0, V11.0.221
  # Is it supposed to be V11.0.3? Checking
  #Run Cell And Check Output  !nvcc --version | grep "Cuda compilation"  Cuda compilation tools, release 11.0, V11.0.3
  Capture Page Screenshot
  JupyterLab Code Cell Error Output Should Not Be Visible
