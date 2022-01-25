*** Settings ***
Force Tags       Sanity
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          DebugLibrary
Library          JupyterLibrary
Library          Screenshot
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Variables ***


*** Test Cases ***
Minimal Tensorflow test
  [Tags]  Regression
  ...     PLACEHOLDER  #Category tags
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
  Spawn Notebook With Arguments  image=tensorflow  size=Default

Verify Installed Python Version in Tensorflow
  [Tags]  Regression
  ...     PLACEHOLDER  #category tags
  ...     ODS-206  #Polarion tags
  Python Version Check

Verify Installed Libraries in Tensorflow
  [Tags]  Regression
  ...     PLACEHOLDER  #category tags
  ...     ODS-207  #Polarion tags
  Run Keyword And Continue On Failure  Run Cell And Check Output  !nvcc --version | grep nvcc:  nvcc: NVIDIA (R) Cuda compiler driver
  Run Keyword And Continue On Failure  Run Cell And Check Output  !nvcc --version | grep "Cuda compilation"  Cuda compilation tools, release 11.0, V11.0.221
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show boto3 | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  1.17
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show kafka-python | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  2.0
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show matplotlib | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  3.4
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show numpy | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  1.19
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show pandas | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  1.2
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show scikit-learn | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  0.24
  Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show scipy | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  1.6
  ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
  IF  ${version-check}==True
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show jupyterlab | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  3.2
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show notebook | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  6.4
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show tensorflow-gpu | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  2.7
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show tensorboard | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  2.6
  ELSE
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show jupyterlab | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  3.0
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show notebook | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  6.4
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show tensorflow-gpu | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  2.4
    Run Keyword And Continue On Failure  Run Cell And Check Output  !pip show tensorboard | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  2.4
  END


Tensorflow Workload Test
  [Tags]  Regression
  ...     PLACEHOLDER  #category tags
  ...     PLACEHOLDER  #Polarion tags
  Run Repo and Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/tensorflow/GPU-no-warnings.ipynb 
  Capture Page Screenshot
  JupyterLab Code Cell Error Output Should Not Be Visible
