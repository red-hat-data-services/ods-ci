# robocop: off=wrong-case-in-keyword-name,too-many-arguments,too-long-keyword
*** Settings ***
Documentation    Collection of keywords to interact with Model Serving
Resource       ../../../Page/Components/Components.resource
Resource       ../../../Common.robot
Resource       ODHDataScienceProject/ModelServer.resource
Resource       ODHDataScienceProject/DataConnections.resource
Resource       ../../../CLI/ModelServing/llm.resource
Library        ../../../../../libs/Helpers.py
Library    RPA.Desktop


*** Variables ***
${MS_HEADER_XP}=     xpath=//h1[text()="Model Serving"]
${S3_NAME_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list Name"]
${S3_KEY_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list AWS_ACCESS_KEY_ID"]
${S3_SECRET_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list AWS_SECRET_ACCESS_KEY"]
${S3_ENDPOINT_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list AWS_S3_ENDPOINT"]
${S3_REGION_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list AWS_DEFAULT_REGION"]
${S3_BUCKET_DC_INPUT_XP}=     xpath=//input[@aria-label="Field list AWS_S3_BUCKET"]
${S3_DEFAULT_BUCKET}=    ods-ci-s3
${MS_TABLE_PROJECT}=    /../../td[@data-label="Project"]
${MS_TABLE_ENDPOINT_INPUT}=    /ancestor::tr//td[@data-label="Inference endpoint"]//input[contains(@id,"text-input-")]
${MS_TABLE_STATUS_SUCCESS}=     /ancestor::tr//td[@data-label="Status"]//span[contains(@class,"pf-m-success")]
${MS_TABLE_STATUS_FAILURE}=     /ancestor::tr//td[@data-label="Status"]//span[contains(@class,"pf-m-danger")]
${KSERVE_MODAL_HEADER}=    //header[@class="pf-v5-c-modal-box__header"]/h1[.="Deploy model"]
${KSERVE_RUNTIME_DROPDOWN}=    //button[@data-testid="serving-runtime-template-selection"]
${LLM_RESOURCES_DIRPATH}=    tests/Resources/Files/llm
${DEPLOY_SINGLE_SV_MODEL_BTN}=    //button[@data-testid="single-serving-select-button"]
${DEPLOY_SINGLE_MODEL_BTN}=    //button[contains(@data-testid,"deploy-button")]
${DEPLOY_MODEL_BTN}=    //button[contains(@data-testid,"deploy-button")]
${TOKEN_AUTH_CHECKBOX_XP}=    xpath://input[@id="alt-form-checkbox-auth"]
${GRPC_URL_REGEX}=  https:\/\/([^\/:]+)


*** Keywords ***
Open Model Serving Home Page
    [Documentation]    Verifies submenu Settings > "Model Serving" is visible and navigates to page
    Navigate To Page    Model Serving
    # Replace sleep with better Wait keyword. Confirm if error page has "Model Serving" h1 element.
    Sleep    1s
    ${loading_error}=    Run Keyword And Return Status
    ...    SeleniumLibrary.Page Should Contain    Problem loading model serving page
    IF    ${loading_error}
        Log    "Page load error encountered"    level=WARN
        SeleniumLibrary.Capture Page Screenshot
        Sleep    5s
        SeleniumLibrary.Reload Page
    END
    Wait For RHODS Dashboard To Load    wait_for_cards=${FALSE}    expected_page=Deployed models
    SeleniumLibrary.Wait Until Page Contains    Manage and view the health and performance of your deployed models.
    ...    timeout=30
    Maybe Wait For Dashboard Loading Spinner Page

Serve Model
    [Documentation]    Deploys a model via the Model Serving page or Model Server section of a DS Project.
    ...    The framework should be either "onnx" or "openvino_ir" or tensorflow.
    ...    Can update existing Model, and use existing Connection.
    [Arguments]    ${project_name}    ${model_name}    ${framework}    ${data_connection_name}    ${model_path}
    ...    ${existing_data_connection}=${TRUE}    ${model_server}=Model Serving Test    ${existing_model}=${FALSE}
    ...    ${serving_runtime}=${NONE}
    Open Model Serving Home Page
    Switch Model Serving Project    ${project_name}
    IF    ${existing_model}
        ${model_row_xpath}=    Set Variable    xpath://tr[starts-with(., '${model_name} ') and contains(., '${project_name}')]
        ${existing_model}=    Run Keyword And Return Status
        ...    Wait Until Page Contains Element    ${model_row_xpath}
    END
    IF  "${existing_model}" == "${TRUE}"
        Log    Model '${model_name}' already exists, editing model   console=True
        ODHDashboard.Click Action From Actions Menu    item_title=${model_name}    action=Edit
    ELSE
        SeleniumLibrary.Wait Until Page Does Not Contain Element    //div[@id="multi-serving-platform-card"]
        SeleniumLibrary.Wait Until Page Does Not Contain Element    //div[@id="single-serving-platform-card"]
        Maybe Wait For Dashboard Loading Spinner Page
        SeleniumLibrary.Wait Until Element Is Enabled    ${DEPLOY_MODEL_BTN}
        SeleniumLibrary.Click Button    ${DEPLOY_MODEL_BTN}
    END
    SeleniumLibrary.Wait Until Page Contains Element    //div[@role="dialog"]
    Set Model Name    ${model_name}
    Select Model Server    ${model_server}
    IF    "${serving_runtime}" != "${NONE}"    Set Model Server Runtime    ${serving_runtime}
    SeleniumLibrary.Wait Until Page Contains Element    xpath://span[.="Model framework (name - version)"]
    Select Framework    ${framework}
    IF    ${existing_data_connection}==${TRUE}
        # Select Radio Button    group_name=radiogroup    value=existing-data-connection-radio
        # Selected by default, let's skip for now
        Select Existing Data Connection    ${data_connection_name}
        Set Folder Path    ${model_path}
    ELSE
        # Existing connection radio is selected by default; for now blindly click on new connection radio
        SeleniumLibrary.Click Element    //input[@id="new-data-connection-radio"]
        # Select Radio Button    group_name=radiogroup    value=new-data-connection-radio
        Set Up New Data Connection    dc_name=${data_connection_name}
        Set Folder Path    ${model_path}
    END
    SeleniumLibrary.Wait Until Element Is Enabled   //button[contains(text(),"Deploy")]
    SeleniumLibrary.Click Button    Deploy
    SeleniumLibrary.Wait Until Page Does Not Contain    xpath://h1[.="Deploy model"]

Select Project
    [Documentation]    Selects a project in the "deploy model" modal.
    ...    If the user has access to a single project or this is being done from within a DSP
    ...    there's no need to do anything but it checks that the project name is the expected one.
    [Arguments]    ${project_name}
    Wait Until Page Contains Element    xpath://span[.="Project"]
    ${choice}=    Run Keyword And Return Status    Page Should Not Contain Element    xpath://span[.="Project"]/../../..//p[.="${project_name}"]
    IF    ${choice}==${TRUE}
        Open Project Options Menu
        Click Element    xpath://li/button[.="${project_name}"]
        Wait Until Page Contains Element    //span[.="Project"]/../../..//span[.="${project_name}"]
        # modal refresh is unreliable
        Sleep    0.5s
    END

Set Model Name
    [Documentation]    Sets the model name in the "deploy model" modal
    [Arguments]    ${model_name}
    Input Text    xpath://input[@id="inference-service-name-input"]    ${model_name}

Select Model Server
    [Documentation]    If there are multiple model servers to choose from, this keyword
    ...    Selects the given one
    [Arguments]    ${model_server}
    ${selectable}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    xpath://span[.="Model servers"]/../../..//button[@aria-label="Options menu"]    timeout=3
    IF    ${selectable}==True
        Click Element    xpath://button[@id="serving-runtime-template-selection"]
        Click Element    xpath://li/button[.="${model_server}"]
    END

Select Framework
    [Documentation]    Selects the framework in the "deploy model" modal.
    ...    Possible values for now: "onnx", "openvino_ir"
    [Arguments]    ${framework}    ${retries}=1
    TRY
        ${is_enabled}=    Run Keyword And Return Status
        ...    Element Should Be Enabled    xpath://button[@id="inference-service-framework-selection"]

        IF    ${is_enabled}
            FOR  ${retry_idx}  IN RANGE  0  1+${retries}
                Click Element    xpath://button[@id="inference-service-framework-selection"]
                Page Should Contain Element    xpath://span[contains(., "${framework}")]
                ${selected}=    Run Keyword And Return Status
                ...    Click Element    xpath://span[contains(., "${framework}")]
                IF  ${selected}==${TRUE}    BREAK
            END
        ELSE
            Element Should Be Disabled    id:inference-service-framework-selection
            ${text}=    Get Text    xpath://button[@id="inference-service-framework-selection"]/span
            Should Be True    ${framework} in ${text}
        END
    EXCEPT
        Log    framework ${framework} does not appear to be supported by the chosen model server
    END


Select Existing Data Connection
    [Documentation]    Selects an existing data connection in the "deploy model" modal.
    [Arguments]    ${data_connection_name}    ${retries}=1

    FOR  ${retry_idx}  IN RANGE  0  1+${retries}
        Click Element    xpath://button[@class="pf-v5-c-menu-toggle__button"]
        Click Element    xpath://button[@class="pf-v5-c-menu__item"]/span/span[contains(., "${data_connection_name}")]
        ${selected}=    Get Element Attribute    //span[@class="pf-v5-c-text-input-group__text"]/input    value
        IF  "${selected}"=="${data_connection_name}"
            BREAK
        END
    END

Set Folder Path
    [Documentation]    Sets the given model path in the "deploy model" modal.
    ...    The path is expected to be relative to the S3 bucket being used.
    ...    e.g.: file in root of S3 bucket -> model_path = filename
    ...    e.g.: file in subfolder of S3 bucket -> model_path = subfolder/filename
    [Arguments]    ${model_path}
    Input Text    xpath://input[@placeholder="Example, data_folder"]    ${model_path}

Set Up New Data Connection
    [Documentation]    Fills in details for new data connection in "deploy model" modal
    [Arguments]    ${dc_name}    ${aws_access_key}=${S3.AWS_ACCESS_KEY_ID}
    ...    ${aws_bucket_name}=${S3_DEFAULT_BUCKET}    ${aws_secret_access}=${S3.AWS_SECRET_ACCESS_KEY}
    ...    ${aws_region}=${S3.AWS_DEFAULT_REGION}    ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}
    Wait Until Page Contains Element    ${S3_NAME_DC_INPUT_XP}
    Input Text    ${S3_NAME_DC_INPUT_XP}    ${dc_name}
    Input Text    ${S3_KEY_DC_INPUT_XP}    ${aws_access_key}
    Input Text    ${S3_SECRET_DC_INPUT_XP}    ${aws_secret_access}
    Input Text    ${S3_ENDPOINT_DC_INPUT_XP}    ${aws_s3_endpoint}
    Input Text    ${S3_REGION_DC_INPUT_XP}    ${aws_region}
    Input Text    ${S3_BUCKET_DC_INPUT_XP}    ${aws_bucket_name}

Verify Model Status
    [Documentation]    Checks the reported model status in the Model Serving or DS Project in the dashboard.
    ...    status can be "success" or any other string (which will expect failure status).
    [Arguments]    ${model_name}    ${expected_status}=success
    IF    "${expected_status}"=="success"
        SeleniumLibrary.Wait Until Page Contains Element
        ...    //a[@data-testid='metrics-link-${model_name}' and text()='${model_name}']${MS_TABLE_STATUS_SUCCESS}    timeout=2m
        Page Should Not Contain Element    //a[@data-testid='metrics-link-test-model' and text()='${model_name}']${MS_TABLE_STATUS_FAILURE}
    ELSE
        SeleniumLibrary.Wait Until Page Contains Element
        ...    //a[@data-testid='metrics-link-${model_name}' and text()='${model_name}']${MS_TABLE_STATUS_FAILURE}    timeout=2m
        Page Should Not Contain Element    //a[@data-testid='metrics-link-test-model' and text()='${model_name}']${MS_TABLE_STATUS_SUCCESS}
    END

Delete Model Via UI
    [Documentation]    Deletes a deployed model from the Model Serving page in the dashboard.
    [Arguments]    ${model_name}
    ${model_row_xpath}=    Set Variable    xpath://tr[starts-with(., '${model_name}')]
    Wait Until Element Is Visible       ${model_row_xpath}
    ODHDashboard.Click Action From Actions Menu    item_title=${model_name}    action=Delete
    Wait Until Page Contains Element    xpath://input[@id="delete-modal-input"]
    Input Text    xpath://input[@id="delete-modal-input"]    ${model_name}
    Click Button    Delete deployed model
    Wait Until Page Does Not Contain Element    ${model_row_xpath}    timeout=30s

Open Model Edit Modal
    [Documentation]    Opens the modal used to edit the details of an already deployed model.
    [Arguments]    ${model_name}
    ODHDashboard.Click Action From Actions Menu    item_title=${model_name}    action=Edit
    # Wait for modal header
    Wait Until Page Contains Element    xpath://span[contains(@class, "modal") and text()="Deploy model"]

Get Model Route Via UI
    [Documentation]    Grabs the serving route (URL) of an already deployed model from the Model Serving page.
    [Arguments]    ${model_name}
    # TODO: Open model serving home page if needed?
    # Click on Inference Endpoints link
    ${endpoint_link}=    Set Variable    //a[@data-testid="metrics-link-${model_name}" and text()="${model_name}"]/ancestor::tr//td//button[@data-testid="internal-external-service-button"]
    SeleniumLibrary.Wait Until Page Contains Element    ${endpoint_link}
    SeleniumLibrary.Click Button    ${endpoint_link}
    # Get the external URL
    ${route_xpath}=    Set Variable    //span[text()="External (can be accessed from inside or outside the cluster)"]/ancestor::dl//dd/div/div/span[1]
    SeleniumLibrary.Wait Until Page Contains Element    //div[@data-testid="external-service-popover"]
    SeleniumLibrary.Wait Until Page Contains Element    ${route_xpath}
    # Get the URL
    Sleep    2    reason=The element takes a little bit longer than expected rendering the url
    ${url}=    Get Text    ${route_xpath}
    ${kserve}=    Run Keyword And Return Status    SeleniumLibrary.Page Should Contain    Single-model serving enabled
    IF    ${kserve}
        ${url}=    Catenate    SEPARATOR=    ${url}    /v2/models/${model_name}/infer
    END
    RETURN    ${url}


Get Model Route for gRPC Via UI
    [Arguments]    ${model_name}
    ${host_url}=    Get Model Route Via UI       model_name=${model_name}
    ${host}=    Evaluate    re.search(r"${GRPC_URL_REGEX}", r"${host_url}").group(1)    re
    RETURN    ${host}

Get Model Route Via CLI
    [Documentation]    Grabs the serving route (URL) of an already deployed model from CLI.
    [Arguments]    ${model_name}    ${project_name}
    ${rc}    ${out}=    Run And Return Rc And Output    oc get route ${model_name} -n ${project_name} --template={{.spec.host}}{{.spec.path}}
    Should Be Equal As Integers	${rc}	 0   msg=Error getting model route
    RETURN    https://${out}/infer

Open ${section} Options Menu
    [Documentation]    Opens the "Options menu" dropdown for different sections
    ...    Valid sections are: "Name", "Model framework (name - version)", "Project"
    ${optionsmenu}=    Run Keyword And Return Status    Page Should Contain Element
    ...    xpath://span[.="${section}"]/../../..//button[@aria-label="Options menu"]
    IF    ${optionsmenu} == ${TRUE}
        SeleniumLibrary.Click Element    xpath://span[.="${section}"]/../../..//button[@aria-label="Options menu"]  # Remove attribute which is not present anymore
    ELSE
        SeleniumLibrary.Click Element    xpath://span[.="${section}"]/../../..//button  # Remove attribute which is not present anymore
    END

Get Access Token Via UI
    [Documentation]    Returns the access token for models deployed in a specific project
    ...    by using the UI of DSP
    [Arguments]    ${project_name}    ${service_account_name}=default-name    ${single_model}=${FALSE}
    ...            ${model_name}=${NONE}
    Log     ${service_account_name}
    Open Data Science Project Details Page    ${project_name}    tab_id=model-server
    ${token}=    Get Model Serving Access Token via UI    ${service_account_name}    ${single_model}    ${model_name}
    RETURN    ${token}

Get Model Project
    [Documentation]    Returns the project under which a model has been deployed
    [Arguments]    ${model_name}
    Page Should Contain Element    //div[.="${model_name} "]
    ${project_name}=    Get Text    xpath://div[.="${model_name} "]${MS_TABLE_PROJECT}
    ${tmp_list}=    Text To List    ${project_name}
    ${project_name}=    Set Variable    ${tmp_list}[0]
    RETURN    ${project_name}

Get Model Inference
    [Documentation]    Returns the inference result after sending a POST request to a deployed
    ...    model endpoint. If token authentication is needed for the model, ${token_auth} should be
    ...    set to ${TRUE}.
    [Arguments]    ${model_name}    ${inference_input}    ${token_auth}=${FALSE}   ${project_title}=${NONE}
    ...    ${kserve_mode}=Serverless   ${deployment_mode}=UI   ${service_port}=8888   ${end_point}=${NONE}
    ...    ${service_account_name}=default-name   ${token}=${NONE}      ${application_type}=${FALSE}
    ${curl_cmd}=     Set Variable    ${NONE}
    ${self_managed}=    Is RHODS Self-Managed
    IF    $deployment_mode == 'UI'
        ${url}=    Get Model Route Via UI    ${model_name}
        ${kserve}=    Run Keyword And Return Status    SeleniumLibrary.Page Should Contain
        ...    Single-model serving enabled
        ${curl_cmd}=     Set Variable    curl -s ${url} -d ${inference_input}
        IF    ${application_type}
            ${curl_cmd}=     Catenate    ${curl_cmd}    -H 'Content-Type: application/json'
        END
        IF    ${token_auth}
            IF    "${project_title}" == "${NONE}"
                ${project_title}=    Get Model Project    ${model_name}
            END
            IF    $token == ${NONE}
                ${token}=    Get Access Token via UI    ${project_title}    service_account_name=${service_account_name}
                ...    single_model=${kserve}    model_name=${model_name}
            END
            ${curl_cmd}=     Catenate    ${curl_cmd}    -H "Authorization: Bearer ${token}"
        END
        IF  ${kserve}
            Fetch Knative CA Certificate    filename=openshift_ca_istio_knative.crt
            ${curl_cmd}=     Catenate    ${curl_cmd}    --cacert openshift_ca_istio_knative.crt
            Log     ${curl_cmd}
        ELSE IF  ${self_managed}
            Fetch Openshift CA Bundle
            ${curl_cmd}=     Catenate    ${curl_cmd}    --cacert openshift_ca.crt
            Log     ${curl_cmd}
        END
    ELSE IF    $deployment_mode == 'Cli'
        ${rc}   ${cmd_op}=  Run And Return Rc And Output
        ...    oc get isvc ${model_name} -o jsonpath='{.metadata.annotations.serving\.kserve\.io/deploymentMode}' -n ${project_title}    # robocop: disable
        Should Be Equal As Integers    ${rc}    0
        IF  "${cmd_op}" != "ModelMesh"
            Fetch Knative CA Certificate    filename=openshift_ca_istio_knative.crt
            ${cert}=    Set Variable    --cacert openshift_ca_istio_knative.crt
        ELSE IF  ${self_managed}
            Fetch Openshift CA Bundle
            ${cert}=   Set Variable   --cacert openshift_ca.crt
        END
        IF    '${kserve_mode}' == 'Serverless'
            ${rc}    ${url}=    Run And Return Rc And Output
            ...    oc get ksvc ${model_name}-predictor -n ${project_title} -o jsonpath='{.status.url}'
            Should Be Equal As Integers    ${rc}    0
            ${curl_cmd}=    Set Variable    curl -s ${url}${end_point} -d ${inference_input}
        ELSE IF    '${kserve_mode}' == 'RawDeployment'
            ${url}=   Set Variable    http://localhost:${service_port}${end_point}
            ${curl_cmd}=    Set Variable    curl -s ${url} -d ${inference_input} --cacert openshift_ca_istio_knative.crt
        ELSE
            Log    "Modelmesh CLI mode only"
        END
        IF    ${token_auth}
            ${token}=    Create Inference Access Token    ${project_title}    ${DEFAULT_BUCKET_SA_NAME}
            ${curl_cmd}=    Catenate    ${curl_cmd}    -H "Authorization: Bearer ${token}"
        END
    END

    ${inference_output}=    Run    ${curl_cmd}
    # Passes if file does not exist, cleans up otherwise. No point keeping these after executing the curl call.
    Remove File    openshift_ca_istio_knative.crt
    Remove File    openshift_ca.crt
    RETURN    ${inference_output}

Verify Model Inference
    [Documentation]    Verifies that the inference result of a model is equal to an expected output
    [Arguments]    ${model_name}    ${inference_input}    ${expected_inference_output}    ${token_auth}=${FALSE}
    ...    ${project_title}=${NONE}    ${deployment_mode}=UI    ${kserve_mode}=Serverless
    ...    ${service_port}=${NONE}   ${end_point}=${NONE}    ${token}=${NONE}      ${application_type}=${FALSE}
    IF   $deployment_mode == 'UI'
         Open Model Serving Home Page
         Switch Model Serving Project    ${project_title}
    END
    ${inference_output}=    Get Model Inference    model_name=${model_name}   inference_input=${inference_input}
    ...    token_auth=${token_auth}    kserve_mode=${kserve_mode}    project_title=${project_title}
    ...    deployment_mode=${deployment_mode}    service_port=${service_port}    end_point=${end_point}
    ...    token=${token}      application_type=${application_type}           # robocop: disable
    Log    ${inference_output}
    ${result}    ${list}=    Inference Comparison    ${expected_inference_output}    ${inference_output}
    Log    ${result}
    Log    ${list}
    IF    ${result}==False
        IF    $project_title == $NONE
              ${rc}    ${project_title}=    Run And Return Rc And Output
              ...    oc get InferenceServices --all-namespaces -ojson | jq '.items[] | select(.metadata.name=="${model_name}") | .metadata.namespace' | tr -d '"'    # robocop: disable
        END
        ${events}    ${podlogs}=    Get Events And Pod Logs    namespace=${project_title}
        ...    label_selector=modelmesh-service=modelmesh-serving
        Fail    msg=comparison between expected and actual failed, ${list}
    END

Verify Model Inference With Retries
    [Documentation]    We see the inference failing often in the tests. One possible cause might be
    ...                timing: model not ready to reply yet, despite the pod is up and running and the
    ...                endpoint exposed.
    ...                This is a temporary mitigation meanwhile we find a better way to check the model
    [Arguments]    ${model_name}    ${inference_input}    ${expected_inference_output}    ${token_auth}=${FALSE}
    ...            ${project_title}=${NONE}    ${retries}=${5}     ${deployment_mode}=UI    ${kserve_mode}=Serverless
    ...            ${service_port}=${NONE}   ${end_point}=${NONE}   ${application_type}=${FALSE}
    ${status}=    Run Keyword And Return Status    Verify Model Inference    ${model_name}    ${inference_input}
    ...    ${expected_inference_output}    ${token_auth}    ${project_title}    ${deployment_mode}     application_type=${application_type}
    IF    not ${status}
        ${retry}=    Set Variable    ${0}
        WHILE    ${retry} < ${retries}
            IF    ${retry} > 0
                Log    message=Modelmesh inference call failed ${retry}/${retries}.
                ...    level=WARN
            END
            ${status}=    Run Keyword And Return Status    Verify Model Inference
            ...    ${model_name}    ${inference_input}    ${expected_inference_output}    ${token_auth}
            ...    project_title=${project_title}     deployment_mode=${deployment_mode}  kserve_mode=${kserve_mode}
            ...    service_port=${service_port}   end_point=${end_point}    application_type=${application_type}
            IF    ${status}
                BREAK
            END
            ${retry}=    Evaluate    ${retry} + 1
            Sleep    5s
        END
        IF    not ${status}
            Fail    msg=Inference operation failed after ${retries+1} attempts
        END
    END

Clean Up Model Serving Page
    [Documentation]    Deletes all currently deployed models, if any are present.
    # Returns an empty list if no matching elements found
    Switch Model Serving Project    project_name=All projects
    ${projects}=    Get WebElements    xpath://table/tbody/tr/td[@data-label="Project"]
    Log    ${projects}
    ${projects_length}=      Get length     ${projects}
    WHILE     ${projects_length} > 0
        ${project}=    Set Variable    ${projects}[0]
        ${project}=    Get Text   ${project}
        @{project description}=  Split String    ${project}
        Switch Model Serving Project    ${project description}[0]
        ${models}=    Get WebElements    xpath://table/tbody/tr/td[@data-label="Name"]
        FOR    ${model}    IN    @{models}
            ${model}=    Get Text   ${model}
            Delete Model Via UI    ${model}
            Sleep    1s
        END
        Switch Model Serving Project    project_name=All projects
        ${projects}=    Get WebElements    xpath://table/tbody/tr/td[@data-label="Project"]
        ${projects_length}=    Get length   ${projects}
    END

Add Namespace To ServiceMeshMemberRoll
    [Arguments]    ${namespace}    ${servicemesh_ns}=istio-system
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc patch smmr/default -n ${servicemesh_ns} --type='json' -p="[{'op': 'add', 'path': '/spec/members/-', 'value': \"${namespace}\"}]"
    Should Be Equal As Integers    ${rc}    ${0}

Namespace Should Be Removed From ServiceMeshMemberRoll
    [Documentation]    Checks if the given namespace is present in the SMMR.
    ...                If yes, it fails
    [Arguments]    ${namespace}    ${servicemesh_ns}=istio-system
    ${rc}    ${member_list}=    Run And Return Rc And Output
    ...    oc get smmr/default -n ${servicemesh_ns} -o json | jq '.spec.members'
    Should Be Equal As Integers    ${rc}    ${0}
    IF    $member_list == "null"
        Log    message=ServiceMeshMemberRoll already cleaned up
    ELSE
        ${rc}    ${ns_idx}=    Run And Return Rc And Output
        ...    oc get smmr/default -n ${servicemesh_ns} -o json | jq '.spec.members | map(. == "${namespace}") | index(true)'    # robocop: disable
        Should Be Equal As Integers    ${rc}    ${0}
        Should Be Equal As Strings    ${ns_idx}    null
        ...    msg=${namespace} should have been automatically removed from SMMR
    END

Deploy Model Via CLI
    [Documentation]    Deploys a model using Model Serving feature by applying the InfereceService
    ...                yaml via CLI. It assumes that the necessary Runtime has been already created
    ...                in the same ${namespace}
    [Arguments]    ${isvc_filepath}    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${isvc_filepath} -n ${namespace}
    Should Be Equal As Integers    ${rc}    ${0}
    Should Not Be Empty    ${out}

Deploy Kserve Model Via UI  #robocop: disable
    [Documentation]  Deploys a model using the kserve/caikit runtime using the Data Science Projects UI
    [Arguments]    ${model_name}    ${serving_runtime}    ${data_connection}    ${path}
    ...    ${model_framework}=caikit    ${replicas}=1    ${size}=Small    ${no_gpus}=${0}
    ...    ${token}=${FALSE}    ${multi_token}=${FALSE}    ${multi_service_account_name}=default-name2
    ...    ${public_endpoint}=${TRUE}    ${service_account_name}=${NONE}    ${existing_server}=${FALSE}
    Move To Tab    Models
    IF    ${existing_server} == False
        SeleniumLibrary.Click Button    ${DEPLOY_SINGLE_SV_MODEL_BTN}
    END
    SeleniumLibrary.Wait Until Page Contains Element    ${DEPLOY_SINGLE_MODEL_BTN}
    SeleniumLibrary.Click Button    ${DEPLOY_SINGLE_MODEL_BTN}
    SeleniumLibrary.Wait Until Page Contains Element    xpath=${KSERVE_MODAL_HEADER}
    Set Model Name   ${model_name}
    Set Model Server Runtime    ${serving_runtime}
    Select Framework    ${model_framework}
    Set Replicas Number With Buttons    ${replicas}
    Set Server Size    ${size}
    IF    ${public_endpoint}
        Enable External Serving Route
        # By default this also enables Token Authentication. Let's disable it and let it get re-enable by the next
        # IF block if needed.
        ${token_enabled}=     Run Keyword And Return Status    SeleniumLibrary.Checkbox Should Be Selected
        ...    ${TOKEN_AUTH_CHECKBOX_XP}
        IF    ${token_enabled}
            Disable Token Authentication
        ELSE
            Log    Token Authentication was supposed to be automatically enabled, but it wasn't    level=ERROR
            ...    console=${True}
        END
    END
    IF    ${token}
        Enable Token Authentication    service_account_name=${service_account_name}
        IF    ${multi_token}
            Add Another Service Account    ${multi_service_account_name}
        END
    END
    Select Existing Data Connection    ${data_connection}
    Set Folder Path    ${path}
    IF    ${no_gpus} > ${0}
        ${gpu_enabled}=    Run Keyword And Return Status    Verify GPU Selector Is Usable
        IF    ${gpu_enabled}==False
            Log    GPU requested but not available
            Fail
        END
        Set Accelerator
        Set Number of GPU With Buttons   ${no_gpus}
    END
    Click Button    Deploy
    Wait Until Page Does Not Contain Element    xpath=//button[@data-testid="modal-submit-button"]   timeout=60s

Set Model Server Runtime
    [Documentation]    Opens the Serving runtime dropdown in the deploy model modal window for models
    ...    and select the given runtime
    [Arguments]    ${runtime}=Caikit TGIS    ${retries}=1
    TRY
        ${is_enabled}=    Run Keyword And Return Status
        ...    Element Should Be Enabled    xpath://button[@id="serving-runtime-template-selection"]

        IF    ${is_enabled}
            FOR  ${retry_idx}  IN RANGE  0  1+${retries}
                Click Element    xpath://button[@id="serving-runtime-template-selection"]
                Page Should Contain Element    xpath://span[contains(., "${runtime}")]
                ${selected}=    Run Keyword And Return Status
                ...    Click Element    xpath://span[contains(., "${runtime}")]
                IF  ${selected}==${TRUE}    BREAK
            END
        ELSE
            Element Should Be Disabled    id:serving-runtime-template-selection
            ${text}=    Get Text    xpath://button[@id="serving-runtime-template-selection"]/span
            Should Be True    ${runtime} in ${text}
        END
    EXCEPT
        Log    framework ${runtime} does not appear to be supported by the chosen model server
    END


Get Kserve Inference Host Via UI
    [Documentation]    Fetches the host of the model's URL from the Data Science Project UI
    [Arguments]    ${model_name}    ${retries}=1
    FOR  ${retry_idx}  IN RANGE  0  1+${retries}
        Wait Until Page Contains Element    //td[@data-label="Name"]/div[.="${model_name} "]/../..//td[@data-label="Inference endpoint"]    timeout=30s  #robocop: disable
        Wait Until Page Contains Element    //td[@data-label="Name"]/div[.="${model_name} "]/../..//td[@data-label="Status"]//span[@aria-label="success icon"]
        ...  timeout=30s  #robocop: disable
        ${endpoint}=    Get Element Attribute    //td[@data-label="Name"]/div[.="${model_name} "]/../..//td[@data-label="Inference endpoint"]//input    value  #robocop: disable
        IF  "${endpoint}"!="${EMPTY}"
            RETURN    ${endpoint}
        END
        Reload Page
    END
    Log    Failed to get model serving host through the UI
    Take Screenshot

Enable Model Serving Runtime Using CLI
    [Documentation]  Update OdhDashboardConfig to enable the model runtime
    [Arguments]    ${namespace}    ${name}=${EMPTY}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc patch OdhDashboardConfig odh-dashboard-config --type=json -p '[{op: "replace", path: "/spec/templateDisablement", value: [${name}]}]' -n ${namespace}
    Should Be Equal As Integers    ${rc}         ${0}

Disable Model Serving Runtime Using CLI
    [Documentation]  Update OdhDashboardConfig to disable the model runtime
    [Arguments]    ${namespace}    ${name}=ovms-gpu
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc patch OdhDashboardConfig odh-dashboard-config --type=json -p '[{op: "replace", path: "/spec/templateDisablement", value: ["${name}"]}]' -n ${namespace}
    Should Be Equal As Integers    ${rc}         ${0}

Wait Until Runtime Pod Is Running
    [Arguments]    ${server_name}    ${project_title}    ${timeout}=10s
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    ${runtime_pod_name}=    Replace String Using Regexp    string=${server_name}    pattern=\\s    replace_with=-
    ${runtime_pod_name}=    Convert To Lower Case    ${runtime_pod_name}
    Log    name=modelmeshserving${runtime_pod_name}
    Wait For Pods To Be Ready    label_selector=name=modelmesh-serving-${runtime_pod_name}
    ...    namespace=${ns_name}    timeout=${timeout}

Get Modelmesh Events And Logs
    [Arguments]    ${server_name}    ${project_title}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    ${runtime_pod_name}=    Replace String Using Regexp    string=${server_name}    pattern=\\s    replace_with=-
    ${runtime_pod_name}=    Convert To Lower Case    ${runtime_pod_name}
    Get Events And Pod Logs    namespace=${ns_name}
    ...    label_selector=name=modelmesh-serving-${runtime_pod_name}

Get Kserve Events And Logs
    [Documentation]    Fetches the events in a given namespace, as well as the logs from all the containers in all the
    ...    pods labelled as part of Kserve.
    [Arguments]    ${model_name}    ${project_title}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    # ${model_name}=    Remove String    ${model_name}    -
    ${model_name}=    Convert To Lower Case    ${model_name}
    Get Events And Pod Logs    namespace=${ns_name}
    ...    label_selector=serving.kserve.io/inferenceservice=${model_name}

Create Custom Serving Runtime Using Template By CLI
    [Documentation]  Use Openshift API to create a custome runtime using template CR
    [Arguments]      ${file_path}
    ${return_code}    ${output}    Run And Return Rc And Output   oc apply -f ${file_path} -n ${APPLICATIONS_NAMESPACE}
    Log To Console    ${output}
    Should Be Equal As Integers    ${return_code}     0   msg=Error while applying the provided file

Get Model Runtime Template Resource Name By Runtime Name OR Display Name
    [Documentation]  Get template name based on runtime name or Display name
    [Arguments]      ${runtime_name}=${EMPTY}     ${runtime_display_name}=${EMPTY}
    IF    "${runtime_name}" != ""
          ${return_code}    ${output}    Run And Return Rc And Output   oc get templates -ojson -n ${APPLICATIONS_NAMESPACE} | jq '.items[] | select(.objects[].metadata."name"=="${runtime_name}") | .metadata.name' | tr -d '"'   #robocop:disable
          Log To Console    ${output}
          Should Be Equal As Integers    ${return_code}     0   msg=Error while applying the provided file
          RETURN   ${output}
    ELSE IF   "${runtime_display_name}" != ""
          ${return_code}    ${output}    Run And Return Rc And Output   oc get templates -ojson -n ${APPLICATIONS_NAMESPACE} | jq '.items[] | select(.objects[].metadata.annotations."openshift.io/display-name"=="${runtime_display_name}") | .metadata.name' | tr -d '"'   #robocop:disable
          Log To Console    ${output}
          Should Be Equal As Integers    ${return_code}     0   msg=Error while applying the provided file
          RETURN   ${output}
    ELSE IF   "${runtime_name}" == "" and "${runtime_display_name}" == ""
         Fail     msg=Kindly provide runtime name or display name
    END

Delete Serving Runtime Template From CLI By Runtime Name OR Display Name
    [Documentation]  Delete template name based on runtime name or Display name
    [Arguments]      ${runtime_name}=${EMPTY}     ${runtime_display_name}=${EMPTY}
    IF    "${runtime_name}" != ""
          ${template_name}   Get Model Runtime Template Resource Name By Runtime Name OR Display Name  runtime_name=${runtime_name}
          ${return_code}    ${output}    Run And Return Rc And Output   oc delete templates ${template_name} -n ${APPLICATIONS_NAMESPACE}  #robocop:disable
          Log To Console    ${output}
          Should Be Equal As Integers    ${return_code}     0   msg=Error while applying the provided file
    ELSE IF   "${runtime_display_name}" != ""
          ${template_name}   Get Model Runtime Template Resource Name By Runtime Name OR Display Name  runtime_display_name=${runtime_display_name}
          ${return_code}    ${output}    Run And Return Rc And Output   oc delete templates ${template_name} -n ${APPLICATIONS_NAMESPACE}  #robocop:disable
          Log To Console    ${output}
          Should Be Equal As Integers    ${return_code}     0   msg=Error while applying the provided file
    ELSE IF   "${runtime_name}" == "" and "${runtime_display_name}" == ""
         Fail     msg=Kindly provide runtime name or display name
    END

Clean Up DSP Page
    [Documentation]    Removes all DSP Projects, if any are present
    ${modal}=    Run Keyword And Return Status    Page Should Contain Element    xpath=${KSERVE_MODAL_HEADER}
    IF  ${modal}==${TRUE}
        Click Element    //button[@aria-label="Close"]
    END
    Open Data Science Projects Home Page
    Delete Project Via CLI By Display Name    ALL
    Reload Page
    Wait For Dashboard Page Title    Data Science Projects    timeout=30s

Clean All Models Of Current User
    [Documentation]    Tries to clean up DSP and Model Serving pages
    ...    In order to deploy a single model in a new project. ${retries}
    ...    controls how many retries are made.
    [Arguments]    ${retries}=5
    Open Model Serving Home Page
    ${projects_empty}=    Run Keyword And Return Status    Page Should Contain    No deployed models
    IF    ${projects_empty}
        Log    No Models Deployed, Skipping Cleanup    console=True
    ELSE
        FOR    ${try}    IN RANGE    0    ${retries}
            ${status}=    Run Keyword And Return Status    Page Should Contain    Select a project
            IF    ${status}
                Capture Page Screenshot
                Click Button    Select a project
                RETURN
            ELSE
                Clean Up Model Serving Page
                Clean Up DSP Page
                Open Model Serving Home Page
                Reload Page
                Sleep  5s
            END
        END
    END

Set Up Project
    [Documentation]    Creates the DS Project (if not exists), creates the data connection for the models,
    ...                creates caikit runtime. This can be used as test setup
    [Arguments]    ${namespace}    ${single_prj}=${TRUE}    ${enable_metrics}=${FALSE}    ${dc_name}=kserve-connection
    IF    ${single_prj}
        Run Keyword And Continue On Failure    Clean All Models Of Current User
    END
    Open Data Science Projects Home Page
    Create Data Science Project    title=${namespace}    description=kserve test project    existing_project=${TRUE}
    Create S3 Data Connection    project_title=${namespace}    dc_name=${dc_name}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=${S3.BUCKET_3.NAME}    aws_s3_endpoint=${S3.BUCKET_3.ENDPOINT}
    ...            aws_region=${S3.BUCKET_3.REGION}
    IF   ${enable_metrics}
        Enable User Workload Monitoring
        Configure User Workload Monitoring
    ELSE
        Log    message=Skipping UserWorkloadMonitoring enablement.
    END
