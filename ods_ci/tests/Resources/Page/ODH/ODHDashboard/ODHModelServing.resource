*** Settings ***
Documentation    Collection of keywords to interact with Model Serving
Resource       ../../../Page/Components/Components.resource
Resource       ../../../Common.robot
Resource       ODHDataScienceProject/ModelServer.resource
Library        ../../../../../libs/Helpers.py


*** Variables ***
${MS_HEADER_XP}=     xpath=//h1[text()="Model serving"]
${S3_NAME_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list Name"]
${S3_KEY_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list AWS_ACCESS_KEY_ID"]
${S3_SECRET_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list AWS_SECRET_ACCESS_KEY"]
${S3_ENDPOINT_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list AWS_S3_ENDPOINT"]
${S3_REGION_DC_INPUT_XP}=          xpath=//input[@aria-label="Field list AWS_DEFAULT_REGION"]
${S3_BUCKET_DC_INPUT_XP}=     xpath=//input[@aria-label="Field list AWS_S3_BUCKET"]
${S3_DEFAULT_BUCKET}=    ods-ci-s3
${MS_TABLE_PROJECT}=    /../../td[@data-label="Project"]
${MS_TABLE_STATUS}=    /../../td[@data-label="Status"]
${MS_TABLE_ENDPOINT}=    /../../td[@data-label="Inference endpoint"]
${MS_TABLE_ENDPOINT_INPUT}=    ${MS_TABLE_ENDPOINT}//div[@class="pf-c-clipboard-copy__group"]/input
${MS_TABLE_DROPDOWN_TOGGLE}=    /../../td[@class="pf-c-table__action"]//button
${MS_TABLE_STATUS_SUCCESS}=    //span[contains(@class,"pf-c-icon__content")][contains(@class,"pf-m-success")]
${MS_TABLE_STATUS_FAILURE}=    //span[contains(@class,"pf-c-icon__content")][contains(@class,"pf-m-danger")]


*** Keywords ***
Open Model Serving Home Page
    [Documentation]    Verifies submenu Settings > "Model Serving" is visible and navigates to page
    Page Should Contain    Model Serving
    Click Link      Model Serving
    # Replace sleep with better Wait keyword. Confirm if error page has "Model serving" h1 element.
    Sleep    1s
    ${loading_error} =    Run Keyword And Return Status    Page Should Contain    Problem loading model serving page
    IF    ${loading_error}
        Log    "Page load error encountered"    level=WARN
        Capture Page Screenshot
        Sleep    5s
        Reload Page
    END
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Model serving
    Wait Until Page Contains    Manage and view the health and performance of your deployed models.    timeout=30
    Maybe Wait For Dashboard Loading Spinner Page

Serve Model
    [Documentation]    Deploys a model via the Model Serving page or Model Server section of a DS Project.
    ...    The framework should be either "onnx" or "openvino_ir".
    [Arguments]    ${project_name}    ${model_name}    ${framework}    ${data_connection_name}    ${model_path}
    ...    ${existing_data_connection}=${TRUE}    ${model_server}=Model Serving Test
    # TODO: Does not work if there's already a model deployed
    Wait Until Page Contains    Deploy model
    Click Button    Deploy model
    Wait Until Page Contains Element    xpath://h1[.="Deploy model"]
    Select Project    ${project_name}
    Set Model Name    ${model_name}
    Select Model Server    ${model_server}
    Wait Until Page Contains Element    xpath://span[.="Model framework (name - version)"]
    Select Framework    ${framework}
    IF    ${existing_data_connection}==${TRUE}
        # Select Radio Button    group_name=radiogroup    value=existing-data-connection-radio
        # Selected by default, let's skip for now
        Select Existing Data Connection    ${data_connection_name}
        Set Folder Path    ${model_path}
    ELSE
        # Existing connection radio is selected by default; for now blindly click on new connection radio
        Click Element    //input[@id="new-data-connection-radio"]
        # Select Radio Button    group_name=radiogroup    value=new-data-connection-radio
        Set Up New Data Connection    dc_name=${data_connection_name}
        Set Folder Path    ${model_path}
    END
    Click Button    Deploy
    Wait Until Page Does Not Contain    xpath://h1[.="Deploy model"]

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
    ${selectable} =    Run Keyword And Return Status
    ...    Page Should Contain Element     xpath://span[.="Model servers"]/../../..//button[@aria-label="Options menu"]
    IF    ${selectable}==True
        Open Model servers Options Menu  # robocop:disable
        Click Element    xpath=//li/button[.="${model_server}"]
    END

Select Framework
    [Documentation]    Selects the framework in the "deploy model" modal.
    ...    Possible values for now: "onnx", "openvino_ir"
    [Arguments]    ${framework}
    TRY
        Open Model framework (name - version) Options Menu
        Page Should Contain Element    xpath://li/button[contains(., "${framework}")]
        Click Element    xpath://li/button[contains(., "${framework}")]
    EXCEPT
        Log    framework ${framework} does not appear to be supported by the chosen model server
    END

Select Existing Data Connection
    [Documentation]    Selects an existing data connection in the "deploy model" modal.
    [Arguments]    ${data_connection_name}
    Open Name Options Menu
    Click Element    xpath://li/button[.="${data_connection_name}"]

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
        Wait Until Keyword Succeeds    120s    5s
        ...    Page Should Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}${MS_TABLE_STATUS_SUCCESS}
        Page Should Not Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}${MS_TABLE_STATUS_FAILURE}
    ELSE
        Wait Until Keyword Succeeds    120s    5s
        ...    Page Should Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}${MS_TABLE_STATUS_FAILURE}
        Page Should Not Contain Element    //div[.="${model_name} "]${MS_TABLE_STATUS}${MS_TABLE_STATUS_SUCCESS}
    END

Delete Model Via UI
    [Documentation]    Deletes a deployed model from the Model Serving page in the dashboard.
    [Arguments]    ${model_name}
    Page Should Contain Element    xpath://div[.="${model_name} "]
    Click Element    xpath://div[.="${model_name} "]${MS_TABLE_DROPDOWN_TOGGLE}
    Click Element    xpath://div[.="${model_name} "]${MS_TABLE_DROPDOWN_TOGGLE}/..//button[.="Delete"]
    Wait Until Page Contains Element    xpath://input[@id="delete-modal-input"]
    Input Text    xpath://input[@id="delete-modal-input"]    ${model_name}
    Click Button    Delete deployed model
    Wait Until Page Does Not Contain Element    xpath://div[.="${model_name} "]

Open Model Edit Modal
    [Documentation]    Opens the modal used to edit the details of an already deployed model.
    [Arguments]    ${model_name}
    Click Element    //div[.="${model_name} "]${MS_TABLE_DROPDOWN_TOGGLE}
    Click Element    //div[.="${model_name} "]${MS_TABLE_DROPDOWN_TOGGLE}/..//button[.="Edit"]
    Wait Until Page Contains    xpath://h1[.="Deploy model"]

Get Model Route via UI
    [Documentation]    Grabs the serving route (URL) of an already deployed model from the Model Serving page.
    [Arguments]    ${model_name}
    # TODO: Open model serving home page if needed?
    Page Should Contain Element    xpath://div[.="${model_name} "]
    ${url}=    Get Element Attribute    xpath://div[.="${model_name} "]${MS_TABLE_ENDPOINT_INPUT}    value
    RETURN    ${url}

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

Get Access Token via UI
    [Documentation]    Returns the access token for models deployed in a specific project
    ...    by using the UI of DSP
    [Arguments]    ${project_name}    ${service_account_name}=default-name
    Open Data Science Project Details Page    ${project_name}
    ${token}=    Get Model Serving Access Token via UI    ${service_account_name}
    RETURN    ${token}

Get Model Project
    [Documentation]    Returns the project under which a model has been deployed
    [Arguments]    ${model_name}
    Page Should Contain Element    //div[.="${model_name} "]
    ${project_name}=    Get Text    xpath://div[.="${model_name} "]${MS_TABLE_PROJECT}
    RETURN    ${project_name}

Get Model Inference
    [Documentation]    Returns the inference result after sending a POST request to a deployed
    ...    model endpoint. If token authentication is needed for the model, ${token_auth} should be
    ...    set to ${TRUE}.
    [Arguments]    ${model_name}    ${inference_input}    ${token_auth}=${FALSE}
    ...    ${project_title}=${NONE}
    ${self_managed} =    Is RHODS Self-Managed
    ${url}=    Get Model Route via UI    ${model_name}
    ${curl_cmd}=     Set Variable    curl -s ${url} -d ${inference_input}
    IF    ${token_auth}
        IF    "${project_title}" == "${NONE}"
            ${project_title}=    Get Model Project    ${model_name}
        END
        ${token}=    Get Access Token via UI    ${project_title}
        ${curl_cmd}=     Catenate    ${curl_cmd}    -H "Authorization: Bearer ${token}"
    END
    IF  ${self_managed}==${TRUE}
        Fetch Openshift CA Bundle
        ${curl_cmd}=     Catenate    ${curl_cmd}    --cacert openshift_ca.crt
    END
    ${inference_output} =    Run    ${curl_cmd}
    RETURN    ${inference_output}

Verify Model Inference
    [Documentation]    Verifies that the inference result of a model is equal to an expected output
    [Arguments]    ${model_name}    ${inference_input}    ${expected_inference_output}    ${token_auth}=${FALSE}
    ...    ${project_title}=${NONE}
    ${inference_output} =    Get Model Inference    ${model_name}    ${inference_input}    ${token_auth}
    ...    project_title=${project_title}
    ${result}    ${list} =    Inference Comparison    ${expected_inference_output}    ${inference_output}
    Log    ${result}
    Log    ${list}
    IF    ${result}==False
        Fail    msg=comparison between expected and actual failed, ${list}
    END

Clean Up Model Serving Page
    [Documentation]    Deletes all currently deployed models, if any are present.
    # Returns an empty list if no matching elements found
    ${models} =    Get WebElements    xpath://table/tbody/tr/td[@data-label="Name"]/div/a
    FOR  ${model}  IN  @{models}
        ${name} =    Get Text   ${model}
        Delete Model Via UI    ${name}
    END

Add Namespace To ServiceMeshMemberRoll
    [Arguments]    ${namespace}    ${servicemesh_ns}=istio-system
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc patch smmr/default -n ${servicemesh_ns} --type='json' -p="[{'op': 'add', 'path': '/spec/members/-', 'value': \"${namespace}\"}]"
    Should Be Equal As Integers    ${rc}    ${0}

Remove Namespace From ServiceMeshMemberRoll
    [Arguments]    ${namespace}    ${servicemesh_ns}=istio-system
    ${rc}    ${ns_idx}=    Run And Return Rc And Output
    ...    oc get smmr/default -n ${servicemesh_ns} -o json | jq '.spec.members | map(. == "${namespace}") | index(true)'
    Should Be Equal As Integers    ${rc}    ${0}
    IF    "${ns_idx}" == "null"
        Log    message=${namespace} was not in the SMMR..
        ...    level=WARN
    ELSE
        ${rc}    ${out}=    Run And Return Rc And Output    oc patch smmr/default -n ${servicemesh_ns} --type='json' -p="[{'op': 'remove', 'path': '/spec/members/${ns_idx}'}]"
        Should Be Equal As Integers    ${rc}    ${0}
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

Get KServe Inference Host Via CLI
    [Arguments]    ${isvc_name}    ${namespace}
    Sleep    5s
    ${rc}    ${ksvc_host}=    Run And Return Rc And Output
    ...    oc get isvc ${isvc_name} -n ${namespace} -o jsonpath='{.status.url}' | cut -d'/' -f3
    # ...    oc get ksvc ${isvc_name}-predictor -n ${namespace} -o jsonpath='{.status.url}' | cut -d'/' -f3
    Should Be Equal As Integers    ${rc}    ${0}
    Should Not Be Empty    ${ksvc_host}
    RETURN    ${ksvc_host}

Get Current Revision ID
    [Arguments]    ${model_name}    ${namespace}
    ${rc}    ${id}=    Run And Return Rc And Output
    ...    oc get pod -n ${namespace} -l serving.kserve.io/inferenceservice=${model_name} -ojson | jq '.items[0].metadata.labels."serving.knative.dev/revisionUID"' | tr -d '"'
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${id}

Set Minimum Replicas Number
    [Arguments]    ${n_replicas}    ${model_name}    ${namespace}
    ${old_revision_id}=    Get Current Revision ID    model_name=${model_name}    namespace=${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc patch InferenceService ${model_name} -n ${namespace} --type=json -p="[{'op': 'replace', 'path': '/spec/predictor/minReplicas', 'value': ${n_replicas}}]"
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${old_revision_id}

Delete InfereceService
    [Arguments]    ${isvc_name}    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output    oc delete InferenceService ${isvc_name} -n ${namespace}
    Should Be Equal As Integers    ${rc}    ${0}

Update Scale To Zero For Knative Serving
    [Arguments]    ${serving_name}    ${namespace}    ${status}
    ${rc}    ${out}=    Run And Return Rc And Output    oc patch KnativeServing ${serving_name} -n ${namespace} --type=json -p="[{'op': 'replace', 'path': '/spec/config/autoscaler/enable-scale-to-zero', 'value': '${status}'}]"
    Should Be Equal As Integers    ${rc}    ${0}

Set Model Hardware Resources
    [Arguments]    ${model_name}    ${namespace}    ${requests}=&{EMPTY}    ${limits}=&{EMPTY}
    IF    ${limits} == ${NONE}
        ${limits}=    Set Variable    null
    END
    IF    ${requests} == ${NONE}
        ${requests}=    Set Variable    null
    END
    ${body}=    Set Variable    {"spec":{"predictor": {"model": {"resources": {"requests": ${requests}, "limits": ${limits} }}}}}
    ${body}=    Replace String    ${body}    '    "
    Log    ${body}
    ${rc}    ${out}=    Run And Return Rc And Output    oc patch isvc ${model_name} -n ${namespace} --type=merge -p '${body}'
    Should Be Equal As Integers    ${rc}    ${0}

Model Pod Should Be Scheduled On A GPU Node
    [Documentation]    Checks that the pods with the given ${label_selector} are actually scheduled on
    ...                a GPU node
    [Arguments]    ${label_selector}    ${namespace}
    ${pods}=    Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=${label_selector}
    FOR    ${index}    ${pod}    IN ENUMERATE    @{pods}
        Log    ${index}: ${pod}[spec][nodeName]
        ${rc}    ${out}=    Run And Return Rc And Output
        ...    oc get node ${pod}[spec][nodeName] -ojson | jq '.metadata.labels."nvidia.com/gpu.present"'
        Should Be Equal As Integers    ${rc}    ${0}
        Should Be Equal As Strings    ${out}    "true"
    END

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
    [Arguments]    ${server_name}    ${project_title}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    ${runtime_pod_name} =    Replace String Using Regexp    string=${server_name}    pattern=\\s    replace_with=-
    ${runtime_pod_name} =    Convert To Lower Case    ${runtime_pod_name}
    Log    name=modelmeshserving${runtime_pod_name}
    Wait For Pods To Be Ready    label_selector=name=modelmesh-serving-${runtime_pod_name}
    ...    namespace=${ns_name}    timeout=10s

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
