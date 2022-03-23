*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource    ../../../venv/lib/python3.8/site-packages/JupyterLibrary/clients/jupyterlab/Shell.resource
Library             DebugLibrary
Library             JupyterLibrary

Suite Setup         Begin Web Test
Suite Teardown      End Web Test

Force Tags          Smoke    Sanity    JupyterHub

*** Variables ***
${RequirementsFileRepo}=    https://github.com/redhat-rhods-qe/useful-files.git

*** Test Cases ***
Open RHODS Dashboard
    Wait for RHODS Dashboard to Load

Can Launch Jupyterhub
    ${version-check} =    Is RHODS Version Greater Or Equal Than    1.4.0
    IF    ${version-check}==True
        Launch JupyterHub From RHODS Dashboard Link
    ELSE
        Launch JupyterHub From RHODS Dashboard Dropdown
    END

Can Login to Jupyterhub
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    Run Keyword If    ${authorization_required}    Authorize jupyterhub service account
    Wait Until Page Contains Element    xpath://span[@id='jupyterhub-logo']

Can Spawn Notebook
    [Tags]    ODS-901    ODS-903
    Fix Spawner Status
    Spawn Notebook With Arguments    image=s2i-minimal-notebook

Verify Tensorflow Can Be Installed In The Minimal Python Image Via Pip
    [Documentation]    Verify Tensorflow Can Be Installed In The Minimal Python image via pip
    [Tags]    ODS-555    ODS-908    ODS-535
    Clone Git Repository    ${RequirementsFileRepo}
    Open With JupyterLab Menu    File    New    Notebook
    Sleep    1
    Maybe Close Popup
    Close Other JupyterLab Tabs
    Maybe Close Popup
    Sleep    1
    Add and Run JupyterLab Code Cell In Active Notebook    !pip install -r useful-files/requirements.txt
    ${version} =    Run Cell And Get Output
    ...    !pip show tensorflow | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s.%s", b[1], b[2], b[3]}'
    Should Be Equal    2.7.0    ${version}
    Add and Run JupyterLab Code Cell In Active Notebook    !pip install --upgrade tensorflow
    ${updated version} =    Run Cell And Get Output
    ...    !pip show tensorflow | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s.%s", b[1], b[2], b[3]}'
    Should Not Be Equal    ${updated version}    ${version}
    Clean Up User Notebook    ${OCP_ADMIN_USER.USERNAME}    ${TEST_USER.USERNAME}

Verify jupyterlab server pods are spawned in a custom namespace
    [Documentation]    Verifies that jupyterlab server pods are spawned in a custom namespace (rhods-notebooks)
    [Tags]    ODS-320
    ${pod_name} =    Get User Notebook Pod Name    ${TEST_USER.USERNAME}
    ${name} =    Remove String    ${pod_name}    jupyterhub-nb-
    Verify Operator Pod Status    namespace=rhods-notebooks    label_selector=jupyterhub.opendatahub.io/user=${name}
    ...    expected_status=Running

Can Launch Python3 Smoke Test Notebook
    [Tags]    ODS-905    ODS-907    ODS-913    ODS-914    ODS-915    ODS-916    ODS-917    ODS-918    ODS-919
    ##################################################
    # Manual Notebook Input
    ##################################################
    # Sometimes the kernel is not ready if we run the cell too fast
    Sleep    5
    Run Cell And Check For Errors    !pip install boto3

    Add and Run JupyterLab Code Cell in Active Notebook    import os
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
    Click Element    xpath://div[.="CLONE"]
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
    ${output} =    Get Text    (//div[contains(@class,"jp-OutputArea-output")])[last()]
    Should Not Match    ${output}    ERROR*
    Should Be Equal As Strings    ${output}
    ...    [0.40201256371442895, 0.8875, 0.846875, 0.875, 0.896875, 0.9116818405511811]
