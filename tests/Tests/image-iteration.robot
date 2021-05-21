*** Settings ***
Resource         ../Resources/ODS.robot
Resource         ../Resources/Common.robot
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
Open ODH Dashboard
  [Tags]  Sanity
  Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for ODH Dashboard to Load

Iterative Testing Classifiers
  [Tags]  Sanity  POLARION-ID-Classifiers
  &{DICTIONARY} =  Evaluate  ${python_dict}
  FOR  ${sublist}  IN  @{DICTIONARY}[classifiers]
    Iterative Image Test  ${sublist}[0]  ${sublist}[1]  ${sublist}[2]
  END

Iterative Testing Clustering
  [Tags]  Sanity  POLARION-ID-Clustering
  &{DICTIONARY} =  Evaluate  ${python_dict}
  FOR  ${sublist}  IN  @{DICTIONARY}[clustering]
    Iterative Image Test  ${sublist}[0]  ${sublist}[1]  ${sublist}[2]
  END

*** Keywords ***
Iterative Image Test
    [Arguments]  ${image}  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
    Launch JupyterHub From ODH Dashboard Dropdown
    Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Select Notebook Image  ${image}
    Spawn Notebook
    Wait for JupyterLab Splash Screen  timeout=30
    Maybe Select Kernel
    ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
    Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
    Launch a new JupyterLab Document
    Close Other JupyterLab Tabs
    Sleep  5
    Run Cell And Check Output  print("Hello World!")  Hello World!
    #Needs to change for RHODS release
    Run Cell And Check Output  !python --version  Python 3.8.3
    #Run Cell And Check Output  !python --version  Python 3.8.7
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
    #This ensures all workloads are run even if one (or more) fails
    Run Keyword And Continue On Failure  Clone Git Repository And Run  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
    Clean Up Server
    Click JupyterLab Menu  File
    Capture Page Screenshot
    Click JupyterLab Menu Item  Hub Control Panel
    Switch Window  JupyterHub
    Sleep  5
    Click Element  //*[@id="stop"]
    Wait Until Page Contains  Start My Server  timeout=15
    Capture Page Screenshot
    Go To  ${ODH_DASHBOARD_URL}
    Sleep  10