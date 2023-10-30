*** Settings ***
Documentation    Collection of keywords to interact with Model Servers
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       Projects.resource


*** Variables ***
${S3_NAME_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field Name"]
${S3_KEY_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_ACCESS_KEY_ID"]
${S3_SECRET_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_SECRET_ACCESS_KEY"]
${S3_ENDPOINT_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_S3_ENDPOINT"]
${S3_REGION_DC_INPUT_XP}=          xpath=//input[@aria-label="AWS field AWS_DEFAULT_REGION"]
${DC_SECTION_XP}=             xpath=//div[@id="data-connections"]
${DC_ADD_BTN_1_XP}=           ${DC_SECTION_XP}//button[.="Add data connection"]
${DC_ADD_BTN_2_XP}=           xpath=//footer/button[.="Add data connection"]
${S3_BUCKET_DC_INPUT_XP}=     xpath=//input[@aria-label="AWS field AWS_S3_BUCKET"]
${REPLICAS_PLUS_BTN_XP}=         xpath=//div/button[@aria-label="Plus"]
${REPLICAS_MIN_BTN_XP}=         xpath=//div/button[@aria-label="Minus"]
${SERVING_RUNTIME_NAME}=        xpath=//input[@id="serving-runtime-name-input"]
${SERVING_ACCELERATOR_DROPDOWN_XPATH}=    xpath=//label[@for='modal-notebook-accelerator']/ancestor::div[@class='pf-c-form__group']/descendant::button
${SERVING_ACCELERATOR_INPUT_XPATH}=    xpath=//input[@aria-label='Number of accelerators']
${SERVING_ACCELERATOR_MINUS_BUTTON_XPATH}=    xpath=${SERVING_ACCELERATOR_INPUT_XPATH}/preceding-sibling::button
${SERVING_ACCELERATOR_PLUS_BUTTON_XPATH}=    xpath=${SERVING_ACCELERATOR_INPUT_XPATH}/following-sibling::button
${SERVING_MODEL_SERVERS_SIDE_MENU}=    xpath=//span[text()='Models and model servers']

*** Keywords ***
Create Model Server
    [Documentation]    Keyword to create a Model Server in a Data Science Project
    [Arguments]    ${no_replicas}=1    ${server_size}=Small    ${ext_route}=${TRUE}
    ...    ${token}=${TRUE}    ${runtime}=OpenVINO Model Server    ${server_name}=Model Serving Test
    ...    ${no_gpus}=0
    Click Button    Add server
    Wait Until Page Contains Element    //span[.="Add model server"]
    Set Model Server Name    ${server_name}
    Set Replicas Number With Buttons    ${no_replicas}
    Set Model Server Runtime    ${runtime}
    Set Server Size    ${server_size}
    IF    ${no_gpus} > ${0}
        ${gpu_enabled} =    Run Keyword And Return Status    Verify GPU Selector Is Usable
        IF    ${gpu_enabled}==False
            Log    GPU requested but not available
            Fail
        END
        Set Accelerator
        Set Number of GPU With Buttons   ${no_gpus}
    END
    IF    ${ext_route}==${TRUE}
        Enable External Serving Route
    END
    IF    ${token}==${TRUE}
        Enable Token Authentication
        # Set Service Account name
        # Add Service Account
    END
    Click Button    Add
    Sleep    1s    reason=Sometimes the modal will intercept later clicks even after being closed, wait for a second

Set Replicas Number With Buttons
    [Documentation]    Sets the number of replicas for the model serving pod
    [Arguments]    ${number}
    ${current}=    Get Element Attribute    xpath://div[@class="pf-c-number-input"]/div/input    value
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
    ${current}=    Get Element Attribute    xpath://div[@class="pf-c-number-input"]/div/input    value
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
    [Arguments]    ${accelerator}='Nvidia GPU'
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
    ${expanded} =    Run Keyword And Return Status
    ...    Page Should Contain Element    xpath://button[@aria-expanded="true"]/span[.="${server_name}"]
    IF    ${expanded}==False
        Click Element    xpath://button[@aria-expanded="false"]/span[.="${server_name}"]
    END
    Click Element    ${SERVING_MODEL_SERVERS_SIDE_MENU}
    Sleep  5s      reason=Sometimes the number of current Accelerators take a few seconds to update
    ${current_accs}=  Get Text  xpath://span[text()="${server_name}"]/../../../following-sibling::tr//td[@data-label]/div/dl/div[4]/dd/div
    Should Match  ${current_accs}  ${no_gpus}

Set Model Server Runtime
    [Documentation]    Selects a given Runtime for the model server
    [Arguments]    ${runtime}
    Open Serving runtime Options Menu  # robocop: disable
    Click Element    xpath://div[@id="serving-runtime-template-selection"]//li//div[text()="${runtime}"]
    # TODO: Implement Custom

Set Model Server Name
    [Documentation]    Sets a custom name for the model server
    [Arguments]    ${server_name}
    Input Text    ${SERVING_RUNTIME_NAME}    ${server_name}

Enable External Serving Route
    [Documentation]    Enables the serving route to be accessed externally
    Select Checkbox    xpath://input[@id="alt-form-checkbox-route"]

Enable Token Authentication
    [Documentation]    Enables Token authentication to serving route
    Select Checkbox    xpath://input[@id="alt-form-checkbox-auth"]
    # TODO: change service account name

Get Model Serving Access Token via UI
    [Documentation]    Returns the token used for authentication to the serving route
    ...    TODO: There can be multiple tokens defined for each model server, handle this case as well
    [Arguments]    ${service_account_name}=default-name
    Wait Until Page Contains Element    xpath://td[@data-label="Tokens"]/button
    Click Element    xpath://td[@data-label="Tokens"]/button
    ${token}=    Get Element Attribute
    ...    xpath://div[.="${service_account_name} "]/../../td[@data-label="Token Secret"]//input    value
    RETURN    ${token}

Click Plus Button
    [Documentation]    Clicks the plus button of the model server replica counter
    Click Element    ${REPLICAS_PLUS_BTN_XP}

Click Minus Button
    [Documentation]    Clicks the minus button of the model server replica counter
    Click Element    ${REPLICAS_MIN_BTN_XP}

Query Model With GRPCURL
    [Arguments]    ${host}    ${port}    ${endpoint}    ${json_body}
    ...            ${json_header}=${NONE}    ${insecure}=${FALSE}    ${background}=${NONE}
    ...            ${skip_res_json}=${FALSE}    &{args}
    ${cmd}=    Set Variable    grpcurl -d ${json_body}
    IF    $json_header != None
        ${cmd}=    Catenate    ${cmd}    -H ${json_header}
    END
    IF    ${insecure} == ${TRUE}
        ${cmd}=    Catenate    ${cmd}    -insecure
    END
    # IF    ${plaintext} == ${TRUE}
    #     ${cmd}=    Catenate    ${cmd}    -plaintext
    # END
    # IF    "${proto_filepath}" != "${NONE}"
    #     ${cmd}=    Catenate    ${cmd}    -proto ${proto_filepath}
    # END
    FOR    ${index}    ${option}    IN ENUMERATE    @{args}
        Log    ${index}: ${option}: ${args}[${option}]
        ${cmd}=    Catenate    ${cmd}    -${option} ${args}[${option}]
    END
    ${cmd}=    Catenate    ${cmd}    ${host}:${port}
    ${cmd}=    Catenate    ${cmd}    ${endpoint}
    IF   '${background}' == '${NONE}'
          ${rc}    ${response}=    Run And Return Rc And Output    ${cmd}
          # ${query_process}=    Run Process    command=${cmd}    stderr=STDOUT    cwd=${PROTO_DIRPATH}    shell=yes
          # Run Keyword And Continue On Failure    Should Be Equal As Integers    ${query_process.rc}    ${0}
          Run Keyword And Continue On Failure    Should Be Equal As Integers    ${rc}    ${0}
          # Log    ${query_process.stdout}    console=yes
          Log    ${response}    console=yes
          # ${json_res}=    Load Json String    ${query_process.stdout}
          IF    ${skip_res_json} == ${TRUE}
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
