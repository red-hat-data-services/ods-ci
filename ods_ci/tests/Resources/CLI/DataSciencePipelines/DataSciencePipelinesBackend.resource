*** Settings ***
Documentation    Collection of keywords to interact with Data Science Pipelines via CLI
Library          String
Library          ../../../../libs/DataSciencePipelinesAPI.py
Library          ../../../../libs/DataSciencePipelinesKfp.py
Resource         ../../../Resources/OCP.resource
Resource         ../../../Resources/Common.robot


*** Variables ***
${DSPA_PATH}=      tests/Resources/Files/pipeline-samples/v2/dspa


*** Keywords ***
Create Pipeline Server
    [Documentation]    Creates a pipeline server providing object storage and database information
    ...    When ${configure_pip_index}=${TRUE}, a configmap ds-pipeline-custom-env-vars is added to the
    ...    project, storing the values for pip_index_url and pip_trusted_host
    ...
    ...    Note: currently, only some of the parameters are used. In the future this keyword will be
    ...    enhanced to use them all
    [Arguments]    ${namespace}
    ...    ${object_storage_access_key}    ${object_storage_secret_key}
    ...    ${object_storage_endpoint}      ${object_storage_region}
    ...    ${object_storage_bucket_name}
#    ...    ${database_host}=${EMPTY}    ${database_port}=3306
#    ...    ${database_username}=${EMPTY}    ${database_password}=${EMPTY}
#    ...    ${database_db_name}=${EMPTY}
    ...    ${configure_pip_index}=${TRUE}

    Create Secret With Pipelines Object Storage Information    namespace=${namespace}
    ...    object_storage_access_key=${object_storage_access_key}
    ...    object_storage_secret_key=${object_storage_secret_key}

    # Pipeline Server creation fails if object storage url starts with https:// or http:// or if it ends with /
    ${object_storage_endpoint}=    Remove String    ${object_storage_endpoint}    https://    http://
    ${object_storage_endpoint}=    Strip String     ${object_storage_endpoint}    characters=/

    # Process DSPA Template to create pipeline server
    ${template_parameters}=    Catenate
    ...    -p OBJECT_STORAGE_HOST=${object_storage_endpoint}
    ...    -p OBJECT_STORAGE_REGION=${object_storage_region}
    ...    -p OBJECT_STORAGE_BUCKET=${object_storage_bucket_name}

    Run And Verify Command    oc process -f ${DSPA_PATH}/dspa-template.yaml ${template_parameters} | oc apply -n ${namespace} -f -    # robocop: off=line-too-long

    IF  ${configure_pip_index}   Create Pipelines ConfigMap With Custom Pip Index Url And Trusted Host  ${namespace}

Create Pipeline Server From CLI    # robocop: off=too-many-calls-in-keyword
    [Documentation]    Creates the pipeline server Secret and DataSciencePipelinesApplication directly.
    ...    AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are stored in secret dashboard-dspa-secret,
    ...    which is the Secret a dashboard-created pipeline server references.
    ...    Bucket, region, and endpoint are DSPA spec fields. The pipeline server does not read them
    ...    from a Connection Secret, so none is created.
    ...    A scheme and a trailing slash on ${aws_s3_endpoint} are removed from the DSPA host.
    [Arguments]    ${project_title}
    ...    ${aws_access_key}
    ...    ${aws_secret_access}
    ...    ${aws_bucket_name}
    ...    ${aws_s3_endpoint}=${S3.AWS_DEFAULT_ENDPOINT}
    ...    ${aws_region}=${S3.AWS_DEFAULT_REGION}

    Create Secret With Pipelines Object Storage Information    namespace=${project_title}
    ...    object_storage_access_key=${aws_access_key}
    ...    object_storage_secret_key=${aws_secret_access}

    ${scheme}=    Set Variable    https
    ${is_http}=    Run Keyword And Return Status    Should Start With    ${aws_s3_endpoint}    http://
    IF    ${is_http}
        ${scheme}=    Set Variable    http
    END
    ${host}=    Remove String    ${aws_s3_endpoint}    https://    http://
    ${host}=    Strip String    ${host}    characters=/

    ${template_parameters}=    Catenate
    ...    -p OBJECT_STORAGE_HOST=${host}
    ...    -p OBJECT_STORAGE_REGION=${aws_region}
    ...    -p OBJECT_STORAGE_BUCKET=${aws_bucket_name}
    ...    -p OBJECT_STORAGE_SCHEME=${scheme}
    Run And Verify Command    oc process -f ${DSPA_PATH}/dspa-dashboard-template.yaml ${template_parameters} | oc apply -n ${project_title} -f -    # robocop: off=line-too-long

# robocop: disable:line-too-long
Create PipelineServer Using Custom DSPA
    [Documentation]    Install and verifies that DataSciencePipelinesApplication CRD is installed and working
    ...    When ${configure_pip_index}=${TRUE}, a configmap ds-pipeline-custom-env-vars is added to the
    ...    project, storing the values for pip_index_url and pip_trusted_host
    ...
    [Arguments]     ${namespace}    ${dspa_file}=data-science-pipelines-sample.yaml
    ...    ${assert_install}=${TRUE}    ${configure_pip_index}=${TRUE}

    Run And Verify Command     oc apply -f "${DSPA_PATH}/${dspa_file}" -n ${namespace}

    IF  ${configure_pip_index}   Create Pipelines ConfigMap With Custom Pip Index Url And Trusted Host  ${namespace}

Verify Pipeline Server Deployments    # robocop: disable
    [Documentation]    Verifies the correct deployment of a DSPv2 DataSciencePipelineApplication
    [Arguments]    ${namespace}

    @{all_pods}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=component=data-science-pipelines

    ${pods_count}=   Get Length    ${all_pods}
    IF    ${pods_count} < 7
         Fail    DSPA requires at least 7 pods running in the namespace
    END

    @{pipeline_api_server}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-dspa
    ${containerNames}=  Create List  kube-rbac-proxy    ds-pipeline-api-server
    Verify Deployment    ${pipeline_api_server}  1  2  ${containerNames}

    @{pipeline_metadata_envoy}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-metadata-envoy-dspa
    ${containerNames}=  Create List  container    kube-rbac-proxy
    Verify Deployment    ${pipeline_metadata_envoy}  1  2  ${containerNames}

    @{pipeline_metadata_grpc}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-metadata-grpc-dspa
    ${containerNames}=  Create List  container
    Verify Deployment    ${pipeline_metadata_grpc}  1  1  ${containerNames}

    @{pipeline_persistenceagent}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-persistenceagent-dspa
    ${containerNames}=  Create List  ds-pipeline-persistenceagent
    Verify Deployment    ${pipeline_persistenceagent}  1  1  ${containerNames}

    @{pipeline_scheduledworkflow}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-scheduledworkflow-dspa
    ${containerNames}=  Create List  ds-pipeline-scheduledworkflow
    Verify Deployment    ${pipeline_scheduledworkflow}  1  1  ${containerNames}

    @{pipeline_workflow_controller}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-workflow-controller-dspa
    ${containerNames}=  Create List  ds-pipeline-workflow-controller
    Verify Deployment    ${pipeline_workflow_controller}  1  1  ${containerNames}

    @{mariadb}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=mariadb-dspa
    ${containerNames}=  Create List  mariadb
    Verify Deployment    ${mariadb}  1  1  ${containerNames}

Wait Until Pipeline Server Is Deployed
    [Documentation]    Waits until all the expected pods of the pipeline server
    ...                are running
    [Arguments]    ${namespace}

    Wait Until Keyword Succeeds    15 times    10s
    ...    Verify Pipeline Server Deployments    namespace=${namespace}

Wait Until Pipeline Server Is Deleted
    [Documentation]    Waits until all pipeline server pods are deleted
    [Arguments]    ${namespace}
    # robocop: off=expression-can-be-simplified
    FOR  ${_}  IN RANGE  0  30
        ${pod_count}=    Run    oc get pods -n ${namespace} -l component=data-science-pipelines | wc -l
        IF  ${pod_count}==0  BREAK
        Sleep  1s
    END

Get Nonready Pipeline Server Conditions
    [Documentation]    Returns a comma separated "Type=Status" list of the DSPA conditions that are
    ...    not True, or an empty string when the pipeline server is healthy.
    [Arguments]    ${namespace}
    ${out}=    Run    oc get dspa dspa -n ${namespace} -o jsonpath='{range .status.conditions[?(@.status!="True")]}{.type}={.status}{"\n"}{end}' 2>/dev/null | grep -v '^ManagedPipelineValid=' | grep -v '^$' | paste -sd, -    # robocop: off=line-too-long
    RETURN    ${out.strip()}

Get First Failed Workflow Step
    [Documentation]    Returns "<step> (<phase>)" for the first Argo workflow node in a failed or
    ...    errored phase, or an empty string when there is none.
    ...    Returns step name and phase instead of node message to prevent echoing component config.
    [Arguments]    ${namespace}
    ${out}=    Run    oc get workflows.argoproj.io -n ${namespace} -o jsonpath='{range .items[*].status.nodes[*]}{.phase}{"\t"}{.displayName}{"\n"}{end}' 2>/dev/null | awk -F'\t' '$1=="Failed" || $1=="Error" {print $2" ("$1")"; exit}'    # robocop: off=line-too-long
    RETURN    ${out.strip()}

Get Pipeline Run Failure Summary
    [Documentation]    Oneline return explaining why a run did not succeed, for use in the
    ...    failure message itself. The TFA sign-off bot copies that message into the Jira issue.
    ...    Returns an empty string when nothing conclusive was found.
    ...    Built only from the two getters above, so it inherits their bounded output.
    ...    Adding unbounded output could cause it to leak to JIRA.
    [Arguments]    ${namespace}
    ${nonready}=    Get Nonready Pipeline Server Conditions    ${namespace}
    IF    '${nonready}' != '${EMPTY}'    RETURN    pipeline server was not ready (${nonready})
    ${step}=    Get First Failed Workflow Step    ${namespace}
    IF    '${step}' != '${EMPTY}'    RETURN    first failing step ${step}
    RETURN    ${EMPTY}

Log Pipeline Diagnostics
    [Documentation]    Writes pipeline server, workflow, pod and event state to the log so a failed
    ...    run can be triaged from the report alone.
    [Arguments]    ${namespace}
    Run Keyword And Warn On Failure    Collect Pipeline Diagnostics    ${namespace}

Collect Pipeline Diagnostics
    [Documentation]    Body of Log Pipeline Diagnostics, split out so the wrapper can swallow
    ...    failures while this stays readable.
    ...    Prints only bounded values: condition types and statuses, Kubernetes state reasons,
    ...    exit codes, phases, and names of objects the test created. Free text from a failing
    ...    component is excluded to avoid leaking component configuration.
    ...    Hold any new field to that same standard.
    [Arguments]    ${namespace}
    ${conditions}=    Run    oc get dspa dspa -n ${namespace} -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}' 2>/dev/null    # robocop: off=line-too-long
    Log    Pipeline server (DSPA) conditions:\n${conditions}    console=True
    ${steps}=    Run    oc get workflows.argoproj.io -n ${namespace} -o jsonpath='{range .items[*].status.nodes[*]}{.displayName}{"="}{.phase}{"\n"}{end}' 2>/dev/null | grep -v '=Succeeded$' | grep -v '^$'    # robocop: off=line-too-long
    Log    Workflow steps that did not succeed:\n${steps}    console=True
    ${pods}=    Run    oc get pods -n ${namespace} --no-headers -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,TERMINATED:.status.containerStatuses[*].state.terminated.reason,EXIT:.status.containerStatuses[*].state.terminated.exitCode,WAITING:.status.containerStatuses[*].state.waiting.reason 2>/dev/null    # robocop: off=line-too-long
    Log    Pod states (name, phase, terminated reason, exit code, waiting reason):\n${pods}    console=True
    ${events}=    Run    oc get events -n ${namespace} --field-selector type=Warning --sort-by=.lastTimestamp --no-headers -o custom-columns=REASON:.reason,OBJECT:.involvedObject.name,COUNT:.count 2>/dev/null | tail -20    # robocop: off=line-too-long
    Log    Recent warning events (reason, object, count):\n${events}    console=True

# robocop: disable:line-too-long
Create Pipelines ConfigMap With Custom Pip Index Url And Trusted Host
    [Documentation]     Creates a Configmap (ds-pipeline-custom-env-vars) in the project,
    ...    storing the values for pip_index_url and pip_trusted_host
    [Arguments]    ${namespace}
    Run And Verify Command    oc create configmap ds-pipeline-custom-env-vars -n ${namespace} --from-literal=pip_index_url=${PIP_INDEX_URL} --from-literal=pip_trusted_host=${PIP_TRUSTED_HOST}    # robocop: off=line-too-long

Create Secret With Pipelines Object Storage Information
    [Documentation]     Creates a secret needed to create a pipeline server containing the object storage credentials
    [Arguments]    ${namespace}    ${object_storage_access_key}    ${object_storage_secret_key}
    Run And Verify Command    oc create secret generic dashboard-dspa-secret -n ${namespace} --from-literal=AWS_ACCESS_KEY_ID=${object_storage_access_key} --from-literal=AWS_SECRET_ACCESS_KEY=${object_storage_secret_key}    # robocop: off=line-too-long
    Run And Verify Command    oc label secret dashboard-dspa-secret -n ${namespace} opendatahub.io/dashboard=true

Import Pipeline And Create Run
    [Documentation]
    [Arguments]    ${namespace}           ${username}                ${password}
    ...    ${pipeline_name}               ${pipeline_description}    ${pipeline_package_path}
    ...    ${pipeline_run_name}           ${pipeline_run_params}=${None}
    ...    ${experiment_name}=Default     ${experiment_description}=${EMPTY}

    DataSciencePipelinesKfp.Setup Client    user=${username}    pwd=${password}    project=${namespace}

    ${pipeline_id}    ${pipeline_version_id}=    DataSciencePipelinesKfp.Upload Pipeline
    ...   pipeline_package_path=${pipeline_package_path}
    ...   pipeline_name=${pipeline_name}
    ...   description=${pipeline_description}
    ...   namespace=${namespace}

    ${experiment_id}=    DataSciencePipelinesKfp.Create Experiment    name=${experiment_name}
    ...    description=${experiment_description}    namespace=${namespace}

    ${pipeline_run_id}=    DataSciencePipelinesKfp.Run Pipeline
    ...   experiment_id=${experiment_id}
    ...   job_name=${pipeline_run_name}
    ...   pipeline_id=${pipeline_id}
    ...   version_id=${pipeline_version_id}
    ...   params=${pipeline_run_params}

    RETURN    ${pipeline_id}    ${pipeline_version_id}    ${pipeline_run_id}    ${experiment_id}

Get Last Run By Pipeline Name
    [Documentation]  Returns ${pipeline_run_id} of the last run for the last version of ${pipeline_name}
    [Arguments]    ${namespace}    ${username}    ${password}    ${pipeline_name}

    DataSciencePipelinesKfp.Setup Client    user=${username}    pwd=${password}    project=${namespace}
    ${pipeline_run_id}=    DataSciencePipelinesKfp.Get Last Run By Pipeline Name    pipeline_name=${pipeline_name}

    RETURN    ${pipeline_run_id}

Get Run Status
    [Documentation]  Returns run status for ${pipeline_run_id}
    [Arguments]    ${namespace}    ${username}    ${password}    ${pipeline_run_id}

    DataSciencePipelinesKfp.Setup Client    user=${username}    pwd=${password}    project=${namespace}
    ${pipeline_run_status}=    DataSciencePipelinesKfp.Get Run Status    run_id=${pipeline_run_id}
    RETURN    ${pipeline_run_status}

Verify Run Status
    [Documentation]  Verifies pipeline run status matches ${pipeline_run_expected_status}
    [Arguments]    ${namespace}           ${username}                  ${password}
    ...    ${pipeline_run_id}    ${pipeline_run_expected_status}="SUCCEEDED"

    ${pipeline_run_status}=    DataSciencePipelinesBackend.Get Run Status
    ...        ${namespace}    ${username}    ${password}    ${pipeline_run_id}

    IF   "${pipeline_run_status}" != "${pipeline_run_expected_status}"
        ${error_msg}=    Catenate    Expected pipeline status was ${pipeline_run_expected_status} but pipeline run
        ...    has status=${pipeline_run_status}
        Fail    ${error_msg}
    END

Wait For Run Completion And Verify Status
    [Documentation]
    [Arguments]    ${namespace}           ${username}                  ${password}
    ...    ${pipeline_run_id}             ${pipeline_run_timeout}=180
    ...    ${pipeline_run_expected_status}="SUCCEEDED"

    DataSciencePipelinesKfp.Setup Client    user=${username}    pwd=${password}    project=${namespace}

    ${pipeline_run_status}=    DataSciencePipelinesKfp.Wait For Run Completion    run_id=${pipeline_run_id}
    ...    timeout=${pipeline_run_timeout}     sleep_duration=${5}

    Verify Run Status   namespace=${namespace}    username=${username}    password=${password}
    ...    pipeline_run_id=${pipeline_run_id}    pipeline_run_expected_status=${pipeline_run_expected_status}

    RETURN    ${pipeline_run_status}

Delete Pipeline And Related Resources
    [Documentation]  Deletes a pipeline, all it's versions and runs depending on the parameters
    ...    If ${delete_versions}=${TRUE}, deletes all versions
    ...    If ${delete_runs}=${TRUE}, deletes pipeline runs in ${experiment_id}
    ...    If ${experiment_id} is not provided, Default experiment will be used
    [Tags]    robot:recursive-continue-on-failure
    [Arguments]    ${namespace}           ${username}                ${password}
    ...    ${pipeline_id}                 ${experiment_id}=${EMPTY}
    ...    ${delete_versions}=${TRUE}     ${delete_runs}=${TRUE}

    DataSciencePipelinesKfp.Setup Client    user=${username}    pwd=${password}    project=${namespace}

    IF    ${delete_runs}==True
        DataSciencePipelinesKfp.Delete All Runs For Pipeline
        ...    namespace=${namespace}    pipeline_id=${pipeline_id}    experiment_id=${experiment_id}
    END

    # TODO: delete recurent jobs

    IF    ${delete_versions}==True
        DataSciencePipelinesKfp.Delete All Pipeline Versions    ${pipeline_id}
    END

    DataSciencePipelinesKfp.Delete Pipeline    ${pipeline_id}
