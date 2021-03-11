*** Settings ***
Library  JupyterLibrary

*** Keywords ***
JupyterHub Dashboard Is Visible
   ${is_dashboard_visible} =  Run Keyword and Return Status  Get WebElement  xpath://a[@title="dashboard"]
   [Return]  ${is_dashboard_visible}

Open JupyterHub Control Panel
   Wait Until Page Contains Element  link:Control Panel
   Click Link  Control Panel

Start Notebook Server
   Open JupyterHub Control Panel
   Click Link  start

Stop Notebook Server
   Open JupyterHub Control Panel
   Wait Until Page Contains  Stop My Server  30 seconds
   # This is a dumb sleep to give the Stop button in the WebUI time to actually work when clicked
   #TODO: Determine if there is any web element attribute that will allow signify when the Stop button will actually work
   Sleep  2 seconds
   Click Element  stop
   Wait Until Element Is Not Visible   stop  3 minute
   Wait Until Page Contains  Start My Server  1 minute

Click Logout
   Click Button  Logout
