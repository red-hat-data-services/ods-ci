*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Test Cases ***
Launch JupyterLab
  [Tags]  Sanity
  Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for ODH Dashboard to Load
  Launch JupyterHub From ODH Dashboard Dropdown
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Fix Spawner Status
  Remove All Spawner Environment Variables
  Select Notebook Image  s2i-generic-data-science-notebook
  Select Container Size  Small
  Sleep  1
  ${ID} =  Spawner Environment Variable Exists  AWS_ACCESS_KEY_ID
  ${PW} =  Spawner Environment Variable Exists  AWS_SECRET_ACCESS_KEY
  IF  ${ID}==True
    Remove Spawner Environment Variable  AWS_ACCESS_KEY_ID
  END
  Add Spawner Environment Variable  AWS_ACCESS_KEY_ID  ${S3.AWS_ACCESS_KEY_ID}
  IF  ${PW}==True
    Remove Spawner Environment Variable  AWS_SECRET_ACCESS_KEY
  END
  Add Spawner Environment Variable  AWS_SECRET_ACCESS_KEY  ${S3.AWS_SECRET_ACCESS_KEY}
  Spawn Notebook
  Wait for JupyterLab Splash Screen  timeout=30
  Sleep  5
  Maybe Select Kernel
  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document


Long Running Test Case
  Run Repo and Clean  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb
  Run Repo and Clean  https://github.com/lugi0/clustering-notebook  clustering-notebook/CCFraud-clustering.ipynb
  Run Repo and Clean  https://github.com/lugi0/clustering-notebook  clustering-notebook/customer-segmentation-k-means-analysis.ipynb
  Run Repo and Clean  https://github.com/lugi0/clustering-notebook  clustering-notebook/CCFraud-clustering-S3.ipynb
  Run Repo and Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
  Run Repo and Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/TensorFlow-MNIST-Minimal.ipynb

*** Keywords ***

Run Repo and Clean
  [Arguments]  ${REPO_URL}  ${NB_NAME}
  Click Element  xpath://span[@title="/opt/app-root/src"]
  Run Keyword And Continue On Failure  Clone Git Repository And Run  ${REPO_URL}  ${NB_NAME}
  Sleep  15
  Click Element  xpath://span[@title="/opt/app-root/src"]
  Open With JupyterLab Menu  File  Close All Tabs
  Maybe Accept a JupyterLab Prompt
  Open With JupyterLab Menu  File  New  Notebook
  Sleep  5
  Maybe Select Kernel
  Sleep  5
  Add and Run JupyterLab Code Cell  !rm -rf *
  Wait Until JupyterLab Code Cell Is Not Active
