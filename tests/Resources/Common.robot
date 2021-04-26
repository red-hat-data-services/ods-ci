*** Settings ***
Library  JupyterLibrary

*** Keywords ***
Begin Web Test
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}

End Web Test
    Click JupyterLab Menu  File
    Click JupyterLab Menu Item  Hub Control Panel
    Switch Window  JupyterHub
    Sleep  5
    Click Element  //*[@id="stop"]
    Wait Until Page Contains  Start My Server  timeout=15
    Close Browser