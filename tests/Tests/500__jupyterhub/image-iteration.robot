*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Variables ***
#{xyz-n}  image  repo_URL  notebook_path
@{generic-1}  s2i-generic-data-science-notebook  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb
@{generic-2}  s2i-generic-data-science-notebook  https://github.com/lugi0/clustering-notebook  clustering-notebook/CCFraud-clustering.ipynb
@{generic-3}  s2i-generic-data-science-notebook  https://github.com/lugi0/clustering-notebook  clustering-notebook/customer-segmentation-k-means-analysis.ipynb
@{minimal-1}  s2i-minimal-notebook  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb
@{minimal-2}  s2i-minimal-notebook  https://github.com/lugi0/clustering-notebook  clustering-notebook/CCFraud-clustering.ipynb
@{minimal-3}  s2i-minimal-notebook  https://github.com/lugi0/clustering-notebook  clustering-notebook/customer-segmentation-k-means-analysis.ipynb

${python_dict}  {'classifiers':[${generic-1}, ${minimal-1}], 'clustering':[${generic-2}, ${generic-3}, ${minimal-2}, ${minimal-3}]}

*** Test Cases ***
Open RHODS Dashboard
  [Tags]  Sanity
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

Iterative Testing Classifiers
  [Tags]  Sanity  POLARION-ID-Classifiers
  &{DICTIONARY} =  Evaluate  ${python_dict}
  FOR  ${sublist}  IN  @{DICTIONARY}[classifiers]
    Run Keyword And Continue On Failure  Iterative Image Test  ${sublist}[0]  ${sublist}[1]  ${sublist}[2]
  END

Iterative Testing Clustering
  [Tags]  Sanity  POLARION-ID-Clustering
  ...     ODS-923  ODS-924
  &{DICTIONARY} =  Evaluate  ${python_dict}
  FOR  ${sublist}  IN  @{DICTIONARY}[clustering]
    Run Keyword And Continue On Failure  Iterative Image Test  ${sublist}[0]  ${sublist}[1]  ${sublist}[2]
  END

*** Keywords ***
Iterative Image Test
    [Arguments]  ${image}  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
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
    Spawn Notebook With Arguments  image=${image}
    Run Cell And Check Output  print("Hello World!")  Hello World!
    Python Version Check
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
    #This ensures all workloads are run even if one (or more) fails
    Run Keyword And Continue On Failure  Clone Git Repository And Run  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
    Clean Up Server
    Stop JupyterLab Notebook Server
    Capture Page Screenshot
    Go To  ${ODH_DASHBOARD_URL}
    Sleep  10
