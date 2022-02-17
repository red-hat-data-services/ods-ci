*** Settings ***
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library             JupyterLibrary

Suite Setup         Begin Web Test
Suite Teardown      End Web Test

Force Tags          Sanity


*** Variables ***
@{status_list}


*** Test Cases ***
Open JupyterHub Spawner Page
    [Tags]    ODS-695
    Wait for RHODS Dashboard to Load
    ${version-check} =    Is RHODS Version Greater Or Equal Than    1.4.0
    IF    ${version-check}==True
        Launch JupyterHub From RHODS Dashboard Link
    ELSE
        Launch JupyterHub From RHODS Dashboard Dropdown
    END
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    Run Keyword If    ${authorization_required}    Authorize jupyterhub service account
    Wait Until Page Contains Element    xpath://span[@id='jupyterhub-logo']

Verify Libraries in Minimal Image
    @{additional_libs} =    Create List
    ${status} =    Verify Libraries In Base Image    s2i-minimal-notebook    ${additional_libs}
    Append To List    ${status_list}    ${status}
    Run Keyword If    '${status}' == 'FAIL'    Fail    Shown and installed libraries for minimal image do not match

Verify Libraries in SDS Image
    @{additional_libs} =    Create List
    Append To List    ${additional_libs}    JupyterLab v3.2    Notebook v6.4
    ${status} =    Verify Libraries In Base Image    s2i-generic-data-science-notebook    ${additional_libs}
    Append To List    ${status_list}    ${status}
    Run Keyword If    '${status}' == 'FAIL'    Fail    Shown and installed libraries for SDS image do not match

Verify Libraries in PyTorch Image
    [Tags]    ODS-215    ODS-216    ODS-217    ODS-218
    @{additional_libs} =    Create List
    Append To List    ${additional_libs}    JupyterLab v3.2    Notebook v6.4
    ${status} =    Verify Libraries In Base Image    pytorch    ${additional_libs}
    Append To List    ${status_list}    ${status}
    Run Keyword If    '${status}' == 'FAIL'    Fail    Shown and installed libraries for pytorch image do not match

Verify Libraries in Tensorflow Image
    [Tags]    ODS-204    ODS-205    ODS-206    ODS-207
    @{additional_libs} =    Create List
    Append To List    ${additional_libs}    JupyterLab v3.2    Notebook v6.4
    ${status} =    Verify Libraries In Base Image    tensorflow    ${additional_libs}
    Append To List    ${status_list}    ${status}
    Run Keyword If    '${status}' == 'FAIL'    Fail    Shown and installed libraries for tensorflow image do not match

Verify All Images And Spawner
    [Tags]    ODS-340
    List Should Not Contain Value    ${status_list}    FAIL
    ${length} =    Get Length    ${status_list}
    Should Be Equal As Integers    ${length}    4
    Log To Console    ${status_list}


*** Keywords ***
Verify Libraries In Base Image
    [Arguments]    ${img}    ${additional_libs}
    @{list} =    Create List
    ${text} =    Fetch Image Description Info    ${img}
    Append To List    ${list}    ${text}
    ${tmp} =    Fetch Image Tooltip Info    ${img}
    ${list} =    Combine Lists    ${list}    ${tmp}
    ${list} =    Combine Lists    ${list}    ${additional_libs}
    Log    ${list}
    Spawn Notebook With Arguments    image=${img}
    ${status} =    Check Versions In JupyterLab    ${list}
    Clean Up Server
    Stop JupyterLab Notebook Server
    Go To    ${ODH_DASHBOARD_URL}
    Wait for RHODS Dashboard to Load
    Launch JupyterHub From RHODS Dashboard Link
    Wait Until JupyterHub Spawner Is Ready
    [Return]    ${status}
