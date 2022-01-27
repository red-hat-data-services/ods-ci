*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Test Cases ***
Launch JupyterLab
  [Tags]  Sanity
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
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
  Fix Spawner Status
  &{S3-credentials} =  Create Dictionary  AWS_ACCESS_KEY_ID=${S3.AWS_ACCESS_KEY_ID}  AWS_SECRET_ACCESS_KEY=${S3.AWS_SECRET_ACCESS_KEY}
  Spawn Notebook With Arguments  image=s2i-generic-data-science-notebook  envs=&{S3-credentials}

Long Running Test Case
  Run Repo and Clean  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb
  Run Repo and Clean  https://github.com/lugi0/clustering-notebook  clustering-notebook/CCFraud-clustering.ipynb
  Run Repo and Clean  https://github.com/lugi0/clustering-notebook  clustering-notebook/customer-segmentation-k-means-analysis.ipynb
  Run Repo and Clean  https://github.com/lugi0/clustering-notebook  clustering-notebook/CCFraud-clustering-S3.ipynb
  Run Repo and Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
  Run Repo and Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb
