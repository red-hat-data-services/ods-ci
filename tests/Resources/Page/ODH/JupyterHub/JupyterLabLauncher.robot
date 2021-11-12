*** Settings ***
Library  JupyterLibrary
Library  Screenshot
Library  String

*** Variables ***
${JL_TABBAR_CONTENT_XPATH} =  //div[contains(@class,"lm-DockPanel-tabBar")]/ul[@class="lm-TabBar-content p-TabBar-content"]
${JL_TABBAR_SELECTED_XPATH} =  ${JL_TABBAR_CONTENT_XPATH}/li[contains(@class,"lm-mod-current p-mod-current")]
${JL_TABBAR_NOT_SELECTED_XPATH} =  ${JL_TABBAR_CONTENT_XPATH}/li[not(contains(@class,"lm-mod-current p-mod-current"))]
${JLAB CSS ACTIVE DOC}    .jp-Document:not(.jp-mod-hidden)
${JLAB CSS ACTIVE CELL}    ${JLAB CSS ACTIVE DOC} .jp-Cell.jp-mod-active
${JLAB CSS ACTIVE INPUT}    ${JLAB CSS ACTIVE CELL} .CodeMirror
${JLAB XP NB TOOLBAR FRAG}    [contains(@class, 'jp-NotebookPanel-toolbar')]
${JLAB CSS ACTIVE DOC}    .jp-Document:not(.jp-mod-hidden)
${JLAB CSS ACTIVE DOC CELLS}    ${JLAB CSS ACTIVE DOC} .jp-Cell
${JLAB CSS ACTIVE CELL}    ${JLAB CSS ACTIVE DOC} .jp-Cell.jp-mod-active
${JLAB CSS ACTIVE INPUT}    ${JLAB CSS ACTIVE CELL} .CodeMirror

*** Keywords ***
Get JupyterLab Selected Tab Label
  ${tab_label} =  Get Text  ${JL_TABBAR_SELECTED_XPATH}/div[contains(@class,"p-TabBar-tabLabel")]
  [return]  ${tab_label}

JupyterLab Launcher Tab Is Visible
  Get WebElement  xpath:${JL_TABBAR_CONTENT_XPATH}/li/div[.="Launcher"]

JupyterLab Launcher Tab Is Selected
  Get WebElement  xpath:${JL_TABBAR_SELECTED_XPATH}/div[.="Launcher"]

Open JupyterLab Launcher
  Open With JupyterLab Menu  File  New Launcher
  JupyterLab Launcher Tab Is Visible
  JupyterLab Launcher Tab Is Selected

Wait Until ${filename} JupyterLab Tab Is Selected
  Wait Until Page Contains Element  xpath:${JL_TABBAR_SELECTED_XPATH}/div[.="${filename}"]

Close Other JupyterLab Tabs
  ${original_tab} =  Get WebElement  xpath:${JL_TABBAR_SELECTED_XPATH}/div[contains(@class, "p-TabBar-tabLabel")]
  #${original_tab} =  Get WebElement  xpath:${JL_TABBAR_SELECTED_XPATH}/div[contains(concat(' ',normalize-space(@class),' '),' p-TabBar-tabLabel ')]

  ${xpath_background_tab} =  Set Variable  xpath:${JL_TABBAR_NOT_SELECTED_XPATH}
  ${jl_tabs} =  Get WebElements  ${xpath_background_tab}

  FOR  ${tab}  IN  @{jl_tabs}
    #Select the tab we want to close
    Click Element  ${tab}
    #Click the close tab icon
    Open With JupyterLab Menu  File  Close Tab
    Sleep  2
    Maybe Close Popup
  END
  Sleep  2
  Maybe Close Popup
  Element Should Be Visible  ${original_tab}
  Element Should Not Be Visible  ${xpath_background_tab}

Close JupyterLab Selected Tab
  Click Element  xpath:${JL_TABBAR_SELECTED_XPATH}/div[contains(@class,"lm-TabBar-tabCloseIcon")]
  Maybe Close Popup

JupyterLab Code Cell Error Output Should Not Be Visible
  Element Should Not Be Visible  xpath://div[contains(@class,"jp-OutputArea-output") and @data-mime-type="application/vnd.jupyter.stderr"]  A JupyterLab code cell output returned an error

Get JupyterLab Code Cell Error Text
  ${error_txt} =  Get Text  //div[contains(@class,"jp-OutputArea-output") and @data-mime-type="application/vnd.jupyter.stderr"]
  [Return]

Wait Until JupyterLab Code Cell Is Not Active
  [Documentation]  Waits until the current cell no longer has an active prompt "[*]:". This assumes that there is only one cell currently active and it is the currently selected cell
  [Arguments]  ${timeout}=120seconds
  Wait Until Element Is Not Visible  //div[contains(@class,"jp-Cell-inputArea")]/div[contains(@class,"jp-InputArea-prompt") and (.="[*]:")][1]  ${timeout}

Select Empty JupyterLab Code Cell
  Click Element  //div[contains(@class,"jp-mod-noOutputs jp-Notebook-cell")]

Start JupyterLab Notebook Server
  Open JupyterHub Control Panel
  Click Link  start

Open JupyterLab Control Panel
  Open With JupyterLab Menu  File  Hub Control Panel
  Switch Window  JupyterHub

Stop JupyterLab Notebook Server
  Open JupyterLab Control Panel
  Run Keyword And Ignore Error   Wait Until Page Contains  Stop My Server   timeout=30
  # This is a dumb sleep to give the Stop button in the WebUI time to actually work when clicked
  # TODO: Determine if there is any web element attribute that will allow signify when the Stop button will actually work
  Sleep  2 seconds
  Capture Page Screenshot
  ${stop_enabled} =  Run Keyword And Return Status  Page Should Contain Element    //*[@id="stop"]
  IF    ${stop_enabled} == True
    Click Element  //*[@id="stop"]
    Wait Until Element Is Not Visible   //*[@id="stop"]  3 minute
    Wait Until Page Contains  Start My Server  timeout=120
    Capture Page Screenshot
  END


Logout JupyterLab
  Open With JupyterLab Menu  File  Log Out

Run Cell And Check For Errors
  [Arguments]  ${input}
  Add and Run JupyterLab Code Cell in Active Notebook  ${input}
  Wait Until JupyterLab Code Cell Is Not Active
  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*

Run Cell And Check Output
  [Arguments]  ${input}  ${expected_output}
  Add and Run JupyterLab Code Cell in Active Notebook  ${input}
  Wait Until JupyterLab Code Cell Is Not Active
  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Match  ${output}  ${expected_output}

Maybe Select Kernel
  ${is_kernel_selected} =  Run Keyword And Return Status  Page Should Not Contain Element  xpath=//div[@class="jp-Dialog-buttonLabel"][.="Select"]
  Run Keyword If  not ${is_kernel_selected}  Click Button  xpath=//div[@class="jp-Dialog-buttonLabel"][.="Select"]/..

Clean Up Server
  Sleep  1
  Maybe Close Popup
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  File  Close All Tabs
  Maybe Close Popup
  Sleep  1
  Maybe Close Popup
  Open With JupyterLab Menu  File  New  Notebook
  Sleep  1
  Maybe Close Popup
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  Untitled.ipynb
  Click Element  xpath://div[.="Open"]
  Maybe Close Popup
  Wait Until Untitled.ipynb JupyterLab Tab Is Selected
  Add and Run JupyterLab Code Cell in Active Notebook  !rm -rf *

JupyterLab Is Visible
  ${jupyterlab_visible} =  Run Keyword and Return Status  Wait Until Element Is Visible  xpath:${JL_TABBAR_CONTENT_XPATH}  timeout=30
  [return]  ${jupyterlab_visible}

Wait Until JupyterLab Is Loaded
  [Arguments]   ${timeout}=60
  Wait Until Element Is Visible  xpath:${JL_TABBAR_CONTENT_XPATH}  timeout=${timeout}

Clone Git Repository
  [Arguments]  ${REPO_URL}
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  Git  Clone a Repository
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  ${REPO_URL}
  Click Element  xpath://div[.="CLONE"]

Clone Git Repository And Open
  [Documentation]  The ${NOTEBOOK_TO_RUN} argument should be of the form /path/relative/to/jlab/root.ipynb
  [Arguments]  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
  Clone Git Repository  ${REPO_URL}
  Sleep  15
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  ${NOTEBOOK_TO_RUN}
  Click Element  xpath://div[.="Open"]

Clone Git Repository And Run
  [Documentation]  The ${NOTEBOOK_TO_RUN} argument should be of the form /path/relative/to/jlab/root.ipynb
  [Arguments]  ${REPO_URL}  ${NOTEBOOK_TO_RUN}  ${timeout}=1200
  Clone Git Repository And Open  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
  #${FILE} =  ${{${NOTEBOOK_TO_RUN}.split("/")[-1] if ${NOTEBOOK_TO_RUN}[-1]!="/" else ${NOTEBOOK_TO_RUN}.split("/")[-2]}}
  Wait Until ${{"${NOTEBOOK_TO_RUN}".split("/")[-1] if "${NOTEBOOK_TO_RUN}"[-1]!="/" else "${NOTEBOOK_TO_RUN}".split("/")[-2]}} JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs
  Open With JupyterLab Menu  Run  Run All Cells
  Wait Until JupyterLab Code Cell Is Not Active  timeout=${timeout}
  Sleep  1
  JupyterLab Code Cell Error Output Should Not Be Visible

Handle Kernel Restarts
  #This section has to be slightly reworked still. Sometimes the pop-up is not in div[8] but in div[7]

  ${kernel_or_server_restarting} =  Run Keyword And Return Status  Page Should Not Contain Element  xpath:/html/body/div[8]/div/div[2]
  IF  ${kernel_or_server_restarting} == False
    ${is_server_down} =  Run Keyword And Return Status  Page Should Not Contain Element  xpath:/html/body/div[8]/div/div[2]/button[2]
    IF  ${is_server_down} == False
        Click Button  xpath:/html/body/div[8]/div/div[2]/button[2]
    ELSE
        Click Button  xpath:/html/body/div[8]/div/div[2]/button
    END
  END

Run Repo and Clean
  [Arguments]  ${REPO_URL}  ${NB_NAME}
  Click Element  xpath://span[@title="/opt/app-root/src"]
  Run Keyword And Continue On Failure  Clone Git Repository And Run  ${REPO_URL}  ${NB_NAME}
  Sleep  15
  Click Element  xpath://span[@title="/opt/app-root/src"]
  Open With JupyterLab Menu  File  Close All Tabs
  Maybe Close Popup
  Open With JupyterLab Menu  File  New  Notebook
  Sleep  1
  Maybe Close Popup
  Sleep  1
  Add and Run JupyterLab Code Cell in Active Notebook  !rm -rf *
  Wait Until JupyterLab Code Cell Is Not Active
  Open With JupyterLab Menu  File  Close All Tabs
  Maybe Close Popup

Maybe Close Popup
    [Documentation]    Click the last button in a JupyterLab dialog (if one is open).
    ### TODO ###
    # Check if the last button is always the confirmation one
    # Server unavailable or unreachable modal has "Dismiss" as last button

    # Sometimes there are multiple tabs already open when loggin into the server and each one might
    # Open a pop-up. Closing all tabs at once also might create a pop-up for each tab. Let's get the
    # Number of open tabs and try closing popups for each one.
    ${jl_tabs} =  Get WebElements  xpath:${JL_TABBAR_NOT_SELECTED_XPATH}
    ${len} =  Get Length  ${jl_tabs}
    FOR  ${index}  IN RANGE  0  2+${len}
      # Check if a popup exists
      ${accept} =    Get WebElements    xpath://div[contains(concat(' ',normalize-space(@class),' '),' jp-Dialog-footer ')]
      # Click the right most button of the popup
      Run Keyword If    ${accept}    Click Element    xpath://div[contains(concat(' ',normalize-space(@class),' '),' jp-Dialog-footer ')]/button[last()]
      Capture Page Screenshot
    END

Add and Run JupyterLab Code Cell in Active Notebook
    [Arguments]    @{code}    ${n}=1
    [Documentation]    Add a ``code`` cell to the ``n`` th notebook on the page and run it.
    ...    ``code`` is a list of strings to set as lines in the code editor.
    ...    ``n`` is the 1-based index of the notebook, usually in order of opening.
    ${add icon} =    Get JupyterLab Icon XPath    add

    ${nb} =    Get WebElement    xpath://div${JLAB XP NB FRAG}\[${n}]
    ${nbid} =    Get Element Attribute    ${nb}    id

    ${active-nb-tab} =    Get WebElement    xpath:${JL_TABBAR_SELECTED_XPATH}
    ${tab-id} =    Get Element Attribute    ${active-nb-tab}    id
    
    Click Element    xpath://div[@aria-labelledby="${tab-id}"]/div[1]//${add icon}
    Sleep    0.1s
    Click Element    xpath://div[@aria-labelledby="${tab-id}"]//div[contains(concat(' ',normalize-space(@class),' '),' jp-mod-selected ')]
    Set CodeMirror Value    \#${nbid}${JLAB CSS ACTIVE INPUT}    @{code}
    Run Current JupyterLab Code Cell MOD  ${tab-id}
    Click Element    xpath://div[@aria-labelledby="${tab-id}"]//div[contains(concat(' ',normalize-space(@class),' '),' jp-mod-selected ')]

Run Current JupyterLab Code Cell MOD
    [Arguments]  ${tab-id}
    [Documentation]    Run the currently-selected cell(s) in the ``n`` th notebook.
    ...    ``n`` is the 1-based index of the notebook, usually in order of opening.
    ${run icon} =    Get JupyterLab Icon XPath    run
    Click Element    xpath://div[@aria-labelledby="${tab-id}"]/div[1]//${run icon}
    Sleep    0.5s
