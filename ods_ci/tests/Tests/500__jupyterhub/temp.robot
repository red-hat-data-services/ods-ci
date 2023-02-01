*** Settings ***
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/OCPDashboard/InstalledOperators/InstalledOperators.robot
Library          DebugLibrary
Library          JupyterLibrary
Library          Process
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Variables ***
${JLAB XP TOP}    //div[@id='jp-top-panel']
${JLAB XP MENU ITEM LABEL}    //div[contains(@class, 'p-Menu-itemLabel')]
${JLAB XP MENU LABEL}    //div[contains(@class, 'p-MenuBar-itemLabel')]


*** Test Cases ***
Test
    Wait for RHODS Dashboard to Load
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    #Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
    Wait Until Page Contains  Start a Notebook server
    Fix Spawner Status
    Select Notebook Image    tensorflow
    Select Notebook Image    pytorch

*** Keywords ***
Click JupyterLab Menu MOD
    [Arguments]    ${label}
    [Documentation]    Click a top-level JupyterLab menu bar item by ``label``,
    ...    e.g. _File_, _Help_, etc.
    ${xpath} =    Set Variable    ${JLAB XP TOP}${JLAB XP MENU LABEL}\[text() = '${label}']
    Wait Until Page Contains Element    ${xpath}
    Mouse Over    ${xpath}
    Click Element    ${xpath}
    Run Keyword and Ignore Error    Mouse Over    ${xpath}

Click JupyterLab Menu Item MOD
    [Arguments]    ${label}
    [Documentation]    Click a currently-visible JupyterLab menu item by ``label``.
    #${item} =    Set Variable    ${JLAB XP MENU ITEM LABEL}\[text() = '${label}']
    ${item} =    Set Variable    ${JLAB XP MENU ITEM LABEL}\[text() = '${label}']/..[not(contains(@class,'p-mod-disabled'))]
    Wait Until Page Contains Element    ${item}
    Mouse Over    ${item}
    Click Element    ${item}
    Run Keyword and Ignore Error    Mouse Over    ${item}

Open With JupyterLab Menu MOD
    [Arguments]    ${menu}    @{submenus}
    [Documentation]    Click into a ``menu``, then a series of ``submenus``.
    Click JupyterLab Menu MOD    ${menu}
    FOR    ${submenu}    IN    @{submenus}
        Click JupyterLab Menu Item MOD    ${submenu}
    END
