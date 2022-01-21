*** Settings ***
Force Tags       Sanity
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Variables ***


*** Test Cases ***
Minimal PyTorch test
  [Tags]  Regression
  ...     PLACEHOLDER  #category tags
  ...     PLACEHOLDER  #Polarion tags
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
  Fix Spawner Status
  Spawn Notebook With Arguments  image=pytorch  size=Default

Verify Installed Python Version in PyTorch
  [Tags]  Regression
  ...     PLACEHOLDER  #category tags
  ...     ODS-217  #Polarion tags
  Python Version Check

Verify Installed Libraries in PyTorch
  [Tags]  Regression
  ...     PLACEHOLDER  #category tags
  ...     ODS-218  #Polarion tags
  Run Keyword And Continue On Failure  Run Cell And Check Output  !nvcc --version | grep nvcc:  nvcc: NVIDIA (R) Cuda compiler driver
  Run Keyword And Continue On Failure  Run Cell And Check Output  !nvcc --version | grep "Cuda compilation"  Cuda compilation tools, release 11.0, V11.0.221
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show torch | grep Version:  Version: 1.8.1
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show tensorboard | grep Version:  Version: 1.15.0
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show boto3 | grep Version:  Version: 1.17.11
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show kafka-python | grep Version:  Version: 2.0.2
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show matplotlib | grep Version:  Version: 3.4.1
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show numpy | grep Version:  Version: 1.19.2
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show pandas | grep Version:  Version: 1.2.4
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show scikit-learn | grep Version:  Version: 0.24.1
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show scipy | grep Version:  Version: 1.6.2
  ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
  IF  ${version-check}==True
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show jupyterlab | grep Version:  Version: 3.2.4
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show notebook | grep Version:  Version: 6.4.6
  ELSE
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show jupyterlab | grep Version:  Version: 3.0.16
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show notebook | grep Version:  Version: 6.4.4
  END

PyTorch Workload test
  [Tags]  Regression
  ...     PLACEHOLDER  #category tags
  ...     PLACEHOLDER  #Polarion tags
  Run Repo and Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
  Capture Page Screenshot
  JupyterLab Code Cell Error Output Should Not Be Visible
