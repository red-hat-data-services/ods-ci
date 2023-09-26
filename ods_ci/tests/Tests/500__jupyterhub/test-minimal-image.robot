*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             DebugLibrary
Library             JupyterLibrary
Library             ../../../libs/Helpers.py

Suite Setup         Begin Web Test
Suite Teardown      End Web Test

Test Tags          Sanity    JupyterHub      OpenDataHub


*** Variables ***
${RequirementsFileRepo}=    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main.git
${RequirementsFilePath}=    ods-ci-notebooks-main/notebooks/500__jupyterhub/test-minimal-image/


*** Test Cases ***
Open RHODS Dashboard
    Wait for RHODS Dashboard to Load

Can Launch Jupyterhub
    Launch Jupyter From RHODS Dashboard Link

Can Login to Jupyterhub
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize jupyterhub service account
    #Wait Until Page Contains Element    xpath://span[@id='jupyterhub-logo']
    Wait Until Page Contains  Start a notebook server

Can Spawn Notebook
    [Tags]    ODS-901    ODS-903
    Fix Spawner Status
    Spawn Notebook With Arguments    image=minimal-notebook

Can Launch Python3 Smoke Test Notebook
    [Tags]    ODS-905    ODS-907    ODS-913    ODS-914    ODS-915    ODS-916    ODS-917    ODS-918    ODS-919
    ##################################################
    # Manual Notebook Input
    ##################################################
    # Sometimes the kernel is not ready if we run the cell too fast
    Sleep    5
    Run Cell And Check For Errors    !pip install boto3

    Add And Run JupyterLab Code Cell In Active Notebook    import os
    Run Cell And Check Output    print("Hello World!")    Hello World!

    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible

    ##################################################
    # Git clone repo and run existing notebook
    ##################################################
    Navigate Home (Root folder) In JupyterLab Sidebar File Browser
    Open With JupyterLab Menu    Git    Clone a Repository
    Wait Until Page Contains    Clone a repo    timeout=30
    Input Text    //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input
    ...    https://github.com/lugi0/minimal-nb-image-test
    Click Element    xpath://button[.="Clone"]
    Sleep    1
    Open With JupyterLab Menu    File    Open from Path…
    Wait Until Page Contains    Open Path    timeout=30
    Input Text    xpath=//input[@placeholder="/path/relative/to/jlab/root"]    minimal-nb-image-test/minimal-nb.ipynb
    Click Element    xpath://div[.="Open"]

    Wait Until minimal-nb.ipynb JupyterLab Tab Is Selected
    Close Other JupyterLab Tabs

    Open With JupyterLab Menu    Run    Run All Cells
    Wait Until JupyterLab Code Cell Is Not Active    timeout=300
    JupyterLab Code Cell Error Output Should Not Be Visible

    #Get the text of the last output cell
    ${output} =   Get Text    (//div[contains(@class,"jp-OutputArea-output")])[last()]
    Should Not Match    ${output}    ERROR*
    Should Be Equal As Strings    ${output}
    ...    [0.40201256371442895, 0.8875, 0.846875, 0.875, 0.896875, 0.9116818405511811]

Verify Tensorflow Can Be Installed In The Minimal Python Image Via Pip
    [Documentation]    Verify Tensorflow Can Be Installed In The Minimal Python image via pip
    [Tags]    ODS-555    ODS-908    ODS-535
    ...       Tier1
    Clone Git Repository And Open    ${RequirementsFileRepo}    ${RequirementsFilePath}
    Open New Notebook
    Close Other JupyterLab Tabs
    Add And Run JupyterLab Code Cell In Active Notebook    !pip install -r requirements.txt --progress-bar off
    Wait Until JupyterLab Code Cell Is Not Active
    ${version} =    Verify Installed Library Version    tensorflow    2.7
    Add And Run JupyterLab Code Cell In Active Notebook    !pip install --upgrade tensorflow --progress-bar off
    Wait Until JupyterLab Code Cell Is Not Active
    ${updated_version} =  Run Cell And Get Output  !pip show tensorflow | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'
    ${res} =      GT    ${updated_version}.0    ${version}[1].0
    IF   not ${res}    Fail
    [Teardown]    Clean Up Server

Verify Jupyterlab Server Pods Are Spawned In A Custom Namespace
    [Documentation]    Verifies that jupyterlab server pods are spawned in a custom namespace (${NOTEBOOKS_NAMESPACE})
    [Tags]    ODS-320
    ${pod_name} =    Get User Notebook Pod Name    ${TEST_USER.USERNAME}
    Verify Operator Pod Status    namespace=${NOTEBOOKS_NAMESPACE}    label_selector=statefulset.kubernetes.io/pod-name=${pod_name}
    ...    expected_status=Running
