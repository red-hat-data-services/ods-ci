*** Settings ***
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
   Click Element  xpath://input[contains(@id, "${notebook_image}")]
   #${notebook_webelement} =  Get WebElement  xpath://a[contains(@id,"${notebook_image}")]
   #Wait Until Element Is Visible  ${notebook_webelement}
   #Click Element  ${notebook_webelement}
   #${selected_notebook} =  Get Text  id:ImageDropdownBtn
   #Should Start With  ${selected_notebook}  ${notebook_image}

Select Container Size
   [Documentation]  Selects the container size based on the ${container_size} argument
   [Arguments]  ${container_size}
   # Expand List
   Click Element  xpath:/html/body/div[1]/form/div/div/div[3]/div[3]/button
   Click Element  xpath://span[.="${container_size}"]/../..
   #Click Element  id:SizeDropdownBtn
   #Wait Until Element Is Visible  id:${container_size}
   #Click Element  id:${container_size}
   #${selected_size} =  Get Text  id:SizeDropdownBtn
   #Should Start With  ${selected_size}  ${container_size}

Set Number of required GPUs
   [Documentation]  Sets the gpu count based on the ${gpus} argument
   [Arguments]  ${gpus}
   # Expand list
   Click Element  xpath:/html/body/div[1]/form/div/div/div[3]/div[5]/button
   Click Element  xpath://li[.="${gpus}"]
   #Input Text  id:gpu-form  ${gpus}
   #Textfield Value Should Be  id:gpu-form  ${gpus}

Add Spawner Environment Variable
   [Documentation]  Adds a new environment variables based on the ${env_var} ${env_var_value} arguments
   [Arguments]  ${env_var}  ${env_var_value}
   Click Button  Add more variables
   Input Text  xpath://input[@id="---NO KEY---"]  ${env_var}
   Element Attribute Value Should Be  xpath://input[@id="${env_var}"]  value  ${env_var}
   Input Text  xpath://input[@id="${env_var}-value"]  ${env_var_value}
   Element Attribute Value Should Be  xpath://input[@id="${env_var}-value"]  value  ${env_var_value}
   #Click Button  Add
   #Input Text  id:KeyForm-  ${env_var}
   #Element Attribute Value Should Be  name:${env_var}  value  ${env_var}
   #Input Text  id:ValueForm-${env_var}  ${env_var_value}
   #Element Attribute Value Should Be  id:ValueForm-${env_var}  value  ${env_var_value}

Remove Spawner Environment Variable
   [Documentation]  Removes an existing environment variable based on the ${env_var} argument
   [Arguments]  ${env_var}
   Click Element  xpath://input[@id="${env_var}"]/../../../../button

Spawner Environment Variable Exists
   [Documentation]  Removes an existing environment variable based on the ${env_var} argument
   [Arguments]  ${env_var}
   Element Should Be Visible  name:${env_var}

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
