*** Settings ***
Resource  ../../OCPDashboard/Pods/Pods.robot
Library  JupyterLibrary
Library  jupyter-helper.py
Library  OperatingSystem
Library  Screenshot
Library  String
Library  OpenShiftLibrary
Library  SeleniumLibrary


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
${REPO_URL}             https://github.com/sclorg/nodejs-ex.git
${FILE_NAME}            nodejs-ex

*** Keywords ***
Get JupyterLab Selected Tab Label
  ${tab_label} =  Get Text  ${JL_TABBAR_SELECTED_XPATH}/div[contains(@class,"p-TabBar-tabLabel")]
  RETURN  ${tab_label}

JupyterLab Launcher Tab Is Visible
  Get WebElement  xpath:${JL_TABBAR_CONTENT_XPATH}/li/div[.="Launcher"]

JupyterLab Launcher Tab Is Selected
  Get WebElement  xpath:${JL_TABBAR_SELECTED_XPATH}/div[.="Launcher"]

Open JupyterLab Launcher
  Maybe Select Kernel
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
    Maybe Close Popup
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
  RETURN  ${error_txt}

Run Git Repo And Return Last Cell Error Text
  [Documentation]    It actually clones the git repo, runs it and then returns the error
  [Arguments]    ${REPO_URL}  ${NOTEBOOK_TO_RUN}
  Run Keyword And Ignore Error    Clone Git Repository And Run    ${LINK_OF_GITHUB}    ${PATH_TO_FILE}
  ${output} =    Get JupyterLab Code Cell Error Text
  RETURN    ${output}

Wait Until JupyterLab Code Cell Is Not Active
  [Documentation]  Waits until the current cell no longer has an active prompt "[*]:". This assumes that there is only one cell currently active and it is the currently selected cell
  [Arguments]    ${timeout}=120seconds
  Wait Until Element Is Not Visible
  ...    //div[contains(@class,"jp-Cell-inputArea")]/div[contains(@class,"jp-InputArea-prompt") and (.="[*]:")][1]
  ...    ${timeout}

Select Empty JupyterLab Code Cell
  Click Element  //div[contains(@class,"jp-mod-noOutputs jp-Notebook-cell")]

Start JupyterLab Notebook Server
  Open JupyterHub Control Panel
  Click Link  start

Open JupyterLab Control Panel
  Open With JupyterLab Menu  File  Hub Control Panel
  Switch Window    NEW

Stop JupyterLab Notebook Server
  Open JupyterLab Control Panel
  Handle Control Panel

Logout JupyterLab
  Open With JupyterLab Menu  File  Log Out

Run Cell And Check For Errors
    [Arguments]    ${input}    ${timeout}=120seconds
    Add And Run JupyterLab Code Cell In Active Notebook    ${input}
    Wait Until JupyterLab Code Cell Is Not Active    ${timeout}
    ${output} =    Get Text    (//div[contains(@class,"jp-OutputArea-output")])[last()]
    Should Not Match    ${output}    *ERROR*    ignore_case=${TRUE}

Run Cell And Check Output
    [Arguments]  ${input}  ${expected_output}
    Add And Run JupyterLab Code Cell In Active Notebook  ${input}
    Wait Until JupyterLab Code Cell Is Not Active
    ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
    Should Match  ${output}  ${expected_output}
    RETURN    ${output}

Run Cell And Get Output
    [Documentation]    Runs a code cell and returns its output
    [Arguments]    ${input}
    Add And Run JupyterLab Code Cell In Active Notebook  ${input}
    Wait Until JupyterLab Code Cell Is Not Active
    ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
    RETURN    ${output}

Python Version Check
  [Arguments]  ${expected_version}=3.8
  Add And Run JupyterLab Code Cell In Active Notebook  !python --version
  Wait Until JupyterLab Code Cell Is Not Active
  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  #start is inclusive, end exclusive, get x.y from Python x.y.z string
  ${output} =  Fetch From Right  ${output}  ${SPACE}
  ${vers} =  Get Substring  ${output}  0  3
  ${status} =  Run Keyword And Return Status  Should Match  ${vers}  ${expected_version}
  IF  '${status}' == 'FAIL'  Run Keyword And Continue On Failure  FAIL  "Expected Python at version ${expected_version}, but found at v ${vers}"


Maybe Select Kernel
  ${is_kernel_selected} =  Run Keyword And Return Status  Page Should Not Contain Element  xpath=//div[@class="jp-Dialog-buttonLabel"][.="Select"]
  IF  not ${is_kernel_selected}  Click Button  xpath=//div[@class="jp-Dialog-buttonLabel"][.="Select"]/..

Clean Up Server
    [Documentation]    Cleans up user server and checks that everything has been removed
    [Arguments]    ${username}=${TEST_USER.USERNAME}    ${admin_username}=${OCP_ADMIN_USER.USERNAME}
    Maybe Close Popup
    Navigate Home (Root folder) In JupyterLab Sidebar File Browser
    Run Keyword And Continue On Failure    Open With JupyterLab Menu    File    Close All Tabs
    Maybe Close Popup
    Clean Up User Notebook    ${admin_username}    ${username}
    Sleep  5s
    Maybe Close Popup
    Wait Until User Server Is Clean
    Maybe Close Popup
    ${notebook_pod_name} =   Get User Notebook Pod Name  ${username}
    ${container_name_nb} =  Get Substring  ${notebook_pod_name}  start=0  end=-2
    ${ls_server} =  Run Command In Container    ${NOTEBOOKS_NAMESPACE}    ${notebook_pod_name}    ls    ${container_name_nb}
    #${ls_server} =  Run Command In Container    ${APPLICATIONS_NAMESPACE}    ${notebook_pod_name}    ls    ${container_name_nb}
    Should Match    "${ls_server}"    "${EMPTY}"

Get User Notebook Pod Name
  [Documentation]   Returns notebook pod name for given username  (e.g. for user ldap-admin1 it will be jupyterhub-nb-ldap-2dadmin1)
  [Arguments]  ${username}
  ${safe_username}=  Get Safe Username    ${username}
  #${notebook_pod_name}=   Set Variable  jupyterhub-nb-${safe_username}
  ${notebook_pod_name}=   Set Variable  jupyter-nb-${safe_username}-0
  RETURN  ${notebook_pod_name}

Get User CR Notebook Name
    [Documentation]   Returns notebook CR name for given username  (e.g. for user ldap-admin1 it will be jupyter-nb-ldap-2dadmin1)
    [Arguments]  ${username}
    ${safe_username}=  Get Safe Username    ${username}
    ${notebook_cr_name}=   Set Variable  jupyter-nb-${safe_username}
    RETURN  ${notebook_cr_name}

Get User Notebook Pod UID
    [Documentation]   Returns notebook pod UID for given username and ${namespace}  (e.g. for user ldap-admin1 it will be jupyter-nb-ldap-2dadmin1)
    [Arguments]  ${username}    ${namespace}
    ${notebook_pod_name}=    Get User Notebook Pod Name    ${username}
    ${pod_info}=    Oc Get    kind=Pod  name=${notebook_pod_name}  api_version=v1  namespace=${namespace}
    ${notebook_pod_uid}=    Set Variable    ${pod_info[0]['metadata']['uid']}
    RETURN  ${notebook_pod_uid}

Wait Until User Server Is Clean
    [Documentation]    Waits until the JL UI does not show any items (folders/files) in the user's server
    [Arguments]    ${timeout}=30s
    Wait Until Page Does Not Contain Element    xpath://li[contains(concat(' ',normalize-space(@class),' '),' jp-DirListing-item ')]    ${timeout}

Clean Up User Notebook
  [Documentation]  Delete all files and folders in the ${username}'s notebook PVC (excluding hidden files and folders).
...   Note: this command requires ${admin_username}  to be logged to the cluster (oc login ...) and to have the user's notebook pod running (e.g. jupyterhub-nb-ldap-2duser1)
  [Arguments]  ${admin_username}  ${username}

  # Verify that ${admin_username}  is connected to the cluster
  ${oc_whoami} =  Run   oc whoami
  IF    '${oc_whoami}' == '${admin_username}' or '${oc_whoami}' == '${SERVICE_ACCOUNT.FULL_NAME}'
      # Verify that the jupyter notebook pod is running
      ${notebook_pod_name} =   Get User Notebook Pod Name  ${username}
      OpenShiftLibrary.Search Pods    ${notebook_pod_name}  namespace=${NOTEBOOKS_NAMESPACE}

      # Delete all files and folders in /opt/app-root/src/  (excluding hidden files/folders)
      # Note: rm -fr /opt/app-root/src/ or rm -fr /opt/app-root/src/* didn't work properly so we ended up using find
      ${output} =  Run   oc exec ${notebook_pod_name} -n ${NOTEBOOKS_NAMESPACE} -- find /opt/app-root/src/ -not -path '*/\.*' -not -path '/opt/app-root/src/' -exec rm -rv {} +
      Log  ${output}
  ELSE
      Fail  msg=This command requires ${admin_username} to be connected to the cluster (oc login ...)
  END

Delete Folder In User Notebook
  [Documentation]  Delete recursively the folder  /opt/app-root/src/${folder} in ${username}'s notebook PVC.
...   Note: this command requires ${admin_username}  to be logged to the cluster (oc login ...) and to have the user's notebook pod running (e.g. jupyterhub-nb-ldap-2duser1)
  [Arguments]  ${admin_username}  ${username}  ${folder}

  # Verify that ${admin_username}  is connected to the cluster
  ${oc_whoami} =  Run   oc whoami
  IF    '${oc_whoami}' == '${admin_username}' or '${oc_whoami}' == '${SERVICE_ACCOUNT.FULL_NAME}'
      # Verify that the jupyter notebook pod is running
      ${notebook_pod_name} =   Get User Notebook Pod Name  ${username}
      OpenShiftLibrary.Search Pods    ${notebook_pod_name}  namespace=${NOTEBOOKS_NAMESPACE}

      ${output} =  Run   oc exec ${notebook_pod_name} -n ${NOTEBOOKS_NAMESPACE} -- rm -fr /opt/app-root/src/${folder}
      Log  ${output}
  ELSE
      Fail  msg=This command requires ${admin_username} to be connected to the cluster (oc login ...)
  END

JupyterLab Is Visible
  ${jupyterlab_visible} =  Run Keyword and Return Status  Wait Until Element Is Visible  xpath:${JL_TABBAR_CONTENT_XPATH}  timeout=30
  RETURN  ${jupyterlab_visible}

Wait Until JupyterLab Is Loaded
  [Arguments]   ${timeout}=60
  Wait Until Element Is Visible  xpath:${JL_TABBAR_CONTENT_XPATH}  timeout=${timeout}

Clone Git Repository
  [Documentation]    Clones git repository and logs error message if fails to clone
  [Arguments]  ${REPO_URL}
  ${status}    ${err_msg} =    Run Keyword and Ignore Error    Clone Repo and Return Error Message    ${REPO_URL}
    IF    "${status}" == "PASS"
        ${dir_name} =    Get Directory Name From Git Repo URL    ${REPO_URL}
        ${current_user} =    Get Current User In JupyterLab
        Delete Folder In User Notebook
        ...    admin_username=${OCP_ADMIN_USER.USERNAME}
        ...    username=${current_user}
        ...    folder=${dir_name}
        ${status}    ${err_msg} =    Run Keyword and Ignore Error    Clone Repo and Return Error Message    ${REPO_URL}
        IF    "${status}" == "PASS"
            Log    Error Message : ${err_msg}
            FAIL
        END
    ELSE
        Run Keyword And Warn On Failure    Wait Until Page Contains    Successfully cloned    timeout=60s
    END

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

Verify File Present In The File Explorer
  [Documentation]   It checks if the file presnt in the file explorer on sidebar of jupyterlab.
  [Arguments]       ${filename}
  Wait Until Page Contains Element      //div[contains(@class,"jp-FileBrowser-listing")]/ul/li[contains(@title,"Name: ${filename}")]    10

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
    [Arguments]    ${REPO_URL}    ${NB_NAME}
    [Documentation]    Clones a given repository and runs a given file. Cleans up
    ...    The server after execution is over, removing the cloned repository.
    Navigate Home (Root folder) In JupyterLab Sidebar File Browser
    Run Keyword And Warn On Failure    Clone Git Repository And Run    ${REPO_URL}    ${NB_NAME}
    Clean Up Server

Maybe Close Popup
    [Documentation]    Click the last button in a JupyterLab dialog (if one is open).
    ### TODO ###
    # Check if the last button is always the confirmation one
    # Server unavailable or unreachable modal has "Dismiss" as last button

    # When first loading the JL interface, the popup might take some time to appear (1/2s)
    # Given the speed up in PR #559 this has become a problem for this keyword, with some popups
    # slipping through. Let's add a small sleep here to try and catch all popups.
    Sleep  0.5s

    # Sometimes there are multiple tabs already open when loggin into the server and each one might
    # Open a pop-up. Closing all tabs at once also might create a pop-up for each tab. Let's get the
    # Number of open tabs and try closing popups for each one.
    ${jl_tabs} =  Get WebElements  xpath:${JL_TABBAR_NOT_SELECTED_XPATH}
    ${len} =  Get Length  ${jl_tabs}
    FOR  ${index}  IN RANGE  0  2+${len}
      # Check if a popup exists
      ${accept} =    Get WebElements    xpath://div[contains(concat(' ',normalize-space(@class),' '),' jp-Dialog-footer ')]
      # Click the right most button of the popup
      IF    ${accept}    Click Element    xpath://div[contains(concat(' ',normalize-space(@class),' '),' jp-Dialog-footer ')]/button[last()]
      Capture Page Screenshot
    END

Add And Run JupyterLab Code Cell In Active Notebook    # robocop:disable
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

Wait Until JupyterLab Code Cell Is Not Active In a Given Tab
  [Documentation]  Waits until the current cell no longer has an active prompt "[*]:".
  ...              This assumes that there is only one cell currently active and it is the currently selected cell
  ...              It works when there are multiple notebook tabs opened
  [Arguments]  ${tab_id_to_wait}  ${timeout}=120seconds
  Wait Until Element Is Not Visible  //div[@aria-labelledby="${tab_id_to_wait}"]/div[@aria-label="notebook content"]/div[1]/div[contains(@class, p-Cell-inputWrapper)]/div[contains(@class,"jp-Cell-inputArea")]/div[contains(@class,"jp-InputArea-prompt") and (.="[*]:")][1]   ${timeout}

Get Selected Tab ID
  ${active-nb-tab} =    Get WebElement    xpath:${JL_TABBAR_SELECTED_XPATH}
  ${tab-id} =    Get Element Attribute    ${active-nb-tab}    id
  RETURN  ${tab-id}

Get JupyterLab Code Output In a Given Tab
   [Arguments]  ${tab_id_to_read}
   ${outputtext}=  Get Text  (//div[@aria-labelledby="${tab_id_to_read}"]/div[@aria-label="notebook content"]/div[1]/div[contains(@class, jp-Cell-outputWrapper)]/div[contains(@class,"jp-Cell-outputArea")]//div[contains(@class,"jp-RenderedText")])[last()]
   RETURN  ${outputtext}

Select ${filename} Tab
  Click Element    xpath:${JL_TABBAR_CONTENT_XPATH}/li/div[.="${filename}"]

Verify Installed Library Version
    [Arguments]  ${lib}  ${ver}
    ${status}  ${value} =  Run Keyword And Warn On Failure  Run Cell And Check Output  !pip show ${lib} | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s", b[1], b[2]}'  ${ver}
    IF  '${status}' == 'FAIL'  Run Keyword And Continue On Failure  FAIL  "Expected ${lib} at version ${ver}, but ${value}"
    RETURN    ${status}    ${value}

Check Versions In JupyterLab
    [Arguments]  ${libraries-to-check}
    ${return_status} =    Set Variable    PASS
    @{packages} =    Create List    Python    Boto3    Kafka-Python    Matplotlib    Scikit-learn    Pandas    Scipy    Numpy
    FOR  ${libString}  IN  @{libraries-to-check}
        # libString = LibName vX.Y -> libDetail= [libName, X.Y]
        @{libDetail} =  Split String  ${libString}  ${SPACE}v
        IF  "${libDetail}[0]" == "TensorFlow"
            ${status}  ${value} =  Verify Installed Library Version  tensorflow  ${libDetail}[1]
            IF  '${status}' == 'FAIL'
              ${return_status} =    Set Variable    FAIL
            END
        ELSE IF  "${libDetail}[0]" == "PyTorch"
            ${status}  ${value} =  Verify Installed Library Version  torch  ${libDetail}[1]
            IF  '${status}' == 'FAIL'
              ${return_status} =    Set Variable    FAIL
            END
        ELSE IF  "${libDetail}[0]" == "Python"
            ${status} =  Python Version Check  ${libDetail}[1]
        # CUDA version is checked in GPU-specific test cases, we can skip it here.
        ELSE IF  "${libDetail}[0]" == "CUDA"
            CONTINUE
        ELSE
            ${status}  ${value} =  Verify Installed Library Version  ${libDetail}[0]  ${libDetail}[1]
            IF  '${status}' == 'FAIL'
              ${return_status} =    Set Variable    FAIL
            END
        END
        Continue For Loop If  "${libDetail}[0]" not in ${packages}
        IF    "${libDetail}[0]" not in ${package_versions}
        ...    Set To Dictionary    ${package_versions}    ${libDetail}[0]=${libDetail}[1]
        IF    "${package_versions["${libDetail}[0]"]}" != "${libDetail}[1]"
             ${return_status} =    Set Variable    FAIL
             Run Keyword And Continue On Failure  FAIL  "${package_versions["${libDetail}[0]"]} != ${libDetail}[1]"
        END
    END
    RETURN  ${return_status}

Install And Import Package In JupyterLab
    [Documentation]  Install any Package and import it
    [Arguments]  ${package}
    Add And Run JupyterLab Code Cell In Active Notebook  !pip install ${package}
    Add And Run JupyterLab Code Cell In Active Notebook  import ${package}
    Wait Until JupyterLab Code Cell Is Not Active
    JupyterLab Code Cell Error Output Should Not Be Visible
    Capture Page Screenshot

Verify Package Is Not Installed In JupyterLab
    [Documentation]  Check Package is not Installed
    [Arguments]  ${package_name}
    Add And Run JupyterLab Code Cell In Active Notebook  import ${package_name}
    Wait Until JupyterLab Code Cell Is Not Active
    ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
    ${output}   Split String     ${output}   \n\n
    Should Match  ${output[-1]}   ModuleNotFoundError: No module named '${package_name}'

Get User Notebook PVC Name
    [Documentation]   Returns notebook pod name for given username
    ...    (e.g. for user ldap-admin10 it will be jupyterhub-nb-ldap-2dadmin10-pvc)
    [Arguments]  ${username}
    ${safe_username} =   Get Safe Username    ${username}
    ${notebook_pod_name} =   Set Variable  jupyterhub-nb-${safe_username}-pvc
    RETURN    ${notebook_pod_name}

Open New Notebook
    [Documentation]    Opens one new jupyter notebook
    Open With JupyterLab Menu    File    New    Notebook
    Sleep    1
    Maybe Close Popup

Clone Repo
    [Documentation]    It is a private keyword used by other keyword to clone the git repo
    [Tags]    Private Keyword
    [Arguments]    ${repo_url}
    Navigate Home (Root folder) In JupyterLab Sidebar File Browser
    Open With JupyterLab Menu    Git    Clone a Repository
    Input Text    //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input    ${repo_url}
    # new/old git extensions versions have a different capitalization of "clone" (Clone v. CLONE). Use a translate
    # hack in the xpath to match in a case-insensitive way.
    Click Element    xpath://button/div[translate(text(),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz') = 'clone']


Clone Repo and Return Error Message
    [Documentation]    Clones the github repository and returns the error
    [Tags]    Private Keyword
    [Arguments]    ${repo_url}
    Clone Repo    ${repo_url}
    Run Keyword And Warn On Failure    Wait Until Page Contains    Cloning...    timeout=5s
    ${err_msg} =    Get Git Clone Error Message
    RETURN    ${err_msg}

Get Directory Name From Git Repo URL
    [Documentation]    Returns directory name from repo link
    [Arguments]    ${repo_url}
    @{ans} =    Split Path    ${repo_url}
    ${ans} =    Remove String    ${ans}[1]    .git
    RETURN    ${ans}

Get Git Clone Error Message
    [Documentation]    Returns expected error after a git clone operation. Fails if error didn't occur
    ${err_msg} =    Set Variable    No error
    Wait Until Page Contains    Failed to clone    timeout=3s
    Click Button    //div[@class="MuiSnackbar-root MuiSnackbar-anchorOriginBottomRight"]/div/div/button    #click show
    ${err_msg} =    Get Text    //div/div/span[@class="lm-Widget p-Widget jp-Dialog-body"]    #get error text
    #dismiss button
    Click Button
    ...    //div/div/button[@class="jp-Dialog-button jp-mod-accept jp-mod-warn jp-mod-styled"]
    RETURN    ${err_msg}

Verify Git Plugin
    [Documentation]     Checks if it can successfully clone a repository.
    Clone Git Repository      ${REPO_URL}
    Verify File Present In The File Explorer      ${FILE_NAME}

Get Current User In JupyterLab
   [Documentation]    Returns the current user while in the JupyterLab environment
   ${current_user_escaped} =  Run Cell And Get Output
   ...    import os; s=os.environ["HOSTNAME"]; username = s.split("-")[2:-1]; print("-".join(username))
   ${current_user} =  Get Unsafe Username  ${current_user_escaped}
   RETURN  ${current_user}

Image Should Be Pinned To A Numeric Version
    [Documentation]     Verifies if the Image Tag is (probably) pinned to a specific image version (e.g., 2.5.0-8).
    ...                 Since each image provider could use different versioning format (e.g., x.y.z, 10May2021, etc),
    ...                 the check may not be always reliable. The logic is that if numbers are present in the tag, the image
    ...                 is likely pinned to a specific version rather than a generic tag (e.g., latest). After that it tries to
    ...                 see if the numbers follow usual versioning pattern (raising a Warning in the negative case).
    ${image_spec}=   Run Cell And Get Output  import os; os.environ['JUPYTER_IMAGE']
    ${image_tag}=    Fetch From Right    string=${image_spec}    marker=:
    ${matches}=    Get Regexp Matches	  ${image_tag}    (main|latest|master|dev|prod)
    IF   len(${matches}) == ${0}
        Log    msg=Image Tag "${image_tag}" does not contain "latest", "main" or "master"
    ELSE
        Fail    msg=Image Tag "${image_tag}" refers to generic versions like "latest", "main" or "master"
    END
    ${matches} =	Get Regexp Matches	  ${image_tag}    [0-9]+
    IF   len(${matches}) == ${0}
        Fail    msg=Image Tag "${image_tag}" is not pinned to a specific version
    ELSE
        ${matches} =	Get Regexp Matches	  ${image_tag}    ([0-9]\.[0-9])(.[0-9]|-[0-9]|)
        Log    Image Tag "${image_tag}" is (probably) pinned to a specific version
        IF   len(${matches}) == ${0}
           Log  level=WARN  message=Image Tag "${image_tag}" is not in the format x.y.z-n or x.y-n or x.y
        END
    END
