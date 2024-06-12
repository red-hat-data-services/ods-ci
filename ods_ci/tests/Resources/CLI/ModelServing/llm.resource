*** Settings ***
Documentation     Collection of keywords to interact with Model Serving feature for LLM (Kserve) via CLI
Resource          ../../../Resources/OCP.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardAPI.resource
Library           ../../../../libs/Helpers.py


*** Variables ***
${LLM_RESOURCES_DIRPATH}=    ods_ci/tests/Resources/Files/llm
${EXP_RESPONSES_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/model_expected_responses.json
${RUNTIME_FORMATS_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/runtime_query_formats.json
${INFERENCESERVICE_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/serving_runtimes/base/isvc.yaml
${INFERENCESERVICE_FILLED_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/serving_runtimes/isvc_filled.yaml
${DEFAULT_BUCKET_SECRET_NAME}=    models-bucket-secret
${DEFAULT_BUCKET_SA_NAME}=        models-bucket-sa
${DEFAULT_BUCKET_PREFIX}=         models-bucket
${BUCKET_SECRET_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/bucket_secret.yaml
${BUCKET_SA_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/bucket_sa.yaml
${ROLE_BINDING_FILEPATH}=   ${LLM_RESOURCES_DIRPATH}/rolebinding_view.yaml
${USE_BUCKET_HTTPS}=    "1"
${MODELS_BUCKET}=    ${S3.BUCKET_3}
${SERVICEMESH_CR_NS}=    istio-system
&{RUNTIME_FLIEPATHS}=    caikit-tgis-runtime=${LLM_RESOURCES_DIRPATH}/serving_runtimes/caikit_tgis_servingruntime_{{protocol}}.yaml
...                      tgis-runtime=${LLM_RESOURCES_DIRPATH}/serving_runtimes/tgis_servingruntime_{{protocol}}.yaml
...                      vllm-runtime=${LLM_RESOURCES_DIRPATH}/serving_runtimes/vllm_servingruntime_{{protocol}}.yaml
${DOWNLOAD_PVC_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/download_model_in_pvc.yaml
${DOWNLOAD_PVC_FILLED_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/download_model_in_pvc_filled.yaml

${DOWNLOAD_PROMPTS_PVC_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/download_prompts_in_pvc.yaml
${DOWNLOAD_PROMPTS_PVC_FILLED_FILEPATH}=    ${LLM_RESOURCES_DIRPATH}/download_prompts_in_pvc_filled.yaml
${MATCHING_RATIO}=    ${60}

*** Keywords ***
Set Up Test OpenShift Project
    [Documentation]    Creates a test namespace and track it under ServiceMesh
    [Arguments]    ${test_ns}
    ${rc}    ${out}=    Run And Return Rc And Output    oc get project ${test_ns}
    IF    "${rc}" == "${0}"
        Log    message=OpenShift Project ${test_ns} already present. Skipping project setup...
        ...    level=WARN
        RETURN
    END
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${test_ns}
    Should Be Equal As Numbers    ${rc}    ${0}

Deploy Serving Runtime
    [Documentation]    Create the ServingRuntime CustomResource in the test ${namespace}.
    ...                This must be done before deploying a model which needs Caikit.
    [Arguments]    ${namespace}    ${runtime}    ${protocol}
    ${rc}    ${out}=    Run And Return Rc And Output    oc get ServingRuntime ${runtime} -n ${namespace}
    IF    "${rc}" == "${0}"
        Log    message=ServingRuntime ${runtime} in ${namespace} NS already present. Skipping runtime setup...
        ...    level=WARN
        RETURN
    END
    ${runtime_final_filepath}=    Replace String    string=${RUNTIME_FLIEPATHS}[${runtime}]    search_for={{protocol}}
    ...    replace_with=${protocol}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${runtime_final_filepath} -n ${namespace}
    Should Be Equal As Integers    ${rc}    ${0}

Set Project And Runtime
    [Documentation]    Creates the DS Project (if not exists), creates the data connection for the models,
    ...                creates caikit runtime. This can be used as test setup
    [Arguments]    ${namespace}    ${enable_metrics}=${FALSE}    ${runtime}=caikit-tgis-runtime    ${protocol}=grpc
    ...            ${access_key_id}=${S3.AWS_ACCESS_KEY_ID}    ${access_key}=${S3.AWS_SECRET_ACCESS_KEY}
    ...            ${endpoint}=${MODELS_BUCKET.ENDPOINT}    ${verify_ssl}=${TRUE}
    ...            ${download_in_pvc}=${FALSE}    ${storage_size}=70Gi    ${model_name}=${NONE}    ${model_path}=${model_name}    ${download_timeout}=600s
    Set Up Test OpenShift Project    test_ns=${namespace}
    IF    ${download_in_pvc}
        Create PVC And Download Model From S3    model_name=${model_name}    namespace=${namespace}    bucket_name=${MODELS_BUCKET.NAME}
        ...    use_https=${USE_BUCKET_HTTPS}    download_timeout=${download_timeout}
        ...    storage_size=${storage_size}    model_path=${model_path}
    ELSE
        Create Secret For S3-Like Buckets    endpoint=${endpoint}
        ...    region=${MODELS_BUCKET.REGION}    namespace=${namespace}
        ...    access_key_id=${access_key_id}    access_key=${access_key}
        ...    verify_ssl=${verify_ssl}
    END
    Deploy Serving Runtime    namespace=${namespace}    runtime=${runtime}    protocol=${protocol}
    IF   ${enable_metrics} == ${TRUE}
        Enable User Workload Monitoring
        Configure User Workload Monitoring
    ELSE
        Log    message=Skipping UserWorkloadMonitoring enablement.
    END

Create Secret For S3-Like Buckets
    [Documentation]    Configures the cluster to fetch models from a S3-like bucket
    [Arguments]    ${name}=${DEFAULT_BUCKET_SECRET_NAME}    ${sa_name}=${DEFAULT_BUCKET_SA_NAME}
    ...            ${namespace}=${TEST_NS}    ${endpoint}=${S3.AWS_DEFAULT_ENDPOINT}
    ...            ${region}=${S3.AWS_DEFAULT_REGION}    ${access_key_id}=${S3.AWS_ACCESS_KEY_ID}
    ...            ${access_key}=${S3.AWS_SECRET_ACCESS_KEY}    ${use_https}=${USE_BUCKET_HTTPS}
    ...            ${verify_ssl}=${TRUE}
    ${rc}    ${out}=    Run And Return Rc And Output    oc get secret ${name} -n ${namespace}
    IF    "${rc}" == "${0}"
        Log    message=Secret ${name} in ${namespace} NS already present. Skipping secret setup...
        ...    level=WARN
        RETURN
    END
    Copy File     ${BUCKET_SECRET_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    Copy File     ${BUCKET_SA_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/bucket_sa_filled.yaml
    ${endpoint}=    Replace String   ${endpoint}    https://    ${EMPTY}
    ${endpoint_escaped}=    Escape String Chars    str=${endpoint}
    ${accesskey_escaped}=    Escape String Chars    str=${access_key}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{ENDPOINT}}/${endpoint_escaped}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{USE_HTTPS}}/${use_https}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{REGION}}/${region}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{ACCESS_KEY_ID}}/${access_key_id}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{SECRET_ACCESS_KEY}}/${accesskey_escaped}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{NAME}}/${name}/g' ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    sed -i'' -e 's/{{NAME}}/${sa_name}/g' ${LLM_RESOURCES_DIRPATH}/bucket_sa_filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -f ${LLM_RESOURCES_DIRPATH}/bucket_secret_filled.yaml -n ${namespace}
    Should Be Equal As Integers    ${rc}    ${0}
    Run Keyword And Ignore Error    Run    oc create -f ${LLM_RESOURCES_DIRPATH}/bucket_sa_filled.yaml -n ${namespace}
    Add Secret To Service Account    sa_name=${sa_name}    secret_name=${name}    namespace=${namespace}
    IF    ${verify_ssl} == ${FALSE}
        ${rc}    ${out}=    Run And Return Rc And Output
        ...    oc annotate secret ${name} -n ${namespace} serving.kserve.io/s3-verifyssl='false' --overwrite
        Should Be Equal As Integers    ${rc}    ${0}
    END

Compile Inference Service YAML
    [Documentation]    Prepare the Inference Service YAML file in order to deploy a model
    [Arguments]    ${isvc_name}    ${model_storage_uri}    ${model_format}=caikit    ${serving_runtime}=caikit-tgis-runtime
    ...            ${kserve_mode}=${NONE}    ${sa_name}=${DEFAULT_BUCKET_SA_NAME}    ${canaryTrafficPercent}=${EMPTY}    ${min_replicas}=1
    ...            ${scaleTarget}=1    ${scaleMetric}=concurrency  ${auto_scale}=${NONE}
    ...            ${requests_dict}=&{EMPTY}    ${limits_dict}=&{EMPTY}    ${overlays}=${EMPTY}
    IF   '${auto_scale}' == '${NONE}'
        ${scaleTarget}=    Set Variable    ${EMPTY}
        ${scaleMetric}=    Set Variable    ${EMPTY}
    END
    Set Test Variable    ${isvc_name}
    Set Test Variable    ${min_replicas}
    Set Test Variable    ${sa_name}
    Set Test Variable    ${model_storage_uri}
    Set Test Variable    ${scaleTarget}
    Set Test Variable    ${scaleMetric}
    Set Test Variable    ${canaryTrafficPercent}
    Set Test Variable    ${model_format}
    Set Test Variable    ${serving_runtime}
    IF    len($overlays) > 0
        FOR    ${index}    ${overlay}    IN ENUMERATE    @{overlays}
            Log    ${index}: ${overlay}
            ${rc}    ${out}=    Run And Return Rc And Output
            ...    oc kustomize ${LLM_RESOURCES_DIRPATH}/serving_runtimes/overlay/${overlay} > ${INFERENCESERVICE_FILLED_FILEPATH}
            Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
        END
        Create File From Template    ${INFERENCESERVICE_FILLED_FILEPATH}    ${INFERENCESERVICE_FILLED_FILEPATH}
    ELSE
        Create File From Template    ${INFERENCESERVICE_FILEPATH}    ${INFERENCESERVICE_FILLED_FILEPATH}
    END
    IF    ${requests_dict} != &{EMPTY}
        Log    Adding predictor model requests to ${INFERENCESERVICE_FILLED_FILEPATH}: ${requests_dict}    console=True    # robocop: disable
        FOR    ${index}    ${resource}    IN ENUMERATE    @{requests_dict.keys()}
            Log    ${index}- ${resource}:${requests_dict}[${resource}]
            ${rc}    ${out}=    Run And Return Rc And Output
            ...    yq -i '.spec.predictor.model.resources.requests."${resource}" = "${requests_dict}[${resource}]"' ${INFERENCESERVICE_FILLED_FILEPATH}    # robocop: disable
            Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
        END
    END
    IF    ${limits_dict} != &{EMPTY}
        Log    Adding predictor model limits to ${INFERENCESERVICE_FILLED_FILEPATH}: ${limits_dict}    console=True    # robocop: disable
        FOR    ${index}    ${resource}    IN ENUMERATE    @{limits_dict.keys()}
            Log    ${index}- ${resource}:${limits_dict}[${resource}]
            ${rc}    ${out}=    Run And Return Rc And Output
            ...    yq -i '.spec.predictor.model.resources.limits."${resource}" = "${limits_dict}[${resource}]"' ${INFERENCESERVICE_FILLED_FILEPATH}    # robocop: disable
            Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
        END
    END
    IF    $kserve_mode is not None
        ${rc}    ${out}=    Run And Return Rc And Output
        ...    yq -i '.metadata.annotations."serving.kserve.io/deploymentMode" = "${kserve_mode}"' ${INFERENCESERVICE_FILLED_FILEPATH}    # robocop: disable
        Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
    ELSE
        ${exists}=    Run Keyword And Return Status    Variable Should Exist  ${DSC_KSERVE_MODE}
        IF    ${exists}    # done in this way because when use non-admin users they cannot fetch DSC
            ${mode}=    Set Variable    ${DSC_KSERVE_MODE}
        ELSE
            ${mode}=    Get KServe Default Deployment Mode From DSC
        END
        Log    message=Using defaultDeploymentMode set in the DSC: ${mode}
    END


Model Response Should Match The Expectation
    [Documentation]    Checks that the actual model response matches the expected answer.
    ...                The goals are:
    ...                   - to ensure we are getting an answer from the model (e.g., not an empty text)
    ...                   - to check that we receive the answer from the right model
    ...                when multiple ones are deployed
    [Arguments]    ${model_response}    ${model_name}    ${query_idx}    ${runtime_details}    ${runtime}=caikit-tgis-runtime    ${streamed_response}=${FALSE}
    IF    ${streamed_response} == ${FALSE}
        ${response_text_field}=    Set Variable    ${runtime_details}[response_fields_map][response_text]
        ${response_tokens_field}=    Set Variable    ${runtime_details}[response_fields_map][response_tokens]
        Should Be Equal As Integers    ${model_response}[${response_tokens_field}]    ${EXP_RESPONSES}[queries][${query_idx}][models][${model_name}][response_tokens]    # robocop: disable
        ${cleaned_response_text}=    Replace String Using Regexp    ${model_response}[${response_text_field}]    \\s+    ${SPACE}
        ${cleaned_exp_response_text}=    Replace String Using Regexp    ${EXP_RESPONSES}[queries][${query_idx}][models][${model_name}][response_text]    \\s+    ${SPACE}    # robocop: disable
        ${cleaned_response_text}=    Strip String    ${cleaned_response_text}
        ${cleaned_exp_response_text}=    Strip String    ${cleaned_exp_response_text}
        ${predcited_ratio}=  Get Strings Matching Ratio   ${cleaned_response_text}    ${cleaned_exp_response_text}
        Run Keyword And Continue On Failure    Compare GreaterOrEqual Based On Number  ${MATCHING_RATIO}   ${predcited_ratio}
    ELSE
        # temporarily disabling these lines - will be finalized in later stage due to a different format
        # of streamed reponse when using http protocol instead of grpc
        # ${cleaned_response_text}=    Replace String Using Regexp    ${model_response}    data:(\\s+)?"    "
        # ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    data:(\\s+)?{    {
        # ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    data:(\\s+)?}    }
        # ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    data:(\\s+)?]    ]
        # ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    data:(\\s+)?\\[    [
        ${cleaned_response_text}=    Replace String Using Regexp    ${model_response}    \\s+    ${EMPTY}
        ${rc}    ${cleaned_response_text}=    Run And Return Rc And Output    echo -e '${cleaned_response_text}'
        ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    "    '
        ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}
        ...    [-]?\\d.\\d+[e]?[-]?\\d+    <logprob_removed>
        Log    ${cleaned_response_text}
        ${cleaned_exp_response_text}=    Replace String Using Regexp
        ...    ${EXP_RESPONSES}[queries][${query_idx}][models][${model_name}][streamed_response_text]
        ...    [-]?\\d.\\d+[e]?[-]?\\d+    <logprob_removed>
        ${cleaned_exp_response_text}=    Replace String Using Regexp    ${cleaned_exp_response_text}    \\s+    ${EMPTY}
        ${predcited_ratio}=  Get Strings Matching Ratio   ${cleaned_response_text}    ${cleaned_exp_response_text}
        Run Keyword And Continue On Failure    Compare GreaterOrEqual Based On Number  ${MATCHING_RATIO}   ${predcited_ratio}
    END

Model Response Should Be
    [Arguments]    ${response}    ${model_name}    ${inference_type}    ${runtime}    ${query_idx}=${0}
    ${cleaned_response_text}=    Replace String Using Regexp    ${response}    \\s+    ${SPACE}
    ${rc}    ${cleaned_response_text}=    Run And Return Rc And Output    echo -e '${cleaned_response_text}'
    ${cleaned_response_text}=    Replace String Using Regexp    ${cleaned_response_text}    "    '
    IF    "${inference_type}" == "model-info"
        ${exp_response}=    Set Variable    ${EXP_RESPONSES}[${inference_type}][${model_name}][${runtime}]
    ELSE
        ${exp_response}=    Set Variable    ${EXP_RESPONSES}[queries][${query_idx}][models][${model_name}][${runtime}][${inference_type}_response_text]
    END
    ${cleaned_exp_response_text}=    Replace String Using Regexp    ${exp_response}    \\s+    ${SPACE}    # robocop: disable
    ${predcited_ratio}=  Get Strings Matching Ratio   ${cleaned_response_text}    ${cleaned_exp_response_text}
    Run Keyword And Continue On Failure    Compare GreaterOrEqual Based On Number  ${MATCHING_RATIO}   ${predcited_ratio}

Compare GreaterOrEqual Based On Number
    [Documentation]    Match the ratio of model response from expecetd response
    [Arguments]     ${MATCHING_RATIO}   ${predcited_ratio}
    IF    ${MATCHING_RATIO} <= ${predcited_ratio}
          Log       Model response is matching with expecetd response by ratio more than 60
    ELSE
          FAIL      Model response did not match with expecetd response by the ration of 60
    END
Load Runtime Query Formats
    [Documentation]    Loads the json file containing the expected query format for each
    ...                serving runtime
    [Arguments]    ${filepath}=${RUNTIME_FORMATS_FILEPATH}
    ${runtimes}=    Load Json File    ${filepath}
    Set Suite Variable    ${RUNTIME_FORMATS}    ${runtimes}

Prepare Payload
    [Arguments]    ${runtime}    ${protocol}    ${inference_type}    ${model_name}    ${query_text}
    ...            ${body_params}
    Set Test Variable    ${model_name}
    Set Test Variable    ${query_text}
    Create File From Template    ${RUNTIME_FORMATS_FILEPATH}    ${LLM_RESOURCES_DIRPATH}/runtime_query_formats_filled.json
    Load Runtime Query Formats    filepath=${LLM_RESOURCES_DIRPATH}/runtime_query_formats_filled.json
    ${runtime_details}=    Set Variable    ${RUNTIME_FORMATS}[${runtime}][endpoints][${inference_type}][${protocol}]
    ${body}=    Replace String    ${runtime_details}[body]    '    "
    ${header}=    Set Variable    ${runtime_details}[header]
    IF    ${body_params} != &{EMPTY}
        FOR    ${index}    ${param}    IN ENUMERATE    @{body_params.keys()}
            Log    ${index}: ${param}
            ${value}=    Set Variable    ${body_params}[${param}]
            ${rc}    ${body}=    Run And Return Rc And Output
            ...    echo '${body}' | jq -c --arg ${param} ${value} '. + {"${param}": "${value}"}'
            Should Be Equal As Integers    ${rc}    ${0}    msg=${body}
        END
    END
    IF    "${protocol}" == "grpc"
        ${body}=    Set Variable    '${body}'
        ${header}=    Set Variable  '${header}'
    END
    IF    "${protocol}" == "http"
        ${dict_header}=    Create Dictionary     Cookie=${EMPTY}
        ${sub_headers}=    Split String    ${header}    separator=${SPACE}
        FOR    ${index}    ${sub_header}    IN ENUMERATE    @{sub_headers}
            Log    ${index}: ${sub_header}
            ${pair}=    Split String    ${sub_header}    separator=:
            Log    ${pair}
            Set To Dictionary    ${dict_header}    ${pair}[0]=${pair}[1]
        END
        ${header}=    Set Variable    ${dict_header}
    END
    ${args}=    Create Dictionary
    ${runtime_args_str}=    Set Variable    ${runtime_details}
    ${args_flag}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${runtime_args_str}    args
    IF    ${args_flag}
        ${sub_args}=    Split String    ${runtime_args_str}[args]    separator=${SPACE}
        FOR    ${index}    ${arg}    IN ENUMERATE    @{sub_args}
            Log    ${index}: ${arg}
            ${pair}=    Split String    ${arg}    separator==
            Log    ${pair}
            Set To Dictionary    ${args}    ${pair}[0]=${pair}[1]
        END
    END
    RETURN    ${body}    ${header}    ${args}

Query Model Multiple Times
    [Documentation]    Queries and checks the responses of the given models in a loop
    ...                running ${n_times}. For each loop run it queries all the model in sequence
    ...                ${inference_type} arguments accepts these 2 values for now:
    ...                  - all-tokens: it returns the entire generated response text
    ...                  - streaming: it returns the streamed generated response (i.e., one word per time)
    ...                In order to use a self-signed certificate when performing the request, pass the CA bundle file
    ...                path as the ${cert} argument - defaults to ${False}, i.e. insecure request.
    [Arguments]    ${model_name}
    ...            ${namespace}
    ...            ${runtime}=caikit-tgis-runtime
    ...            ${isvc_name}=${model_name}
    ...            ${inference_type}=all-tokens
    ...            ${n_times}=10
    ...            ${query_idx}=0
    ...            ${validate_response}=${TRUE}
    ...            ${string_check_only}=${FALSE}
    ...            ${protocol}=grpc
    ...            ${port_forwarding}=${FALSE}
    ...            ${port}=443
    ...            ${body_params}=&{EMPTY}
    ...            ${cert}=${False}
    ...            ${token}=${None}
    ...            &{args}
    IF    "${inference_type}" == "streaming"
        ${streamed_response}=    Set Variable    ${TRUE}
    ELSE
        ${streamed_response}=    Set Variable    ${FALSE}
    END
    IF    ${validate_response} == ${FALSE} or ${string_check_only}
        ${skip_json_load_response}=    Set Variable    ${TRUE}
    ELSE
        ${skip_json_load_response}=    Set Variable    ${streamed_response}    # always skip if using streaming endpoint
    END
    IF    ${port_forwarding}
        ${host}=    Set Variable    localhost    # temp - we might need to query using service URL
        ${port}=    Extract Service Port    service_name=${isvc_name}-predictor    protocol=${protocol}    namespace=${namespace}
        ${insecure}=    Set Variable    ${FALSE}
        ${plaintext}=    Set Variable    ${TRUE}
    ELSE
        ${host}=    Get KServe Inference Host Via CLI    isvc_name=${isvc_name}   namespace=${namespace}
        ${insecure}=    Set Variable    ${TRUE}
        ${plaintext}=    Set Variable    ${FALSE}
    END
    ${body}    ${header}    ${extra_args}=    llm.Prepare Payload    runtime=${runtime}    protocol=${protocol}
    ...    inference_type=${inference_type}    model_name=${model_name}    body_params=${body_params}
    ...    query_text=${EXP_RESPONSES}[queries][${query_idx}][query_text]
    IF    "${token}" != "${None}"
        ${header}=    Set Variable  "Authorization: Bearer ${token}" -H ${header}
    END
    ${runtime_details}=    Set Variable    ${RUNTIME_FORMATS}[${runtime}][endpoints][${inference_type}][${protocol}]
    ${endpoint}=    Set Variable    ${runtime_details}[endpoint]
    Set To Dictionary    ${args}    &{extra_args}
    FOR    ${counter}    IN RANGE    0    ${n_times}    1
        Log    ${counter}
        IF    "${protocol}" == "grpc"
            ${res}=    Query Model With GRPCURL   host=${host}    port=${port}
            ...    endpoint=${endpoint}
            ...    json_body=${body}    json_header=${header}
            ...    insecure=${insecure}    plaintext=${plaintext}    skip_res_json=${skip_json_load_response}
            ...    cert=${cert}    &{args}
         ELSE IF    "${protocol}" == "http"
            ${payload}=     ODHDashboardAPI.Prepare Payload     body=${body}    str_to_json=${TRUE}
            Log Dictionary    ${args}
            Set To Dictionary    ${args}    url=https://${host}:${port}/${endpoint}   expected_status=any
            ...             headers=${header}   json=${payload}    verify=${cert}
            ${is_timeout}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${args}    timeout
            IF    ${is_timeout} == ${FALSE}
                Set To Dictionary    ${args}    timeout=10
            END
            Log Dictionary    ${args}
            ${res}=    Run Keyword And Continue On Failure     Perform Request     request_type=POST
            ...    skip_res_json=${skip_json_load_response}    &{args}
            Run Keyword And Continue On Failure    Status Should Be  200
        END
        Log    ${res}
        IF    ${validate_response} == ${TRUE}
            IF    ${string_check_only}
                Model Response Should Be    response=${res}    model_name=${model_name}    inference_type=${inference_type}
                ...    runtime=${runtime}    query_idx=${query_idx}
            ELSE
                ${response_container_field}=    Set Variable    ${runtime_details}[response_fields_map][response]
                IF    "${response_container_field}" != "${EMPTY}"
                    # runtimes may support multiple queries per time. Here forcing to use only 1 for sake of simplicity.
                    ${res}=    Set Variable    ${res}[${response_container_field}][0]
                END
                Run Keyword And Continue On Failure
                ...    Model Response Should Match The Expectation    model_response=${res}    model_name=${model_name}
                ...    runtime_details=${runtime_details}    runtime=${runtime}
                ...    streamed_response=${streamed_response}    query_idx=${query_idx}
            END
        END
    END

Compile Deploy And Query LLM model
    [Documentation]    Group together the test steps for preparing, deploying
    ...                and querying a model
    [Arguments]    ${model_storage_uri}    ${model_name}    ${isvc_name}=${model_name}
    ...            ${runtime}=caikit-tgis-runtime    ${model_format}=caikit    ${protocol}=grpc    ${inference_type}=all-tokens
    ...            ${canaryTrafficPercent}=${EMPTY}   ${namespace}=${TEST_NS}  ${sa_name}=${DEFAULT_BUCKET_SA_NAME}
    ...            ${n_queries}=${1}    ${query_idx}=${0}    ${validate_response}=${TRUE}    ${limits_dict}=&{EMPTY}
    ...            ${port_forwarding}=${FALSE}
    Compile Inference Service YAML    isvc_name=${isvc_name}
    ...    sa_name=${sa_name}    serving_runtime=${runtime}
    ...    model_storage_uri=${model_storage_uri}
    ...    canaryTrafficPercent=${canaryTrafficPercent}
    ...    model_format=${model_format}
    ...    limits_dict=${limits_dict}
    Deploy Model Via CLI    isvc_filepath=${INFERENCESERVICE_FILLED_FILEPATH}
    ...    namespace=${namespace}
    Wait For Model KServe Deployment To Be Ready    label_selector=serving.kserve.io/inferenceservice=${isvc_name}
    ...    namespace=${namespace}    runtime=${runtime}
    ${pod_name}=  Get Pod Name    namespace=${namespace}    label_selector=serving.kserve.io/inferenceservice=${isvc_name}
    IF    ${IS_KSERVE_RAW}     Start Port-forwarding    namespace=${namespace}    pod_name=${pod_name}
    Query Model Multiple Times    isvc_name=${isvc_name}    model_name=${model_name}
    ...    n_times=${n_queries}    namespace=${namespace}    query_idx=${query_idx}
    ...    validate_response=${validate_response}    protocol=${protocol}
    ...    runtime=${runtime}    inference_type=${inference_type}
    ...    port_forwarding=${port_forwarding}

Upgrade Runtime Image
    [Documentation]    Replaces the image URL of the Caikit Runtim with the given
    ...    ${new_image_url}
    [Arguments]    ${new_image_url}    ${namespace}    ${container}    ${runtime}
    ${rc}    ${container_idx}=    Run And Return Rc And Output
    ...    oc get ServingRuntime/${runtime} -n ${namespace} -o json | jq '.spec.containers | map(.name == "${container}") | index(true)'    # robocop: disable
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc patch ServingRuntime ${runtime} -n ${namespace} --type=json -p="[{'op': 'replace', 'path': '/spec/containers/${container_idx}/image', 'value': '${new_image_url}'}]"    # robocop: disable
    Should Be Equal As Integers    ${rc}    ${0}

Get Model Pods Creation Date And Image URL
    [Documentation]    Fetches the creation date and the caikit runtime image URL.
    ...                Useful in upgrade scenarios
    [Arguments]    ${model_name}    ${namespace}    ${container}
    ${created_at}=    Oc Get    kind=Pod    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    namespace=${namespace}    fields=["metadata.creationTimestamp"]
    ${rc}    ${container_idx}=    Run And Return Rc And Output
    ...    oc get pod --selector serving.kserve.io/inferenceservice=${model_name} -n ${namespace} -o json | jq '.items[].spec.containers | map(.name == "${container}") | index(true)'    # robocop: disable
    ${rc}    ${image_url}=    Run And Return Rc And Output
    ...    oc get pod --selector serving.kserve.io/inferenceservice=${model_name} -n ${namespace} -ojson | jq '.items[].spec.containers[${container_idx}].image'    # robocop: disable
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${created_at}    ${image_url}

User Can Fetch Number Of Requests Over Defined Time
    [Documentation]    Fetches the `tgi_request_count` metric and checks that it reports the expected
    ...                model information (name, namespace, pod name and type of request).
    ...                If ${exp_value} is given, it checks also the metric value
    [Arguments]    ${thanos_url}    ${thanos_token}    ${model_name}    ${namespace}
    ...           ${query_kind}=single    ${period}=30m    ${exp_value}=${EMPTY}
    ${resp}=    Prometheus.Run Query    https://${thanos_url}    ${thanos_token}    tgi_request_count[${period}]
    Log    ${resp.json()["data"]}
    Check Query Response Values    response=${resp}    exp_namespace=${namespace}
    ...    exp_model_name=${model_name}    exp_query_kind=${query_kind}    exp_value=${exp_value}

User Can Fetch Number Of Successful Requests Over Defined Time
    [Documentation]    Fetches the `tgi_request_success` metric and checks that it reports the expected
    ...                model information (name, namespace and type of request).
    ...                If ${exp_value} is given, it checks also the metric value
    [Arguments]    ${thanos_url}    ${thanos_token}    ${model_name}    ${namespace}
    ...            ${query_kind}=single    ${period}=30m    ${exp_value}=${EMPTY}
    ${resp}=    Prometheus.Run Query    https://${thanos_url}    ${thanos_token}    tgi_request_success[${period}]
    Log    ${resp.json()["data"]}
    Check Query Response Values    response=${resp}    exp_namespace=${namespace}
    ...    exp_model_name=${model_name}    exp_query_kind=${query_kind}    exp_value=${exp_value}

User Can Fetch CPU Utilization
    [Documentation]    Fetches the `pod:container_cpu_usage:sum` metric and checks that it reports the expected
    ...                model information (pod name and namespace).
    ...                If ${exp_value} is given, it checks also the metric value
    [Arguments]    ${thanos_url}    ${thanos_token}    ${namespace}    ${model_name}    ${period}=30m    ${exp_value}=${EMPTY}    # robocop: disable
    ${resp}=    Prometheus.Run Query    https://${thanos_url}    ${thanos_token}    pod:container_cpu_usage:sum{namespace="${namespace}"}[${period}]    # robocop: disable
    ${pod_name}=    Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=serving.kserve.io/inferenceservice=${model_name}
    ...    fields=['metadata.name']
    Log    ${resp.json()["data"]}
    Check Query Response Values    response=${resp}    exp_namespace=${namespace}
    ...    exp_pod_name=${pod_name}[0][metadata.name]    exp_value=${exp_value}

TGI Caikit And Istio Metrics Should Exist
    [Documentation]    Checks that the `tgi_`, `caikit_` and `istio_` metrics exist.
    ...                Returns the list of metrics names
    [Arguments]    ${thanos_url}    ${thanos_token}
    ${tgi_metrics_names}=    Get Thanos Metrics List    thanos_url=${thanos_url}    thanos_token=${thanos_token}
    ...    search_text=tgi
    Should Not Be Empty    ${tgi_metrics_names}
    ${tgi_metrics_names}=    Split To Lines    ${tgi_metrics_names}
    ${caikit_metrics_names}=    Get Thanos Metrics List    thanos_url=${thanos_url}    thanos_token=${thanos_token}
    ...    search_text=caikit
    ${caikit_metrics_names}=    Split To Lines    ${caikit_metrics_names}
    ${istio_metrics_names}=    Get Thanos Metrics List    thanos_url=${thanos_url}    thanos_token=${thanos_token}
    ...    search_text=istio
    ${istio_metrics_names}=    Split To Lines    ${istio_metrics_names}
    ${metrics}=    Append To List    ${tgi_metrics_names}    @{caikit_metrics_names}    @{istio_metrics_names}
    RETURN    ${metrics}

Check Query Response Values    # robocop:disable
    [Documentation]    Implements the metric checks for `User Can Fetch Number Of Requests Over Defined Time`
    ...                `User Can Fetch Number Of Successful Requests Over Defined Time` and
    ...                `User Can Fetch CPU Utilization`. It searches among the available metric values
    ...                for the specific model
    [Arguments]    ${response}    ${exp_namespace}    ${exp_model_name}=${EMPTY}
    ...            ${exp_query_kind}=${EMPTY}    ${exp_value}=${EMPTY}    ${exp_pod_name}=${EMPTY}
    ${json_results}=    Set Variable    ${response.json()["data"]["result"]}
    FOR    ${index}    ${result}    IN ENUMERATE    @{json_results}
        Log    ${index}: ${result}
        ${value_keyname}=    Run Keyword And Return Status
        ...    Dictionary Should Contain Key    ${result}    value
        IF    ${value_keyname} == ${TRUE}
            ${curr_value}=    Set Variable    ${result["value"][-1]}
        ELSE
            ${curr_value}=    Set Variable    ${result["values"][-1][-1]}
        END
        ${source_namespace}=    Set Variable    ${result["metric"]["namespace"]}
        ${checked}=    Run Keyword And Return Status
        ...    Should Be Equal As Strings    ${source_namespace}    ${exp_namespace}
        IF    ${checked} == ${FALSE}
            Continue For Loop
        ELSE
            Log    message=Metrics source namespaced succesfully checked. Going to next step.
        END
        IF    "${exp_model_name}" != "${EMPTY}"
            ${source_model}=    Set Variable    ${result["metric"]["job"]}
            ${checked}=    Run Keyword And Return Status    Should Be Equal As Strings    ${source_model}
            ...    ${exp_model_name}-metrics
            IF    ${checked} == ${FALSE}
                Continue For Loop
            ELSE
                Log    message=Metrics source model succesfully checked. Going to next step.
            END
            IF    "${exp_query_kind}" != "${EMPTY}"
                ${source_query_kind}=    Set Variable    ${result["metric"]["kind"]}
                ${checked}=    Run Keyword And Return Status    Should Be Equal As Strings    ${source_query_kind}
                ...    ${exp_query_kind}
                IF    ${checked} == ${FALSE}
                    Continue For Loop
                ELSE
                    Log    message=Metrics query kind succesfully checked. Going to next step.
                END
            END
        END
        IF    "${exp_pod_name}" != "${EMPTY}"
            ${source_pod}=    Set Variable    ${result["metric"]["pod"]}
            ${checked}=    Run Keyword And Return Status    Should Be Equal As Strings    ${source_pod}
            ...    ${exp_pod_name}
            IF    ${checked} == ${FALSE}
                Continue For Loop
            ELSE
                Log    message=Metrics source pod succesfully checked. Going to next step.
            END
        END
        IF    "${exp_value}" != "${EMPTY}"
            Run Keyword And Continue On Failure    Should Be Equal As Strings    ${curr_value}    ${exp_value}
        ELSE
            Run Keyword And Continue On Failure    Should Not Be Empty    ${curr_value}
        END
        IF    ${checked} == ${TRUE}
            Log    message=The desired query result has been found.
            Exit For Loop
        END
    END
    IF    ${checked} == ${FALSE}
        Fail    msg=The metric you are looking for has not been found. Check the query parameter and try again
    END

Traffic Should Be Redirected Based On Canary Percentage
    [Documentation]    Sends an arbitrary number of queries ${total} and checks the amount of
    ...                them which gets redirected to the given ${model_name}
    ...                matches the expected probability ${exp_percentage}.
    ...                It applies an arbitrary toleration margin of ${toleration}
    [Arguments]    ${exp_percentage}    ${isvc_name}    ${model_name}    ${namespace}
    ...            ${runtime}
    ${total}=    Set Variable    ${20}
    ${hits}=    Set Variable    ${0}
    ${toleration}=    Set Variable    ${20}
    FOR    ${counter}    IN RANGE    ${0}    ${total}
        Log    ${counter}
        ${status}=    Run Keyword And Return Status
        ...    Query Model Multiple Times    isvc_name=${isvc_name}    model_name=${model_name}    n_times=1
        ...    namespace=${namespace}    runtime=${runtime}
        IF    ${status} == ${TRUE}
            ${hits}=    Evaluate    ${hits}+1
        END
    END
    Log    ${hits}
    ${actual_percentage}=    Evaluate    (${hits}/${total})*100
    ${diff}=    Evaluate    abs(${exp_percentage}-${actual_percentage})
    IF    ${diff} > ${toleration} or ${actual_percentage} == ${0}
        Fail    msg=Percentage of traffic redirected to new revision is greater than toleration ${toleration}%
    END

Get KServe Inference Host Via CLI
    [Documentation]    Fetches the model URL
    [Arguments]    ${isvc_name}    ${namespace}    ${retries}=10
    ${ksvc_host}=    Set Variable    ""
    ${condition1}=    Evaluate    ${ksvc_host}=="${EMPTY}"
    ${condition2}=    Evaluate    ${retries} > 0
    WHILE    ${condition1} and ${condition2}
        Sleep    5s
        ${rc}    ${ksvc_host}=    Run And Return Rc And Output
        ...    oc get isvc ${isvc_name} -n ${namespace} -o jsonpath='{.status.url}' | cut -d'/' -f3
        Should Be Equal As Integers    ${rc}    ${0}
        ${retries} =    Evaluate    ${retries} - 1
        ${condition1}=    Evaluate    "${ksvc_host}"=="${EMPTY}"
        ${condition2}=    Evaluate    ${retries} > 0
    END
    Should Not Be Empty    ${ksvc_host}
    RETURN    ${ksvc_host}

Get Current Revision ID
    [Documentation]    Fetches the knative revision ID for the given model
    [Arguments]    ${model_name}    ${namespace}
    ${rc}    ${id}=    Run And Return Rc And Output
    ...    oc get pod -n ${namespace} -l serving.kserve.io/inferenceservice=${model_name} -ojson | jq '.items[0].metadata.labels."serving.knative.dev/revisionUID"' | tr -d '"'
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${id}

Set Minimum Replicas Number
    [Documentation]    Sets the minimum number of model replicas in the corresponding InferenceService
    [Arguments]    ${n_replicas}    ${model_name}    ${namespace}
    ${old_revision_id}=    Get Current Revision ID    model_name=${model_name}    namespace=${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc patch InferenceService ${model_name} -n ${namespace} --type=json -p="[{'op': 'replace', 'path': '/spec/predictor/minReplicas', 'value': ${n_replicas}}]"
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${old_revision_id}

Delete InfereceService
    [Documentation]    Deletes the given InferenceService
    [Arguments]    ${isvc_name}    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output    oc delete InferenceService ${isvc_name} -n ${namespace}
    Should Be Equal As Integers    ${rc}    ${0}

Set Model Hardware Resources
    [Documentation]    Edits the hardware requirements for the given model by patching the corresponding InferenceService
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

Load Expected Responses
    [Documentation]    Loads the json file containing the expected answer for each
    ...                query and model
    [Arguments]    ${exp_res_filepath}=${EXP_RESPONSES_FILEPATH}
    ${exp_responses}=    Load Json File    ${exp_res_filepath}
    Set Suite Variable    ${EXP_RESPONSES}    ${exp_responses}

Fetch Knative CA Certificate
    [Documentation]    Gets the CA certificate defined in the secret `knative-serving-cert` in namespace `istio-system`
    ...                namespace. Useful when working with self-managed clusters to verify connections (TLS)
    [Arguments]    ${filename}=openshift_ca_istio_knative.crt
    ${rc} =    Run And Return Rc
    ...    oc get secret -n istio-system knative-serving-cert -o json | jq '.data."tls.crt"' | sed 's/"//g' | base64 -d > ${filename}    # robocop: disable
    Should Be Equal As Strings    ${rc}    ${0}

Generate Client TLS Certificates
    [Documentation]    Generates and self-signes local certificates for the client. It creates:
    ...                - ${dirpath}/client_certs
    ...                - ${dirpath}/client_certs/root.crt
    ...                - ${dirpath}/client_certs/root.key
    ...                - ${dirpath}/client_certs/sign_req.csr
    ...                - ${dirpath}/client_certs/private.key
    ...                - ${dirpath}/client_certs/public.crt
    [Arguments]    ${dirpath}=${CURDIR}
    Log    ${CURDIR}
    Log    ${EXECDIR}
    ${abs_path}=    Set Variable    ${EXECDIR}/${dirpath}
    ${rc}    Run and Watch Command    cd ${abs_path} && ${abs_path}/gen_client_certs.sh    timeout=2 min
    Should Be Equal As Integers  ${rc}   ${0}   msg=Error detected while generating client certificates

Clean Up Test Project
    [Documentation]    Deletes the given InferenceServices, check the NS gets removed from ServiceMeshMemberRoll
    ...                and deletes the DS Project
    [Arguments]    ${test_ns}    ${isvc_names}    ${isvc_delete}=${TRUE}    ${wait_prj_deletion}=${TRUE}
    ...            ${kserve_mode}=${NONE}
    IF    ${isvc_delete} == ${TRUE}
        FOR    ${index}    ${isvc_name}    IN ENUMERATE    @{isvc_names}
              Log    Deleting ${isvc_name}
              Delete InfereceService    isvc_name=${isvc_name}    namespace=${test_ns}
        END
    ELSE
        Log To Console     InferenceService Delete option not provided by user
    END
    IF    $kserve_mode is None
        ${kserve_mode}=    Get KServe Default Deployment Mode From DSC
        Log    message=Using defaultDeploymentMode set in the DSC: ${kserve_mode}
    END
    IF    "${kserve_mode}"=="Serverless"
           Wait Until Keyword Succeeds    10    1s    Namespace Should Be Removed From ServiceMeshMemberRoll
           ...    namespace=${test_ns}
    END
    ${rc}    ${out}=    Run And Return Rc And Output    oc delete project ${test_ns}
    Should Be Equal As Integers    ${rc}    ${0}
    IF    ${wait_prj_deletion}
        ${rc}    ${out}=    Run And Return Rc And Output    oc wait --for=delete namespace ${test_ns} --timeout=300s
        Should Be Equal As Integers    ${rc}    ${0}
    ELSE
        Log    Project deletion started, but won't wait for it to finish..
    END

Create PVC And Download Model From S3
    [Arguments]    ${model_name}    ${bucket_name}
    ...            ${use_https}    ${namespace}    ${storage_size}
    ...            ${model_path}    ${download_timeout}=500s
    Set Log Level    NONE
    Set Test Variable    ${model_name}
    Set Test Variable    ${bucket_name}
    # AWS variables defined in the Setup Test Variables
    Set Test Variable    ${use_https}
    Set Test Variable    ${namespace}
    Set Test Variable    ${storage_size}
    Set Test Variable    ${model_path}
    Set Log Level    INFO
    Create File From Template    ${DOWNLOAD_PVC_FILEPATH}    ${DOWNLOAD_PVC_FILLED_FILEPATH}
    ${rc}    ${out}=    Run And Return Rc And Output    oc -n ${namespace} apply -f ${DOWNLOAD_PVC_FILLED_FILEPATH}
    Should Be Equal As Integers    ${rc}    ${0}
    Wait For Pods To Be Ready    label_selector=name=download-${model_name}    namespace=${namespace}
    Wait For Pods To Succeed    label_selector=name=download-${model_name}    namespace=${namespace}
    ...    timeout=${download_timeout}
    ${rc}    ${out}=    Run And Return Rc And Output    oc delete pods -l name=download-${model_name} -n ${namespace}
    Should Be Equal As Integers    ${rc}    ${0}

Extract Service Port
    [Arguments]    ${service_name}    ${namespace}    ${protocol}
    IF    "${protocol}" == "grpc"
        ${port_name}=    Set Variable    h2c
    ELSE
        ${port_name}=    Set Variable    ${protocol}
    END
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get svc/${service_name} -n ${namespace} -o jsonpath='{range .spec.ports[?(@.name=="${port_name}")]}{@.targetPort}{end}'
    Should Be Equal As Integers    ${rc}    ${0}    msg=${out}
    RETURN    ${out}

Download Prompts Weights In PVC
    [Arguments]    ${prompts_path}    ${model_name}    ${bucket_name}
    ...            ${use_https}    ${namespace}    ${storage_size}
    ...            ${model_path}    ${download_timeout}=120s
    Set Log Level    NONE
    Set Test Variable    ${prompts_path}
    Set Test Variable    ${model_name}
    Set Test Variable    ${bucket_name}
    # AWS variables defined in the Setup Test Variables
    Set Test Variable    ${use_https}
    Set Test Variable    ${namespace}
    Set Test Variable    ${storage_size}
    Set Test Variable    ${model_path}
    Set Log Level    INFO
    Create File From Template    ${DOWNLOAD_PROMPTS_PVC_FILEPATH}    ${DOWNLOAD_PROMPTS_PVC_FILLED_FILEPATH}
    ${rc}    ${out}=    Run And Return Rc And Output    oc -n ${namespace} apply -f ${DOWNLOAD_PROMPTS_PVC_FILLED_FILEPATH}
    Should Be Equal As Integers    ${rc}    ${0}
    Wait For Pods To Be Ready    label_selector=name=${model_name}-download-prompts    namespace=${namespace}
    Wait For Pods To Succeed    label_selector=name=${model_name}-download-prompts    namespace=${namespace}
    ...    timeout=${download_timeout}

Get KServe Default Deployment Mode From DSC
    [Arguments]    ${dsc_name}=${DSC_NAME}
    ${rc}    ${mode}=    Run And Return Rc And Output
    ...    oc get dsc ${DSC_NAME} -ojsonpath='{.spec.components.kserve.defaultDeploymentMode}'
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${rc}    ${0}    msg=${mode}
    IF    "${mode}" == "${EMPTY}"
        Log    message=if defaultDeploymentMode is not set, then it means Serverless
        ${mode}=    Set Variable    Serverless
    END
    RETURN    ${mode}

Start Port-forwarding
    [Arguments]    ${namespace}    ${pod_name}    ${process_alias}=llm-query-process    ${local_port}=8033
    ...    ${remote_port}=8033
    ${process}=    Start Process    oc -n ${namespace} port-forward pod/${pod_name} ${local_port}:${remote_port}
    ...    alias=${process_alias}    stderr=STDOUT    shell=yes
    Process Should Be Running    ${process}
    sleep  7s

Create Role Binding For Authorino
    [Arguments]    ${name}    ${namespace}
    Set Test Variable    ${name}
    Set Test Variable    ${namespace}
    Set Test Variable    ${nameview}    ${name}-view
    Set Test Variable    ${namesa}    ${name}-sa
    Create File From Template    ${ROLE_BINDING_FILEPATH}   ${LLM_RESOURCES_DIRPATH}/rb.filled.yaml
    ${rc}    ${out}=    Run And Return Rc And Output
    ...     oc apply -f ${LLM_RESOURCES_DIRPATH}/rb.filled.yaml
    Should Be Equal As Integers    ${rc}    ${0}

Create Inference Access Token
    [Arguments]  ${test_namespace}  ${bucket_sa_name}
    ${rc}    ${out}=    Run And Return Rc And Output    oc create token -n ${test_namespace} ${bucket_sa_name}
    Should Be Equal As Strings    ${rc}    0
    [Return]    ${out}

Wait For Model KServe Deployment To Be Ready
    [Documentation]    Waits for the Pod to be Ready (i.e., Running status) and checks that
    ...                the deployment has the expected pods and containers
    [Arguments]    ${label_selector}    ${namespace}    ${runtime}
    ...    ${timeout}=300s    ${exp_replicas}=${1}
    Wait For Pods To Be Ready    label_selector=${label_selector}    namespace=${namespace}    timeout=${timeout}
    Verify Model KServe Deployment    ${label_selector}    ${namespace}    ${runtime}    ${exp_replicas}

Verify Model KServe Deployment
    [Documentation]    Checks the given deployment has the expected pods and containers
    [Arguments]    ${label_selector}    ${namespace}    ${runtime}    ${exp_replicas}
    ${test_mode_var_exist}=    Run Keyword And Return Status    Variable Should Exist    ${KSERVE_MODE}
    ${dsc_raw_var_exist}=    Run Keyword And Return Status    Variable Should Exist    ${IS_KSERVE_RAW}
    IF    ${test_mode_var_exist}
        IF    "${KSERVE_MODE}" == "RawDeployment"
            Set Test Variable    ${is_raw}    ${TRUE}
        ELSE
            Set Test Variable    ${is_raw}    ${FALSE}
        END
    ELSE IF  ${dsc_raw_var_exist}
        IF    ${IS_KSERVE_RAW}
            Set Test Variable    ${is_raw}    ${TRUE}
        ELSE
            Set Test Variable    ${is_raw}    ${FALSE}
        END
    ELSE
        Fail    msg=either ${KSERVE_MODE} or ${IS_KSERVE_RAW} suite/global variables are expected to be set
    END
    Load Runtime Query Formats
    @{model_pods}=  Oc Get    kind=Pod    namespace=${namespace}    label_selector=${label_selector}
    ${containers}=  Set Variable    ${RUNTIME_FORMATS}[${runtime}][containers]
    IF    not ${is_raw}
        ${serverless_container}=    Create List    queue-proxy    istio-proxy
        Append To List    ${containers}    @{serverless_container}
    END
    ${n_containers}=    Get Length    ${containers}
    Run Keyword And Continue On Failure    Verify Deployment    ${model_pods}  ${exp_replicas}
    ...    ${n_containers}  ${containers}
