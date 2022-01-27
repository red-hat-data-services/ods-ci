*** Settings ***
Resource  JupyterLabLauncher.robot
Resource  ../../LoginPage.robot
Resource  ../../ODH/ODHDashboard/ODHDashboard.robot
Resource  LoginJupyterHub.robot
Resource  JupyterLabSidebar.robot
Resource  ../../OCPDashboard/InstalledOperators/InstalledOperators.robot
Library   JupyterLibrary
Library   String
Library   Collections

*** Variables ***
${JUPYTERHUB_SPAWNER_HEADER_XPATH} =  //div[contains(@class,"jsp-spawner__header__title") and .="Start a notebook server"]

*** Keywords ***
JupyterHub Spawner Is Visible
   ${spawner_visible} =  Run Keyword and Return Status  Page Should Contain  xpath:${JUPYTERHUB_SPAWNER_HEADER_XPATH}
   [return]  ${spawner_visible}

Wait Until JupyterHub Spawner Is Ready
   # Container size selector is usually the last element to load in the spawner page
   # Let's use it to check when the spawner has finished loading.
   ${version-check} =  Is RHODS Version Greater Or Equal Than  1.5.0
   IF  ${version-check}==True
      Wait Until Page Contains Element    xpath://div[contains(concat(' ',normalize-space(@class),' '),' jsp-spawner__size_options__select ')]
   ELSE
      Wait Until Page Contains Element    xpath:/html/body/div[1]/form/div/div/div[3]/div[3]/button
   END

Select Notebook Image
   [Documentation]  Selects a notebook image based on a partial match of ${notebook_image} argument
   [Arguments]    ${notebook_image}
   ${version-check} =    Is RHODS Version Greater Or Equal Than  1.5.0
   IF    ${version-check}==True
      Wait Until Element Is Visible    xpath://div[@class="jsp-spawner__image-options"]
   ELSE
      Wait Until Element Is Visible    xpath:/html/body/div[1]/form/div/div/div[2]/div[2]/div[1]
   END
   Wait Until Element Is Visible    xpath://input[contains(@id, "${notebook_image}")]
   Element Should Be Enabled    xpath://input[contains(@id, "${notebook_image}")]
   Click Element    xpath://input[contains(@id, "${notebook_image}")]

Select Container Size
   [Documentation]  Selects the container size based on the ${container_size} argument
   [Arguments]  ${container_size}
   # Expand List
   Wait Until Page Contains    Container size   timeout=30   error=Container size selector is not present in JupyterHub Spawner
   ${version-check} =  Is RHODS Version Greater Or Equal Than  1.5.0
   IF  ${version-check}==True
      Click Element  xpath://div[contains(concat(' ',normalize-space(@class),' '),' jsp-spawner__size_options__select ')]
   ELSE
      Click Element  xpath:/html/body/div[1]/form/div/div/div[3]/div[3]/button
   END
   Click Element  xpath://span[.="${container_size}"]/../..

Set Number of required GPUs
   [Documentation]  Sets the gpu count based on the ${gpus} argument
   [Arguments]  ${gpus}
   # Expand list
   Click Element  xpath:/html/body/div[1]/form/div/div/div[3]/div[5]/button
   Click Element  xpath://li[.="${gpus}"]

Add Spawner Environment Variable
   [Documentation]  Adds a new environment variables based on the ${env_var} ${env_var_value} arguments
   [Arguments]  ${env_var}  ${env_var_value}
   Click Button  Add more variables
   Input Text  xpath://input[@id="---NO KEY---"]  ${env_var}
   Element Attribute Value Should Be  xpath://input[@id="${env_var}"]  value  ${env_var}
   Input Text  xpath://input[@id="${env_var}-value"]  ${env_var_value}
   Element Attribute Value Should Be  xpath://input[@id="${env_var}-value"]  value  ${env_var_value}

Remove All Spawner Environment Variables
   [Documentation]  Removes all existing environment variables in the Spawner
   @{env_vars_list}=  Create List
   @{env_elements}=    Get WebElements    xpath://*[.='Variable name']/../../div[2]/input

   # We need to fist get the env values and remove them later to avoid a
   # selenium error due to modifiying the DOM while iterating its contents
   FOR    ${element}    IN    @{env_elements}
       ${txt}=   Get Value  ${element}
       Append To List  ${env_vars_list}   ${txt}
   END

   FOR    ${env}    IN    @{env_vars_list}
       Remove Spawner Environment Variable   ${env}
   END

Remove Spawner Environment Variable
   [Documentation]  If it exists, removes an environment variable based on the ${env_var} argument
   [Arguments]  ${env_var}
   ${env-check} =  Spawner Environment Variable Exists   ${env_var}
   IF  ${env-check}==True
      Click Element  xpath://input[@id="${env_var}"]/../../../../button
   END

Spawner Environment Variable Exists
   [Documentation]  Checks if an environment variable is set based on the ${env_var} argument
   [Arguments]  ${env_var}
   ${var_visible} =  Run Keyword and Return Status  Element Should Be Visible  id:${env_var}
   [return]  ${var_visible}

Get Spawner Environment Variable Value
   [Documentation]  Get the value of an existing environment variable based on the ${env_var} argument
   [Arguments]  ${env_var}
   ${env_var_value} =  Get Value  id:${env_var}
   [Return]  ${env_var_value}

Spawn Notebook
   [Documentation]  Start the notebook pod spawn and wait ${spawner_timeout} seconds (DEFAULT: 600s)
   [Arguments]  ${spawner_timeout}=600 seconds
   ${version-check} =  Is RHODS Version Greater Or Equal Than  1.5.0
   IF  ${version-check}==True
      Click Button  Start Server
      Wait Until Page Contains  Starting server
   ELSE
      Click Button  Start server
      Wait Until Page Contains  Your server is starting up
   END
   Wait Until Element is Visible  id:progress-bar
   Wait Until Page Does Not Contain Element  id:progress-bar  ${spawner_timeout}

Has Spawn Failed
   ${version-check} =  Is RHODS Version Greater Or Equal Than  1.5.0
   IF  ${version-check}==True
      ${spawn_status} =  Run Keyword and Return Status  Page Should Contain  Spawn failed
   ELSE
      ${spawn_status} =  Run Keyword and Return Status  Page Should Contain Element  xpath://p[starts-with(., "Spawn failed")]
   END
   [Return]  ${spawn_status}

Spawn Notebook With Arguments
   [Documentation]  Selects required settings and spawns a notebook pod. If it fails due to timeout or other issue
   ...              It will try again ${retries} times (Default: 1). Environment variables can be passed in as kwargs
   ...              By creating a dictionary beforehand, e.g. &{test-dict}  Create Dictionary  name=robot  password=secret
   [Arguments]  ${retries}=1  ${image}=s2i-generic-data-science-notebook  ${size}=Small  ${spawner_timeout}=600 seconds  &{envs}
   FOR  ${index}  IN RANGE  0  1+${retries}
      ${spawner_ready} =    Run Keyword and Return Status    Wait Until JupyterHub Spawner Is Ready
      IF  ${spawner_ready}==True
         Select Notebook Image  ${image}
         Select Container Size  ${size}
         IF  &{envs}
            Remove All Spawner Environment Variables
            FOR  ${key}  ${value}  IN  &{envs}[envs]
               Sleep  1
               Add Spawner Environment Variable  ${key}  ${value}
            END
         END
         Spawn Notebook
         Run Keyword And Continue On Failure  Wait Until Page Does Not Contain Element  id:progress-bar  ${spawner_timeout}
         Wait for JupyterLab Splash Screen  timeout=30
         Maybe Close Popup
         ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
         Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
         Open With JupyterLab Menu  File  New  Notebook
         Sleep  1
         Maybe Close Popup
         Close Other JupyterLab Tabs
         Maybe Close Popup
         Sleep  1
         Spawned Image Check    ${image}
         ${spawn_fail} =  Has Spawn Failed
         Exit For Loop If  ${spawn_fail} == False
         Click Element  xpath://span[@id='jupyterhub-logo']
      ELSE
         Click Element  xpath://span[@id='jupyterhub-logo']
      END
   END

Spawned Image Check
    [Documentation]    This Keyword checks that the spawned image matches a given image name
    ...                (Presumably the one the user wanted to spawn)
    [Arguments]    ${image}
    Run Cell And Check Output    import os; print(os.environ["JUPYTER_IMAGE"].split("/")[-1].split(":")[0])    ${image}
    Open With JupyterLab Menu    Edit    Select All Cells
    Open With JupyterLab Menu    Edit    Delete Cells

Launch JupyterHub Spawner From Dashboard
  Menu.Navigate To Page    Applications    Enabled
  ${version-check} =  Is RHODS Version Greater Or Equal Than  1.4.0
  IF  ${version-check}==True
    Launch JupyterHub From RHODS Dashboard Link
  ELSE
    Launch JupyterHub From RHODS Dashboard Dropdown
  END
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
  Fix Spawner Status
  Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']


Get Spawner Progress Message
   [Documentation]  Get the progress message currently displayed
   ${msg} =  Get Text  progress-message
   [Return]  ${msg}

Get Spawner Event Log
   [Documentation]  Get the spawner event log messages as a list
   ${event_elements} =  Get WebElements  class:progress-log-event
   [Return] @{event_elements}

Server Not Running Is Visible
   ${SNR_visible} =  Run Keyword and Return Status  Wait Until Page Contains    Server not running  timeout=15
   [return]  ${SNR_visible}

Handle Server Not Running
   Click Element  xpath://a[@id='start']

Start My Server Is Visible
   ${SMS_visible} =  Run Keyword and Return Status  Page Should Contain  Start My Server
   [return]  ${SMS_visible}

Handle Start My Server
   Click Element  xpath://a[@id='start']

Server Is Stopping Is Visible
   ${SIS_visible} =  Run Keyword and Return Status  Page Should Contain  Your server is stopping.
   [return]  ${SIS_visible}

Handle Server Is Stopping
   Sleep  10
   Handle Server Not Running

Fix Spawner Status
   [Documentation]  This keyword handles spawner states that would prevent
   ...              test cases from passing. If a server is already running
   ...              or if we are redirected to an alternative spawner page,
   ...              this keyword will bring us back to the actual spawner.
   ${spawner_visible} =  JupyterHub Spawner Is Visible
   IF  ${spawner_visible}!=True
      ${SNR_visible} =  Server Not Running Is Visible
      ${SMS_visible} =  Start My Server Is Visible
      ${SIS_visible} =  Server Is Stopping Is Visible
      IF  ${SIS_visible}==True
         Handle Server Is Stopping
      ELSE IF  ${SNR_visible}==True
         Handle Server Not Running
      ELSE IF  ${SMS_visible}==True
         Handle Start My Server
      ELSE
         ${JL_visible} =  JupyterLab Is Visible
         IF  ${JL_visible}==True
            Maybe Close Popup
            Navigate Home (Root folder) In JupyterLab Sidebar File Browser
            Open With JupyterLab Menu  File  New  Notebook
            Sleep  1
            Maybe Close Popup
            Close Other JupyterLab Tabs
            Add and Run JupyterLab Code Cell in Active Notebook  !rm -rf *
            Open With JupyterLab Menu  File  Close All Tabs
            Maybe Close Popup
            Stop JupyterLab Notebook Server
            Handle Start My Server
            Maybe Handle Server Not Running Page
         END
      END
   END

User Is Allowed
   JupyterHub Spawner is Visible
   Page Should Not Contain  403 : Forbidden
   ${spawner_ready} =    Run Keyword and Return Status    Wait Until JupyterHub Spawner Is Ready
   IF  ${spawner_ready}==False
      Fail    Spawner page was not ready
   END

User Is Not Allowed
   JupyterHub Spawner is Visible
   Page Should Contain  403 : Forbidden

User Is JupyterHub Admin
   JupyterHub Spawner is Visible
   Page Should Contain  Admin

User Is Not JupyterHub Admin
   JupyterHub Spawner is Visible
   Page Should Not Contain  Admin

Logout Via Button
   Click Element  xpath://a[@id='logout']
   Wait Until Page Contains  Successfully logged out.

Login Via Button
   [Documentation]  This takes you back to the login page
   ...  And you will need to use the `Login To Jupyterhub`
   ...  Keyword.
   Click Element  xpath://a[@id='login']
   Wait Until Page Contains  Log in with

Maybe Handle Server Not Running Page
  ${SNR_visible} =  Server Not Running Is Visible
  IF  ${SNR_visible}==True
         Handle Server Not Running
  END
