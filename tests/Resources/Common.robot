*** Settings ***
Library   JupyterLibrary
Resource  Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource  Page/ODH/JupyterHub/JupyterHubSpawner.robot

*** Keywords ***
Begin Web Test
    [Documentation]  This keyword should be used as a Suite Setup; it will log in to the
    ...              ODH dashboard, checking that the spawner is in a ready state before 
    ...              handing control over to the test suites.
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for ODH Dashboard to Load
    Launch JupyterHub From ODH Dashboard Dropdown
    Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Fix Spawner Status
    Sleep  10
    Go To  ${ODH_DASHBOARD_URL}

End Web Test
    ${server} =  Run Keyword and Return Status  Page Should Contain Element  //div[@id='jp-top-panel']//div[contains(@class, 'p-MenuBar-itemLabel')][text() = 'File']
    IF  ${server}==True
        Clean Up Server
        Click JupyterLab Menu  File
        Capture Page Screenshot
        Click JupyterLab Menu Item  Hub Control Panel
        Switch Window  JupyterHub
        Sleep  5
        Click Element  //*[@id="stop"]
        Wait Until Page Contains  Start My Server  timeout=15
        Capture Page Screenshot
    END
    Close Browser