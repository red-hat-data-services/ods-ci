*** Settings ***
Documentation  Set of Keywords to interact with the JupyterHub Spawner
Resource  JupyterLabLauncher.robot
Resource  ../../LoginPage.robot
Resource  ../../ODH/ODHDashboard/ODHDashboard.robot
Resource  LoginJupyterHub.robot
Resource  JupyterLabSidebar.robot
Resource  ../../OCPDashboard/InstalledOperators/InstalledOperators.robot
Library   ../../../../../libs/Helpers.py
Library   String
Library   Collections
Library   JupyterLibrary
Library   OpenShiftLibrary


*** Variables ***
${KFNBC_SPAWNER_HEADER_XPATH} =    //h1[.="Start a notebook server"]
${JUPYTERHUB_DROPDOWN_XPATH} =    //button[@aria-label="Options menu"]
${KFNBC_CONTAINER_SIZE_TITLE} =    //div[.="Deployment size"]/..//span[.="Container Size"]
${KFNBC_CONTAINER_SIZE_DROPDOWN_XPATH} =  //label[@for="modal-notebook-container-size"]/../..//button[@aria-label="Options menu"]
${KFNBC_ACCELERATOR_HEADER_XPATH} =    //span[text()='Accelerator']
${KFNBC_ACCELERATOR_DROPDOWN_XPATH} =    //label[@for='modal-notebook-accelerator']/ancestor::div[@class='pf-c-form__group']/descendant::button
${KFNBC_ACCELERATOR_INPUT_XPATH} =    //input[@aria-label='Number of accelerators']
${KFNBC_ACCELERATOR_LESS_BUTTON_XPATH} =    ${KFNBC_ACCELERATOR_INPUT_XPATH}/preceding-sibling::button
${KFNBC_ACCELERATOR_PLUS_BUTTON_XPATH} =    ${KFNBC_ACCELERATOR_INPUT_XPATH}/following-sibling::button
${KFNBC_MAX_ACCELERATOR_WARNING_XPATH} =    //div[@aria-label='Warning Alert']//h4[contains(text(), 'accelerator detected')]
${KFNBC_MODAL_HEADER_XPATH} =    //div[@aria-label="Starting server modal"]
${KFNBC_MODAL_CANCEL_XPATH} =    ${KFNBC_MODAL_HEADER_XPATH}//button[.="Cancel"]
${KFNBC_MODAL_CLOSE_XPATH} =    ${KFNBC_MODAL_HEADER_XPATH}//button[.="Close"]
${KFNBC_MODAL_X_XPATH} =    ${KFNBC_MODAL_HEADER_XPATH}//button[@aria-label="Close"]
${KFNBC_CONTROL_PANEL_HEADER_XPATH} =    //h1[.="Notebook server control panel"]
${KFNBC_ENV_VAR_NAME_PRE} =    //span[.="Variable name"]/../../../div[@class="pf-c-form__group-control"]
${DEFAULT_PYTHON_VER} =    3.9
${PREVIOUS_PYTHON_VER} =    3.8


*** Keywords ***
JupyterHub Spawner Is Visible
    [Documentation]  Checks if spawner is visibile and returns the status
    ${spawner_visible} =  Run Keyword And Return Status  Page Should Contain Element
    ...    xpath:${KFNBC_SPAWNER_HEADER_XPATH}
    RETURN  ${spawner_visible}

Wait Until JupyterHub Spawner Is Ready
    [Documentation]  Waits for the spawner page to be ready using the server size dropdown
    Wait Until Page Contains Element    xpath:${KFNBC_CONTAINER_SIZE_TITLE}    timeout=15s
    Wait Until Page Contains Element    xpath:${JUPYTERHUB_DROPDOWN_XPATH}\[1]    timeout=15s

Select Notebook Image
    [Documentation]    Selects a notebook image based on a partial match of ${notebook_image} argument
    ...                ${version} controls if the default or previous version is selected (default | previous)
    [Arguments]    ${notebook_image}    ${version}=default
    ${KFNBC_IMAGE_ROW} =    Set Variable    //input[contains(@id, "${notebook_image}")]
    ${KFNBC_IMAGE_DROPDOWN} =    Set Variable    ${KFNBC_IMAGE_ROW}/../../div[contains(@class, "notebook-image-tags")]
    Wait Until Element Is Visible    xpath://div[.="Notebook image"]/..
    Wait Until Element Is Visible    xpath=${KFNBC_IMAGE_ROW}
    Element Should Be Enabled    xpath=${KFNBC_IMAGE_ROW}
    IF    "${version}"=="default"
        Click Element    xpath=${KFNBC_IMAGE_ROW}
    ELSE IF    "${version}"=="previous"
        Verify Version Dropdown Is Present    ${notebook_image}
        Click Element    xpath=${KFNBC_IMAGE_ROW}/../..//button[.="Versions"]
        Click Element
        ...    xpath=${KFNBC_IMAGE_DROPDOWN}//span[contains(text(), "Python v${PREVIOUS_PYTHON_VER}")]/../input
    ELSE
        Verify Version Dropdown Is Present    ${notebook_image}
        Click Element    xpath=${KFNBC_IMAGE_ROW}/../..//button[.="Versions"]
        Sleep    5s
        ${tag_exists} =    Run Keyword And Return Status    Page Should Contain Element
        ...    xpath=${KFNBC_IMAGE_DROPDOWN}//input[@data-id="${notebook_image}:${version}"]
        IF  ${tag_exists}==True
            Click Element    xpath=${KFNBC_IMAGE_DROPDOWN}//input[@data-id="${notebook_image}:${version}"]
        ELSE
            Log To Console    Unknown image version requested
            Fail    Unknown image version requested
        END
    END

Verify Version Dropdown Is Present
    [Documentation]    Validates the version dropdown for a given Notebook image
    [Arguments]    ${notebook_image}
    ${KFNBC_IMAGE_ROW} =    Set Variable    //input[contains(@id, "${notebook_image}")]
    ${KFNBC_IMAGE_DROPDOWN} =    Set Variable    ${KFNBC_IMAGE_ROW}/../../div[contains(@class, "notebook-image-tags")]
    Page Should Contain Element    xpath=${KFNBC_IMAGE_ROW}/../..//button[.="Versions"]
    Click Element    xpath=${KFNBC_IMAGE_ROW}/../..//button[.="Versions"]
    Wait Until Page Contains Element    xpath=${KFNBC_IMAGE_DROPDOWN}
    Page Should Contain Element    xpath=${KFNBC_IMAGE_DROPDOWN}//span[contains(text(), "Python v${DEFAULT_PYTHON_VER}")]
    Page Should Contain Element    xpath=${KFNBC_IMAGE_DROPDOWN}//span[contains(text(), "Python v${PREVIOUS_PYTHON_VER}")]
    Click Element    xpath=${KFNBC_IMAGE_ROW}/../..//button[.="Versions"]

Select Container Size
    [Documentation]  Selects the container size based on the ${container_size} argument
    [Arguments]  ${container_size}
    # Expand List
    Wait Until Page Contains    Container Size    timeout=30
    ...    error=Container size selector is not present in JupyterHub Spawner
    Click Element  xpath:${JUPYTERHUB_DROPDOWN_XPATH}\[1]
    Click Element  xpath://span[.="${container_size}"]/../..

Wait Until Accelerator Dropdown Exists
    [Documentation]    Verifies that the dropdown to select the Accelerator exists
    Page Should Not Contain    All GPUs are currently in use, try again later.
    Wait Until Page Contains Element    xpath:${KFNBC_ACCELERATOR_DROPDOWN_XPATH}
    ...    error=Accelerator selector is not present in JupyterHub Spawner

Set GPU Accelerator
    [Documentation]  Set Accelerator type
    [Arguments]  ${accelerator_type}='Nvidia GPU'
    Click Element  xpath:${KFNBC_ACCELERATOR_DROPDOWN_XPATH}
    Click Element  xpath://div[@class and text()=${accelerator_type}]

Set Number Of Required Accelerators
    [Documentation]  Sets the Accelerators count based on the ${accelerators} argument
    [Arguments]  ${accelerators}
    ${acc_num} =   Get Value   xpath:${KFNBC_ACCELERATOR_INPUT_XPATH}
    Log    Actual num of Accelerators: ${acc_num}
    IF    ${acc_num} != ${accelerators}
        Input Text  ${KFNBC_ACCELERATOR_INPUT_XPATH}  ${accelerators}
    END


Fetch Max Number Of GPUs In Spawner Page
    [Documentation]    Returns the maximum number of GPUs a user can request from the spawner
    ${gpu_visible} =    Run Keyword And Return Status    Wait Until Accelerator Dropdown Exists
    IF  ${gpu_visible}==True
       Set GPU Accelerator
       ${max_operator_detected} =  Run Keyword And Return Status    Page Should Contain Element    xpath=${KFNBC_MAX_ACCELERATOR_WARNING_XPATH}
       WHILE  not ${max_operator_detected}
          Click Element    xpath:${KFNBC_ACCELERATOR_PLUS_BUTTON_XPATH}
          ${max_operator_detected} =  Run Keyword And Return Status    Page Should Contain Element    xpath=${KFNBC_MAX_ACCELERATOR_WARNING_XPATH}
          ${maxGPUs} =    Get Value   xpath:${KFNBC_ACCELERATOR_INPUT_XPATH}
          ${maxGPUs} =    Convert To Integer    ${maxGPUs}
          ${maxGPUs} =  Set Variable  ${maxGPUs-1}
       END
    ELSE
       ${maxGPUs} =    Set Variable    ${0}
    END
    RETURN    ${maxGPUs}

Add Spawner Environment Variable
   [Documentation]  Adds a new environment variables based on the ${env_var} ${env_var_value} arguments
   [Arguments]  ${env_var}  ${env_var_value}
   Click Button  Add more variables
   #Input Text  xpath://input[@id="---NO KEY---"]  ${env_var}
   Input Text  xpath://input[contains(@id,"-NO KEY-")][1]  ${env_var}
   Element Attribute Value Should Be  xpath:${KFNBC_ENV_VAR_NAME_PRE}//input[contains(@id,"-${env_var}")]  value  ${env_var}
   #Input Text  xpath://input[@id="${env_var}-value"]  ${env_var_value}
   Input Text  xpath://input[contains(@id, "-${env_var}-value")]  ${env_var_value}
   #Element Attribute Value Should Be  xpath://input[@id="${env_var}-value"]  value  ${env_var_value}
   Element Attribute Value Should Be  xpath://input[contains(@id, "-${env_var}-value")]  value  ${env_var_value}

Remove All Spawner Environment Variables
   [Documentation]  Removes all existing environment variables in the Spawner
   @{env_vars_list} =    Create List
   @{env_elements} =    Get WebElements    xpath://*[.='Variable name']/../../div[2]/input

   # We need to fist get the env values and remove them later to avoid a
   # selenium error due to modifiying the DOM while iterating its contents
   FOR    ${element}    IN    @{env_elements}
       ${txt} =   Get Value  ${element}
       Append To List  ${env_vars_list}   ${txt}
   END

   FOR    ${env}    IN    @{env_vars_list}
       Remove Spawner Environment Variable   ${env}
   END

Remove Spawner Environment Variable
   [Documentation]  If it exists, removes an environment variable based on the ${env_var} argument
   [Arguments]  ${env_var}
   ${env_check} =  Spawner Environment Variable Exists   ${env_var}
   IF  ${env_check}==True
      Click Element  xpath://input[contains(@id, "environment-variable-row")][@value="${env_var}"]/../../../../div/button
   END

Spawner Environment Variable Exists
   [Documentation]  Checks if an environment variable is set based on the ${env_var} argument
   [Arguments]  ${env_var}
   ${var_visible} =  Run Keyword And Return Status  Element Should Be Visible  xpath://input[contains(@id, "environment-variable-row")][@value="${env_var}"]
   RETURN  ${var_visible}

Get Spawner Environment Variable Value
   [Documentation]  Get the value of an existing environment variable based on the ${env_var} argument
   [Arguments]  ${env_var}
   ${env_var_value} =  Get Value  xpath://input[contains(@id, "environment-variable-row")][@value="${env_var}"]/../../..//input[contains(@id, "${env_var}-value")]
   RETURN  ${env_var_value}

Spawn Notebook
    [Documentation]  Start the notebook pod spawn and wait ${spawner_timeout} seconds (DEFAULT: 600s)
    ...    If ${expect_autoscaling} is set to ${True} also expects a "TriggeredScaleUp" message in the
    ...    spawn modal.
    [Arguments]  ${spawner_timeout}=600 seconds  ${same_tab}=${True}  ${expect_autoscaling}=${False}
    # TODO: Make sure server spawns in same tab in 1.17+
    # Currently no way to know if option already selected or not
    #${version-check}=   Is RHODS Version Greater Or Equal Than  1.17.0
    #IF  ${version-check}==True
    #    Click Element  xpath://input[@id="checkbox-notebook-browser-tab-preference"]
    #END
    Click Button  Start server
    # Waiting for 60 seconds, since a long wait seems to redirect the user to the control panel
    # if the spawn was successful
    ${modal} =    Run Keyword And Return Status    Wait Until Page Contains
    ...    Starting server    60s
    IF  ${modal}==False
        Log    message=Starting server modal didn't appear after 60s    level=ERROR
        ${control_panel_visible} =  Control Panel Is Visible
        IF  ${control_panel_visible}==True
         # If the user has been redirected to the control panel, move to the server and continue execution
            Click Button    Return to server
            # If route annotation is empty redirect won't work, fail here
            Wait Until Page Does Not Contain Element    xpath:${KFNBC_CONTROL_PANEL_HEADER_XPATH}
            ...    timeout=15s    error=Redirect hasn't happened, check route annotation (opendatahub.io/link) in Notebook CR
            RETURN
        ELSE
            Reload Page
            Sleep  5s
            # Unsure what would happen at this point
            ${spawner_visible} =  JupyterHub Spawner Is Visible
            ${control_panel_visible} =  Control Panel Is Visible
            ${JL_visible} =  JupyterLab Is Visible
            IF  ${spawner_visible}==True
                ${modal_visible} =  Spawner Modal Is Visible
                IF  ${modal_visible}==True
                    ${spawn_fail} =  Has Spawn Failed
                    IF  ${spawn_fail}==True
                        # If the modal is now visible, and spawn has failed
                        # return and let `Spawn Notebook With Arguments` deal with it
                        RETURN
                    ELSE
                        # If modal is visible and spawn hasn't failed, continue
                        # execution and let rest of keyword deal with the timeout
                        Sleep  1s
                        Capture Page Screenshot
                    END
                END
            ELSE IF  ${control_panel_visible}==True
                # If the user has been redirected to the control panel,
                # move to the server and continue execution
                Click Button    Return to server
                RETURN
            ELSE IF  ${JL_Visible}==True
                # We are in JL, return and let `Spawn Notebook With Arguments`
                # deal with it
                RETURN
            ELSE
                # No idea where we are
                Capture Page Screenshot
                Fail  msg=Unknown scenario while spawning server
            END
        END
    END
    Wait Until Element Is Visible  xpath://div[@role="progressbar"]
    IF    ${expect_autoscaling}
        Wait Until Page Contains    TriggeredScaleUp    timeout=120s
    END
    Wait Until Page Contains    The notebook server is up and running.    ${spawner_timeout}
    IF  ${same_tab}
        Click Button    Open in current tab
    ELSE
        Click Button    Open in new tab
        Switch Window    NEW
    END

Has Spawn Failed
    [Documentation]    Checks if spawning the image has failed
    ${spawn_status} =  Run Keyword And Return Status  Page Should Contain  Spawn failed
    RETURN  ${spawn_status}

Spawn Notebook With Arguments  # robocop: disable
    [Documentation]  Selects required settings and spawns a notebook pod. If it fails due to timeout or other issue
    ...              It will try again ${retries} times (Default: 1) after ${retries_delay} delay (Default: 0 seconds).
    ...              Environment variables can be passed in as kwargs by creating a dictionary beforehand
    ...              e.g. &{test-dict}  Create Dictionary  name=robot  password=secret
    ...              ${version} controls if the default or previous version is selected (default | previous)
    [Arguments]  ${retries}=1  ${retries_delay}=0 seconds  ${image}=science-notebook  ${size}=Small
    ...    ${spawner_timeout}=600 seconds  ${gpus}=0  ${refresh}=${False}  ${same_tab}=${True}
    ...    ${username}=${TEST_USER.USERNAME}  ${password}=${TEST_USER.PASSWORD}  ${auth_type}=${TEST_USER.AUTH_TYPE}
    ...    ${version}=default    &{envs}
    ${spawn_fail} =  Set Variable  True
    FOR  ${index}  IN RANGE  0  1+${retries}
        ${spawner_ready} =    Run Keyword And Return Status    Wait Until JupyterHub Spawner Is Ready
        IF  ${spawner_ready}==True
            Select Notebook Image    ${image}    ${version}
            Select Container Size  ${size}
            ${gpu_visible} =    Run Keyword And Return Status    Wait Until Accelerator Dropdown Exists
            IF  ${gpu_visible}==True and ${gpus}>0
                Set GPU Accelerator
                Set Number Of Required Accelerators  ${gpus}
            ELSE IF  ${gpu_visible}==False and ${gpus}>0
                IF    ${index} < ${retries}
                    Sleep    30s    reason=Wait for GPU to free up
                    Reload Page
                    Wait Until JupyterHub Spawner Is Ready
                    CONTINUE
                ELSE
                    Fail  GPUs required but not available
                END
            END
            IF   ${refresh}
                Reload Page
                Capture Page Screenshot    reload.png
                Wait Until JupyterHub Spawner Is Ready
            END
            IF  &{envs}
                Remove All Spawner Environment Variables
                FOR  ${key}  ${value}  IN  &{envs}[envs]
                    Sleep  1
                    Add Spawner Environment Variable  ${key}  ${value}
                END
            END
            Spawn Notebook    ${spawner_timeout}    ${same_tab}
            Run Keyword And Warn On Failure    Wait Until Page Contains    Log in with OpenShift    timeout=15s
            ${oauth_prompt_visible} =    Is OpenShift OAuth Login Prompt Visible
            IF  ${oauth_prompt_visible}    Click Button     Log in with OpenShift
            Run Keyword And Warn On Failure   Login To Openshift  ${username}  ${password}  ${auth_type}
            ${authorization_required} =  Is Service Account Authorization Required
            IF  ${authorization_required}  Authorize jupyterhub service account
            Wait Until Page Contains Element  xpath://div[@id="jp-top-panel"]  timeout=60s
            Sleep    2s    reason=Wait for a possible popup
            Maybe Close Popup
            Open New Notebook In Jupyterlab Menu
            Spawned Image Check    ${image}    ${version}
            ${spawn_fail} =  Has Spawn Failed
            Exit For Loop If  ${spawn_fail} == False
            Reload Page
        ELSE
            Sleep  ${retries_delay}
            Reload Page
        END
    END
    IF  ${spawn_fail} == True
        Fail  msg= Spawner failed loading after ${retries} retries
    END

Spawned Image Check
    [Documentation]    This Keyword checks that the spawned image contains a given image name substring
    ...                (Presumably the one the user wanted to spawn)
    [Arguments]    ${image}    ${version}=default
    ${out} =    Run Cell And Get Output    import os; print(os.environ["JUPYTER_IMAGE"].split("/")[-1].split(":")[0])
    Should Contain    ${out}    ${image}
    IF    "${version}"=="default"
        Python Version Check    expected_version=${DEFAULT_PYTHON_VER}
    ELSE IF    "${version}"=="previous"
        Python Version Check    expected_version=${PREVIOUS_PYTHON_VER}
    ELSE
        Log To Console    Unknown Tag, Cannot Check Python Version
    END
    Open With JupyterLab Menu    Edit    Select All Cells
    Open With JupyterLab Menu    Edit    Delete Cells

Launch JupyterHub Spawner From Dashboard
    [Documentation]  Launches JupyterHub from the RHODS Dashboard
    [Arguments]    ${username}=${TEST_USER.USERNAME}    ${password}=${TEST_USER.PASSWORD}    ${auth}=${TEST_USER.AUTH_TYPE}
    Menu.Navigate To Page    Applications    Enabled
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub  ${username}  ${password}  ${auth}
    ${authorization_required} =  Is Service Account Authorization Required
    IF  ${authorization_required}  Authorize jupyterhub service account
    Fix Spawner Status
    #Wait Until Page Contains Element  xpath://span[@id='jupyterhub-logo']
    Wait Until Page Contains   Start server
    Wait Until JupyterHub Spawner Is Ready

Get Spawner Progress Message
   [Documentation]  Get the progress message currently displayed
   ${msg} =  Get Text  progress-message
   RETURN  ${msg}

Get Spawner Event Log
   [Documentation]  Get the spawner event log messages as a list
   ${event_elements} =  Get WebElements  class:progress-log-event
   RETURN @{event_elements}

Server Not Running Is Visible
   [Documentation]  Checks if "Server Not Running" page is open
   ${SNR_visible} =  Run Keyword And Return Status  Wait Until Page Contains    Server not running  timeout=15
   RETURN  ${SNR_visible}

Handle Server Not Running
   [Documentation]  Moves back to spawner page
   Click Element  xpath://a[@id='start']

Start My Server Is Visible
   [Documentation]  Checks if "Start My Server" page is open
   ${SMS_visible} =  Run Keyword And Return Status  Page Should Contain  Start My Server
   RETURN  ${SMS_visible}

Handle Start My Server
   [Documentation]  Moves back to spawner page
   # TODO: Compare to "Handle Server Not Running" and remove?
   Click Element  xpath://a[@id='start']

Server Is Stopping Is Visible
   [Documentation]  Checks if "Server Is Stopping" page is open
   ${SIS_visible} =  Run Keyword And Return Status  Page Should Contain  Your server is stopping.
   RETURN  ${SIS_visible}

Handle Server Is Stopping
   [Documentation]  Handles "Server Is Stopping" page
   Sleep  10
   Handle Server Not Running

Control Panel Is Visible
   [Documentation]  Checks if Control Panel page is open
   Sleep  2s
   ${control_panel_visible} =  Run Keyword And Return Status  Page Should Contain  Notebook server control panel
   RETURN  ${control_panel_visible}

Handle Control Panel
   [Documentation]  Handles control panel page
   Wait Until Page Contains     Stop notebook server    timeout=30s
   Click Button  Stop notebook server
   Wait Until Page Contains Element  xpath://button[.="Stop server"]
   Click Button  xpath://button[.="Stop server"]

Spawner Modal Is Visible
   [Documentation]  Checks if the spawner modal is present in the spawner page
   ${modal_visible} =  Run Keyword And Return Status  Page Should Contain Element  ${KFNBC_MODAL_HEADER_XPATH}
   RETURN  ${modal_visible}

Handle Spawner Modal
   [Documentation]  Closes the spawner modal
   # If there's a "Close" button instead of "Cancel" in the modal, spawn has failed
   ${spawn_failed} =  Run Keyword And Return Status  Page Should Contain Element  ${KFNBC_MODAL_CLOSE_XPATH}
   IF  ${spawn_failed}==True
       Click Button    ${KFNBC_MODAL_CLOSE_XPATH}
   ELSE
       Click Button    ${KFNBC_MODAL_CANCEL_XPATH}
   END

Fix Spawner Status
   [Documentation]  This keyword handles spawner states that would prevent
   ...              test cases from passing. If a server is already running
   ...              or if we are redirected to an alternative spawner page,
   ...              this keyword will bring us back to the actual spawner.
   [Arguments]    ${username}=${TEST_USER.USERNAME}
   ${spawner_visible} =  JupyterHub Spawner Is Visible
   IF  ${spawner_visible}!=True
      ${control_panel_visible} =  Control Panel Is Visible
      IF  ${control_panel_visible}==True
         Handle Control Panel
      ELSE
         ${JL_visible} =  JupyterLab Is Visible
         IF  ${JL_visible}==True
            Maybe Close Popup
            Clean Up Server    username=${username}
            Stop JupyterLab Notebook Server
         END
      END
   ELSE
      # We are in the spawner page. Is the modal visible?
      ${modal_visible} =  Spawner Modal Is Visible
      IF  ${modal_visible}==True
         # If the modal is visible at this point in time, it might be stuck
         # or a spawn might've failed. Let's close it and clean up the spawner.
         Handle Spawner Modal
      END
   END

User Is Allowed
   [Documentation]  Checks if the user is allowed
   ${spawner_ready} =    Run Keyword And Return Status    Wait Until JupyterHub Spawner Is Ready
   IF  ${spawner_ready}==False
      Fail    Spawner page was not ready
   END
   Page Should Not Contain  Page Not Found

User Is Not Allowed
   [Documentation]  Checks if the user is not allowed
   Wait Until Page Contains  Page Not Found     timeout=10
   # Page Should Contain  403 : Forbidden

User Is JupyterHub Admin
   [Documentation]  Checks if the user is an admin
   Wait Until JupyterHub Spawner Is Ready
   Page Should Contain  Administration

User Is Not JupyterHub Admin
   [Documentation]  Checks if the user is not an admin
   Wait Until JupyterHub Spawner Is Ready
   Page Should Not Contain  Administration

Logout Via Button
   [Documentation]  Logs out from JupyterHub
   Click Element  xpath://a[@id='logout']
   Wait Until Page Contains  Successfully logged out.

Login Via Button
   [Documentation]  This takes you back to the login page
   ...  And you will need to use the `Login To Jupyterhub`
   ...  Keyword.
   Click Element  xpath://a[@id='login']
   Wait Until Page Contains  Log in with

Maybe Handle Server Not Running Page
    [Documentation]  Checks if page is displayed, and if so handles it
    ${SNR_visible} =  Server Not Running Is Visible
    IF  ${SNR_visible}==True
        Handle Server Not Running
    END

Get Container Size
   [Documentation]   This keyword capture the size from JH spawner page based on container size
   [Arguments]  ${container_size}
   Wait Until Page Contains Element    ${KFNBC_CONTAINER_SIZE_TITLE}
   ...    timeout=30   error=Container size selector is not present in KFNBC Spawner
   Click Element    xpath:${KFNBC_CONTAINER_SIZE_DROPDOWN_XPATH}
   Wait Until Page Contains Element    xpath://span[.="${container_size}"]/../..  timeout=10
   ${data}   Get Text  xpath://span[.="${container_size}"]/../span[2]
   ${l_data}   Convert To Lower Case    ${data}
   ${data}    Get Formated Container Size To Dictionary     ${l_data}
   RETURN  ${data}

Get Formated Container Size To Dictionary
   [Documentation]   This is the helper keyword to format the size and convert it to Dictionary
   [Arguments]     ${data}
   ${limit}    Split String     ${data}
   ${idx}      Get Index From List    ${limit}    requests:
   &{f_dict}      Create Dictionary
   &{limits}   Create Dictionary
   &{req}      Create Dictionary
   Set To Dictionary    ${limits}     ${limit[2]}[:-1]=${limit[1]}     ${limit[4]}=${limit[3]}
   Set To Dictionary    ${req}    ${limit[${idx} + ${2}]}[:-1]=${limit[${idx} + ${1}]}    ${limit[${idx} + ${4}]}=${limit[${idx} + ${3}]}
   Set To Dictionary    ${f_dict}       limits=${limits}          requests=${req}
   RETURN    ${f_dict}

Fetch Image Description Info
    [Documentation]  Fetches libraries in image description text
    [Arguments]  ${img}
    ${xpath_img_description} =  Set Variable  //input[contains(@id, "${img}")]/../span
    ${text} =  Get Text  ${xpath_img_description}
    ${text} =  Fetch From Left  ${text}  ,
    RETURN  ${text}

Fetch Image Tooltip Description
    [Documentation]  Fetches Description in image tooltip
    [Arguments]  ${img}
    ${xpath_img_tooltip} =  Set Variable  //input[contains(@id, "${img}")]/../label/span/*
    ${xpath_tooltip_desc} =  Set Variable  //span[@class="jsp-spawner__image-options__packages-popover__title"]
    Click Element  ${xpath_img_tooltip}
    ${desc} =  Get Text  ${xpath_tooltip_desc}
    Click Element  //div[@class='jsp-app__header__title']
    RETURN  ${desc}

Fetch Image Tooltip Info
    [Documentation]    Fetches libraries in image tooltip text
    [Arguments]    ${img}
    ${xpath_img_tooltip} =    Set Variable    //input[contains(@id, "${img}")]/../label//div[@class=""][.=""]
    ${xpath_tooltip_items} =    Set Variable    //div[@class='pf-c-popover__body']/p
    @{tmp_list} =    Create List
    Click Element    ${xpath_img_tooltip}
    ${libs} =    Get Element Count    ${xpath_tooltip_items}
    Log    ${libs}
    FOR    ${index}    IN RANGE    3    1+${libs}
        Sleep    0.1s
        ${item} =    Get Text    ${xpath_tooltip_items}\[${index}]
        Append To List    ${tmp_list}    ${item}
    END
    Click Element    xpath://div[@class='pf-c-popover__content']/button[@aria-label="Close"]
    RETURN    ${tmp_list}

Spawn Notebooks And Set S3 Credentials
    [Documentation]     Spawn a jupyter notebook server and set the env variables
    ...                 to connect with AWS S3
    [Arguments]     ${image}=science-notebook
    Set Log Level    NONE
    &{S3-credentials} =  Create Dictionary  AWS_ACCESS_KEY_ID=${S3.AWS_ACCESS_KEY_ID}  AWS_SECRET_ACCESS_KEY=${S3.AWS_SECRET_ACCESS_KEY}
    Spawn Notebook With Arguments  image=${image}  envs=&{S3-credentials}
    Set Log Level    INFO

Handle Bad Gateway Page
    [Documentation]    It reloads the JH page until Bad Gateway error page
    ...                disappears. It is possible to control how many
    ...                times to try refreshing using 'retries' argument
    [Arguments]   ${retries}=10     ${retry_interval}=1s
    Capture Page Screenshot    jh_badgateway_kw.png
    FOR    ${counter}    IN RANGE    0    ${retries}+1
        ${bg_present} =    Run Keyword And Return Status    Page Should Contain    Bad Gateway
        IF    $bg_present == True
            Reload Page
            Sleep    ${retry_interval}
        END
        Exit For Loop If    $bg_present == False
    END
    IF    $bg_present == True
        Fail    Bad Gateway error page appears
    END

Verify Image Can Be Spawned
    [Documentation]    Verifies that an image with given arguments can be spawned
    [Arguments]    ${retries}=1    ${retries_delay}=0 seconds    ${image}=science-notebook    ${size}=Small
    ...    ${spawner_timeout}=600 seconds    ${gpus}=0    ${refresh}=${False}
    ...    ${username}=${TEST_USER.USERNAME}    ${password}=${TEST_USER.PASSWORD}
    ...    ${auth_type}=${TEST_USER.AUTH_TYPE}    &{envs}
    Begin Web Test    username=${username}    password=${password}    auth_type=${auth_type}
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    retries=${retries}   retries_delay=${retries_delay}    image=${image}    size=${size}
    ...    spawner_timeout=${spawner_timeout}    gpus=${gpus}    refresh=${refresh}
    ...    username=${username}    password=${password}
    ...    auth_type=${auth_type}  envs=&{envs}
    End Web Test    username=${username}

Verify Library Version Is Greater Than
    [Arguments]     ${library}      ${target}
    ${ver} =  Run Cell And Get Output   !pip show ${library} | grep Version: | awk '{split($0,a); print a[2]}' | awk '{split($0,b,"."); printf "%s.%s.%s", b[1], b[2], b[3]}'
    ${comparison} =  GTE  ${ver}  ${target}
    IF  ${comparison}==False
        Run Keyword And Continue On Failure     FAIL    Library Version Is Smaller Than Expected
    END

Get List Of All Available Container Size
    [Documentation]  This keyword capture the available sizes from JH spawner page
    Wait Until Page Contains    Container size    timeout=30
    ...    error=Container size selector is not present in JupyterHub Spawner
    ${size}    Create List
    #Click Element  xpath://div[contains(concat(' ',normalize-space(@class),' '),' jsp-spawner__size_options__select ')]\[1]
    Click Element  xpath://button[@aria-label="Options menu"][1]
    ${link_elements}   Get WebElements  xpath://*[@class="pf-c-select__menu-item-main"]
    FOR  ${idx}  ${ext_link}  IN ENUMERATE  @{link_elements}  start=1
          ${text}      Get Text    ${ext_link}
          Append To List    ${size}     ${text}
    END
    RETURN    ${size}

Open New Notebook In Jupyterlab Menu
    [Documentation]     Opens a new Jupyterlab Launcher and Opens New Notebook from Jupyterlab Menu
    ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
    Maybe Select Kernel
    IF  not ${is_launcher_selected}  Open JupyterLab Launcher
    Open With JupyterLab Menu  File  New  Notebook
    Sleep  1
    Maybe Close Popup
    Close Other JupyterLab Tabs
    Maybe Close Popup
    Sleep  1

Log In N Users To JupyterLab And Launch A Notebook For Each Of Them
    [Documentation]    Log in N users and run notebook for each of them
    [Arguments]    ${list_of_usernames}
    FOR    ${username}    IN    @{list_of_usernames}
        Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}    alias=${username}
        Login To RHODS Dashboard    ${username}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
        Wait for RHODS Dashboard to Load
        Launch Jupyter From RHODS Dashboard Link
        Login To Jupyterhub    ${username}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
        Page Should Not Contain    403 : Forbidden
        ${authorization_required} =    Is Service Account Authorization Required
        IF    ${authorization_required}    Authorize jupyterhub service account
        Fix Spawner Status
        Spawn Notebook With Arguments
    END
    [Teardown]    Close All Browsers

CleanUp JupyterHub For N Users
    [Documentation]    Cleans JupyterHub for N users
    [Arguments]    ${list_of_usernames}
    Close All Browsers
    FOR    ${username}    IN    @{list_of_usernames}
        Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}    alias=${username}
        Login To RHODS Dashboard    ${username}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
        Wait for RHODS Dashboard to Load
        Launch Jupyter From RHODS Dashboard Link
        Login To Jupyterhub    ${username}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
        Page Should Not Contain    403 : Forbidden
        ${authorization_required} =    Is Service Account Authorization Required
        IF    ${authorization_required}    Authorize jupyterhub service account
        #Fix Spawner Status stops the current notebook, handling the different possible states
        Fix Spawner Status
    END
    [Teardown]    Close All Browsers

Delete User Notebook CR
    [Documentation]    Delete the `Notebook` CR for a specific user
    [Arguments]    ${user}
    ${safe_username} =   Get Safe Username    ${user}
    ${CR_name} =    Set Variable    jupyter-nb-${safe_username}
    TRY
        Verify Notebook CR Is Running    cr_name=${CR_name}
    EXCEPT
        Fail    Notebook not found/running for ${user}, cannot stop it
    END
    OpenShiftLibrary.Oc Delete    kind=Notebook    name=${CR_name}    namespace=${NOTEBOOKS_NAMESPACE}
