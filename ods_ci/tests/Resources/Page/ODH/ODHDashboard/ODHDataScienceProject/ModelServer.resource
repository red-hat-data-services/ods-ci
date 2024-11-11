*** Settings ***
Documentation    Collection of keywords to interact with Model Servers
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       ../ODHModelServing.resource
Resource       Projects.resource


*** Variables ***
${S3_NAME_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field Name"]
${S3_KEY_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_ACCESS_KEY_ID"]
${S3_SECRET_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_SECRET_ACCESS_KEY"]
${S3_ENDPOINT_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_S3_ENDPOINT"]
${S3_REGION_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_DEFAULT_REGION"]
${S3_BUCKET_DC_INPUT_XP}=     xpath=//input[@aria-label="AWS field AWS_S3_BUCKET"]
${REPLICAS_PLUS_BTN_XP}=         xpath=//div/button[@aria-label="Plus"]
${REPLICAS_MIN_BTN_XP}=         xpath=//div/button[@aria-label="Minus"]
${SERVING_RUNTIME_NAME}=        xpath=//input[@id="serving-runtime-name-input"]
${SERVING_ACCELERATOR_DROPDOWN_XPATH}=    xpath=//label[@for='modal-notebook-accelerator']/ancestor::div[@class='pf-v5-c-form__group-control']/descendant::button
${SERVING_ACCELERATOR_INPUT_XPATH}=    xpath=//input[@aria-label='Number of accelerators']
${SERVING_ACCELERATOR_MINUS_BUTTON_XPATH}=    xpath=${SERVING_ACCELERATOR_INPUT_XPATH}/preceding-sibling::button
${SERVING_ACCELERATOR_PLUS_BUTTON_XPATH}=    xpath=${SERVING_ACCELERATOR_INPUT_XPATH}/following-sibling::button
${SERVING_MODEL_SERVERS_SIDE_MENU}=    xpath=//span[text()='Models and model servers']
${TOKEN_AUTH_CHECKBOX_XP}=    xpath://input[@id="alt-form-checkbox-auth"]
${ADD_SERVICE_ACCOUNT_BUTTON}=    xpath://button[text()='Add a service account']
${SERVICE_ACCOUNT_INPUT}=    xpath://input[@data-testid='service-account-form-name']
${REPLICAS_COUNT_XP}=     xpath=//input[@id='model-server-replicas']
${PROJECT_SELECTOR_XP}=    xpath://main[contains(@id, 'dashboard-page-main')]//*[@data-testid="project-selector-toggle"]


*** Keywords ***
Create Model Server
    [Documentation]    Keyword to create a Model Server in a Data Science Project
    [Arguments]    ${no_replicas}=1    ${server_size}=Small    ${ext_route}=${TRUE}
    ...    ${token}=${TRUE}    ${runtime}=OpenVINO Model Server    ${server_name}=Model Serving Test
    ...    ${no_gpus}=0    ${existing_server}=${FALSE}
    Move To Tab    Models
    IF    ${existing_server}
        ${existing_server}=  Run Keyword And Return Status     Wait Until Page Contains Element    //button[.="${server_name}"]
        IF  ${existing_server}    Run Keyword And Return
        ...    Log    Model Server '${server_name}' already exists, reusing server    console=True
    END
    SeleniumLibrary.Click Button    Add model server
    SeleniumLibrary.Wait Until Page Contains Element    //span[.="Add model server"]
    Set Model Server Name    ${server_name}
    Set Replicas Number With Buttons    ${no_replicas}
    Set Model Server Runtime    ${runtime}
    Set Server Size    ${server_size}
    IF    ${no_gpus} > ${0}
        ${gpu_enabled}=    Run Keyword And Return Status    Verify GPU Selector Is Usable
        IF    ${gpu_enabled}==False
            Log    GPU requested but not available
            Fail
        END
        Set Accelerator
        Set Number of GPU With Buttons   ${no_gpus}
    END
    IF    ${ext_route}==${TRUE}
        Enable External Serving Route
        Wait Until Page Contains Element   ${TOKEN_AUTH_CHECKBOX_XP}   timeout=10s
        IF    ${token}==${FALSE}
            Disable Token Authentication
        ELSE
            Log    message=Token Auth should be enabled by default..(from v2.5)
            SeleniumLibrary.Checkbox Should Be Selected    ${TOKEN_AUTH_CHECKBOX_XP}
        END
    ELSE IF    ${token}==${TRUE}
        Enable Token Authentication
    END
    SeleniumLibrary.Wait Until Element Is Enabled   //button[contains(text(),"Add")]
    SeleniumLibrary.Click Button    Add
    Sleep    1s    reason=Sometimes the modal will intercept later clicks even after being closed, wait for a second

Set Replicas Number With Buttons
    [Documentation]    Sets the number of replicas for the model serving pod
    [Arguments]    ${number}
    ${current}=    Get Element Attribute    ${REPLICAS_COUNT_XP}   value
    ${difference}=    Evaluate    int(${number})-int(${current})
    ${op}=    Set Variable    plus
    IF    ${difference}<${0}
        ${difference}=    Evaluate    abs(${difference})
        ${op}=    Set Variable    minus
    END
    FOR  ${idx}  IN RANGE  ${difference}
        IF  '${op}'=='plus'
            Click Plus Button
        ELSE
            Click Minus Button
        END
    END
    ${current}=    Get Element Attribute    ${REPLICAS_COUNT_XP}   value
    Should Be Equal As Integers    ${current}    ${number}

Set Server Size
    [Documentation]    Sets the size of the model serving pod
    ...    Can be "Small", "Medium", "Large", "Custom"
    ...    If "Custom", need CPU request/limit and Memory request/limit
    [Arguments]    ${size}
    Open Model server size Options Menu  # robocop:disable
    # Does Not Work for "Custom"
    # //li/button[.="Custom"]
    Click Element    xpath://li//span[.="${size}"]/../../button
    # TODO: Implement Custom

Verify GPU Selector Is Usable
    [Documentation]    Verifies that the GPU selector is present and enabled
    Page Should Contain Element    ${SERVING_ACCELERATOR_DROPDOWN_XPATH}

Set Accelerator
    [Documentation]  Set Accelerator
    [Arguments]    ${accelerator}='NVIDIA GPU'
    Click Element  ${SERVING_ACCELERATOR_DROPDOWN_XPATH}
    Click Element  xpath=//div[@class and text()=${accelerator}]

Set Number of GPU With Buttons
    [Documentation]    Select the number of GPUs to attach to the model server
    [Arguments]    ${no_gpus}
    ${current}=    Get Element Attribute    ${SERVING_ACCELERATOR_INPUT_XPATH}    value
    ${difference}=    Evaluate    int(${no_gpus})-int(${current})
    ${op}=    Set Variable    plus
    IF    ${difference}<${0}
        ${difference}=    Evaluate    abs(${difference})
        ${op}=    Set Variable    minus
    END
    FOR  ${idx}  IN RANGE  ${difference}
        IF  '${op}'=='plus'
            Click GPU Plus Button
        ELSE
            Click GPU Minus Button
        END
    END
    ${current}=    Get Element Attribute    ${SERVING_ACCELERATOR_INPUT_XPATH}    value
    Should Be Equal As Integers    ${current}    ${no_gpus}

Click GPU Plus Button
    [Documentation]    Click the plus button in the GPU selector
    Click Element    ${SERVING_ACCELERATOR_PLUS_BUTTON_XPATH}

Click GPU Minus Button
    [Documentation]    Click the minus button in the GPU selector
    Click Element    ${SERVING_ACCELERATOR_MINUS_BUTTON_XPATH}

Verify Displayed GPU Count
    [Documentation]    Verifies the number of GPUs displayed in the Model Server table
    [Arguments]    ${server_name}    ${no_gpus}
    Wait Until Page Contains Element    xpath://span[.="${server_name}"]
    ${expanded}=    Run Keyword And Return Status
    ...    Page Should Contain Element    xpath://button[@aria-expanded="true"]/span[.="${server_name}"]
    IF    ${expanded}==False
        Click Element    xpath://button[@aria-expanded="false"]/span[.="${server_name}"]
    END
    Sleep  5s      reason=Sometimes the number of current Accelerators take a few seconds to update
    ${current_accs}=  Get Text  xpath://span[text()="${server_name}"]/../../../following-sibling::tr//td[@data-label]/div/dl/div[4]/dd/div
    Should Match  ${current_accs}  ${no_gpus}

Verify Displayed GPU Count In Single Model Serving
    [Documentation]    Verifies the number of GPUs displayed in the Model Server table of single model serving matches
    ...    the expected value
    [Arguments]    ${model_name}    ${no_gpus}
    SeleniumLibrary.Wait Until Page Contains Element    xpath://td[@data-label="Name"]/div[text()="${model_name}"]
    ${expanded}=    Run Keyword And Return Status    Page Should Contain Element
    ...    xpath://td[@data-label="Name"]/div[text()="${model_name}"]/../..//button[@aria-expanded="true"]
    IF    not ${expanded}
        SeleniumLibrary.Click Element
        ...    xpath://td[@data-label="Name"]/div[text()="${model_name}"]/../..//button[@aria-expanded="false"]
    END
    Sleep    5s    reason=Sometimes the number of current Accelerators take a few seconds to update
    ${current_accs}=    SeleniumLibrary.Get Text
    ...    xpath://td[@data-label="Name"]/div[text()="${model_name}"]/../../../tr[last()]//span[.="Number of accelerators"]/../../dd/div  #robocop: disable
    Should Match    ${current_accs}    ${no_gpus}

Set Model Server Name
    [Documentation]    Sets a custom name for the model server
    [Arguments]    ${server_name}
    Input Text    ${SERVING_RUNTIME_NAME}    ${server_name}

Enable External Serving Route
    [Documentation]    Enables the serving route to be accessed externally
    SeleniumLibrary.Select Checkbox    xpath://input[@id="alt-form-checkbox-route"]

Enable Token Authentication
    [Documentation]    Enables Token authentication to serving route
    [Arguments]    ${service_account_name}=${NONE}
    SeleniumLibrary.Select Checkbox    ${TOKEN_AUTH_CHECKBOX_XP}
    IF    "${service_account_name}" != "${NONE}"
        Input Service Account Name    ${service_account_name}
    END

Disable Token Authentication
    [Documentation]    Disable Token authentication to serving route
    ...                If a Service Account is given, just disable the token for the specific one.
    [Arguments]    ${service_account_name}=${NONE}
    IF    "${service_account_name}" != "${NONE}"
        Click Button    xpath://input[@value="${service_account_name}"]/parent::span/parent::div/following::div/button[@aria-label="Remove service account"]
    ELSE
        SeleniumLibrary.Unselect Checkbox    ${TOKEN_AUTH_CHECKBOX_XP}
    END

Add Another Service Account
    [Documentation]    Add another Service Account once the Token Authorization is enabled
    [Arguments]    ${service_account_name}=default-name2
    Click Button     ${ADD_SERVICE_ACCOUNT_BUTTON}
    Input Service Account Name    ${service_account_name}

Input Service Account Name
    [Documentation]    Input the name of the last Added Service Account.
    [Arguments]    ${service_account_name}=default-name
    ${service_accounts}=    Get WebElements    ${SERVICE_ACCOUNT_INPUT}
    ${last_service_account}=    Set Variable    ${service_accounts}[-1]
    Clear Element And Input Text    ${last_service_account}   ${service_account_name}

Get Model Serving Access Token via UI
    [Documentation]    Returns the token used for authentication to the serving route
    ...    TODO: There can be multiple tokens defined for each model server, handle this case as well
    [Arguments]    ${service_account_name}=default-name    ${single_model}=${FALSE}    ${model_name}=${NONE}
    IF    ${single_model}
        # Expand the model
        SeleniumLibrary.Click Button    xpath: //a[text()='${model_name}']/parent::div/parent::td[@data-label='Name']/preceding-sibling::td/button  # robocop: off=line-too-long
        ${token}=    Get Single Model Token    ${service_account_name}
    ELSE
        SeleniumLibrary.Wait Until Page Contains Element    xpath://td[@data-label="Tokens"]/button
        SeleniumLibrary.Click Element    xpath://td[@data-label="Tokens"]/button
        ${token}=    SeleniumLibrary.Get Element Attribute
        ...    xpath://div[.="${service_account_name} "]/../../td[@data-label="Token Secret"]//span/input    value
    END
    RETURN    ${token}

Get Single Model Token
    [Documentation]    Gets the (Single Model) Token of an specific Service Account
    [Arguments]    ${service_account_name}
    ${token}=    Get Element Attribute
    ...    xpath://div[text()='${service_account_name}']/parent::td[@data-label='Token Name']/following-sibling::td[@data-label='Token Secret']//input   value
    RETURN    ${token}

Click Plus Button
    [Documentation]    Clicks the plus button of the model server replica counter
    Click Element    ${REPLICAS_PLUS_BTN_XP}

Click Minus Button
    [Documentation]    Clicks the minus button of the model server replica counter
    Click Element    ${REPLICAS_MIN_BTN_XP}

Query Model With GRPCURL
    [Arguments]    ${host}
    ...            ${port}
    ...            ${endpoint}
    ...            ${json_body}
    ...            ${protobuf_file}=${NONE}
    ...            ${input_filepath}=${NONE}
    ...            ${json_header}=${NONE}
    ...            ${insecure}=${FALSE}
    ...            ${plaintext}=${FALSE}
    ...            ${background}=${NONE}
    ...            ${skip_res_json}=${FALSE}
    ...            ${cert}=${False}
    ...            ${connect_timeout}=10
    ...            &{args}
    ${cmd}=    Set Variable    grpcurl -connect-timeout ${connect_timeout} -d ${json_body}
    IF    $json_header != None
        ${cmd}=    Catenate    ${cmd}    -H ${json_header}
    END
    IF    ${insecure}
        ${cmd}=    Catenate    ${cmd}    -insecure
    ELSE  # -insecure and -cacert are incompatible with each other. Assuming we want either option always on.
        IF    ${cert}==${False}
            Log    The call will fail because you have not provided a valid CA bundle file
        END
        ${cmd}=    Catenate    ${cmd}    -cacert ${cert}
    END
    IF    "${protobuf_file}" != "${NONE}"
        ${cmd}=    Catenate    ${cmd}    -proto ${protobuf_file}
    END
    IF    ${plaintext}
        ${cmd}=    Catenate    ${cmd}    -plaintext
    END
    IF    "${input_filepath}" != "${NONE}"
         ${cmd}=    Catenate    ${cmd}    < ${input_filepath}
     END
    FOR    ${index}    ${option}    IN ENUMERATE    @{args}
        Log    ${index}: ${option}: ${args}[${option}]
        ${cmd}=    Catenate    ${cmd}    -${option} ${args}[${option}]
    END
    ${cmd}=    Catenate    ${cmd}    ${host}:${port}
    ${cmd}=    Catenate    ${cmd}    ${endpoint}
    IF   '${background}' == '${NONE}'
          # ${rc}    ${response}=    Run And Return Rc And Output    ${cmd}
          Log    ${cmd}    console=yes
          ${query_process}=    Run Process    command=${cmd}    stderr=STDOUT  shell=yes
          # Run Keyword And Continue On Failure    Should Be Equal As Integers    ${query_process.rc}    ${0}
          ${rc}=    Set Variable    ${query_process.rc}
          Run Keyword And Continue On Failure    Should Be Equal As Integers    ${rc}    ${0}
          Log    ${query_process.stdout}    console=yes
          ${response}=    Set Variable    ${query_process.stdout}
          Log    ${response}    console=yes
          Log    ${rc}    console=yes
          # ${json_res}=    Load Json String    ${query_process.stdout}
          IF    ${rc} != ${0} or ${skip_res_json} == ${TRUE}
            Log    ${response}
            RETURN    ${response}
          ELSE
            ${json_res}=    Load Json String    ${response}
            # ...    strict=False
            RETURN    ${json_res}
          END
    ELSE
          ${rc}    ${response}=    Run And Return Rc And Output    ${cmd}&
          Run Keyword And Continue On Failure    Should Be Equal As Integers    ${rc}    ${0}
    END

Enable Toleration Feature In KNativeServing
    [Documentation]    Enables the usage of node tolerations in inference services
    [Arguments]    ${knative_serving_ns}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc patch configmap config-features -n ${knative_serving_ns} --type=merge -p '{"data":{"kubernetes.podspec-tolerations": "enabled"}}'
    Should Be Equal As Integers    ${rc}    ${0}

Switch Model Serving Project
    [Documentation]    Switch to an existing project '${project_name}' from Model Serving dropdown list
    [Arguments]    ${project_name}=All projects
    IF    "${project_name}" == "${NONE}"
        ${project_name}=    Set Variable    All projects
    END
    Wait Until Element Is Visible  ${PROJECT_SELECTOR_XP}
    Click Element  ${PROJECT_SELECTOR_XP}
    Wait Until Element Is Visible     //ul//li[contains(., '${project_name}')]
    Click Element     //ul//li[contains(., '${project_name}')]
    ODHDashboard.Maybe Wait For Dashboard Loading Spinner Page
