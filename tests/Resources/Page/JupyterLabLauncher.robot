*** Settings ***
Library  JupyterLibrary

*** Keywords ***
Get JupyterLab Selected Tab Label
  ${tab_label} =  Get Text  //div[contains(@class,"lm-DockPanel-tabBar")]/ul[@class="lm-TabBar-content p-TabBar-content"]/li[contains(@class,"lm-mod-current p-mod-current")]/div[contains(@class,"p-TabBar-tabLabel")]
  [return]  ${tab_label}

JupyterLab Launcher Tab Is Visible
  Get WebElement  xpath://div[contains(@class,"lm-DockPanel-tabBar")]/ul[@class="lm-TabBar-content p-TabBar-content"]/li/div[.="Launcher"]

JupyterLab Launcher Tab Is Selected
  Get WebElement  xpath://div[contains(@class,"lm-DockPanel-tabBar")]/ul[@class="lm-TabBar-content p-TabBar-content"]/li[contains(@class,"lm-mod-current p-mod-current")]/div[.="Launcher"]

Open JupyterLab Launcher
  Open With JupyterLab Menu  File  New Launcher
  JupyterLab Launcher Tab Is Visible
  JupyterLab Launcher Tab Is Selected

Close JupyterLab Selected Tab
  Click Element  xpath://div[contains(@class,"lm-DockPanel-tabBar")]/ul[@class="lm-TabBar-content p-TabBar-content"]/li[contains(@class,"lm-mod-current p-mod-current")]/div[contains(@class,"lm-TabBar-tabCloseIcon")]
  Maybe Accept a JupyterLab Prompt

JupyterLab Code Cell Error Output Should Not Be Visible
  Element Should Not Be Visible  xpath://div[contains(@class,"jp-OutputArea-output") and @data-mime-type="application/vnd.jupyter.stderr"]  A JupyterLab code cell output returned an error

Get JupyterLab Code Cell Error Text
  ${error_txt} =  Get Text  //div[contains(@class,"jp-OutputArea-output") and @data-mime-type="application/vnd.jupyter.stderr"]
  [Return]

Wait Until JupyterLab Code Cells Is Not Active
  [Documentation]  Waits until the current cell no longer has an active prompt "[*]:". This assumes that there is only one cell currently active and it is the currently selected cell
  [Arguments]  ${timeout}=120seconds
  Wait Until Element Is Not Visible  //div[contains(@class,"jp-Cell-inputArea")]/div[contains(@class,"jp-InputArea-prompt") and (.="[*]:")][1]  ${timeout}

Select Empty JupyterLab Code Cell
  Click Element  //div[contains(@class,"jp-mod-noOutputs jp-Notebook-cell")]

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

Logout JupyterLab
  Open With JupyterLab Menu  File  Log Out
