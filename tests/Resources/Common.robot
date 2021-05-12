*** Settings ***
Library   JupyterLibrary
Resource  Page/ODH/JupyterHub/JupyterLabLauncher.robot

*** Keywords ***
Begin Web Test
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}

End Web Test
    ${server} =  Run Keyword and Return Status  Page Should Contain Element  //div[@id='jp-top-panel']//div[contains(@class, 'p-MenuBar-itemLabel')][text() = 'File']
    IF  ${server}
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

Iterative Image Test
    [Arguments]  ${image}
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
    Run Cell And Check For Errors  !pip install boto3
    Add and Run JupyterLab Code Cell  import os
    Run Cell And Check Output  print("Hello World!")  Hello World!
    #Needs to change for RHODS release
    Run Cell And Check Output  !python --version  Python 3.8.3
    #Run Cell And Check Output  !python --version  Python 3.8.7
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
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