*** Settings ***
Resource  JupyterLabLauncher.robot
Library  JupyterLibrary
Library  String

*** Variables ***
${JUPYTERHUB_SPAWNER_HEADER_XPATH} =  //div[contains(@class,"jsp-spawner__header__title") and .="Start a notebook server"]

*** Keywords ***
JupyterHub Spawner Is Visible
   ${spawner_visible} =  Run Keyword and Return Status  Wait Until Element Is Visible  xpath:${JUPYTERHUB_SPAWNER_HEADER_XPATH}
   [return]  ${spawner_visible}

Select Notebook Image
   [Documentation]  Selects a notebook image based on a partial match of ${notebook_image} argument
   [Arguments]  ${notebook_image}
   Wait Until Element Is Visible  xpath:/html/body/div[1]/form/div/div/div[2]/div[2]/div[1]
   Click Element  xpath://input[contains(@id, "${notebook_image}")]

Select Container Size
   [Documentation]  Selects the container size based on the ${container_size} argument
   [Arguments]  ${container_size}
   # Expand List
   Click Element  xpath:/html/body/div[1]/form/div/div/div[3]/div[3]/button
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

Remove Spawner Environment Variable
   [Documentation]  Removes an existing environment variable based on the ${env_var} argument
   [Arguments]  ${env_var}
   Click Element  xpath://input[@id="${env_var}"]/../../../../button

Spawner Environment Variable Exists
   [Documentation]  Removes an existing environment variable based on the ${env_var} argument
   [Arguments]  ${env_var}
   #Element Should Be Visible  name:${env_var}
   ${var_visible} =  Run Keyword and Return Status  Element Should Be Visible  name:${env_var}
   [return]  ${var_visible}

Get Spawner Environment Variable Value
   [Documentation]  Get the value of an existing environment variable based on the ${env_var} argument
   [Arguments]  ${env_var}
   ${env_var_value} =  Get Value  name:${env_var}
   [Return]  ${env_var_value}

Spawn Notebook
   [Documentation]  Start the notebook pod spawn and wait ${spawner_timeout} seconds (DEFAULT: 600s)
   [Arguments]  ${spawner_timeout}=600 seconds
   Click Button  Start server
   Wait Until Page Contains  Your server is starting up
   Wait Until Element is Visible  id:progress-bar
   Wait Until Page Does Not Contain Element  id:progress-bar  ${spawner_timeout}

Get Spawner Progress Message
   [Documentation]  Get the progress message currently displayed
   ${msg} =  Get Text  progress-message
   [Return]  ${msg}

Get Spawner Event Log
   [Documentation]  Get the spawner event log messages as a list
   ${event_elements} =  Get WebElements  class:progress-log-event
   [Return] @{event_elements}

Server Not Running Is Visible
   ${SNR_visible} =  Run Keyword and Return Status  Page Should Contain  Server not running
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
            Click JupyterLab Menu  File
            Capture Page Screenshot
            Click JupyterLab Menu Item  Hub Control Panel
            Switch Window  JupyterHub
            Sleep  5
            Click Element  //*[@id="stop"]
            Wait Until Page Contains  Start My Server  timeout=15
         END
      END
   END
