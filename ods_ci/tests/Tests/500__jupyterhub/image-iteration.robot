*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test
Test Tags       JupyterHub

*** Variables ***
#{xyz-n}  image  repo_URL  notebook_path
@{generic-1}  data-science-notebook  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb
@{generic-2}  data-science-notebook  https://github.com/lugi0/clustering-notebook  clustering-notebook/CCFraud-clustering.ipynb
@{generic-3}  data-science-notebook  https://github.com/lugi0/clustering-notebook  clustering-notebook/customer-segmentation-k-means-analysis.ipynb
@{minimal-1}  minimal-notebook  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb
@{minimal-2}  minimal-notebook  https://github.com/lugi0/clustering-notebook  clustering-notebook/CCFraud-clustering.ipynb
@{minimal-3}  minimal-notebook  https://github.com/lugi0/clustering-notebook  clustering-notebook/customer-segmentation-k-means-analysis.ipynb

${python_dict}  {'classifiers':[${generic-1}, ${minimal-1}], 'clustering':[${generic-2}, ${generic-3}, ${minimal-2}, ${minimal-3}]}

*** Test Cases ***
Open RHODS Dashboard
  [Tags]  Tier1
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For RHODS Dashboard To Load

Iterative Testing Classifiers
  [Tags]  POLARION-ID-Classifiers    Tier1
  ...     Execution-Time-Over-15m
  &{DICTIONARY} =  Evaluate  ${python_dict}
  FOR  ${sublist}  IN  @{DICTIONARY}[classifiers]
    Run Keyword And Warn On Failure  Iterative Image Test  ${sublist}[0]  ${sublist}[1]  ${sublist}[2]
  END

Iterative Testing Clustering
  [Tags]  Tier2  POLARION-ID-Clustering
  ...     ODS-923  ODS-924
  ...     Execution-Time-Over-15m
  &{DICTIONARY} =  Evaluate  ${python_dict}
  FOR  ${sublist}  IN  @{DICTIONARY}[clustering]
    Run Keyword And Warn On Failure  Iterative Image Test  ${sublist}[0]  ${sublist}[1]  ${sublist}[2]
  END


*** Keywords ***
Iterative Image Test
    [Arguments]  ${image}  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    IF  ${authorization_required}  Authorize jupyterhub service account
    Fix Spawner Status
    Spawn Notebook With Arguments  image=${image}
    Run Cell And Check Output  print("Hello World!")  Hello World!
    Python Version Check
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
    #This ensures all workloads are run even if one (or more) fails
    Run Keyword And Warn On Failure  Clone Git Repository And Run  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
    Clean Up Server
    Stop JupyterLab Notebook Server
    Capture Page Screenshot
    Go To  ${ODH_DASHBOARD_URL}
    Sleep  10
